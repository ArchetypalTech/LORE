import type { SchemaType as ISchemaType } from "@dojoengine/sdk";

import { CairoCustomEnum, type BigNumberish } from 'starknet';

// Type definition for `lore::components::area::Area` struct
export interface Area {
	inst: BigNumberish;
	is_area: boolean;
}

// Type definition for `lore::components::area::AreaValue` struct
export interface AreaValue {
	is_area: boolean;
}

// Type definition for `lore::components::container::ActionMapContainer` struct
export interface ActionMapContainer {
	action: string;
	inst: BigNumberish;
	action_fn: ContainerActionsEnum;
}

// Type definition for `lore::components::container::Container` struct
export interface Container {
	inst: BigNumberish;
	is_container: boolean;
	can_be_opened: boolean;
	can_receive_items: boolean;
	is_open: boolean;
	num_slots: BigNumberish;
	action_map: Array<ActionMapContainer>;
}

// Type definition for `lore::components::container::ContainerValue` struct
export interface ContainerValue {
	is_container: boolean;
	can_be_opened: boolean;
	can_receive_items: boolean;
	is_open: boolean;
	num_slots: BigNumberish;
	action_map: Array<ActionMapContainer>;
}

// Type definition for `lore::components::exit::ActionMapExit` struct
export interface ActionMapExit {
	action: string;
	inst: BigNumberish;
	action_fn: ExitActionsEnum;
}

// Type definition for `lore::components::exit::Exit` struct
export interface Exit {
	inst: BigNumberish;
	is_exit: boolean;
	is_enterable: boolean;
	leads_to: BigNumberish;
	direction_type: DirectionEnum;
	action_map: Array<ActionMapExit>;
}

// Type definition for `lore::components::exit::ExitValue` struct
export interface ExitValue {
	is_exit: boolean;
	is_enterable: boolean;
	leads_to: BigNumberish;
	direction_type: DirectionEnum;
	action_map: Array<ActionMapExit>;
}

// Type definition for `lore::components::inspectable::ActionMapInspectable` struct
export interface ActionMapInspectable {
	action: string;
	inst: BigNumberish;
	action_fn: InspectableActionsEnum;
}

// Type definition for `lore::components::inspectable::Inspectable` struct
export interface Inspectable {
	inst: BigNumberish;
	is_inspectable: boolean;
	is_visible: boolean;
	description: Array<string>;
	action_map: Array<ActionMapInspectable>;
}

// Type definition for `lore::components::inspectable::InspectableValue` struct
export interface InspectableValue {
	is_inspectable: boolean;
	is_visible: boolean;
	description: Array<string>;
	action_map: Array<ActionMapInspectable>;
}

// Type definition for `lore::components::inventoryItem::ActionMapInventoryItem` struct
export interface ActionMapInventoryItem {
	action: string;
	inst: BigNumberish;
	action_fn: InventoryItemActionsEnum;
}

// Type definition for `lore::components::inventoryItem::InventoryItem` struct
export interface InventoryItem {
	inst: BigNumberish;
	is_inventory_item: boolean;
	owner_id: BigNumberish;
	can_be_picked_up: boolean;
	can_go_in_container: boolean;
	action_map: Array<ActionMapInventoryItem>;
}

// Type definition for `lore::components::inventoryItem::InventoryItemValue` struct
export interface InventoryItemValue {
	is_inventory_item: boolean;
	owner_id: BigNumberish;
	can_be_picked_up: boolean;
	can_go_in_container: boolean;
	action_map: Array<ActionMapInventoryItem>;
}

// Type definition for `lore::components::player::Player` struct
export interface Player {
	inst: BigNumberish;
	is_player: boolean;
	address: string;
	location: BigNumberish;
	use_debug: boolean;
}

// Type definition for `lore::components::player::PlayerStory` struct
export interface PlayerStory {
	inst: BigNumberish;
	story: Array<string>;
}

// Type definition for `lore::components::player::PlayerStoryValue` struct
export interface PlayerStoryValue {
	story: Array<string>;
}

