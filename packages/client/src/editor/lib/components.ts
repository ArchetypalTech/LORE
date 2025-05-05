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
import { createRandomName, randomKey } from "../editor.utils";
import type { EntityCollection, WithStringEnums } from "./types";
import { WalletAccount, AccountInterface } from "starknet";

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
	//address: WalletAccount["address"],
  ): WithStringEnums<Pick<SchemaType["lore"], "Entity" | "Player">> => ({
		// Adding the Entity as we need to set the inst to be the address
	Entity: {
		...schema.lore.Entity,
		inst: randomKey(), // TODO:  this is a hack to get the entity to work. Should be player address
		is_entity: true,
		name: createRandomName(),
		alt_names: [],
	},
	Player: {
		...schema.lore.Player,
		inst: 0, // TODO:  this is a hack to get the entity to work. Should be player address
		is_player: true,
		address: "", // TODO:  this is a hack to get the entity to work. Should be player address
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
		description: [],
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
		can_be_picked_up: false,
		can_go_in_container: false,
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
		creator: createPlayerEntity,
	},
	Area: {
		order: 1,
		inspector: AreaInspector,
		icon: "🥾",
		creator: createDefaultAreaComponent,
	},
	Inspectable: {
		order: 2,
		inspector: InspectableInspector,
		icon: "🔍",
		creator: createDefaultInspectableComponent,
	},
	Exit: {
		order: 3,
		inspector: ExitInspector,
		icon: "🚪",
		creator: createDefaultExitComponent,
	},
	InventoryItem: {
		order: 4,
		inspector: InventoryItemInspector,
		icon: "📦",
		creator: createDefaultInventoryItemComponent,
	},
	Container: {
		order: 5,
		inspector: ContainerInspector,
		icon: "🎒",
		creator: createDefaultContainerComponent,
	},
};
