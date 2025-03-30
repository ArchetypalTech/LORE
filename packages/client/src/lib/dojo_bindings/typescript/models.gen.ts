import type { SchemaType as ISchemaType } from "@dojoengine/sdk";

import { CairoCustomEnum, type BigNumberish } from 'starknet';

// Type definition for `lore::components::area::Area` struct
export interface Area {
	inst: BigNumberish;
	is_area: boolean;
	direction: DirectionEnum;
}

// Type definition for `lore::components::area::AreaValue` struct
export interface AreaValue {
	is_area: boolean;
	direction: DirectionEnum;
}

// Type definition for `lore::components::container::Container` struct
export interface Container {
	inst: BigNumberish;
	is_container: boolean;
	can_be_opened: boolean;
	can_receive_items: boolean;
	is_open: boolean;
	num_slots: BigNumberish;
	item_ids: Array<BigNumberish>;
}

// Type definition for `lore::components::container::ContainerValue` struct
export interface ContainerValue {
	is_container: boolean;
	can_be_opened: boolean;
	can_receive_items: boolean;
	is_open: boolean;
	num_slots: BigNumberish;
	item_ids: Array<BigNumberish>;
}

// Type definition for `lore::components::exit::Exit` struct
export interface Exit {
	inst: BigNumberish;
	is_exit: boolean;
	is_enterable: boolean;
	leads_to: BigNumberish;
	direction_type: DirectionEnum;
	action_map: Array<string>;
}

// Type definition for `lore::components::exit::ExitValue` struct
export interface ExitValue {
	is_exit: boolean;
	is_enterable: boolean;
	leads_to: BigNumberish;
	direction_type: DirectionEnum;
	action_map: Array<string>;
}

// Type definition for `lore::components::inspectable::Inspectable` struct
export interface Inspectable {
	inst: BigNumberish;
	is_inspectable: boolean;
	is_visible: boolean;
	description: Array<string>;
}

// Type definition for `lore::components::inspectable::InspectableValue` struct
export interface InspectableValue {
	is_inspectable: boolean;
	is_visible: boolean;
	description: Array<string>;
}

// Type definition for `lore::components::inventoryItem::InventoryItem` struct
export interface InventoryItem {
	inst: BigNumberish;
	is_inventory_item: boolean;
	owner_id: BigNumberish;
	can_be_picked_up: boolean;
	can_go_in_container: boolean;
}

// Type definition for `lore::components::inventoryItem::InventoryItemValue` struct
export interface InventoryItemValue {
	is_inventory_item: boolean;
	owner_id: BigNumberish;
	can_be_picked_up: boolean;
	can_go_in_container: boolean;
}

// Type definition for `lore::components::player::Player` struct
export interface Player {
	inst: BigNumberish;
	is_player: boolean;
	address: string;
	location: BigNumberish;
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
		Container: Container,
		ContainerValue: ContainerValue,
		Exit: Exit,
		ExitValue: ExitValue,
		Inspectable: Inspectable,
		InspectableValue: InspectableValue,
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
		direction: new CairoCustomEnum({ 
					None: "",
				North: undefined,
				South: undefined,
				East: undefined,
				West: undefined,
				Up: undefined,
				Down: undefined, }),
		},
		AreaValue: {
			is_area: false,
		direction: new CairoCustomEnum({ 
					None: "",
				North: undefined,
				South: undefined,
				East: undefined,
				West: undefined,
				Up: undefined,
				Down: undefined, }),
		},
		Container: {
			inst: 0,
			is_container: false,
			can_be_opened: false,
			can_receive_items: false,
			is_open: false,
			num_slots: 0,
			item_ids: [0],
		},
		ContainerValue: {
			is_container: false,
			can_be_opened: false,
			can_receive_items: false,
			is_open: false,
			num_slots: 0,
			item_ids: [0],
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
			action_map: [""],
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
			action_map: [""],
		},
		Inspectable: {
			inst: 0,
			is_inspectable: false,
			is_visible: false,
			description: [""],
		},
		InspectableValue: {
			is_inspectable: false,
			is_visible: false,
			description: [""],
		},
		InventoryItem: {
			inst: 0,
			is_inventory_item: false,
			owner_id: 0,
			can_be_picked_up: false,
			can_go_in_container: false,
		},
		InventoryItemValue: {
			is_inventory_item: false,
			owner_id: 0,
			can_be_picked_up: false,
			can_go_in_container: false,
		},
		Player: {
			inst: 0,
			is_player: false,
			address: "",
			location: 0,
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
	Container = 'lore-Container',
	ContainerValue = 'lore-ContainerValue',
	Exit = 'lore-Exit',
	ExitValue = 'lore-ExitValue',
	Inspectable = 'lore-Inspectable',
	InspectableValue = 'lore-InspectableValue',
	InventoryItem = 'lore-InventoryItem',
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