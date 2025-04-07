import { useMemo } from "react";
import type { CairoCustomEnum } from "starknet";
import { z } from "zod";
import type { OptionType } from "./types";

export const ValidationErrorSchema = z.object({
	message: z.string(),
});
export type ValidationError = z.infer<typeof ValidationErrorSchema>;

export function transformWithSchema<T>(
	schema: z.ZodSchema<T>,
	data: unknown,
): { data: T; errors: ValidationError[] } {
	const result = schema.safeParse(data);
	if (result.success) {
		console.log(result);
		return { data: result.data, errors: [] };
	}
	console.error(result.error);
	const errors: ValidationError[] = result.error.errors.map((err) => {
		return {
			message: `${err.message}`,
			details: {},
		};
	});

	return { data: result.data as T, errors };
}

export const ConfigSchema = z.object({
	dataPool: z.array(z.any()),
});
export type ConfigSchemaType = z.infer<typeof ConfigSchema>;

/*
 * Enums
 */

// Strip Cairo enum construction
export const cleanCairoEnum = (
	value: CairoCustomEnum | string | { None: boolean } | { Some: unknown },
) => {
	if (typeof value !== "string") {
		if ("None" in value) return "None";
	}
	return value;
};

// @dev: highly illegal conversions
export const stringCairoEnum = <T>(
	value: CairoCustomEnum | string | { None: boolean } | { Some: unknown },
) => {
	if (typeof value !== "string") {
		if ("None" in value) return "None";
	}
	return value as keyof T;
};

// convert a cairo enum to a usable format
export const convertCairoEnum = (
	cairoEnum: CairoCustomEnum,
	targetEnum: unknown[] | readonly unknown[],
): { value: string; options: OptionType[] } => {
	const value = cleanCairoEnum(cairoEnum);
	return {
		value: targetEnum.find((e: unknown) => e === value) as string,
		options: targetEnum.map((x: unknown) => ({
			value: x as string,
			label: x as string,
		})) as OptionType[],
	};
};

// cairo enum selector React hook
export const useCairoEnum = (
	cairoEnum: CairoCustomEnum,
	targetEnum: unknown[] | readonly unknown[],
) => {
	return useMemo(
		() => convertCairoEnum(cairoEnum, targetEnum),
		[cairoEnum, targetEnum],
	);
};

export const toEnumIndex = (
	value: CairoCustomEnum | string,
	targetEnum: unknown[] | readonly unknown[],
) => {
	const match = targetEnum.findIndex((e) => e === cleanCairoEnum(value));
	return match >= 0 ? match : 0;
};
