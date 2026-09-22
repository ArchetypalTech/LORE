/// <reference types="vite/client" />

interface ImportMetaEnv {
	/** SHA-256 hex of the /walkthrough PIN. Unset = the walkthrough can't be unlocked. */
	readonly VITE_WALKTHROUGH_PIN_HASH?: string;
	/** URL embedded on /walkthrough once unlocked. */
	readonly VITE_WALKTHROUGH_EMBED?: string;
}
