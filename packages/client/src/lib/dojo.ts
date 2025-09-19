import { createDojoConfig, DojoProvider } from "@dojoengine/core";
import {
	init,
	type StandardizedQueryResult,
	ToriiQueryBuilder,
} from "@dojoengine/sdk";
import { LORE_CONFIG } from "@lib/config";
import {
	type SchemaType,
	schema,
} from "@lib/dojo_bindings/typescript/models.gen";

/**
 * ## Initializes the Dojo SDK and configuration
 * @dev @dojoengine/sdk has WASM components which cannot be linked to in other parts of the client
 * @warning
 * ### 🚸 after a fresh sozo build of the bindings you may see a `BigNumberish` error in `models.gen.ts`
 * this can be fixed by prefixing the import with `'type'`
 * #### Example: `import { CairoCustomEnum, type BigNumberish } from "starknet"`
 * @returns An object containing the initialized SDK, config, provider, and query functions
 */
export const InitDojo = async () => {
	const manifest = LORE_CONFIG.manifest.default;
	const rpcUrl = LORE_CONFIG.endpoints.katana;
	const dojoConfig = createDojoConfig({
			manifest,
			rpcUrl,
			toriiUrl: LORE_CONFIG.endpoints.torii.http,
			masterAddress: LORE_CONFIG.wallet.address,
			masterPrivateKey: LORE_CONFIG.wallet.private_key,
			accountClassHash: LORE_CONFIG.manifest.world.class_hash,
			feeTokenAddress: LORE_CONFIG.manifest.world.fee_token_address,
		});

	const sdkConfig = {
		client: {
			rpcUrl,
			toriiUrl: LORE_CONFIG.endpoints.torii.http,
			worldAddress: dojoConfig.manifest.world.address,
		},
		// Those values are used
		domain: {
			name: "lore",
			version: "1.0",
			chainId: "KATANA",
			revision: "1",
		},
		schema,
	};

	const sdk = await init<SchemaType>(sdkConfig);

	const provider = new DojoProvider(manifest, rpcUrl);

	const query = () => {
			const builder = new ToriiQueryBuilder<SchemaType>();
			// const query = builder.withOffset(0).withLimit(1000);

			const query = builder.withCursor("").withLimit(1000).includeHashedKeys();
			return query;
		};

	/**
	 * Dojo Entity Subscription Query
	 */
	const sub = async (
		callback: (response: {
			data?: StandardizedQueryResult<SchemaType> | undefined;
			error?: Error;
		}) => void,
		sub_query?: ToriiQueryBuilder<SchemaType>,
	) => {
		return await sdk.subscribeEntityQuery({
			query: sub_query ?? query(),
			callback,
		});
	};

	// console.log( {sdk, dojoConfig, provider, query, sub})

	return { sdk, dojoConfig, provider, query, sub };
};