// Type definition for `lore::components::player::PlayerValue` struct
export interface PlayerValue {
	is_player: boolean;
	address: string;
	location: BigNumberish;
	use_debug: boolean;
}

// Type definition for `lore::lib::dictionary::Dict` struct
export interface Dict {
	dict_key: BigNumberish;
	word: string;
	tokenType: TokenTypeEnum;
	n_value: BigNumberish;
}

// Type definition for `lore::lib::dictionary::DictValue` struct
export interface DictValue {
	word: string;
	tokenType: TokenTypeEnum;
	n_value: BigNumberish;
}

// Type definition for `lore::lib::entity::Entity` struct
export interface Entity {
	inst: BigNumberish;
	is_entity: boolean;
	name: string;
	alt_names: Array<string>;
}

// Type definition for `lore::lib::entity::EntityValue` struct
export interface EntityValue {
	is_entity: boolean;
	name: string;
	alt_names: Array<string>;
}

// Type definition for `lore::lib::relations::ChildToParent` struct
export interface ChildToParent {
	inst: BigNumberish;
	is_child: boolean;
	parent: BigNumberish;
}

// Type definition for `lore::lib::relations::ChildToParentValue` struct
export interface ChildToParentValue {
	is_child: boolean;
	parent: BigNumberish;
}

// Type definition for `lore::lib::relations::ParentToChildren` struct
export interface ParentToChildren {
	inst: BigNumberish;
	is_parent: boolean;
	children: Array<BigNumberish>;
}

// Type definition for `lore::lib::relations::ParentToChildrenValue` struct
export interface ParentToChildrenValue {
	is_parent: boolean;
	children: Array<BigNumberish>;
}

// Type definition for `lore::components::container::ContainerActions` enum
export const containerActions = [
	'Open',
	'Close',
	'Check',
] as const;
export type ContainerActions = { [key in typeof containerActions[number]]: string };
export type ContainerActionsEnum = CairoCustomEnum;

// Type definition for `lore::components::exit::ExitActions` enum
export const exitActions = [
	'UseExit',
] as const;
export type ExitActions = { [key in typeof exitActions[number]]: string };
export type ExitActionsEnum = CairoCustomEnum;

// Type definition for `lore::components::inspectable::InspectableActions` enum
export const inspectableActions = [
	'SetVisible',
	'ReadRandomDescription',
	'ReadFirstDescription',
] as const;
export type InspectableActions = { [key in typeof inspectableActions[number]]: string };
export type InspectableActionsEnum = CairoCustomEnum;

// Type definition for `lore::components::inventoryItem::InventoryItemActions` enum
export const inventoryItemActions = [
	'UseItem',
	'PickupItem',
	'DropItem',
	'PutItem',
	'TakeOutItem',
] as const;
export type InventoryItemActions = { [key in typeof inventoryItemActions[number]]: string };
export type InventoryItemActionsEnum = CairoCustomEnum;

// Type definition for `lore::constants::constants::Direction` enum
export const direction = [
	'None',
	'North',
	'South',
	'East',
	'West',
	'Up',
	'Down',
] as const;
export type Direction = { [key in typeof direction[number]]: string };
export type DirectionEnum = CairoCustomEnum;

// Type definition for `lore::lib::a_lexer::TokenType` enum
export const tokenType = [
	'Unknown',
	'Verb',
	'Direction',
	'Article',
	'Preposition',
	'Pronoun',
	'Adjective',
	'Noun',
	'Quantifier',
	'Interrogative',
	'System',
] as const;
export type TokenType = { [key in typeof tokenType[number]]: string };
export type TokenTypeEnum = CairoCustomEnum;

