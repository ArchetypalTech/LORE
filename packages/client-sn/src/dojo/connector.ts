import { ControllerConnector } from "@cartridge/connector";
import type { SessionPolicies } from "@cartridge/controller";
import { constants } from "starknet";
import { selectedProfileConfig } from "./dojoConfig";

// `lore_sn-permit_token` for the active profile (resolved from its manifest).
const PERMIT_TOKEN_ADDRESS = selectedProfileConfig.contractAddresses.permit_token;

const policies: SessionPolicies = {
	contracts: {
		[PERMIT_TOKEN_ADDRESS]: {
			description: "Starter pack purchase and approvals for >LORE on Starknet",
			methods: [
				{ name: "Buy starter pack", entrypoint: "purchased_starter_pack" },
				{ name: "Approve", entrypoint: "approve" },
			],
		},
	},
};

/**
 * Single Controller connector instance for the app.
 * Connects to the L2 Starknet world (lore_sn) for the active profile.
 */
export const controllerConnector = new ControllerConnector({
	namespace: selectedProfileConfig.namespace,
	chains: [{ rpcUrl: selectedProfileConfig.rpcUrl }],
	defaultChainId: constants.StarknetChainId.SN_SEPOLIA,
	preset: "orug",
	policies,
});
