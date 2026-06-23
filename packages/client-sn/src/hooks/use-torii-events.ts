import type { ModelDef, Stores } from "@/lib/torii";
import {
	type ClientGetter,
	type ToriiSource,
	useToriiStore,
} from "@/hooks/use-torii-store";

// Event-message flow: `getEventMessages` + `onEventMessageUpdated`, matching
// every event message carrying one of the tracked models.
const EVENTS_SOURCE: ToriiSource = {
	keys: [undefined],
	fetchPage: (client, clause, tags, cursor) =>
		client.getEventMessages({
			world_addresses: [],
			pagination: { limit: 1000, cursor, direction: "Forward", order_by: [] },
			clause,
			no_hashed_keys: false,
			models: tags,
			historical: false,
		}),
	subscribe: (client, clause, callback) =>
		client.onEventMessageUpdated(clause, undefined, callback),
};

/**
 * Live view of the given event-message `models` from the world served by
 * `getClient`. Returns a store map per model; see {@link useToriiStore}.
 */
export function useToriiEvents(
	getClient: ClientGetter,
	models: readonly ModelDef<unknown>[],
): Stores {
	return useToriiStore(getClient, models, EVENTS_SOURCE);
}
