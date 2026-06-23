import {
	createContext,
	type PropsWithChildren,
	useContext,
	useMemo,
} from "react";
import { PROFILE } from "@/dojo/dojoConfig";
import { getToriiClientStarknet } from "@/dojo/torii";
import { useToriiEntities } from "@/hooks/use-torii-entities";
import { useToriiEvents } from "@/hooks/use-torii-events";
import {
	type MessageConsumedEvent,
	type ModelDef,
	parseMessageConsumedEvent,
	parsePermitTokenInfo,
	tag,
} from "@/lib/torii";

const NS = PROFILE.namespace.starknet;

// ── Model registries ──────────────────────────────────────────────────────────
// One source of truth per Torii flow. To add a model: write its `Parse<T>` in
// `lib/torii.ts`, add an entry to the matching registry below, then add its
// `store` field to `ToriiStarknetModels`. The machinery needs no other changes.

/** Models read as entities (`getEntities` / `onEntityUpdated`). */
const ENTITY_MODELS: readonly ModelDef<unknown>[] = [
	{
		store: "permitTokenInfos",
		tag: tag(NS, "PermitTokenInfo"),
		parse: parsePermitTokenInfo,
	},
];

/** Models read as event messages (`getEventMessages` / `onEventMessageUpdated`). */
const EVENT_MODELS: readonly ModelDef<unknown>[] = [
	{
		store: "messageConsumedEvents",
		tag: tag(NS, "MessageConsumedEvent"),
		parse: parseMessageConsumedEvent,
	},
];

// ── Context ──────────────────────────────────────────────────────────────────

/** Typed view of the provider's stores; one field per registered model. */
interface ToriiStarknetModels {
	/** PermitTokenInfo: permit id (decimal string) → is_used. */
	permitTokenInfos: Map<string, boolean>;
	/** MessageConsumedEvent: uuid (decimal string) → event. */
	messageConsumedEvents: Map<string, MessageConsumedEvent>;
}

const ToriiStarknetContext = createContext<ToriiStarknetModels | undefined>(
	undefined,
);

/**
 * Owns the Torii fetch + subscriptions for the active profile's L2 world: the
 * `PermitTokenInfo` entities and the `MessageConsumedEvent` event messages.
 * Each model is parsed into its own store map and kept live; hooks read the
 * maps via {@link useToriiStarknetContext} and filter to what they need.
 */
export function ToriiStarknetProvider({ children }: PropsWithChildren) {
	const entities = useToriiEntities(getToriiClientStarknet, ENTITY_MODELS);
	const events = useToriiEvents(getToriiClientStarknet, EVENT_MODELS);
	const value = useMemo(
		() => ({ ...entities, ...events }) as unknown as ToriiStarknetModels,
		[entities, events],
	);

	return (
		<ToriiStarknetContext.Provider value={value}>
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

/**
 * Returns the `MessageConsumedEvent`s served by {@link ToriiStarknetProvider},
 * sorted by `uuid` ascending. Must be used under a `<ToriiStarknetProvider>`.
 */
export function useMessageConsumedEvents(): MessageConsumedEvent[] {
	const { messageConsumedEvents } = useToriiStarknetContext();
	return useMemo(
		() => [...messageConsumedEvents.values()].sort((a, b) => a.uuid - b.uuid),
		[messageConsumedEvents],
	);
}
