import { createDojoConfig } from "@dojoengine/core";
import {
	getProfileConfig,
	type ProfileConfig,
	type ProfileName,
} from "./config_profiles";

// Select the active profile. Override with VITE_PROFILE in .env
// (e.g. VITE_PROFILE=dev), otherwise fall back to the Vite mode, then sepolia.
export const PROFILE_NAME: ProfileName =
	(import.meta.env.VITE_PROFILE as ProfileName) ||
	(import.meta.env.MODE as ProfileName) ||
	"sepolia";

export const PROFILE: ProfileConfig = getProfileConfig(PROFILE_NAME);

export const dojoConfig = createDojoConfig({
	manifest: PROFILE.manifest.starknet,
});

console.log(`DEBUG: selectedProfile [${PROFILE_NAME}]:`, PROFILE);
