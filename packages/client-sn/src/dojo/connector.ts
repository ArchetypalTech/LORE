import { ControllerConnector } from "@cartridge/connector";
import type { SessionPolicies } from "@cartridge/controller";
import { constants } from "starknet";
import { NAMESPACE, RPC_URL } from "./dojoConfig";

// `lore_sn-permit_token` on Starknet Sepolia (manifest_sepolia.json).
const PERMIT_TOKEN_ADDRESS =
	"0x52073be9902c993ddb321883133b8c64e0a1c544af014c2a36c367fdcd8d2e6";

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
 * Connects to the L2 Starknet Sepolia world (lore_sn).
 */
export const controllerConnector = new ControllerConnector({
	namespace: NAMESPACE,
	chains: [{ rpcUrl: RPC_URL }],
	defaultChainId: constants.StarknetChainId.SN_SEPOLIA,
	policies,
});
