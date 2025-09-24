import Controller, { type ControllerOptions } from "@cartridge/controller";
import { LORE_CONFIG } from "@lib/config";
import { WalletAccount, addAddressPadding } from "starknet";
import { APP_EDITOR_DATA } from "@/data/app.data";
import { StoreBuilder } from "../utils/storebuilder";

/**
 * Interface representing the wallet state.
 * @interface WalletStore
 * @property {WalletAccount | undefined} account - The wallet account instance
 * @property {string | undefined} username - The user's username
 * @property {string | undefined} walletAddress - The wallet's address
 * @property {Controller | undefined} controller - The cartridge controller instance
 * @property {boolean} isConnected - Indicates if the wallet is connected
 * @property {boolean} isLoading - Indicates if wallet operations are in progress
 */
interface WalletStore {
	account: WalletAccount | undefined;
	username: string | undefined;
	walletAddress: string | undefined;
	controller: Controller | undefined;
	isConnected: boolean;
	isLoading: boolean;
}

const {
	get,
	set,
	createFactory,
	useStore: useWalletStore,
} = StoreBuilder<WalletStore>({
	account: undefined,
	username: undefined,
	walletAddress: undefined,
	controller: undefined,
	isConnected: false,
	isLoading: false,
});

/**
 * Sets up the Cartridge controller with required configuration.
 * Configures policies, chains, and tokens for the controller.
 * @returns {Promise<Controller | undefined>} The configured controller instance
 */
const setupController = async () => {
	const worldName = LORE_CONFIG.manifest.default.world.name;
	// const isEditor = window.location.pathname.startsWith("/editor");
	// const editorConfig = {
	// 	[LORE_CONFIG.manifest.designer.address]: {
	// 		name: APP_EDITOR_DATA.title, // Optional, can be added if you want a name
	// 		description: `Aprove submitting transactions to ${APP_EDITOR_DATA.title}`,
	// 		methods: [
	// 			{
	// 				entrypoint: "register_property_registry",
	// 				description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
	// 			},
	// 			{
	// 				entrypoint: "create_player",
	// 				description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
	// 			},
	// 			{
	// 				entrypoint: "create_entity",
	// 				description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
	// 			},
	// 			{
	// 				entrypoint: "create_reactable",
	// 				description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
	// 			},
	// 			{
	// 				entrypoint: "create_description_text",
	// 				description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
	// 			},
	// 			{
	// 				entrypoint: "create_area",
	// 				description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
	// 			},
	// 			{
	// 				entrypoint: "create_exit",
	// 				description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
	// 			},
	// 			{
	// 				entrypoint: "create_inventory_item",
	// 				description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
	// 			},
	// 			{
	// 				entrypoint: "create_container",
	// 				description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
	// 			},
	// 			{
	// 				entrypoint: "create_parent",
	// 				description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
	// 			},
	// 			{
	// 				entrypoint: "create_condition",
	// 				description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
	// 			},
	// 			{
	// 				entrypoint: "create_effect",
	// 				description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
	// 			},
	// 			{
	// 				entrypoint: "create_action",
	// 				description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
	// 			},
	// 			{
	// 				entrypoint: "create_trigger",
	// 				description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
	// 			},
	// 			{
	// 				entrypoint: "create_child",
	// 				description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
	// 			},
	// 			{
	// 				entrypoint: "delete_player",
	// 				description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
	// 			},
	// 			{
	// 				entrypoint: "delete_entity",
	// 				description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
	// 			},
	// 			{
	// 				entrypoint: "delete_reactable",
	// 				description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
	// 			},
	// 			{
	// 				entrypoint: "delete_description_text",
	// 				description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
	// 			},
	// 			{
	// 				entrypoint: "delete_description_text",
	// 				description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
	// 			},
	// 			{
	// 				entrypoint: "delete_area",
	// 				description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
	// 			},
	// 			{
	// 				entrypoint: "delete_exit",
	// 				description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
	// 			},
	// 			{
	// 				entrypoint: "delete_condition",
	// 				description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
	// 			},
	// 			{
	// 				entrypoint: "delete_inventory_item",
	// 				description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
	// 			},
	// 			{
	// 				entrypoint: "delete_trigger",
	// 				description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
	// 			},
	// 			{
	// 				entrypoint: "delete_effect",
	// 				description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
	// 			},
	// 			{
	// 				entrypoint: "delete_action",
	// 				description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
	// 			},
	// 			{
	// 				entrypoint: "delete_container",
	// 				description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
	// 			},
	// 			{
	// 				entrypoint: "delete_parent",
	// 				description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
	// 			},
	// 			{
	// 				entrypoint: "delete_child",
	// 				description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
	// 			},
	// 		],
	// 	},
	// };
	const controllerConfig: ControllerOptions = {
		namespace: "lore_staging",
		policies: {
			contracts: {
				[addAddressPadding(LORE_CONFIG.manifest.entity.address)]: {
					name: worldName, // Optional, can be added if you want a name
					description: `Aprove submitting transactions to ${worldName}`,
					methods: [
						{
							entrypoint: "prompt",
							description: `The terminal endpoint for ${worldName}`,
						},
					],
				},
				// ...(isEditor ? editorConfig : {}),
				// [LORE_CONFIG.token.contract_address]: {
				// 	name: "TOT NFT", // Optional
				// 	description: "Mint and transfer TOT tokens",
				// 	methods: [
				// 		{
				// 			entrypoint: "mint", // The actual method name
				// 			description: "Approve minting a TOT Token",
				// 		},
				// 		{
				// 			entrypoint: "transfer_from", // The actual method name
				// 			description: "Transfer a TOT Token",
				// 		},
				// 	],
				// },
				[addAddressPadding(LORE_CONFIG.manifest.designer.address)]: {
					name: APP_EDITOR_DATA.title, // Optional, can be added if you want a name
					description: `Aprove submitting transactions to ${APP_EDITOR_DATA.title}`,
					methods: [
						{
							entrypoint: "register_property_registry",
							description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
						},
						{
							entrypoint: "create_player",
							description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
						},
						{
							entrypoint: "create_entity",
							description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
						},
						{
							entrypoint: "create_reactable",
							description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
						},
						{
							entrypoint: "create_description_text",
							description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
						},
						{
							entrypoint: "create_area",
							description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
						},
						{
							entrypoint: "create_exit",
							description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
						},
						{
							entrypoint: "create_inventory_item",
							description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
						},
						{
							entrypoint: "create_container",
							description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
						},
						{
							entrypoint: "create_parent",
							description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
						},
						{
							entrypoint: "create_condition",
							description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
						},
						{
							entrypoint: "create_effect",
							description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
						},
						{
							entrypoint: "create_action",
							description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
						},
						{
							entrypoint: "create_trigger",
							description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
						},
						{
							entrypoint: "create_child",
							description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
						},
						{
							entrypoint: "delete_player",
							description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
						},
						{
							entrypoint: "delete_entity",
							description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
						},
						{
							entrypoint: "delete_reactable",
							description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
						},
						{
							entrypoint: "delete_description_text",
							description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
						},
						{
							entrypoint: "delete_description_text",
							description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
						},
						{
							entrypoint: "delete_area",
							description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
						},
						{
							entrypoint: "delete_exit",
							description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
						},
						{
							entrypoint: "delete_condition",
							description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
						},
						{
							entrypoint: "delete_inventory_item",
							description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
						},
						{
							entrypoint: "delete_trigger",
							description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
						},
						{
							entrypoint: "delete_effect",
							description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
						},
						{
							entrypoint: "delete_action",
							description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
						},
						{
							entrypoint: "delete_container",
							description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
						},
						{
							entrypoint: "delete_parent",
							description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
						},
						{
							entrypoint: "delete_child",
							description: `The terminal endpoint for ${APP_EDITOR_DATA.title}`,
						},
					],
				},
			},
		},
		chains: [
			{
				rpcUrl: LORE_CONFIG.env.VITE_KATANA_HTTP_RPC, // FIXME: workaround for endpoint being proxied
			},
		],
		defaultChainId: LORE_CONFIG.token.chainId, // controller chain id
		tokens: {
			// erc20: LORE_CONFIG.token.erc20,
			//erc721: [addrContract],
		},
		slot: LORE_CONFIG.env.VITE_SLOT,
	};

	try {
		const controller = new Controller(controllerConfig);
		console.log("DEBUG: controller", controller);
		set({
			controller,
		});
		return controller;
	} catch (e) {
		console.error("Error creating controller", e);
	}
};

