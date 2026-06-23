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
import { getToriiClientAppchain } from "@/dojo/torii";

type ModelData = Entity["models"][string];

// A model's contribution to its store: the key it's indexed by and its value.
type Parse<T> = (model: ModelData) => [key: string, value: T] | undefined;

interface ModelDef<T> {
	/** Store name — must match a field in {@link ToriiAppchainModels}. */
	store: string;
	/** Namespaced Dojo model tag. */
	tag: string;
	/** Turns a model into a `[key, value]` entry for its store. */
	parse: Parse<T>;
}

const tag = (name: string): string => `${PROFILE.namespace.appchain}-${name}`;

export type AppchainMessageEvent = {
	uuid: number;
	callerAddress: string;
	fromAddress: string;
	toAddress: string;
	blockNumber: number;
	blockTimestamp: number;
	messageHash: string;
	messageType: string;
	/** Raw `Array<felt252>` payload, as decimal/hex felt strings — what
	 * `consume_message` on the L2 permit token expects back verbatim. */
	payload: string[];
};

// A Dojo `Array<felt252>` field arrives as a Ty whose `value` is an array of
// primitive Tys; flatten it to the felt strings.
const parseFeltArray = (field: ModelData[string] | undefined): string[] =>
	Array.isArray(field?.value)
		? (field.value as { value: unknown }[]).map((item) => String(item.value))
		: [];

// AppchainMessageEvent: keyed by uuid (decimal string) → the parsed event.
const parseAppchainMessageEvent: Parse<AppchainMessageEvent> = (model) => {
	if (model?.uuid == null) return undefined;
	const uuid = Number(model.uuid.value);
	return [
		String(uuid),
		{
			uuid,
			callerAddress: String(model.caller_address?.value ?? ""),
			fromAddress: String(model.from_address?.value ?? ""),
			toAddress: String(model.to_address?.value ?? ""),
			blockNumber: Number(model.block_number?.value ?? 0),
			blockTimestamp: Number(model.block_timestamp?.value ?? 0),
			messageHash: String(model.message_hash?.value ?? ""),
			messageType: String(model.message_type?.value ?? ""),
			payload: parseFeltArray(model.payload),
		},
	];
};

// ── Model registry ──────────────────────────────────────────────────────────
// The single source of truth for what the provider tracks. To add a model:
//   1. write a `Parse<T>` for it,
//   2. add an entry here,
//   3. add its `store` field to `ToriiAppchainModels` below.
// The fetch + subscription machinery needs no other changes.
const MODELS: readonly ModelDef<unknown>[] = [
	{ store: "appchainMessageEvents", tag: tag("AppchainMessageEvent"), parse: parseAppchainMessageEvent },
];

const ALL_TAGS = MODELS.map((m) => m.tag);

// Clause matching every event message carrying one of the tracked models.
const ALL_MODELS_CLAUSE: Clause = {
	Keys: { keys: [undefined], pattern_matching: "VariableLen", models: ALL_TAGS },
};

// ── Context ──────────────────────────────────────────────────────────────────

/** Typed view of the provider's stores; one field per registered model. */
interface ToriiAppchainModels {
	/** AppchainMessageEvent: uuid (decimal string) → event. */
	appchainMessageEvents: Map<string, AppchainMessageEvent>;
}

type Stores = Record<string, Map<string, unknown>>;

const emptyStores = (): Stores => {
	const stores: Stores = {};
	for (const m of MODELS) stores[m.store] = new Map();
	return stores;
};

const ToriiAppchainContext = createContext<ToriiAppchainModels | undefined>(
	undefined,
);

/**
 * Owns a single Torii fetch + subscription covering every model in {@link MODELS}
 * for the active profile's appchain (L3) world. Each event message is parsed into
 * its own store map and kept live; hooks read the maps via
 * {@link useToriiAppchainContext} and shape them to what they need.
 */
export function ToriiAppchainProvider({ children }: PropsWithChildren) {
	const [stores, setStores] = useState<Stores>(emptyStores);
	// Mutable working copy; state holds published snapshots of the changed maps.
	const workRef = useRef<Stores>(undefined);
	if (!workRef.current) workRef.current = emptyStores();

	useEffect(() => {
		const work = workRef.current as Stores;
		let subscription: Subscription | undefined;
		let cancelled = false;

		// Route an event message into the store of each model it carries.
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
			const client = await getToriiClientAppchain();
			if (cancelled) return;

			const changed = new Set<string>();
			let cursor: string | undefined;
			do {
				const page = await client.getEventMessages({
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

			subscription = await client.onEventMessageUpdated(
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
		<ToriiAppchainContext.Provider
			value={stores as unknown as ToriiAppchainModels}
		>
			{children}
		</ToriiAppchainContext.Provider>
	);
}

/**
 * Access the models served by {@link ToriiAppchainProvider}. Throws if used
 * outside a `<ToriiAppchainProvider>`.
 */
export function useToriiAppchainContext(): ToriiAppchainModels {
	const ctx = useContext(ToriiAppchainContext);
	if (ctx === undefined) {
		throw new Error(
			"useToriiAppchainContext must be used within a <ToriiAppchainProvider>",
		);
	}
	return ctx;
}

/**
 * Returns the `AppchainMessageEvent`s served by {@link ToriiAppchainProvider},
 * sorted by `uuid` ascending. Must be used under a `<ToriiAppchainProvider>`.
 */
export function useAppchainMessageEvents(): AppchainMessageEvent[] {
	const { appchainMessageEvents } = useToriiAppchainContext();

	// console.log(`EVENTS:`,appchainMessageEvents)
	return useMemo(
		() =>
			[...appchainMessageEvents.values()].sort((a, b) => a.uuid - b.uuid),
		[appchainMessageEvents],
	);
}
