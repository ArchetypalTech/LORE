import clsx, { type ClassValue } from "clsx";
import { BigNumberish } from "starknet";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
	return twMerge(clsx(inputs));
}

/**
 * Processes string input, replacing escape sequences with actual whitespace characters
 * @param {string} input - The input string with escape sequences
 * @returns {string[]} An array of strings split by newline characters
 */
export function processWhitespaceTags(input: string): string[] {
	const tagRegex = /\\([nrt])/g;
	const replacements: { [key: string]: string } = {
		n: "\n",
		r: "\r",
		t: "\t",
	};

	const processedString = input.replace(
		tagRegex,
		(match, p1) => replacements[p1] || match,
	);
	return processedString.split("\n");
}

export const decodeDojoText = (text: string) => {
	try {
		const decodedText = decodeURI(text.trimStart()).replaceAll("%2C", ",");
		return decodedText;
	} catch (error) {
		console.error("decodeDojoText(): Bad text:", text);
		throw error;
	}
};

// svelte like tick
export const tick = async () => {
	await new Promise((resolve) => setTimeout(resolve, 1));
};

export const delay = (ms: number) =>
	new Promise((resolve) => setTimeout(resolve, ms));

// hex formatters
export const bigintToHex = (v: BigNumberish): `0x${string}` => (!v ? '0x0' : `0x${BigInt(v).toString(16)}`)
export const bigintToHex64 = (v: BigNumberish): `0x${string}` => (!v ? '0x0' : `0x${BigInt(v).toString(16).padStart(16, '0')}`)
export const bigintToHex128 = (v: BigNumberish): `0x${string}` => (!v ? '0x0' : `0x${BigInt(v).toString(16).padStart(32, '0')}`)
export const bigintToAddress = (v: BigNumberish): `0x${string}` => (!v ? '0x0' : `0x${BigInt(v).toString(16).padStart(64, '0')}`)
export const bigintEquals = (a: BigNumberish | undefined, b: BigNumberish | undefined): boolean => (a != undefined && b != undefined && BigInt(a) == BigInt(b))
