import { shortString, type BigNumberish, getChecksumAddress } from "starknet";

export const bigintToAddress = (v: BigNumberish | undefined): `0x${string}` =>
	!v ? "0x0" : getChecksumAddress(v) as `0x${string}`;

export const bigintToHex = (v: BigNumberish | undefined): `0x${string}` =>
	!v ? "0x0" : `0x${BigInt(v).toString(16)}`;

export const stringToFelt = (v: string | undefined): BigNumberish =>
	v ? shortString.encodeShortString(v) : "0x0";

/** Truncate an address for display, e.g. `0x1234…cdef`. */
export const shortAddress = (address: string | undefined): string =>
	address ? `${address.slice(0, 6)}…${address.slice(-4)}` : "";
