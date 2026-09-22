/**
 * Client-side PIN lock (the website has no server). This only hides content from casual
 * visitors: the expected hash and the protected content both ship in the bundle.
 */

const UNLOCK_KEY = "walkthrough-unlocked-until";
const UNLOCK_TTL_MS = 36_000 * 1000; // matches the old `archetypal-token` cookie maxAge (10h)

/** SHA-256 hex digest of the PIN, as set in `VITE_WALKTHROUGH_PIN_HASH`. */
export async function hashPin(pin: string): Promise<string> {
	const buffer = await crypto.subtle.digest(
		"SHA-256",
		new TextEncoder().encode(pin),
	);
	return Array.from(new Uint8Array(buffer))
		.map((b) => b.toString(16).padStart(2, "0"))
		.join("");
}

export async function checkPin(pin: string): Promise<boolean> {
	const expected = import.meta.env.VITE_WALKTHROUGH_PIN_HASH;
	return Boolean(expected) && (await hashPin(pin)) === expected;
}

export function isUnlocked(): boolean {
	try {
		return Number(localStorage.getItem(UNLOCK_KEY)) > Date.now();
	} catch {
		return false;
	}
}

export function rememberUnlock(): void {
	try {
		localStorage.setItem(UNLOCK_KEY, String(Date.now() + UNLOCK_TTL_MS));
	} catch {
		// storage unavailable — stays unlocked for this visit only
	}
}
