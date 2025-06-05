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

// Type definition for `lore::lib::actions::Action` struct
export interface Action {
	inst: BigNumberish;
	key: BigNumberish;
	name: string;
	description: string;
	is_enabled: boolean;
	trigger: Array<[BigNumberish, BigNumberish]>;
	conditions: Array<[BigNumberish, BigNumberish]>;
	effects: Array<[BigNumberish, BigNumberish]>;
	tags: Array<string>;
}

// Type definition for `lore::lib::actions::ActionValue` struct
export interface ActionValue {
	name: string;
	description: string;
	is_enabled: boolean;
	trigger: Array<[BigNumberish, BigNumberish]>;
	conditions: Array<[BigNumberish, BigNumberish]>;
	effects: Array<[BigNumberish, BigNumberish]>;
	tags: Array<string>;
}

// Type definition for `lore::lib::condition::Condition` struct
export interface Condition {
	inst: BigNumberish;
	key: BigNumberish;
	target: BigNumberish;
	component: ComponentsEnum;
	property: string;
	operator: OperatorEnum;
	value: BigNumberish;
}

// Type definition for `lore::lib::condition::ConditionValue` struct
export interface ConditionValue {
	target: BigNumberish;
	component: ComponentsEnum;
	property: string;
	operator: OperatorEnum;
	value: BigNumberish;
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

// Type definition for `lore::lib::effect::Effect` struct
export interface Effect {
	inst: BigNumberish;
	key: BigNumberish;
	target: BigNumberish;
	component: ComponentsEnum;
	property: string;
	value: Array<string>;
}

// Type definition for `lore::lib::effect::EffectExecution` struct
export interface EffectExecution {
	key: BigNumberish;
	effect_key: BigNumberish;
	timestamp: BigNumberish;
	parameters: Array<EffectParameter>;
	status: ExecutionStatusEnum;
	error_message: string;
}

// Type definition for `lore::lib::effect::EffectExecutionValue` struct
export interface EffectExecutionValue {
	effect_key: BigNumberish;
	timestamp: BigNumberish;
	parameters: Array<EffectParameter>;
	status: ExecutionStatusEnum;
	error_message: string;
}

// Type definition for `lore::lib::effect::EffectParameter` struct
export interface EffectParameter {
	name: string;
	value: BigNumberish;
}

// Type definition for `lore::lib::effect::EffectValue` struct
export interface EffectValue {
	target: BigNumberish;
	component: ComponentsEnum;
	property: string;
	value: Array<string>;
}

// Type definition for `lore::lib::entity::Entity` struct
export interface Entity {
	inst: BigNumberish;
	is_entity: boolean;
	name: string;
	alt_names: Array<string>;
	actions_keys: Array<BigNumberish>;
}

// Type definition for `lore::lib::entity::EntityValue` struct
export interface EntityValue {
	is_entity: boolean;
	name: string;
	alt_names: Array<string>;
	actions_keys: Array<BigNumberish>;
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

// Type definition for `lore::lib::trigger::Trigger` struct
export interface Trigger {
	inst: BigNumberish;
	key: BigNumberish;
	name: string;
	trigger_type: TriggerTypeEnum;
	parameters: Array<TriggerParameter>;
	is_enabled: boolean;
}

// Type definition for `lore::lib::trigger::TriggerIndex` struct
export interface TriggerIndex {
	trigger_type: TriggerTypeEnum;
	trigger_id: Array<[BigNumberish, BigNumberish]>;
}

// Type definition for `lore::lib::trigger::TriggerIndexValue` struct
export interface TriggerIndexValue {
	trigger_id: Array<[BigNumberish, BigNumberish]>;
}

// Type definition for `lore::lib::trigger::TriggerParameter` struct
export interface TriggerParameter {
	name: string;
	value: BigNumberish;
}

// Type definition for `lore::lib::trigger::TriggerValue` struct
export interface TriggerValue {
	name: string;
	trigger_type: TriggerTypeEnum;
	parameters: Array<TriggerParameter>;
	is_enabled: boolean;
}

// Type definition for `lore::lib::variable_property::ComponentProperty` struct
export interface ComponentProperty {
	name: string;
	property_type: PropertyTypeEnum;
	access_flags: PropertyAccessEnum;
}

// Type definition for `lore::lib::variable_property::ComponentVariable` struct
export interface ComponentVariable {
	key: BigNumberish;
	component_type: ComponentsEnum;
	entity_id: BigNumberish;
	property_name: string;
	value: string;
	last_updated: BigNumberish;
}

// Type definition for `lore::lib::variable_property::ComponentVariableValue` struct
export interface ComponentVariableValue {
	component_type: ComponentsEnum;
	entity_id: BigNumberish;
	property_name: string;
	value: string;
	last_updated: BigNumberish;
}

// Type definition for `lore::lib::variable_property::PropertyRegistry` struct
export interface PropertyRegistry {
	component_type: ComponentsEnum;
	properties: Array<ComponentProperty>;
}

// Type definition for `lore::lib::variable_property::PropertyRegistryValue` struct
export interface PropertyRegistryValue {
	properties: Array<ComponentProperty>;
}

// Type definition for `lore::components::Components` enum
export const components = [
	'Area',
	'Container',
	'Entity',
	'Exit',
	'Inspectable',
	'InventoryItem',
	'Player',
] as const;
export type Components = { [key in typeof components[number]]: string };
export type ComponentsEnum = CairoCustomEnum;

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

// Type definition for `lore::lib::condition::Operator` enum
export const operator = [
	'Equals',
	'NotEquals',
] as const;
export type Operator = { [key in typeof operator[number]]: string };
export type OperatorEnum = CairoCustomEnum;

// Type definition for `lore::lib::effect::ExecutionStatus` enum
export const executionStatus = [
	'Success',
	'Failure',
] as const;
export type ExecutionStatus = { [key in typeof executionStatus[number]]: string };
export type ExecutionStatusEnum = CairoCustomEnum;

// Type definition for `lore::lib::trigger::TriggerType` enum
export const triggerType = [
	'None',
	'PlayerEntersArea',
	'PlayerLeavesArea',
] as const;
export type TriggerType = { [key in typeof triggerType[number]]: string };
export type TriggerTypeEnum = CairoCustomEnum;

// Type definition for `lore::lib::variable_property::PropertyAccess` enum
export const propertyAccess = [
	'ReadOnly',
	'WriteOnly',
	'ReadWrite',
] as const;
export type PropertyAccess = { [key in typeof propertyAccess[number]]: string };
export type PropertyAccessEnum = CairoCustomEnum;

// Type definition for `lore::lib::variable_property::PropertyType` enum
export const propertyType = [
	'Boolean',
	'Integer',
	'Felt252',
	'Direction',
	'ContractAddress',
	'String',
	'ByteArray',
	'Enum',
] as const;
export type PropertyType = { [key in typeof propertyType[number]]: string };
export type PropertyTypeEnum = CairoCustomEnum;

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
		Action: Action,
		ActionValue: ActionValue,
		Condition: Condition,
		ConditionValue: ConditionValue,
		Dict: Dict,
		DictValue: DictValue,
		Effect: Effect,
		EffectExecution: EffectExecution,
		EffectExecutionValue: EffectExecutionValue,
		EffectParameter: EffectParameter,
		EffectValue: EffectValue,
		Entity: Entity,
		EntityValue: EntityValue,
		ChildToParent: ChildToParent,
		ChildToParentValue: ChildToParentValue,
		ParentToChildren: ParentToChildren,
		ParentToChildrenValue: ParentToChildrenValue,
		Trigger: Trigger,
		TriggerIndex: TriggerIndex,
		TriggerIndexValue: TriggerIndexValue,
		TriggerParameter: TriggerParameter,
		TriggerValue: TriggerValue,
		ComponentProperty: ComponentProperty,
		ComponentVariable: ComponentVariable,
		ComponentVariableValue: ComponentVariableValue,
		PropertyRegistry: PropertyRegistry,
		PropertyRegistryValue: PropertyRegistryValue,
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
		Action: {
			inst: 0,
			key: 0,
		name: "",
		description: "",
			is_enabled: false,
			trigger: [[0, 0]],
			conditions: [[0, 0]],
			effects: [[0, 0]],
			tags: [""],
		},
		ActionValue: {
		name: "",
		description: "",
			is_enabled: false,
			trigger: [[0, 0]],
			conditions: [[0, 0]],
			effects: [[0, 0]],
			tags: [""],
		},
		Condition: {
			inst: 0,
			key: 0,
			target: 0,
		component: new CairoCustomEnum({ 
					Area: "",
				Container: undefined,
				Entity: undefined,
				Exit: undefined,
				Inspectable: undefined,
				InventoryItem: undefined,
				Player: undefined, }),
		property: "",
		operator: new CairoCustomEnum({ 
					Equals: "",
				NotEquals: undefined, }),
			value: 0,
		},
		ConditionValue: {
			target: 0,
		component: new CairoCustomEnum({ 
					Area: "",
				Container: undefined,
				Entity: undefined,
				Exit: undefined,
				Inspectable: undefined,
				InventoryItem: undefined,
				Player: undefined, }),
		property: "",
		operator: new CairoCustomEnum({ 
					Equals: "",
				NotEquals: undefined, }),
			value: 0,
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
		Effect: {
			inst: 0,
			key: 0,
			target: 0,
		component: new CairoCustomEnum({ 
					Area: "",
				Container: undefined,
				Entity: undefined,
				Exit: undefined,
				Inspectable: undefined,
				InventoryItem: undefined,
				Player: undefined, }),
		property: "",
			value: [""],
		},
		EffectExecution: {
			key: 0,
			effect_key: 0,
			timestamp: 0,
			parameters: [{ name: "", value: 0, }],
		status: new CairoCustomEnum({ 
					Success: "",
				Failure: undefined, }),
		error_message: "",
		},
		EffectExecutionValue: {
			effect_key: 0,
			timestamp: 0,
			parameters: [{ name: "", value: 0, }],
		status: new CairoCustomEnum({ 
					Success: "",
				Failure: undefined, }),
		error_message: "",
		},
		EffectParameter: {
		name: "",
			value: 0,
		},
		EffectValue: {
			target: 0,
		component: new CairoCustomEnum({ 
					Area: "",
				Container: undefined,
				Entity: undefined,
				Exit: undefined,
				Inspectable: undefined,
				InventoryItem: undefined,
				Player: undefined, }),
		property: "",
			value: [""],
		},
		Entity: {
			inst: 0,
			is_entity: false,
		name: "",
			alt_names: [""],
			actions_keys: [0],
		},
		EntityValue: {
			is_entity: false,
		name: "",
			alt_names: [""],
			actions_keys: [0],
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
		Trigger: {
			inst: 0,
			key: 0,
		name: "",
		trigger_type: new CairoCustomEnum({ 
					None: "",
				PlayerEntersArea: undefined,
				PlayerLeavesArea: undefined, }),
			parameters: [{ name: "", value: 0, }],
			is_enabled: false,
		},
		TriggerIndex: {
		trigger_type: new CairoCustomEnum({ 
					None: "",
				PlayerEntersArea: undefined,
				PlayerLeavesArea: undefined, }),
			trigger_id: [[0, 0]],
		},
		TriggerIndexValue: {
			trigger_id: [[0, 0]],
		},
		TriggerParameter: {
		name: "",
			value: 0,
		},
		TriggerValue: {
		name: "",
		trigger_type: new CairoCustomEnum({ 
					None: "",
				PlayerEntersArea: undefined,
				PlayerLeavesArea: undefined, }),
			parameters: [{ name: "", value: 0, }],
			is_enabled: false,
		},
		ComponentProperty: {
		name: "",
		property_type: new CairoCustomEnum({ 
					Boolean: "",
				Integer: undefined,
				Felt252: undefined,
				Direction: undefined,
				ContractAddress: undefined,
				String: undefined,
				ByteArray: undefined,
				Enum: undefined, }),
		access_flags: new CairoCustomEnum({ 
					ReadOnly: "",
				WriteOnly: undefined,
				ReadWrite: undefined, }),
		},
		ComponentVariable: {
			key: 0,
		component_type: new CairoCustomEnum({ 
					Area: "",
				Container: undefined,
				Entity: undefined,
				Exit: undefined,
				Inspectable: undefined,
				InventoryItem: undefined,
				Player: undefined, }),
			entity_id: 0,
		property_name: "",
		value: "",
			last_updated: 0,
		},
		ComponentVariableValue: {
		component_type: new CairoCustomEnum({ 
					Area: "",
				Container: undefined,
				Entity: undefined,
				Exit: undefined,
				Inspectable: undefined,
				InventoryItem: undefined,
				Player: undefined, }),
			entity_id: 0,
		property_name: "",
		value: "",
			last_updated: 0,
		},
		PropertyRegistry: {
		component_type: new CairoCustomEnum({ 
					Area: "",
				Container: undefined,
				Entity: undefined,
				Exit: undefined,
				Inspectable: undefined,
				InventoryItem: undefined,
				Player: undefined, }),
			properties: [{ name: "", property_type: new CairoCustomEnum({ 
					Boolean: "",
				Integer: undefined,
				Felt252: undefined,
				Direction: undefined,
				ContractAddress: undefined,
				String: undefined,
				ByteArray: undefined,
				Enum: undefined, }), access_flags: new CairoCustomEnum({ 
					ReadOnly: "",
				WriteOnly: undefined,
				ReadWrite: undefined, }), }],
		},
		PropertyRegistryValue: {
			properties: [{ name: "", property_type: new CairoCustomEnum({ 
					Boolean: "",
				Integer: undefined,
				Felt252: undefined,
				Direction: undefined,
				ContractAddress: undefined,
				String: undefined,
				ByteArray: undefined,
				Enum: undefined, }), access_flags: new CairoCustomEnum({ 
					ReadOnly: "",
				WriteOnly: undefined,
				ReadWrite: undefined, }), }],
		},
	},
};
export enum ModelsMapping {
	Components = 'lore-Components',
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
	Action = 'lore-Action',
	ActionValue = 'lore-ActionValue',
	Condition = 'lore-Condition',
	ConditionValue = 'lore-ConditionValue',
	Operator = 'lore-Operator',
	Dict = 'lore-Dict',
	DictValue = 'lore-DictValue',
	Effect = 'lore-Effect',
	EffectExecution = 'lore-EffectExecution',
	EffectExecutionValue = 'lore-EffectExecutionValue',
	EffectParameter = 'lore-EffectParameter',
	EffectValue = 'lore-EffectValue',
	ExecutionStatus = 'lore-ExecutionStatus',
	Entity = 'lore-Entity',
	EntityValue = 'lore-EntityValue',
	ChildToParent = 'lore-ChildToParent',
	ChildToParentValue = 'lore-ChildToParentValue',
	ParentToChildren = 'lore-ParentToChildren',
	ParentToChildrenValue = 'lore-ParentToChildrenValue',
	Trigger = 'lore-Trigger',
	TriggerIndex = 'lore-TriggerIndex',
	TriggerIndexValue = 'lore-TriggerIndexValue',
	TriggerParameter = 'lore-TriggerParameter',
	TriggerType = 'lore-TriggerType',
	TriggerValue = 'lore-TriggerValue',
	ComponentProperty = 'lore-ComponentProperty',
	ComponentVariable = 'lore-ComponentVariable',
	ComponentVariableValue = 'lore-ComponentVariableValue',
	PropertyAccess = 'lore-PropertyAccess',
	PropertyRegistry = 'lore-PropertyRegistry',
	PropertyRegistryValue = 'lore-PropertyRegistryValue',
	PropertyType = 'lore-PropertyType',
}