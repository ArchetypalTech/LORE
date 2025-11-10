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
import { addAddressPadding } from "starknet";


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
	const manifest = LORE_CONFIG.dojo_manifest;
	const rpcUrl = LORE_CONFIG.rpcUrl;
	const dojoConfig = createDojoConfig({
			manifest,
			rpcUrl,
			toriiUrl: LORE_CONFIG.toriiUrl,
			masterAddress: LORE_CONFIG.burnerAddress ? addAddressPadding(LORE_CONFIG.burnerAddress) : undefined,
			masterPrivateKey: LORE_CONFIG.burnerPrivateKey ? addAddressPadding(LORE_CONFIG.burnerPrivateKey) : undefined,
		});
	const sdkConfig = {
		client: {
			rpcUrl,
			toriiUrl: LORE_CONFIG.toriiUrl,
			worldAddress: addAddressPadding(manifest.world.address),
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
			
			const query = builder.withCursor("")
			.withLimit(90000)
			.includeHashedKeys()
			.withEntityModels(
				[
					"lore-Entity",
					"lore-Area",
					"lore-Exit",
					"lore-Reactable",
					"lore-DescriptionText",
					"lore-Container",
					"lore-InventoryItem",
					"lore-Action",
					"lore-Condition",
					"lore-Trigger",
					"lore-Effect",
					"lore-Player",
					"lore-ParentToChildren",
					"lore-ChildToParent",
					"lore-PlayerStory",
				]);
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
