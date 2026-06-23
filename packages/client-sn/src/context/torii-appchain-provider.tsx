import {
	createContext,
	type PropsWithChildren,
	useContext,
	useMemo,
} from "react";
import { PROFILE } from "@/dojo/dojoConfig";
import { getToriiClientAppchain } from "@/dojo/torii";
import { useToriiEvents } from "@/hooks/use-torii-events";
import {
	type AppchainMessageEvent,
	type ModelDef,
	parseAppchainMessageEvent,
	tag,
} from "@/lib/torii";

const NS = PROFILE.namespace.appchain;

// ── Model registry ──────────────────────────────────────────────────────────
// The single source of truth for what the provider tracks. To add a model:
//   1. write a `Parse<T>` for it in `lib/torii.ts`,
//   2. add an entry here,
//   3. add its `store` field to `ToriiAppchainModels` below.
// The fetch + subscription machinery needs no other changes.
const MODELS: readonly ModelDef<unknown>[] = [
	{
		store: "appchainMessageEvents",
		tag: tag(NS, "AppchainMessageEvent"),
		parse: parseAppchainMessageEvent,
	},
];

// ── Context ──────────────────────────────────────────────────────────────────

/** Typed view of the provider's stores; one field per registered model. */
interface ToriiAppchainModels {
	/** AppchainMessageEvent: uuid (decimal string) → event. */
	appchainMessageEvents: Map<string, AppchainMessageEvent>;
}

const ToriiAppchainContext = createContext<ToriiAppchainModels | undefined>(
	undefined,
);

/**
 * Owns a single Torii event-message subscription covering every model in
 * {@link MODELS} for the active profile's appchain (L3) world. Hooks read the
 * maps via {@link useToriiAppchainContext} and shape them to what they need.
 */
export function ToriiAppchainProvider({ children }: PropsWithChildren) {
	const stores = useToriiEvents(getToriiClientAppchain, MODELS);
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
	return useMemo(
		() => [...appchainMessageEvents.values()].sort((a, b) => a.uuid - b.uuid),
		[appchainMessageEvents],
	);
}
