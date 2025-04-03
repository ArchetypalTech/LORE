import {
	direction,
	inspectableActions,
	type Direction,
} from "@/lib/dojo_bindings/typescript/models.gen";
import type { CairoCustomEnum } from "starknet";
import { z } from "zod";

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
export type Config = z.infer<typeof ConfigSchema>;

/*
 * Enums
 */

const cleanCairoEnum = (
	value: CairoCustomEnum | string | { None: boolean } | { Some: unknown },
) => {
	if (typeof value !== "string") {
		if ("None" in value) return "None";
	}
	return value;
};

export const directionToIndex = (
	value: CairoCustomEnum | string | { None: boolean } | { Some: Direction },
) => {
	const match = direction.findIndex((e) => e === cleanCairoEnum(value));
	return match >= 0 ? match : 0;
};

export const inspectableActionsToIndex = (
	value:
		| CairoCustomEnum
		| string
		| { None: boolean }
		| { Some: CairoCustomEnum },
) => {
	const match = inspectableActions.findIndex((e) => e === cleanCairoEnum(value));
	return match >= 0 ? match : 0;
};
