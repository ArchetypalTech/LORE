import {
	direction,
	inspectableActions,
	type tokenType,
	type Direction,
	type Entity,
	type SchemaType,
	type DirectionEnum,
	type InspectableActionsEnum,
	type TokenTypeEnum,
} from "@/lib/dojo_bindings/typescript/models.gen";
import type { CairoCustomEnum } from "starknet";
import { z } from "zod";
import { useMemo, type FC } from "react";
import { randomKey } from "../editor.utils";
import randomName from "@scaleway/random-name";
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
		})) as unknown as OptionType[],
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

export type AnyObject = WithStringEnums<
	Omit<
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
	>
>;
export type EntityComponents = Pick<
	AnyObject,
	"Area" | "Container" | "Exit" | "Inspectable"
>;
export type EntityCollection = { Entity: Entity } & Partial<SchemaType["lore"]>;

export type EditorCollection = WithStringEnums<EntityCollection>;

export type ModelCollection = {
	[K in keyof AnyObject]?: Partial<WithStringEnums<AnyObject>>;
};

export type ComponentInspector<T> = FC<{
	componentObject: T;
	componentName: keyof NonNullable<EntityComponents>;
	handleEdit: (
		componentName: keyof EntityComponents,
		component: T,
	) => Promise<void>;
}>;

/**
 * Utility type that replaces CairoCustomEnum fields with string literal unions
 * from the corresponding constant arrays.
 */
export type WithStringEnums<T> = {
	[K in keyof T]: T[K] extends DirectionEnum
		? (typeof direction)[number]
		: T[K] extends InspectableActionsEnum
			? (typeof inspectableActions)[number]
			: T[K] extends TokenTypeEnum
				? (typeof tokenType)[number]
				: T[K] extends Array<infer U>
					? Array<WithStringEnums<U>>
					: T[K] extends object
						? WithStringEnums<T[K]>
						: T[K];
};

export const createDefaultEntity = (): WithStringEnums<
	Pick<SchemaType["lore"], "Entity">
> => ({
	Entity: {
		inst: randomKey(),
		is_entity: true,
		name: randomName(),
		alt_names: [],
	},
});

export const createDefaultAreaComponent = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "Area">> => ({
	Area: {
		inst: entity.inst,
		is_area: true,
		direction: "None",
	},
});

export const createDefaultInspectableComponent = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "Inspectable">> => ({
	Inspectable: {
		inst: entity.inst,
		is_inspectable: true,
		is_visible: false,
		description: [],
		action_map: [],
	},
});

export const createDefaultExitComponent = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "Exit">> => ({
	Exit: {
		inst: entity.inst,
		is_exit: true,
		is_enterable: false,
		leads_to: 0,
		direction_type: "None",
		action_map: [],
	},
});
