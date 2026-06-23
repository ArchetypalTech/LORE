import { type Chain, devnet, mainnet, sepolia } from "@starknet-react/chains";
import { addAddressPadding } from "starknet";
import { getContractByName } from '@dojoengine/core';
import { bigintToHex, stringToFelt } from "@/lib/utils";
import manifest_dev from "@lore/starknet/manifest_dev.json";
import manifest_sepolia from "@lore/starknet/manifest_sepolia.json";
import manifest_dev_appchain from "@lore/contracts/manifest_dev.json";
import manifest_sepolia_appchain from "@lore/contracts/manifest_appchain-sepolia.json";
const manifest_mainnet = {};
const manifest_mainnet_appchain = {};

const NAMESPACE = "lore_sn";
const NAMESPACE_APPCHAIN = "lore";

// No burner accounts in client-sn — connection is always via Cartridge Controller.
export const burnerAccounts: never[] = [];

//----------------------------------------------------
// Profiles
//

export type ProfileName = "dev" | "sepolia" | "mainnet";

export type ProfileConfig = {
	profileName: ProfileName;
	manifest: {
		starknet: any;
		appchain: any;
	};
	namespace: {
		starknet: string;
		appchain: string;
	};
	chain: Chain; // @starknet-react/chains chain for StarknetConfig
	chainName: string;
	chainId: `0x${string}`; // chain name in hex used by starknet
	rpcUrl: {
		starknet: string;
		appchain: string;
	};
	toriiUrl: {
		starknet: string;
		appchain: string;
	};
	slotName: string | undefined;
	useController: boolean;
	burnerAccount?: (typeof burnerAccounts)[number] | undefined;
	//
	// built in getProfileConfig()
	contractAddresses: {
		starknet: {
			world: string;
			permit_token: string;
			setup: string;
		},
		appchain: {
			world: string;
			actions_token: string;
		},
	};
};

const profileConfigs: Record<ProfileName, ProfileConfig> = {
	dev: {
		profileName: "dev",
		manifest: {
			starknet: manifest_dev,
			appchain: manifest_dev_appchain,
		},
		namespace: {
			starknet: NAMESPACE,
			appchain: NAMESPACE_APPCHAIN,
		},
		chain: devnet,
		chainName: "KATANA_LOCAL",
		chainId: bigintToHex(stringToFelt("KATANA_LOCAL")),
		rpcUrl: {
			starknet: "http://localhost:50000/",
			appchain: "http://localhost:6969/",
		},
		toriiUrl: {
			starknet: "http://localhost:8280",
			appchain: "http://localhost:8380",
		},
		slotName: undefined,
		useController: true,
		burnerAccount: undefined,
		contractAddresses: {} as any,
	},
	sepolia: {
		profileName: "sepolia",
		manifest: {
			starknet: manifest_sepolia,
			appchain: manifest_sepolia_appchain,
		},
		namespace: {
			starknet: NAMESPACE,
			appchain: NAMESPACE_APPCHAIN,
		},
		chain: sepolia,
		chainName: "SN_SEPOLIA",
		chainId: bigintToHex(stringToFelt("SN_SEPOLIA")),
		rpcUrl: {
			starknet: "https://api.cartridge.gg/x/starknet/sepolia/rpc/v0_9",
			appchain: "http://localhost:6969/",
		},
		toriiUrl: {
			starknet: "http://localhost:8280",
			appchain: "http://localhost:8380",
		},
		slotName: undefined,
		useController: true,
		burnerAccount: undefined,
		contractAddresses: {} as any,
	},
	mainnet: {
		profileName: "mainnet",
		manifest: {
			starknet: manifest_mainnet,
			appchain: manifest_mainnet_appchain,
		},
		namespace: {
			starknet: NAMESPACE,
			appchain: NAMESPACE_APPCHAIN,
		},
		chain: mainnet,
		chainName: "SN_MAIN",
		chainId: bigintToHex(stringToFelt("SN_MAIN")),
		rpcUrl: {
			starknet: "https://api.cartridge.gg/x/starknet/mainnet/rpc/v0_9",
			appchain: "http://localhost:6969/",
		},
		toriiUrl: {
			starknet: "https://api.cartridge.gg/x/lore_sn-mainnet/torii",
			appchain: "https://api.cartridge.gg/x/lore_sn-appchain/torii",
		},
		slotName: undefined,
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
		starknet: {
			world: addAddressPadding(result.manifest.starknet.world?.address ?? "0x0"),
			permit_token: getContractByName(result.manifest.starknet, NAMESPACE, 'permit_token')?.address ?? "0x0",
			setup: getContractByName(result.manifest.starknet, NAMESPACE, 'setup')?.address ?? "0x0",
		},
		appchain: {
			world: addAddressPadding(result.manifest.appchain.world?.address ?? "0x0"),
			actions_token: getContractByName(result.manifest.appchain, NAMESPACE_APPCHAIN, 'actions_token')?.address ?? "0x0",
		},
	};
	return result;
};
