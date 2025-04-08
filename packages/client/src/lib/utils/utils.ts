import clsx, { type ClassValue } from "clsx";
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
	const decodedText = decodeURI(text.trimStart()).replaceAll("%2C", ",");
	return decodedText;
};

// svelte like tick
export const tick = async () => {
	await new Promise((resolve) => setTimeout(resolve, 1));
};

export const delay = (ms: number) =>
	new Promise((resolve) => setTimeout(resolve, ms));
