import {
	direction,
	inspectableActions,
	type Direction,
	type Entity,
	type SchemaType,
} from "@/lib/dojo_bindings/typescript/models.gen";
import type { CairoCustomEnum } from "starknet";
import { z } from "zod";
import { useMemo, type FC } from "react";
import { randomKey } from "../editor.utils";
import randomName from "@scaleway/random-name";

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

export const cleanCairoEnum = (
	value: CairoCustomEnum | string | { None: boolean } | { Some: unknown },
) => {
	if (typeof value !== "string") {
		if ("None" in value) return "None";
	}
	return value;
};

export const convertCairoEnum = (
	cairoEnum: CairoCustomEnum,
	targetEnum: unknown[] | readonly unknown[],
): { value: string; options: HTMLOptionsCollection } => {
	const value = cleanCairoEnum(cairoEnum);
	return {
		value: targetEnum.find((e: unknown) => e === value) as string,
		options: targetEnum.map((x: unknown) => ({
			value: x as string,
			label: x as string,
		})) as unknown as HTMLOptionsCollection,
	};
};

export const useCairoEnum = (
	cairoEnum: CairoCustomEnum,
	targetEnum: unknown[] | readonly unknown[],
) => {
	return useMemo(
		() => convertCairoEnum(cairoEnum, targetEnum),
		[cairoEnum, targetEnum],
	);
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

export type AnyObject = Omit<
	Partial<SchemaType["lore"]>,
	| "AreaValue"
	| "ContainerValue"
	| "ExitValue"
	| "InspectableValue"
	| "InventoryItemValue"
	| "PlayerStoryValue"
	| "PlayerValue"
	| "DictValue"
	| "EntityValue"
	| "ChildToParentValue"
	| "ParentToChildrenValue"
	| "ActionMapInspectable"
>;
export type EntityComponents = Pick<
	AnyObject,
	"Area" | "Container" | "Exit" | "Inspectable"
>;
export type EntityCollection = { Entity: Entity } & Partial<SchemaType["lore"]>;

export type ModelCollection = {
	[K in keyof AnyObject]?: Partial<AnyObject>;
};

export type ComponentInspector<T> = FC<{
	componentObject: T;
	componentName: keyof NonNullable<EntityComponents>;
}>;

export const createDefaultEntity = () => ({
	Entity: {
		inst: randomKey(),
		is_entity: true,
		name: randomName(),
		alt_names: [],
	},
});

export const createDefaultAreaComponent = (entity: Entity) => ({
	Area: {
		inst: entity.inst,
		is_area: true,
		direction: "None",
	},
});

export const createDefaultInspectableComponent = (entity: Entity) => ({
	Inspectable: {
		inst: entity.inst,
		is_inspectable: true,
		is_visible: false,
		description: [],
		action_map: [],
	},
});

export const createDefaultExitComponent = (entity: Entity) => ({
	Exit: {
		inst: entity.inst,
		is_exit: true,
		is_enterable: false,
		leads_to: 0,
		direction_type: "None",
		action_map: [],
	},
});
