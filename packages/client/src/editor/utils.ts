import { byteArray, type BigNumberish } from "starknet";

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
