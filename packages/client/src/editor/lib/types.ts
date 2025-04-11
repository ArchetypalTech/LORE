import type { BigNumberish } from "starknet";
import type {
	DirectionEnum,
	direction,
	Entity,
	InspectableActionsEnum,
	inspectableActions,
	SchemaType,
	TokenTypeEnum,
	tokenType,
} from "@/lib/dojo_bindings/typescript/models.gen";

export interface OptionType {
	value: string;
	label: string;
	disabled?: boolean;
}

export type EditorAction = "update" | "delete";
export type ChangeSet = {
	type: EditorAction;
	object: EditorCollection;
	inst: BigNumberish;
};
export type AnyObject = WithStringEnums<
	Pick<
		Partial<SchemaType["lore"]>,
		| "Area"
		| "Container"
		| "Exit"
		| "Inspectable"
		| "InventoryItem"
		| "PlayerStory"
		| "Player"
		| "Dict"
		| "Entity"
		| "ChildToParent"
		| "ParentToChildren"
		| "ActionMapInspectable"
	>
>;

export type OneOf<Obj> = Obj[keyof Obj];

export type EntityCollection = { Entity: Entity } & Partial<SchemaType["lore"]>;

export type EditorCollection = {
	[K in keyof EntityCollection]?: WithStringEnums<Partial<SchemaType["lore"]>>;
};

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

export interface ActionMap<T> {
	action: string;
	inst: BigNumberish;
	action_fn: T;
}
