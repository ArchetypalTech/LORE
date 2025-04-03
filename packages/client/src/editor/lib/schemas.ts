import {
	direction,
	inspectableActions,
	type Direction,
} from "@/lib/dojo_bindings/typescript/models.gen";
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

export const directionToIndex = (value: string) => {
	if (value.None) return 0;
	if (value.Some) value = value.Some;
	const match = direction.findIndex((e) => e === value);
	return match >= 0 ? match : 0;
};

export const inspectableActionsToIndex = (value: string) => {
	if (value.None) return 0;
	if (value.Some) value = value.Some;
	const match = inspectableActions.findIndex((e) => e === value);
	return match >= 0 ? match : 0;
};
