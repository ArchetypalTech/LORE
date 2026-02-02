import { cleanEnv, str, url } from "envalid";
import { DojoProvider } from "@dojoengine/core";
import { setupWorld } from "@lib/dojo_bindings/typescript/contracts.gen";
import { getProfileConfig, ProfileConfig, ProfileName } from "./config_profiles";

const getOrFail = <T>(value: T | undefined, name?: string): T => {
	if (value === undefined || value === null) {
		throw new Error(name ? `Value {${name}} is undefined` : "Value is undefined");
	}
	return value;
};


//----------------------------------------------------
// environment 
//

const env = cleanEnv(import.meta.env, {
	VITE_PROFILE: str({ default: undefined }),
	VITE_RPC_URL: url({ default: undefined }),
	VITE_TORII_URL: url({ default: undefined }),
	VITE_BURNER_ADDRESS: str({ default: undefined }),
	VITE_BURNER_PRIVATE_KEY: str({ default: undefined }),
	VITE_SLOT: str({ default: undefined }),
});

// select current profile config
const selectedProfile: ProfileName = getOrFail(env.VITE_PROFILE, "VITE_PROFILE") as ProfileName;
const profile: ProfileConfig = getProfileConfig(selectedProfile);

const selectedProfileConfig: ProfileConfig = {
	...profile,
	rpcUrl: env.VITE_RPC_URL || profile.rpcUrl,
	toriiUrl: env.VITE_TORII_URL || profile.toriiUrl,
	slotName: env.VITE_SLOT || profile.slotName,
	burnerAccount: (env.VITE_BURNER_ADDRESS && env.VITE_BURNER_PRIVATE_KEY) ? {
		name: "ENV Burner Wallet",
		address: env.VITE_BURNER_ADDRESS!,
		privateKey: env.VITE_BURNER_PRIVATE_KEY!,
	} : profile.burnerAccount,
};


//----------------------------------------------------
// Lore config 
//

const provider = new DojoProvider(
	selectedProfileConfig.dojo_manifest,
	selectedProfileConfig.rpcUrl,
);

const world = setupWorld(provider);

const isLocalhost = window.location.hostname === "localhost";
const isEditor = window.location.pathname.startsWith("/editor");

export type LoreConfig = ProfileConfig & {
	provider: DojoProvider;
	world: ReturnType<typeof setupWorld>;
	LOCALHOST: boolean;
	EDITOR_MODE: boolean;
	env: typeof env;
};

export const LORE_CONFIG: LoreConfig = {
	...selectedProfileConfig,
	provider,
	world,
	LOCALHOST: isLocalhost,
	EDITOR_MODE: isEditor,
	env: env,
};

console.log("DEBUG: LORE_CONFIG:", LORE_CONFIG);
