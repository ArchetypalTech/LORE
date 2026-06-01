import { type Chain, devnet, mainnet, sepolia } from "@starknet-react/chains";
import { addAddressPadding } from "starknet";
import { bigintToHex, stringToFelt } from "@/lib/utils";
// L2 Starknet world manifests. client-sn always targets packages/starknet (lore_sn),
// never the L3 packages/contracts (lore) engine.
import manifest_dev from "@lore/starknet/manifest_dev.json";
import manifest_sepolia from "@lore/starknet/manifest_sepolia.json";
// No mainnet export from @lore/starknet yet — stub until the world is deployed.
const manifest_mainnet = {};

// Dojo namespace of the L2 world (see packages/starknet/dojo_*.toml).
const NAMESPACE = "lore_sn";

// No burner accounts in client-sn — connection is always via Cartridge Controller.
export const burnerAccounts: never[] = [];

//----------------------------------------------------
// Profiles
//

export type ProfileName = "dev" | "sepolia" | "mainnet";

export type ProfileConfig = {
	profileName: ProfileName;
	dojo_manifest: any;
	namespace: string;
	chain: Chain; // @starknet-react/chains chain for StarknetConfig
	chainName: string;
	chainId: `0x${string}`; // chain name in hex used by starknet
	rpcUrl: string;
	toriiUrl: string;
	slotName: string | undefined;
	useController: boolean;
	burnerAccount?: (typeof burnerAccounts)[number] | undefined;
	//
	// built in getProfileConfig()
	contractAddresses: {
		world: string;
		permit_token: string;
	};
};

const profileConfigs: Record<ProfileName, ProfileConfig> = {
	dev: {
		profileName: "dev",
		dojo_manifest: manifest_dev,
		namespace: NAMESPACE,
		chain: devnet,
		chainName: "KATANA",
		chainId: bigintToHex(stringToFelt("KATANA")),
		rpcUrl: "http://localhost:50000/",
		toriiUrl: "http://localhost:8080",
		slotName: undefined,
		useController: true,
		burnerAccount: undefined,
		contractAddresses: {} as any,
	},
	sepolia: {
		profileName: "sepolia",
		dojo_manifest: manifest_sepolia,
		namespace: NAMESPACE,
		chain: sepolia,
		chainName: "SN_SEPOLIA",
		chainId: bigintToHex(stringToFelt("SN_SEPOLIA")),
		rpcUrl: "https://api.cartridge.gg/x/starknet/sepolia/rpc/v0_9",
		toriiUrl: "https://api.cartridge.gg/x/lore_sn-stage/torii",
		slotName: "lore_sn-stage",
		useController: true,
		burnerAccount: undefined,
		contractAddresses: {} as any,
	},
	mainnet: {
		profileName: "mainnet",
		dojo_manifest: manifest_mainnet,
		namespace: NAMESPACE,
		chain: mainnet,
		chainName: "SN_MAIN",
		chainId: bigintToHex(stringToFelt("SN_MAIN")),
		rpcUrl: "https://api.cartridge.gg/x/starknet/mainnet/rpc/v0_9",
		toriiUrl: "https://api.cartridge.gg/x/lore_sn-mainnet/torii",
		slotName: "lore_sn-mainnet",
		useController: true,
		burnerAccount: undefined,
		contractAddresses: {} as any,
	},
};

export const getProfileConfig = (profileName: ProfileName): ProfileConfig => {
	const result: ProfileConfig = profileConfigs[profileName];
	if (!result) {
		throw new Error(`Profile config for [${profileName}] not found`);
	}
	result.contractAddresses = {
		world: addAddressPadding(result.dojo_manifest.world?.address ?? "0x0"),
		permit_token: addAddressPadding(
			result.dojo_manifest.contracts?.find(
				(c: any) => c.tag === `${NAMESPACE}-permit_token`,
			)?.address ?? "0x0",
		),
	};
	return result;
};
