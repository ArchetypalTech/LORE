import type { BigNumberish } from "starknet";
import type {
	DirectionEnum,
	direction,
	Entity,
	ReactableActionsEnum,
	reactableActions,
	SchemaType,
	TokenTypeEnum,
	tokenType,
	triggerType,
	TriggerTypeEnum,
	OperatorEnum,
	operator,
	ComponentTypeEnum,
	componentType,
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
<<<<<<< HEAD
<<<<<<< HEAD
		| "Reactable"
=======
		| "Inspectable"
>>>>>>> 91b4d21 (wip: implementing description text model in client side)
=======
		| "Reactable"
>>>>>>> 9d4ef2b (chore: update client side to match changes of Inspectable -> Reactable)
		| "DescriptionText"
		| "InventoryItem"
		| "PlayerStory"
		| "Player"
		| "Trigger"
		| "Condition"
		| "Effect"
		| "Action"
		| "Dict"
		| "Entity"
		| "ChildToParent"
		| "ParentToChildren"
		| "ActionMapReactable"
	>
>;

export type OneOf<Obj> = Obj[keyof Obj];

<<<<<<< HEAD
type MultiKeys = "Effect" | "Trigger" | "Condition" | "DESCRIPTIONTEXT" | "DescriptionText"; // expand as needed
=======
type MultiKeys = "Effect" | "Trigger" | "Condition"; // expand as needed
>>>>>>> 91b4d21 (wip: implementing description text model in client side)

type MultiInstanceWrapped<T> = {
  [K in keyof T]: K extends MultiKeys ? T[K] : T[K];
};

export type EntityCollection = {
  Entity: Entity;
} & Partial<MultiInstanceWrapped<SchemaType["lore"]>>;

export type EditorCollection = {
  [K in keyof EntityCollection]?: WithStringEnums<EntityCollection[K]>;
};

/**
 * Utility type that replaces CairoCustomEnum fields with string literal unions
 * from the corresponding constant arrays.
 */

export type WithStringEnums<T> = {
	[K in keyof T]: T[K] extends DirectionEnum
		? (typeof direction)[number]
			: T[K] extends ComponentTypeEnum
				? (typeof componentType)[number]
				: T[K] extends TriggerTypeEnum
					? (typeof triggerType)[number]
						: T[K] extends OperatorEnum
							? (typeof operator)[number]
							: T[K] extends ReactableActionsEnum
								? (typeof reactableActions)[number]
								: T[K] extends TokenTypeEnum
									? (typeof tokenType)[number]
									: T[K] extends Array<infer U>
										? Array<WithStringEnums<U>>
										: T[K] extends object
											? WithStringEnums<T[K]>
											: T[K];
};

// Standard ActionMap
export interface ActionMap<T> {
	action: string;
	inst: BigNumberish;
	action_fn: T;
	entrypoint: BigNumberish;
}

// Reactable ActionMap
export interface ActionMapForReactable<T> {
	action: string;
	inst: BigNumberish;
	action_fn: T;
	entrypoints: [BigNumberish, BigNumberish];
}

export interface TriggerParameter {
	name: string;
	value: BigNumberish;
}
