import { createDojoConfig } from "@dojoengine/core";
import {
	getProfileConfig,
	type ProfileConfig,
	type ProfileName,
} from "./config_profiles";

// Select the active profile. Override with VITE_PROFILE in .env
// (e.g. VITE_PROFILE=dev), otherwise fall back to the Vite mode, then sepolia.
const selectedProfile: ProfileName =
	(import.meta.env.VITE_PROFILE as ProfileName) ||
	(import.meta.env.MODE as ProfileName) ||
	"sepolia";

const profile: ProfileConfig = getProfileConfig(selectedProfile);

/** The resolved config for the active profile — import this where config is needed. */
export const selectedProfileConfig: ProfileConfig = {
	...profile,
	rpcUrl: import.meta.env.VITE_RPC_URL || profile.rpcUrl,
	toriiUrl: import.meta.env.VITE_TORII_URL || profile.toriiUrl,
	slotName: import.meta.env.VITE_SLOT || profile.slotName,
};

export const dojoConfig = createDojoConfig({
	manifest: selectedProfileConfig.dojo_manifest,
});

console.log("DEBUG: selectedProfileConfig:", selectedProfileConfig);
