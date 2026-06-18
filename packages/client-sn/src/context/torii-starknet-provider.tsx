import type { Clause, Entity, Subscription } from "@dojoengine/torii-client";
import {
	createContext,
	type PropsWithChildren,
	useContext,
	useEffect,
	useMemo,
	useRef,
	useState,
} from "react";
import { PROFILE } from "@/dojo/dojoConfig";
import { getToriiClientStarknet } from "@/dojo/torii";

type ModelData = Entity["models"][string];

// A model's contribution to its store: the key it's indexed by and its value.
type Parse<T> = (model: ModelData) => [key: string, value: T] | undefined;

interface ModelDef<T> {
	/** Store name — must match a field in {@link ToriiStarknetModels}. */
	store: string;
	/** Namespaced Dojo model tag. */
	tag: string;
	/** Turns a model into a `[key, value]` entry for its store. */
	parse: Parse<T>;
}

const tag = (name: string): string => `${PROFILE.namespace.starknet}-${name}`;

// PermitTokenInfo: keyed by permit id (decimal string) → is_used.
const parsePermitTokenInfo: Parse<boolean> = (model) => {
	if (!model?.permit_id) return undefined;
	return [
		BigInt(String(model.permit_id.value)).toString(),
		Boolean(model.is_used?.value),
	];
};

// ── Model registry ──────────────────────────────────────────────────────────
// The single source of truth for what the provider tracks. To add a model:
//   1. write a `Parse<T>` for it,
//   2. add an entry here,
//   3. add its `store` field to `ToriiStarknetModels` below.
// The fetch + subscription machinery needs no other changes.
const MODELS: readonly ModelDef<unknown>[] = [
	{ store: "permitTokenInfos", tag: tag("PermitTokenInfo"), parse: parsePermitTokenInfo },
];

const ALL_TAGS = MODELS.map((m) => m.tag);

// Clause matching any entity that carries one of the tracked models.
const ALL_MODELS_CLAUSE: Clause = {
	Keys: { keys: [], pattern_matching: "VariableLen", models: ALL_TAGS },
};

// ── Context ──────────────────────────────────────────────────────────────────

/** Typed view of the provider's stores; one field per registered model. */
interface ToriiStarknetModels {
	/** PermitTokenInfo: permit id (decimal string) → is_used. */
	permitTokenInfos: Map<string, boolean>;
}

type Stores = Record<string, Map<string, unknown>>;

const emptyStores = (): Stores => {
	const stores: Stores = {};
	for (const m of MODELS) stores[m.store] = new Map();
	return stores;
};

const ToriiStarknetContext = createContext<ToriiStarknetModels | undefined>(
	undefined,
);

/**
 * Owns a single Torii fetch + subscription covering every model in {@link MODELS}
 * for the active profile's L2 world. Each model is parsed into its own store map
 * and kept live; hooks read the maps via {@link useToriiStarknetContext} and
 * filter to what they need.
 */
export function ToriiStarknetProvider({ children }: PropsWithChildren) {
	const [stores, setStores] = useState<Stores>(emptyStores);
	// Mutable working copy; state holds published snapshots of the changed maps.
	const workRef = useRef<Stores>(undefined);
	if (!workRef.current) workRef.current = emptyStores();

	useEffect(() => {
		const work = workRef.current as Stores;
		let subscription: Subscription | undefined;
		let cancelled = false;

		// Route an entity into the store of each model it carries.
		const apply = (entity: Entity, changed: Set<string>) => {
			for (const def of MODELS) {
				const model = entity.models[def.tag];
				if (!model) continue;
				const kv = def.parse(model);
				if (!kv) continue;
				work[def.store].set(kv[0], kv[1]);
				changed.add(def.store);
			}
		};

		// Re-snapshot only the stores that changed; others keep their identity.
		const publish = (changed: Set<string>) => {
			if (changed.size === 0) return;
			setStores((prev) => {
				const next = { ...prev };
				for (const store of changed) next[store] = new Map(work[store]);
				return next;
			});
		};

		(async () => {
			const client = await getToriiClientStarknet();
			if (cancelled) return;

			const changed = new Set<string>();
			let cursor: string | undefined;
			do {
				const page = await client.getEntities({
					world_addresses: [],
					pagination: {
						limit: 1000,
						cursor,
						direction: "Forward",
						order_by: [],
					},
					clause: ALL_MODELS_CLAUSE,
					no_hashed_keys: false,
					models: ALL_TAGS,
					historical: false,
				});
				if (cancelled) return;
				page.items.forEach((entity) => apply(entity, changed));
				cursor = page.next_cursor;
			} while (cursor);
			publish(changed);

			subscription = await client.onEntityUpdated(
				ALL_MODELS_CLAUSE,
				undefined,
				(entity: Entity) => {
					const c = new Set<string>();
					apply(entity, c);
					publish(c);
				},
			);
			if (cancelled) subscription.cancel();
		})();

		return () => {
			cancelled = true;
			subscription?.cancel();
		};
	}, []);

	return (
		<ToriiStarknetContext.Provider
			value={stores as unknown as ToriiStarknetModels}
		>
			{children}
		</ToriiStarknetContext.Provider>
	);
}

/**
 * Access the models served by {@link ToriiStarknetProvider}. Throws if used
 * outside a `<ToriiStarknetProvider>`.
 */
export function useToriiStarknetContext(): ToriiStarknetModels {
	const ctx = useContext(ToriiStarknetContext);
	if (ctx === undefined) {
		throw new Error(
			"useToriiStarknetContext must be used within a <ToriiStarknetProvider>",
		);
	}
	return ctx;
}

/**
 * Returns a map of permit id (decimal string) → `is_used` for the given owned
 * token ids, filtered from the provider's full `PermitTokenInfo` set. Must be
 * used under a `<ToriiStarknetProvider>`.
 */
export function usePermitTokenInfos(tokenIds: string[]): Map<string, boolean> {
	const { permitTokenInfos } = useToriiStarknetContext();
	// Stable dependency: re-filter only when the owned set actually changes.
	const key = tokenIds.join(",");

	return useMemo(() => {
		const ids = key ? key.split(",") : [];
		const filtered = new Map<string, boolean>();
		for (const id of ids) {
			const k = BigInt(id).toString();
			const used = permitTokenInfos.get(k);
			if (used !== undefined) filtered.set(k, used);
		}
		return filtered;
	}, [permitTokenInfos, key]);
}
