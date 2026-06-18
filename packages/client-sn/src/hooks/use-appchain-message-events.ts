import type {
	Clause,
	Entity,
	KeysClause,
	Subscription,
} from "@dojoengine/torii-client";
import { useEffect, useState } from "react";
import { PROFILE } from "@/dojo/dojoConfig";
import { getToriiClientAppchain } from "@/dojo/torii";

const MODEL_TAG = `${PROFILE.namespace.appchain}-AppchainMessageEvent`;

export type AppchainMessageEvent = {
	uuid: number;
	callerAddress: string;
	fromAddress: string;
	toAddress: string;
	blockNumber: number;
	blockTimestamp: number;
	messageHash: string;
	messageType: string;
};

/**
 * Fetches the `AppchainMessageEvent` Dojo events from the appchain Torii and
 * keeps them live via an event-message subscription. Returns the events sorted
 * by `uuid` ascending.
 */
export function useAppchainMessageEvents(): AppchainMessageEvent[] {
	const [events, setEvents] = useState<AppchainMessageEvent[]>([]);

	useEffect(() => {
		// uuid -> event.
		const byUuid = new Map<number, AppchainMessageEvent>();
		let subscription: Subscription | undefined;
		let cancelled = false;

		// Match every AppchainMessageEvent (its single key is `uuid`).
		const clause: Clause = {
			Keys: {
				keys: [undefined],
				pattern_matching: "VariableLen",
				models: [MODEL_TAG],
			} satisfies KeysClause,
		};

		const apply = (entity: Entity) => {
			const model = entity.models[MODEL_TAG];
			if (model?.uuid == null) return;
			const uuid = Number(model.uuid.value);
			byUuid.set(uuid, {
				uuid,
				callerAddress: String(model.caller_address?.value ?? ""),
				fromAddress: String(model.from_address?.value ?? ""),
				toAddress: String(model.to_address?.value ?? ""),
				blockNumber: Number(model.block_number?.value ?? 0),
				blockTimestamp: Number(model.block_timestamp?.value ?? 0),
				messageHash: String(model.message_hash?.value ?? ""),
				messageType: String(model.message_type?.value ?? ""),
			});
		};

		const publish = () =>
			setEvents([...byUuid.values()].sort((a, b) => a.uuid - b.uuid));

		(async () => {
			const client = await getToriiClientAppchain();
			if (cancelled) return;

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
					clause,
					no_hashed_keys: false,
					models: [MODEL_TAG],
					historical: false,
				});
				if (cancelled) return;
				page.items.forEach(apply);
				cursor = page.next_cursor;
			} while (cursor);
			publish();

			// Keep the list live as new appchain messages are emitted.
			subscription = await client.onEventMessageUpdated(
				clause,
				undefined,
				(entity: Entity) => {
					apply(entity);
					publish();
				},
			);
			if (cancelled) subscription.cancel();
		})();

		return () => {
			cancelled = true;
			subscription?.cancel();
		};
	}, []);

	return events;
}
