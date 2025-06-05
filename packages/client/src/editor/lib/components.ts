import {
	type Entity,
	type SchemaType,
	schema,
} from "@/lib/dojo_bindings/typescript/models.gen";
import { AreaInspector } from "../components/inspectors/AreaInspector";
import { EntityInspector } from "../components/inspectors/EntityInspector";
import { ExitInspector } from "../components/inspectors/ExitInspector";
import { InventoryItemInspector } from "../components/inspectors/InventoryItemInspector";
import { InspectableInspector } from "../components/inspectors/InspectableInspector";
import type { ComponentInspector } from "../components/inspectors/useInspector";
import { ContainerInspector } from "../components/inspectors/ContainerInspector";
import { PlayerInspector } from "../components/inspectors/PlayerInspector";
import { TriggerInspector } from "../components/inspectors/TriggerInspector";
import { ConditionInspector } from "../components/inspectors/ConditionInspector";
import { EffectInspector } from "../components/inspectors/EffectInspector";
import { ActionInspector } from "../components/inspectors/ActionInspector";
import { createRandomName, randomKey, generateNumericUniqueId } from "../editor.utils";
import type { EntityCollection, WithStringEnums } from "./types";
import { LORE_CONFIG } from "@/lib/config";

export const createDefaultEntity = (): WithStringEnums<
	Pick<SchemaType["lore"], "Entity">
> => ({
	Entity: {
		...schema.lore.Entity,
		inst: randomKey(),
		is_entity: true,
		name: createRandomName(),
		alt_names: [],
	},
});

export const createPlayerEntity = (
  ): WithStringEnums<Pick<SchemaType["lore"], "Entity" | "Player">> => ({
		// Adding the Entity as we need to set the inst to be the address
	Entity: {
		...schema.lore.Entity,
		inst: LORE_CONFIG.wallet.address, // TODO:  this is a hack to get the entity to work. Should be player address
		is_entity: true,
		name: createRandomName(),
		alt_names: [],
	},
	Player: {
		...schema.lore.Player,
		inst: LORE_CONFIG.wallet.address, // TODO:  this is a hack to get the entity to work. Should be player address
		is_player: true,
		address: LORE_CONFIG.wallet.address, // TODO:  this is a hack to get the entity to work. Should be player address
		location: 0,
		use_debug: false,
	},
});

export const createPlayerComponent = (
	_entity:Entity
  ): WithStringEnums<Pick<SchemaType["lore"], "Player">> => ({
	Player: {
		...schema.lore.Player,
		inst: LORE_CONFIG.wallet.address, // TODO:  this is a hack to get the entity to work. Should be player address
		is_player: true,
		address: LORE_CONFIG.wallet.address, // TODO:  this is a hack to get the entity to work. Should be player address
		location: 0,
		use_debug: false,
	},
});

export const createDefaultAreaComponent = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "Area">> => ({
	Area: {
		...schema.lore.Area,
		inst: entity.inst,
		is_area: true,
	},
});

export const createDefaultInspectableComponent = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "Inspectable">> => ({
	Inspectable: {
		...schema.lore.Inspectable,
		inst: entity.inst,
		is_inspectable: true,
		is_visible: true,
		description: [entity.name],
		action_map: [
			{ action: "look", inst: 0, action_fn: "ReadRandomDescription" },
			{ action: "stare", inst: 0, action_fn: "ReadRandomDescription" },
		],
	},
});

export const createDefaultExitComponent = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "Exit">> => ({
	Exit: {
		...schema.lore.Exit,
		inst: entity.inst,
		is_exit: true,
		is_enterable: true,
		direction_type: "None",
		action_map: [
			{ action: "go", inst: 0, action_fn: "UseExit" },
			{ action: "enter", inst: 0, action_fn: "UseExit" },
			{ action: "use", inst: 0, action_fn: "UseExit" },
		],
	},
});

export const createDefaultInventoryItemComponent = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "InventoryItem">> => ({
	InventoryItem: {
		...schema.lore.InventoryItem,
		inst: entity.inst,
		is_inventory_item: true,
		owner_id: 0,
		can_be_picked_up: true,
		can_go_in_container: true,
		action_map: [
			{ action: "pickup", inst: 0, action_fn: "PickupItem" },
			{ action: "drop", inst: 0, action_fn: "DropItem" },
			{ action: "put", inst: 0, action_fn: "PutItem" },
			{ action: "take", inst: 0, action_fn: "TakeOutItem" },
			{ action: "use", inst: 0, action_fn: "UseItem" },
		],
	},
});

