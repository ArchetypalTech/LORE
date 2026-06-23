import { ControllerConnector } from "@cartridge/connector";
import type { SessionPolicies } from "@cartridge/controller";
import { PROFILE } from "./dojoConfig";

// `lore_sn-permit_token` for the active profile (resolved from its manifest).
const PERMIT_TOKEN_ADDRESS = PROFILE.contractAddresses.starknet.permit_token;

const policies: SessionPolicies = {
	contracts: {
		[PERMIT_TOKEN_ADDRESS]: {
			description: ">ORUG Permit token",
			methods: [
				{ name: "Use Permits", entrypoint: "use_permits" },
				{ name: "Consume Message", entrypoint: "consume_message" },
			],
		},
	},
};

/**
 * Single Controller connector instance for the app.
 * Connects to the L2 Starknet world (lore_sn) for the active profile.
 */
export const controllerConnector = new ControllerConnector({
	namespace: PROFILE.namespace.starknet,
	chains: [{ rpcUrl: PROFILE.rpcUrl.starknet }],
	defaultChainId: PROFILE.chainId,
	preset: "orug",
	policies,
});
