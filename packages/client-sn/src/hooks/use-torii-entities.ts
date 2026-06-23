import type { ModelDef, Stores } from "@/lib/torii";
import {
	type ClientGetter,
	type ToriiSource,
	useToriiStore,
} from "@/hooks/use-torii-store";

// Entities flow: `getEntities` + `onEntityUpdated`, matching any entity that
// carries one of the tracked models.
const ENTITIES_SOURCE: ToriiSource = {
	keys: [],
	fetchPage: (client, clause, tags, cursor) =>
		client.getEntities({
			world_addresses: [],
			pagination: { limit: 1000, cursor, direction: "Forward", order_by: [] },
			clause,
			no_hashed_keys: false,
			models: tags,
			historical: false,
		}),
	subscribe: (client, clause, callback) =>
		client.onEntityUpdated(clause, undefined, callback),
};

/**
 * Live view of the given entity `models` from the world served by `getClient`.
 * Returns a store map per model; see {@link useToriiStore}.
 */
export function useToriiEntities(
	getClient: ClientGetter,
	models: readonly ModelDef<unknown>[],
): Stores {
	return useToriiStore(getClient, models, ENTITIES_SOURCE);
}
