import { cleanEnv, str, url } from "envalid";
import { addAddressPadding } from "starknet";
import { bigintToHex, stringToFelt } from "./utils/utils";
import manifest_dev from "@lore/contracts/manifest_dev.json";
import manifest_slot from "@lore/contracts/manifest_slot.json";
import manifest_stage from "@lore/contracts/manifest_stage.json";
import { setupWorld } from "@lib/dojo_bindings/typescript/contracts.gen";
import { DojoProvider } from "@dojoengine/core";

const getOrFail = <T>(value: T | undefined, name?: string): T => {
	if (value === undefined || value === null) {
		throw new Error(name ? `Value {${name}} is undefined` : "Value is undefined");
	}
	return value;
};
const padAddress = (address: string | undefined) => (address ? addAddressPadding(address) : undefined);


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
  burnerAddress?: string | undefined
  burnerPrivateKey?: string | undefined;
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
		burnerAddress: `0x6677fe62ee39c7b07401f754138502bab7fac99d2d3c5d37df7d1c6fab10819`,
		burnerPrivateKey: `0x3e3979c1ed728490308054fe357a9f49cf67f80f9721f44cc57235129e090f4`,
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
		// burnerAddress: `0x6677fe62ee39c7b07401f754138502bab7fac99d2d3c5d37df7d1c6fab10819`,
		// burnerPrivateKey: `0x3e3979c1ed728490308054fe357a9f49cf67f80f9721f44cc57235129e090f4`,
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
		// burnerAddress: `0x6677fe62ee39c7b07401f754138502bab7fac99d2d3c5d37df7d1c6fab10819`,
		// burnerPrivateKey: `0x3e3979c1ed728490308054fe357a9f49cf67f80f9721f44cc57235129e090f4`,
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
	// 	burnerAddress: undefined,
	// 	burnerPrivateKey: undefined,
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
	// 	burnerAddress: undefined,
	// 	burnerPrivateKey: undefined,
  // },
}


//----------------------------------------------------
// environment 
//

const env = cleanEnv(import.meta.env, {
	VITE_PROFILE: str({ default: "dev" }),
	VITE_RPC_URL: url({ default: undefined }),
	VITE_TORII_URL: url({ default: undefined }),
	VITE_BURNER_ADDRESS: str({ default: undefined }),
	VITE_BURNER_PRIVATE_KEY: str({ default: undefined }),
	VITE_SLOT: str({ default: undefined }),
});

// select current profile config
const selectedProfile: ProfileName = getOrFail(env.VITE_PROFILE, "VITE_PROFILE") as ProfileName;
const _config: ProfileConfig = getOrFail(profileConfigs[selectedProfile], "ProfileConfig") as ProfileConfig;

const selectedProfileConfig: ProfileConfig = {
	..._config,
	rpcUrl: env.VITE_RPC_URL || _config.rpcUrl,
	toriiUrl: env.VITE_TORII_URL || _config.toriiUrl,
	burnerAddress: padAddress(env.VITE_BURNER_ADDRESS || _config.burnerAddress),
	burnerPrivateKey: padAddress(env.VITE_BURNER_PRIVATE_KEY || _config.burnerPrivateKey),
	slotName: env.VITE_SLOT || _config.slotName,
};

const isLocalhost = window.location.hostname === "localhost";
const isEditor = window.location.pathname.startsWith("/editor");




//----------------------------------------------------
// Lore config 
//

const provider = new DojoProvider(
	selectedProfileConfig.dojo_manifest,
	selectedProfileConfig.rpcUrl,
);

const world = setupWorld(provider);

const manifests = {
	world: selectedProfileConfig.dojo_manifest.world,
	prompt: getOrFail(
		selectedProfileConfig.dojo_manifest.contracts.find((c: any) => c.tag === "lore-prompt"),
		"lore-prompt",
	),
	designer: getOrFail(
		selectedProfileConfig.dojo_manifest.contracts.find((c: any) => c.tag === "lore-designer"),
		"lore-designer",
	),
	game_token: getOrFail(
		selectedProfileConfig.dojo_manifest.contracts.find((c: any) => c.tag === "lore-game_token"),
		"lore-game_token",
	),
	trail_token: getOrFail(
		selectedProfileConfig.dojo_manifest.contracts.find((c: any) => c.tag === "lore-trail_token"),
		"lore-trail_token",
	),
};

export type LoreConfig = ProfileConfig & {
	provider: DojoProvider;
	manifests: {
		world: any;
		prompt: any;
		designer: any;
		game_token: any;
		trail_token: any;
	}
	world: ReturnType<typeof setupWorld>;
	LOCALHOST: boolean;
	EDITOR_MODE: boolean;
	env: typeof env;
};

export const LORE_CONFIG: LoreConfig = {
	...selectedProfileConfig,
	provider,
	manifests,
	world,
	LOCALHOST: isLocalhost,
	EDITOR_MODE: isEditor,
	env: env,
};

console.log("DEBUG: LORE_CONFIG:", LORE_CONFIG);
