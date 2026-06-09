import { ToriiClient } from "@dojoengine/torii-client";
import { selectedProfileConfig } from "@/dojo/dojoConfig";

// Single shared Torii client for the active profile. The wasm `ToriiClient`
// constructor connects asynchronously and resolves to the instance, so `new`
// actually yields a Promise — memoize that promise and await it at call sites.
let clientPromise: Promise<ToriiClient> | undefined;

/** Lazily create and memoize the Torii client for the selected profile. */
export function getToriiClient(): Promise<ToriiClient> {
	if (!clientPromise) {
		clientPromise = Promise.resolve(
			new ToriiClient({
				toriiUrl: selectedProfileConfig.toriiUrl,
				worldAddress: selectedProfileConfig.contractAddresses.world,
			}) as unknown as Promise<ToriiClient>,
		);
	}
	return clientPromise;
}
