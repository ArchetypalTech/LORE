import randomName from "@scaleway/random-name";
import {
	ConfigSchema,
	transformWithSchema,
	type ConfigSchemaType,
	type ValidationError,
} from "./lib/schemas";
import { byteArray, hash, type BigNumberish } from "starknet";
import JSONbig from "json-bigint";

const convertIfString = (item: unknown) => {
	if (item === "") {
		return 0;
	}
	// check if string is NOT all numbers
	if (typeof item === "string" && !/^[0-9]+$/.test(item) && item !== "") {
		return byteArray.byteArrayFromString(item);
	}
	return item;
};

/**
 * Converts a JavaScript array to a Cairo array format.
 *
 * Cairo arrays are represented as [length, item1, item2, ...].
 * Empty arrays are represented as [0].
 *
 * For Cairo object arrays in the format [[var,var,var,[],var,var],[var,var,var,[],var,var]],
 * we need special handling:
 * - When we have an array, we start with the length then items
 * - When we have a Cairo object, we flatten it
 * - When we have an array in a Cairo object, we use the array format [length, item, item, item]
 *
 * Examples:
 * // Simple array
 * toCairoArray([1, 2, 3]) // returns [3, 1, 2, 3]
 *
 * // Empty array
 * toCairoArray([]) // returns [0]
 *
 * // Nested arrays
 * toCairoArray([1, [2, 3], 4]) // returns [3, 1, 2, 2, 3, 4]
 * toCairoArray([[1, 2], [3, 4]]) // returns [2, 2, 1, 2, 2, 3, 4]
 *
 * // Cairo object array
 * toCairoArray([
 *   [288709, 1, 0, 3, 6, [], 0],
 *   [791662, 1, 0, 3, 6, [], 0]
 * ]) // returns [2, 288709, 1, 0, 3, 6, 0, 0, 791662, 1, 0, 3, 6, 0, 0]
 */

// @DEV: FIXME: ⚠️
// biome-ignore lint/complexity/noExcessiveCognitiveComplexity: <this is a really shitty implementation because handling both the ByteArrays and nested arrays is max pain- this is why we currently manually layout the Calldata in publisher.ts>
export const toCairoArray = (args: unknown[]): unknown[] => {
	// Handle empty array case
	if (args.length === 0) {
		return [0]; // Empty array is represented as [0] in Cairo
	}

	const result: unknown[] = [args.length];

	for (const arg of args) {
		// If the argument is an array, process it recursively
		if (Array.isArray(arg)) {
			// For nested arrays within Cairo objects
			if (arg.length === 0) {
				result.push(0);
			} else {
				// Process each element in the array
				const processedItems: unknown[] = [];

				for (const item of arg) {
					if (Array.isArray(item)) {
						// Recursive case: nested array
						if (item.length === 0) {
							processedItems.push(0);
						} else {
							// Convert the nested array to Cairo format
							processedItems.push(toCairoArray(item));
						}
					} else {
						// Base case: convert primitive value
						processedItems.push(convertIfString(item));
					}
				}

				// Add processed items to result
				result.push(...processedItems);
			}
		} else {
			// For primitive values, apply conversion
			result.push(convertIfString(arg));
		}
	}

	return result;
};

export const colorizeHash = (hash: string) => {
	let coloredHash = "";

	for (let i = 0; i < hash.length; i += 3) {
		const chunk = hash.substring(i, Math.min(i + 3, hash.length));
		let combinedCharCode = 0;
		for (let j = 0; j < chunk.length; j++) {
			combinedCharCode += (chunk.charCodeAt(j) + 10) * (j + 1);
		}
		const hue = (combinedCharCode * 37) % 360;
		const saturation = 20 + (combinedCharCode % 30);
		const lightness = 45 + (combinedCharCode % 20);

		const color = `hsl(${hue}, ${saturation}%, ${lightness}%)`;

		coloredHash += `<span style="color:${color}; font-weight:bold;">${chunk}</span>`;
	}

	return coloredHash;
};

export const formatColorHash = (bigInt: BigNumberish) => {
	return colorizeHash(bigInt.toString().slice(-9));
};

/**
 * Load a game config from a JSON file
 */
export const loadConfigFile = async (file: File): Promise<ConfigSchemaType> => {
	return new Promise((resolve, reject) => {
		const reader = new FileReader();

		reader.onload = (event) => {
			try {
				console.log(event.target?.result);
				const json = JSONbig.parse(event.target?.result as string);
				try {
					console.log(json);
					const { data, errors } = transformWithSchema(ConfigSchema, json);
					if (errors.length > 0) {
						reject(new Error(errors[0].message));
					}
					resolve(data);
				} catch (error) {
					if (error instanceof Error) {
						reject(error);
					} else {
						reject(new Error(`Invalid config format: ${(error as Error).message}`));
					}
				}
			} catch (error) {
				reject(new Error(`Invalid JSON file: ${(error as Error).message}`));
			}
		};

		reader.onerror = () => {
			reject(new Error("Error reading file"));
		};

		reader.readAsText(file);
	});
};

/**
 * Save a game config to a JSON file
 */
export const saveConfigToFile = (
	config: ConfigSchemaType,
	filename?: string,
): void => {
	const formatter = new Intl.DateTimeFormat("en-US", {
		year: "numeric",
		month: "short",
		day: "numeric",
		hour: "2-digit",
		minute: "2-digit",
		second: "2-digit",
		// hour12: false // Uncomment for 24-hour format
	});
	const newFile =
		filename ||
		`lore_config_${formatter.format(new Date()).replaceAll(" ", "_")}.json`;
	const json = JSONbig.stringify(config, null, 2);
	const blob = new Blob([json], { type: "application/json" });
	const url = URL.createObjectURL(blob);

	const a = document.createElement("a");
	a.href = url;
	a.download = newFile;
	a.click();

	URL.revokeObjectURL(url);
};

/**
 * Modified version of generateUniqueId that ensures:
 * - Only contains digits
 * - Is exactly 16 characters long
 * - Doesn't conflict with existing IDs in the config
 */
export const generateNumericUniqueId = (
	existingIds: Set<string> = new Set(),
): string => {
	let id: string;
	do {
		// Generate a string of random digits
		const array = new Uint32Array(8); // Using 8 to get plenty of digits
		crypto.getRandomValues(array);
		id = array
			.reduce((acc, num) => `${acc}${num.toString()}`, "")
			.substring(0, 16);

		// Pad with zeros if needed to get to 16 characters
		while (id.length < 16) {
			id = `0${id}`;
		}
	} while (existingIds.has(id));

	return id;
};

export const randomKey = () => {
	return hash.keccakBn(generateNumericUniqueId());
};

export const createRandomName = () => {
	return `${randomName("", " ")
		.split(" ")
		.map((word) => word[0].toUpperCase() + word.slice(1))
		.join(" ")}`;
};

export const formatValidationError = (error: ValidationError): string => {
	return error.message;
};
