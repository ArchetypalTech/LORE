import { useMemo } from "react";
import { useAppchainMessageEvents } from "@/context/torii-appchain-provider";
import { useMessageConsumedEvents } from "@/context/torii-starknet-provider";
import type { AppchainMessageEvent } from "@/lib/torii";

export type AppchainMessageEventStatus = AppchainMessageEvent & {
	/** True once L2 has emitted a matching MessageConsumedEvent (same uuid). */
	consumed: boolean;
};

/**
 * Appchain (L3) message events joined with their L2 consumption status: an
 * event is `consumed` once the Starknet world emits a `MessageConsumedEvent`
 * carrying the same uuid. Sorted by uuid ascending. Must be used under both
 * `<ToriiAppchainProvider>` and `<ToriiStarknetProvider>`.
 */
export function useAppchainMessageEventsStatus(): AppchainMessageEventStatus[] {
	const events = useAppchainMessageEvents();
	const consumed = useMessageConsumedEvents();

	return useMemo(() => {
		const consumedUuids = new Set(consumed.map((e) => e.uuid));
		return events.map((e) => ({ ...e, consumed: consumedUuids.has(e.uuid) }));
	}, [events, consumed]);
}
