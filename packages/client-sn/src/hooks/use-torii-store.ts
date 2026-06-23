import type {
	Clause,
	Entities,
	Entity,
	Subscription,
	ToriiClient,
} from "@dojoengine/torii-client";
import { useEffect, useRef, useState } from "react";
import { emptyStores, type ModelDef, type Stores } from "@/lib/torii";

/** Resolves the Torii client for a given world (L2 or L3). */
export type ClientGetter = () => Promise<ToriiClient>;

/**
 * The two ways Torii exposes data — entities (`getEntities`/`onEntityUpdated`)
 * and event messages (`getEventMessages`/`onEventMessageUpdated`). A source
 * abstracts over which pair to use so the fetch + subscribe machinery is shared.
 */
export interface ToriiSource {
	/** `keys` segment of the matching clause. */
	keys: (string | undefined)[];
	/** Fetch one page for the clause. */
	fetchPage: (
		client: ToriiClient,
		clause: Clause,
		tags: string[],
		cursor: string | undefined,
	) => Promise<Entities>;
	/** Subscribe to live updates for the clause. */
	subscribe: (
		client: ToriiClient,
		clause: Clause,
		callback: (entity: Entity) => void,
	) => Promise<Subscription>;
}

/**
 * Owns a single Torii fetch + subscription covering every model in `models`,
 * via the given `source`. Each model is parsed into its own store map and kept
 * live; the latest snapshot of every changed store is returned.
 *
 * `getClient`, `models` and `source` must be stable references (module-level
 * constants) — the subscription is established once on mount.
 */
export function useToriiStore(
	getClient: ClientGetter,
	models: readonly ModelDef<unknown>[],
	source: ToriiSource,
): Stores {
	const [stores, setStores] = useState<Stores>(() => emptyStores(models));
	// Mutable working copy; state holds published snapshots of the changed maps.
	const workRef = useRef<Stores>(undefined);
	if (!workRef.current) workRef.current = emptyStores(models);

	useEffect(() => {
		const work = workRef.current as Stores;
		let subscription: Subscription | undefined;
		let cancelled = false;

		const tags = models.map((m) => m.tag);
		// Clause matching every entity/message carrying one of the tracked models.
		const clause: Clause = {
			Keys: { keys: source.keys, pattern_matching: "VariableLen", models: tags },
		};

		// Route an entity into the store of each model it carries.
		const apply = (entity: Entity, changed: Set<string>) => {
			for (const def of models) {
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
			const client = await getClient();
			if (cancelled) return;

			const changed = new Set<string>();
			let cursor: string | undefined;
			do {
				const page = await source.fetchPage(client, clause, tags, cursor);
				if (cancelled) return;
				page.items.forEach((entity) => apply(entity, changed));
				cursor = page.next_cursor;
			} while (cursor);
			publish(changed);

			subscription = await source.subscribe(client, clause, (entity) => {
				const c = new Set<string>();
				apply(entity, c);
				publish(c);
			});
			if (cancelled) subscription.cancel();
		})();

		return () => {
			cancelled = true;
			subscription?.cancel();
		};
	}, [getClient, models, source]);

	return stores;
}
