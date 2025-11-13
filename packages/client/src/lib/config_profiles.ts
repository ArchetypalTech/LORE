import { bigintToHex, stringToFelt } from "./utils/utils";
import manifest_dev from "@lore/contracts/manifest_dev.json";
import manifest_slot from "@lore/contracts/manifest_slot.json";
import manifest_stage from "@lore/contracts/manifest_stage.json";
import { addAddressPadding } from "starknet";


export const burnerAccounts = [
	{
		name: "Deployer Wallet",
		address: `0x6677fe62ee39c7b07401f754138502bab7fac99d2d3c5d37df7d1c6fab10819`,
		privateKey: `0x3e3979c1ed728490308054fe357a9f49cf67f80f9721f44cc57235129e090f4`,
	}, {
		name: "Kataka Account #1",
		address: `0x127fd5f1fe78a71f8bcd1fec63e3fe2f0486b6ecd5c86a0466c3a21fa5cfcec`,
		privateKey: `0xc5b2fcab997346f3ea1c00b002ecf6f382c5f9c9659a3894eb783c5320f912`,
	}, {
		name: "Kataka Account #2",
		address: `0x13d9ee239f33fea4f8785b9e3870ade909e20a9599ae7cd62c1c292b73af1b7`,
		privateKey: `0x1c9053c053edf324aec366a34c6901b1095b07af69495bffec7d7fe21effb1b`,
	}, {
		name: "Kataka Account #3",
		address: `0x17cc6ca902ed4e8baa8463a7009ff18cc294fa85a94b4ce6ac30a9ebd6057c7`,
		privateKey: `0x14d6672dcb4b77ca36a887e9a11cd9d637d5012468175829e9c6e770c61642`,
	}
];


//----------------------------------------------------
// Profiles 
//

export type ProfileName = "dev" | "slot" | "stage";// | "sepolia" | "mainnet";

export type ProfileConfig = {
	profileName: ProfileName;
  dojo_manifest: any;
  chainName: string;
  chainId: `0x${string}`; // chain name in hex used by starknet
  rpcUrl: string;
  toriiUrl: string;
  slotName: string | undefined;
	useController: boolean;
	burnerAccount?: typeof burnerAccounts[number] | undefined;
	//
	// built in getProfileConfig()
	contractAddresses: {
		world: string;
		prompt: string;
		designer: string;
		game_token: string;
		trail_token: string;
	}
};

const profileConfigs: Record<ProfileName, ProfileConfig> = {
  dev: {
		profileName: "dev",
    dojo_manifest: manifest_dev,
    chainName: "KATANA",
    chainId: bigintToHex(stringToFelt("KATANA")),
    // rpcUrl: "https://localhost:5173/katana",
    // rpcUrl: "http://127.0.0.1:5050",
    rpcUrl: "http://localhost:5050",
    toriiUrl: "http://localhost:8080",
    slotName: undefined,
		useController: false,
		burnerAccount: burnerAccounts[0],
		// burnerAccount: burnerAccounts[1],
		// burnerAccount: burnerAccounts[2],
		// burnerAccount: burnerAccounts[3],
		contractAddresses: {} as any,
  },
  slot: {
		profileName: "slot",
    dojo_manifest: manifest_slot,
    chainName: "WP_LORE_V3",
    chainId: bigintToHex(stringToFelt("WP_LORE_V3")),
    rpcUrl: "https://api.cartridge.gg/x/orug-slot/katana",
    toriiUrl: "https://api.cartridge.gg/x/orug-slot/torii",
    slotName: "orug-slot",
		useController: true,
		contractAddresses: {} as any,
  },
  stage: {
		profileName: "stage",
    dojo_manifest: manifest_stage,
    chainName: "WP_LORE_STAGE",
    chainId: bigintToHex(stringToFelt("WP_LORE_STAGE")),
    rpcUrl: "https://api.cartridge.gg/x/lore-stage/katana",
    toriiUrl: "https://api.cartridge.gg/x/lore-stage/torii",
    slotName: "lore-stage",
		useController: true,
		contractAddresses: {} as any,
  },
  // sepolia: {
	// 	profileName: "sepolia",
  //   dojo_manifest: {},
  //   chainName: "SN_SEPOLIA",
  //   chainId: bigintToHex(stringToFelt("SN_SEPOLIA")),
  //   rpcUrl: "https://api.cartridge.gg/x/starknet/sepolia/rpc/v0_9",
  //   // rpcUrl: "https://starknet-sepolia.public.blastapi.io",
  //   toriiUrl: "https://api.cartridge.gg/x/lore-sepolia/torii",
  //   slotName: 'lore-sepolia',
	//   contractAddresses: {} as any,
  // },
  // mainnet: {
	// 	profileName: "mainnet",
  //   dojo_manifest: {},
  //   chainName: "SN_MAIN",
  //   chainId: bigintToHex(stringToFelt("SN_MAIN")),
  //   rpcUrl: "https://api.cartridge.gg/x/starknet/mainnet/rpc/v0_9",
  //   // rpcUrl: "https://starknet-mainnet.public.blastapi.io",
  //   toriiUrl: "https://api.cartridge.gg/x/lore-mainnet/torii",
  //   slotName: 'lore-mainnet',
	//   contractAddresses: {} as any,
  // },
}

export const getProfileConfig = (profileName: ProfileName): ProfileConfig => {
	const result: ProfileConfig = profileConfigs[profileName];
	if (!result) {
		throw new Error(`Profile config for [${profileName}] not found`);
	}
	result.contractAddresses = {
		world: addAddressPadding(result.dojo_manifest.world.address),
		prompt: addAddressPadding(result.dojo_manifest.contracts.find((c: any) => c.tag === "lore-prompt")?.address ?? '0x0'),
		designer: addAddressPadding(result.dojo_manifest.contracts.find((c: any) => c.tag === "lore-designer")?.address ?? '0x0'),
		game_token: addAddressPadding(result.dojo_manifest.contracts.find((c: any) => c.tag === "lore-game_token")?.address ?? '0x0'),
		trail_token: addAddressPadding(result.dojo_manifest.contracts.find((c: any) => c.tag === "lore-trail_token")?.address ?? '0x0'),
	};
	return result;
}
