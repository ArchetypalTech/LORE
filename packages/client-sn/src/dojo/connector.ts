import { ControllerConnector } from "@cartridge/connector";
import type { SessionPolicies } from "@cartridge/controller";
import { constants } from "starknet";
import { selectedProfileConfig } from "./dojoConfig";

// `lore_sn-permit_token` for the active profile (resolved from its manifest).
const PERMIT_TOKEN_ADDRESS = selectedProfileConfig.contractAddresses.permit_token;

const policies: SessionPolicies = {
	contracts: {
		[PERMIT_TOKEN_ADDRESS]: {
			description: ">ORUG Permit token",
			methods: [
				{ name: "Use Permits", entrypoint: "use_permits" },
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