export interface SchemaType extends ISchemaType {
	lore: {
		Area: Area,
		AreaValue: AreaValue,
		ActionMapContainer: ActionMapContainer,
		Container: Container,
		ContainerValue: ContainerValue,
		ActionMapExit: ActionMapExit,
		Exit: Exit,
		ExitValue: ExitValue,
		ActionMapInspectable: ActionMapInspectable,
		Inspectable: Inspectable,
		InspectableValue: InspectableValue,
		ActionMapInventoryItem: ActionMapInventoryItem,
		InventoryItem: InventoryItem,
		InventoryItemValue: InventoryItemValue,
		Player: Player,
		PlayerStory: PlayerStory,
		PlayerStoryValue: PlayerStoryValue,
		PlayerValue: PlayerValue,
		Dict: Dict,
		DictValue: DictValue,
		Entity: Entity,
		EntityValue: EntityValue,
		ChildToParent: ChildToParent,
		ChildToParentValue: ChildToParentValue,
		ParentToChildren: ParentToChildren,
		ParentToChildrenValue: ParentToChildrenValue,
	},
}
export const schema: SchemaType = {
	lore: {
		Area: {
			inst: 0,
			is_area: false,
		},
		AreaValue: {
			is_area: false,
		},
		ActionMapContainer: {
		action: "",
			inst: 0,
		action_fn: new CairoCustomEnum({ 
					Open: "",
				Close: undefined,
				Check: undefined, }),
		},
		Container: {
			inst: 0,
			is_container: false,
			can_be_opened: false,
			can_receive_items: false,
			is_open: false,
			num_slots: 0,
			action_map: [{ action: "", inst: 0, action_fn: new CairoCustomEnum({ 
					Open: "",
				Close: undefined,
				Check: undefined, }), }],
		},
		ContainerValue: {
			is_container: false,
			can_be_opened: false,
			can_receive_items: false,
			is_open: false,
			num_slots: 0,
			action_map: [{ action: "", inst: 0, action_fn: new CairoCustomEnum({ 
					Open: "",
				Close: undefined,
				Check: undefined, }), }],
		},
		ActionMapExit: {
		action: "",
			inst: 0,
		action_fn: new CairoCustomEnum({ 
					UseExit: "", }),
		},
		Exit: {
			inst: 0,
			is_exit: false,
			is_enterable: false,
			leads_to: 0,
		direction_type: new CairoCustomEnum({ 
					None: "",
				North: undefined,
				South: undefined,
				East: undefined,
				West: undefined,
				Up: undefined,
				Down: undefined, }),
			action_map: [{ action: "", inst: 0, action_fn: new CairoCustomEnum({ 
					UseExit: "", }), }],
		},
		ExitValue: {
			is_exit: false,
			is_enterable: false,
			leads_to: 0,
		direction_type: new CairoCustomEnum({ 
					None: "",
				North: undefined,
				South: undefined,
				East: undefined,
				West: undefined,
				Up: undefined,
				Down: undefined, }),
			action_map: [{ action: "", inst: 0, action_fn: new CairoCustomEnum({ 
					UseExit: "", }), }],
		},
		ActionMapInspectable: {
		action: "",
			inst: 0,
		action_fn: new CairoCustomEnum({ 
					SetVisible: "",
				ReadRandomDescription: undefined,
				ReadFirstDescription: undefined, }),
		},
		Inspectable: {
			inst: 0,
			is_inspectable: false,
			is_visible: false,
			description: [""],
			action_map: [{ action: "", inst: 0, action_fn: new CairoCustomEnum({ 
					SetVisible: "",
				ReadRandomDescription: undefined,
				ReadFirstDescription: undefined, }), }],
		},
		InspectableValue: {
			is_inspectable: false,
			is_visible: false,
			description: [""],
			action_map: [{ action: "", inst: 0, action_fn: new CairoCustomEnum({ 
					SetVisible: "",
				ReadRandomDescription: undefined,
				ReadFirstDescription: undefined, }), }],
		},
		ActionMapInventoryItem: {
		action: "",
			inst: 0,
		action_fn: new CairoCustomEnum({ 
					UseItem: "",
				PickupItem: undefined,
				DropItem: undefined,
				PutItem: undefined,
				TakeOutItem: undefined, }),
		},
		InventoryItem: {
			inst: 0,
			is_inventory_item: false,
			owner_id: 0,
			can_be_picked_up: false,
			can_go_in_container: false,
			action_map: [{ action: "", inst: 0, action_fn: new CairoCustomEnum({ 
					UseItem: "",
				PickupItem: undefined,
				DropItem: undefined,
				PutItem: undefined,
				TakeOutItem: undefined, }), }],
		},
		InventoryItemValue: {
			is_inventory_item: false,
			owner_id: 0,
			can_be_picked_up: false,
			can_go_in_container: false,
			action_map: [{ action: "", inst: 0, action_fn: new CairoCustomEnum({ 
					UseItem: "",
				PickupItem: undefined,
				DropItem: undefined,
				PutItem: undefined,
				TakeOutItem: undefined, }), }],
		},
		Player: {
			inst: 0,
			is_player: false,
			address: "",
			location: 0,
			use_debug: false,
		},
		PlayerStory: {
			inst: 0,
			story: [""],
		},
		PlayerStoryValue: {
			story: [""],
		},
		PlayerValue: {
			is_player: false,
			address: "",
			location: 0,
			use_debug: false,
		},
		Dict: {
			dict_key: 0,
		word: "",
		tokenType: new CairoCustomEnum({ 
					Unknown: "",
				Verb: undefined,
				Direction: undefined,
				Article: undefined,
				Preposition: undefined,
				Pronoun: undefined,
				Adjective: undefined,
				Noun: undefined,
				Quantifier: undefined,
				Interrogative: undefined,
				System: undefined, }),
			n_value: 0,
		},
		DictValue: {
		word: "",
		tokenType: new CairoCustomEnum({ 
					Unknown: "",
				Verb: undefined,
				Direction: undefined,
				Article: undefined,
				Preposition: undefined,
				Pronoun: undefined,
				Adjective: undefined,
				Noun: undefined,
				Quantifier: undefined,
				Interrogative: undefined,
				System: undefined, }),
			n_value: 0,
		},
		Entity: {
			inst: 0,
			is_entity: false,
		name: "",
			alt_names: [""],
		},
		EntityValue: {
			is_entity: false,
		name: "",
			alt_names: [""],
		},
		ChildToParent: {
			inst: 0,
			is_child: false,
			parent: 0,
		},
		ChildToParentValue: {
			is_child: false,
			parent: 0,
		},
		ParentToChildren: {
			inst: 0,
			is_parent: false,
			children: [0],
		},
		ParentToChildrenValue: {
			is_parent: false,
			children: [0],
		},
	},
};
export enum ModelsMapping {
	Area = 'lore-Area',
	AreaValue = 'lore-AreaValue',
	ActionMapContainer = 'lore-ActionMapContainer',
	Container = 'lore-Container',
	ContainerActions = 'lore-ContainerActions',
	ContainerValue = 'lore-ContainerValue',
	ActionMapExit = 'lore-ActionMapExit',
	Exit = 'lore-Exit',
	ExitActions = 'lore-ExitActions',
	ExitValue = 'lore-ExitValue',
	ActionMapInspectable = 'lore-ActionMapInspectable',
	Inspectable = 'lore-Inspectable',
	InspectableActions = 'lore-InspectableActions',
	InspectableValue = 'lore-InspectableValue',
	ActionMapInventoryItem = 'lore-ActionMapInventoryItem',
	InventoryItem = 'lore-InventoryItem',
	InventoryItemActions = 'lore-InventoryItemActions',
	InventoryItemValue = 'lore-InventoryItemValue',
	Player = 'lore-Player',
	PlayerStory = 'lore-PlayerStory',
	PlayerStoryValue = 'lore-PlayerStoryValue',
	PlayerValue = 'lore-PlayerValue',
	Direction = 'lore-Direction',
	TokenType = 'lore-TokenType',
	Dict = 'lore-Dict',
	DictValue = 'lore-DictValue',
	Entity = 'lore-Entity',
	EntityValue = 'lore-EntityValue',
	ChildToParent = 'lore-ChildToParent',
	ChildToParentValue = 'lore-ChildToParentValue',
	ParentToChildren = 'lore-ParentToChildren',
	ParentToChildrenValue = 'lore-ParentToChildrenValue',
}