export const createDefaultContainerComponent = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "Container">> => ({
	Container: {
		...schema.lore.Container,
		inst: entity.inst,
		is_container: true,
		can_be_opened: true,
		can_receive_items: true,
		is_open: true,
		num_slots: 0,
		action_map: [
			{ action: "open", inst: 0, action_fn: "Open" },
			{ action: "close", inst: 0, action_fn: "Close" },
			{ action: "check", inst: 0, action_fn: "Check" },
		],
	},
});

export const createDefaultTrigger = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "Trigger">> => ({
	Trigger: {
		...schema.lore.Trigger,
		inst: entity.inst,
		key: generateNumericUniqueId(),
		name: "",
		trigger_type:"None",
		parameters: [{ name: schema.lore.Trigger.name, value: schema.lore.Trigger.inst }],
		is_enabled: true,
	},
});

export const createDefaultCondition = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "Condition">> => ({
	Condition: {
		...schema.lore.Condition,
		inst: entity.inst,
		key: generateNumericUniqueId(),
		target: 0,
		component: "Area",
		property: "",
		operator: "Equals",
		value: 0,
	},
});

export const createDefaultEffectComponent = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "Effect">> => ({
	Effect: {
		...schema.lore.Effect,
		inst: entity.inst,
		key: generateNumericUniqueId(),
		target: 0,
		component: "Inspectable",
		property: "is_visible",
		value: [],
	},
});

export const createDefaultActionComponent = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "Action">> => ({
	Action: {
		...schema.lore.Action,
		inst: entity.inst,
		key: generateNumericUniqueId(),
		name: "",
		description: "",
		is_enabled: true,
		trigger: [],
		conditions: [],
		effects: [],
		tags: [],
	},
});


export const createDefaultChildToParentComponent = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "ChildToParent">> => ({
	ChildToParent: {
		...schema.lore.ChildToParent,
		inst: entity.inst,
		is_child: true,
		parent: 0,
	},
});

export const createDefaultParentToChildrenComponent = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "ParentToChildren">> => ({
	ParentToChildren: {
		...schema.lore.ParentToChildren,
		inst: entity.inst,
		is_parent: true,
		children: [],
	},
});

export const componentData: {
	[K in keyof EntityCollection]: {
		order: number;
		inspector?: ComponentInspector<NonNullable<EntityCollection[K]>>;
		icon?: string;
		creator?: (entity: Entity) => WithStringEnums<Pick<EntityCollection, K>>;
	};
} = {
	Entity: {
		order: 0,
		inspector: EntityInspector,
		creator: createDefaultEntity,
	},
	Player: {
		order: 1,
		inspector: PlayerInspector,
		icon: "👤",
		creator: createPlayerComponent,
	},
	Area: {
		order: 2,
		inspector: AreaInspector,
		icon: "🥾",
		creator: createDefaultAreaComponent,
	},
	Inspectable: {
		order: 3,
		inspector: InspectableInspector,
		icon: "🔍",
		creator: createDefaultInspectableComponent,
	},
	Exit: {
		order: 4,
		inspector: ExitInspector,
		icon: "🚪",
		creator: createDefaultExitComponent,
	},
	InventoryItem: {
		order: 5,
		inspector: InventoryItemInspector,
		icon: "📦",
		creator: createDefaultInventoryItemComponent,
	},
	Container: {
		order: 6,
		inspector: ContainerInspector,
		icon: "🎒",
		creator: createDefaultContainerComponent,
	},
	Trigger: {
		order: 7,
		inspector: TriggerInspector,
		icon: "🛎️",
		creator: createDefaultTrigger,
	},
	Condition: {
		order: 8,
		inspector: ConditionInspector,
		icon: "⚖️",
		creator: createDefaultCondition,
	},
	Effect: {
		order: 9,
		inspector: EffectInspector,
		icon: "✨",
		creator: createDefaultEffectComponent,
	},
	Action: {
		order: 10,
		inspector: ActionInspector,
		icon: "📝",
		creator: createDefaultActionComponent,
	},
};