/**
 * Connects to the wallet using the configured controller.
 * Sets wallet state including account, username, and address on successful connection.
 * @throws {Error} When controller is not found or connection fails
 */
const connectController = async () => {
	const wallet = get();
	if (wallet.isConnected) {
		return;
	}
	set({ isLoading: true });
	try {
		const controller = get().controller;
		if (!controller) {
			throw new Error("No controller found");
		}
		console.log("DEBUG: Getting controller response:", controller);
		const res = await controller.connect(); // Get response from the
		if (!res) {
			throw new Error("No response from Cartridge Game Controller");
		}
		console.log("DEBUG: controller response:", res);
		const data = {
			account: res,
			username: await controller.username(),
			walletAddress: addAddressPadding(res.address),	
			isConnected: true,
			isLoading: false,
			controller,
		} satisfies WalletStore;
		console.log(
			"[Controller] username:",
			data.username,
			"address:",
			data.walletAddress,
		);
		set(data);
	} catch (e) {
		console.error(e);
		throw e;
	} finally {
		set({ isLoading: false });
	}
};

/**
 * Opens the user profile in the Controller UI.
 * Navigates to the inventory section of the profile.
 */
const openUserProfile = () => {
	get().controller?.openProfile("inventory");
};

/**
 * Disconnects the wallet from the application.
 * Resets wallet state to default values.
 */
const disconnectController = async () => {
	get().controller?.disconnect(); // Disconnect the controller
	set({
		account: undefined,
		username: undefined,
		walletAddress: undefined,
		isConnected: false,
	});
};

/**
 * Factory function that returns wallet store state and methods.
 * Provides access to the entire wallet API in one object.
 * @returns {Object} Combined wallet state and methods
 */
const WalletStore = createFactory({
	setupController,
	connectController,
	openUserProfile,
	disconnectController,
});

export default WalletStore;
export { useWalletStore };

// Initialize controller if using slot configuration
if (LORE_CONFIG.useController) {
	await setupController();
	const account = await get().controller?.probe();
	console.log("DEBUG: account", account);
	if (account !== undefined) {
		console.log("[Controller] connected");
		await connectController();
	}
}
