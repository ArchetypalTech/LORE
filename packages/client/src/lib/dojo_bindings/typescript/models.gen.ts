import type { SchemaType as ISchemaType } from "@dojoengine/sdk";

import { CairoCustomEnum, type BigNumberish } from 'starknet';

// Type definition for `lore::lib::relations::ChildToParent` struct
export interface ChildToParent {
	inst: BigNumberish;
	is_child: boolean;
	parent: BigNumberish;
}

<<<<<<< HEAD
<<<<<<< HEAD
// Type definition for `lore::lib::relations::ChildToParentValue` struct
export interface ChildToParentValue {
	is_child: boolean;
	parent: BigNumberish;
}

// Type definition for `lore::models::index::Action` struct
=======
=======
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
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

// Type definition for `lore::components::inspectable::ActionMapInspectable` struct
export interface ActionMapInspectable {
	action: string;
	inst: BigNumberish;
	action_fn: InspectableActionsEnum;
	entrypoint: BigNumberish;
}

// Type definition for `lore::components::inspectable::Inspectable` struct
export interface Inspectable {
	inst: BigNumberish;
	is_inspectable: boolean;
	is_visible: boolean;
	description: Array<string>;
	action_map: Array<ActionMapInspectable>;
	already_shown: boolean;
	new_entry: string;
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
	already_used: boolean;
	multiple_use: boolean;
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

// Type definition for `lore::lib::actions::Action` struct
<<<<<<< HEAD
>>>>>>> e854c5e (chore: Upgrade Dependencies, Controller Localhost & SSL certificate Localhost (#128))
=======
=======
// Type definition for `lore::lib::relations::ChildToParentValue` struct
export interface ChildToParentValue {
	is_child: boolean;
	parent: BigNumberish;
}

// Type definition for `lore::models::index::Action` struct
>>>>>>> ef7cc2d (chore: implemented names variable for action system and adjusted dropdown key list)
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
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
	executed: boolean;
	failing_response: Array<string>;
	success_response: Array<string>;
}

<<<<<<< HEAD
<<<<<<< HEAD
// Type definition for `lore::models::index::ActionValue` struct
export interface ActionValue {
	name: string;
	description: string;
	is_enabled: boolean;
	trigger: Array<[BigNumberish, BigNumberish]>;
	conditions: Array<[BigNumberish, BigNumberish]>;
	effects: Array<[BigNumberish, BigNumberish]>;
	tags: Array<string>;
	executed: boolean;
	failing_response: Array<string>;
	success_response: Array<string>;
}

// Type definition for `lore::models::index::Area` struct
export interface Area {
	inst: BigNumberish;
	is_area: boolean;
	is_spawn_point: boolean;
}

// Type definition for `lore::models::index::AreaValue` struct
export interface AreaValue {
	is_area: boolean;
	is_spawn_point: boolean;
}

// Type definition for `lore::models::index::ComponentVariable` struct
export interface ComponentVariable {
	inst: BigNumberish;
	key: BigNumberish;
	id: BigNumberish;
	component_type: ComponentTypeEnum;
	property_name: string;
	value: string;
	last_updated: BigNumberish;
}

// Type definition for `lore::models::index::ComponentVariableValue` struct
export interface ComponentVariableValue {
	component_type: ComponentTypeEnum;
	property_name: string;
	value: string;
	last_updated: BigNumberish;
}

// Type definition for `lore::models::index::Condition` struct
=======
// Type definition for `lore::lib::condition::Condition` struct
>>>>>>> e854c5e (chore: Upgrade Dependencies, Controller Localhost & SSL certificate Localhost (#128))
=======
// Type definition for `lore::lib::condition::Condition` struct
=======
// Type definition for `lore::models::index::ActionValue` struct
export interface ActionValue {
	name: string;
	description: string;
	is_enabled: boolean;
	trigger: Array<[BigNumberish, BigNumberish]>;
	conditions: Array<[BigNumberish, BigNumberish]>;
	effects: Array<[BigNumberish, BigNumberish]>;
	tags: Array<string>;
	executed: boolean;
	failing_response: Array<string>;
	success_response: Array<string>;
}

// Type definition for `lore::models::index::Area` struct
export interface Area {
	inst: BigNumberish;
	is_area: boolean;
	is_spawn_point: boolean;
}

// Type definition for `lore::models::index::AreaValue` struct
export interface AreaValue {
	is_area: boolean;
	is_spawn_point: boolean;
}

// Type definition for `lore::models::index::ComponentVariable` struct
export interface ComponentVariable {
	inst: BigNumberish;
	key: BigNumberish;
	id: BigNumberish;
	component_type: ComponentTypeEnum;
	property_name: string;
	value: string;
	last_updated: BigNumberish;
}

// Type definition for `lore::models::index::ComponentVariableValue` struct
export interface ComponentVariableValue {
	component_type: ComponentTypeEnum;
	property_name: string;
	value: string;
	last_updated: BigNumberish;
}

// Type definition for `lore::models::index::Condition` struct
>>>>>>> ef7cc2d (chore: implemented names variable for action system and adjusted dropdown key list)
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
export interface Condition {
	inst: BigNumberish;
	key: BigNumberish;
	name: string;
	target: BigNumberish;
	component: ComponentTypeEnum;
	property: string;
	operator: OperatorEnum;
	value: Array<BigNumberish>;
}

<<<<<<< HEAD
<<<<<<< HEAD
// Type definition for `lore::models::index::ConditionValue` struct
export interface ConditionValue {
	name: string;
	target: BigNumberish;
	component: ComponentTypeEnum;
	property: string;
	operator: OperatorEnum;
	value: Array<BigNumberish>;
}

// Type definition for `lore::models::index::Container` struct
export interface Container {
	inst: BigNumberish;
	is_container: boolean;
	can_be_opened: boolean;
	can_receive_items: boolean;
	is_open: boolean;
	num_slots: BigNumberish;
	action_map: Array<ActionMapContainer>;
}

// Type definition for `lore::models::index::ContainerValue` struct
export interface ContainerValue {
	is_container: boolean;
	can_be_opened: boolean;
	can_receive_items: boolean;
	is_open: boolean;
	num_slots: BigNumberish;
	action_map: Array<ActionMapContainer>;
}

// Type definition for `lore::models::index::DescriptionText` struct
export interface DescriptionText {
	inst: BigNumberish;
	key: BigNumberish;
	text: string;
}

// Type definition for `lore::models::index::DescriptionTextValue` struct
export interface DescriptionTextValue {
	text: string;
}

// Type definition for `lore::models::index::Dict` struct
=======
// Type definition for `lore::lib::dictionary::Dict` struct
>>>>>>> e854c5e (chore: Upgrade Dependencies, Controller Localhost & SSL certificate Localhost (#128))
=======
// Type definition for `lore::lib::dictionary::Dict` struct
=======
// Type definition for `lore::models::index::ConditionValue` struct
export interface ConditionValue {
	name: string;
	target: BigNumberish;
	component: ComponentTypeEnum;
	property: string;
	operator: OperatorEnum;
	value: Array<BigNumberish>;
}

// Type definition for `lore::models::index::Container` struct
export interface Container {
	inst: BigNumberish;
	is_container: boolean;
	can_be_opened: boolean;
	can_receive_items: boolean;
	is_open: boolean;
	num_slots: BigNumberish;
	action_map: Array<ActionMapContainer>;
}

// Type definition for `lore::models::index::ContainerValue` struct
export interface ContainerValue {
	is_container: boolean;
	can_be_opened: boolean;
	can_receive_items: boolean;
	is_open: boolean;
	num_slots: BigNumberish;
	action_map: Array<ActionMapContainer>;
}

// Type definition for `lore::models::index::DescriptionText` struct
export interface DescriptionText {
	inst: BigNumberish;
	key: BigNumberish;
	text: string;
}

// Type definition for `lore::models::index::DescriptionTextValue` struct
export interface DescriptionTextValue {
	text: string;
}

// Type definition for `lore::models::index::Dict` struct
>>>>>>> ef7cc2d (chore: implemented names variable for action system and adjusted dropdown key list)
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
export interface Dict {
	dict_key: BigNumberish;
	word: string;
	tokenType: TokenTypeEnum;
	n_value: BigNumberish;
}

<<<<<<< HEAD
<<<<<<< HEAD
// Type definition for `lore::models::index::DictValue` struct
export interface DictValue {
	word: string;
	tokenType: TokenTypeEnum;
	n_value: BigNumberish;
}

// Type definition for `lore::models::index::Effect` struct
export interface Effect {
	inst: BigNumberish;
	key: BigNumberish;
	name: string;
	target: BigNumberish;
	component: ComponentTypeEnum;
	property: string;
	value: Array<[string, BigNumberish]>;
}

// Type definition for `lore::models::index::EffectValue` struct
export interface EffectValue {
	name: string;
	target: BigNumberish;
	component: ComponentTypeEnum;
	property: string;
	value: Array<[string, BigNumberish]>;
}

// Type definition for `lore::models::index::Entity` struct
=======
=======
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
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

// Type definition for `lore::lib::effect::EffectParameter` struct
export interface EffectParameter {
	name: string;
	value: BigNumberish;
}

// Type definition for `lore::lib::entity::Entity` struct
<<<<<<< HEAD
>>>>>>> e854c5e (chore: Upgrade Dependencies, Controller Localhost & SSL certificate Localhost (#128))
=======
=======
// Type definition for `lore::models::index::DictValue` struct
export interface DictValue {
	word: string;
	tokenType: TokenTypeEnum;
	n_value: BigNumberish;
}

// Type definition for `lore::models::index::Effect` struct
export interface Effect {
	inst: BigNumberish;
	key: BigNumberish;
	name: string;
	target: BigNumberish;
	component: ComponentTypeEnum;
	property: string;
	value: Array<[string, BigNumberish]>;
}

// Type definition for `lore::models::index::EffectValue` struct
export interface EffectValue {
	name: string;
	target: BigNumberish;
	component: ComponentTypeEnum;
	property: string;
	value: Array<[string, BigNumberish]>;
}

// Type definition for `lore::models::index::Entity` struct
>>>>>>> ef7cc2d (chore: implemented names variable for action system and adjusted dropdown key list)
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
export interface Entity {
	inst: BigNumberish;
	is_entity: boolean;
	name: string;
	alt_names: Array<string>;
	actions_keys: Array<BigNumberish>;
}

<<<<<<< HEAD
<<<<<<< HEAD
=======
// Type definition for `lore::lib::relations::ChildToParent` struct
export interface ChildToParent {
=======
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
// Type definition for `lore::models::index::EntityValue` struct
export interface EntityValue {
	is_entity: boolean;
	name: string;
	alt_names: Array<string>;
	actions_keys: Array<BigNumberish>;
}

// Type definition for `lore::models::index::Exit` struct
export interface Exit {
<<<<<<< HEAD
=======
// Type definition for `lore::lib::relations::ChildToParent` struct
export interface ChildToParent {
>>>>>>> e854c5e (chore: Upgrade Dependencies, Controller Localhost & SSL certificate Localhost (#128))
=======
>>>>>>> ef7cc2d (chore: implemented names variable for action system and adjusted dropdown key list)
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
	inst: BigNumberish;
	is_exit: boolean;
	is_enterable: boolean;
	leads_to: BigNumberish;
	direction_type: DirectionEnum;
	action_map: Array<ActionMapExit>;
}

<<<<<<< HEAD
<<<<<<< HEAD
// Type definition for `lore::models::index::ExitValue` struct
export interface ExitValue {
	is_exit: boolean;
	is_enterable: boolean;
	leads_to: BigNumberish;
	direction_type: DirectionEnum;
	action_map: Array<ActionMapExit>;
}

// Type definition for `lore::models::index::InventoryItem` struct
export interface InventoryItem {
	inst: BigNumberish;
	is_inventory_item: boolean;
	owner_id: BigNumberish;
	can_be_picked_up: boolean;
	can_go_in_container: boolean;
	action_map: Array<ActionMapInventoryItem>;
	already_used: boolean;
	multiple_use: boolean;
}

// Type definition for `lore::models::index::InventoryItemValue` struct
export interface InventoryItemValue {
	is_inventory_item: boolean;
	owner_id: BigNumberish;
	can_be_picked_up: boolean;
	can_go_in_container: boolean;
	action_map: Array<ActionMapInventoryItem>;
	already_used: boolean;
	multiple_use: boolean;
}

// Type definition for `lore::models::index::ParentToChildren` struct
=======
// Type definition for `lore::lib::relations::ParentToChildren` struct
>>>>>>> e854c5e (chore: Upgrade Dependencies, Controller Localhost & SSL certificate Localhost (#128))
=======
// Type definition for `lore::lib::relations::ParentToChildren` struct
=======
// Type definition for `lore::models::index::ExitValue` struct
export interface ExitValue {
	is_exit: boolean;
	is_enterable: boolean;
	leads_to: BigNumberish;
	direction_type: DirectionEnum;
	action_map: Array<ActionMapExit>;
}

// Type definition for `lore::models::index::Inspectable` struct
export interface Inspectable {
	inst: BigNumberish;
	is_inspectable: boolean;
	is_visible: boolean;
	description: Array<BigNumberish>;
	action_map: Array<ActionMapInspectable>;
	already_shown: boolean;
	new_entry: string;
}

// Type definition for `lore::models::index::InspectableValue` struct
export interface InspectableValue {
	is_inspectable: boolean;
	is_visible: boolean;
	description: Array<BigNumberish>;
	action_map: Array<ActionMapInspectable>;
	already_shown: boolean;
	new_entry: string;
}

// Type definition for `lore::models::index::InventoryItem` struct
export interface InventoryItem {
	inst: BigNumberish;
	is_inventory_item: boolean;
	owner_id: BigNumberish;
	can_be_picked_up: boolean;
	can_go_in_container: boolean;
	action_map: Array<ActionMapInventoryItem>;
	already_used: boolean;
	multiple_use: boolean;
}

// Type definition for `lore::models::index::InventoryItemValue` struct
export interface InventoryItemValue {
	is_inventory_item: boolean;
	owner_id: BigNumberish;
	can_be_picked_up: boolean;
	can_go_in_container: boolean;
	action_map: Array<ActionMapInventoryItem>;
	already_used: boolean;
	multiple_use: boolean;
}

// Type definition for `lore::models::index::ParentToChildren` struct
>>>>>>> ef7cc2d (chore: implemented names variable for action system and adjusted dropdown key list)
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
export interface ParentToChildren {
	inst: BigNumberish;
	is_parent: boolean;
	children: Array<BigNumberish>;
}

<<<<<<< HEAD
<<<<<<< HEAD
// Type definition for `lore::models::index::ParentToChildrenValue` struct
export interface ParentToChildrenValue {
	is_parent: boolean;
	children: Array<BigNumberish>;
}

// Type definition for `lore::models::index::Player` struct
export interface Player {
	inst: BigNumberish;
	is_player: boolean;
	address: string;
	location: BigNumberish;
	story_line: BigNumberish;
	use_debug: boolean;
}

// Type definition for `lore::models::index::PlayerStory` struct
export interface PlayerStory {
	inst: BigNumberish;
	story: Array<BigNumberish>;
}

// Type definition for `lore::models::index::PlayerStoryValue` struct
export interface PlayerStoryValue {
	story: Array<BigNumberish>;
}

// Type definition for `lore::models::index::PlayerValue` struct
export interface PlayerValue {
	is_player: boolean;
	address: string;
	location: BigNumberish;
	story_line: BigNumberish;
	use_debug: boolean;
}

// Type definition for `lore::models::index::PropertyRegistry` struct
export interface PropertyRegistry {
	component_type: ComponentTypeEnum;
	properties: Array<ComponentProperty>;
}

// Type definition for `lore::models::index::PropertyRegistryValue` struct
export interface PropertyRegistryValue {
	properties: Array<ComponentProperty>;
}

// Type definition for `lore::models::index::Reactable` struct
export interface Reactable {
	inst: BigNumberish;
	is_reactable: boolean;
	is_visible: boolean;
	description: Array<BigNumberish>;
	action_map: Array<ActionMapReactable>;
	already_shown: boolean;
	new_entry: string;
}

// Type definition for `lore::models::index::ReactableValue` struct
export interface ReactableValue {
	is_reactable: boolean;
	is_visible: boolean;
	description: Array<BigNumberish>;
	action_map: Array<ActionMapReactable>;
	already_shown: boolean;
	new_entry: string;
}

// Type definition for `lore::models::index::StoryLine` struct
export interface StoryLine {
	inst: BigNumberish;
	key: BigNumberish;
	line: string;
}

// Type definition for `lore::models::index::StoryLineValue` struct
export interface StoryLineValue {
	line: string;
}

// Type definition for `lore::models::index::Trigger` struct
=======
// Type definition for `lore::lib::trigger::Trigger` struct
>>>>>>> e854c5e (chore: Upgrade Dependencies, Controller Localhost & SSL certificate Localhost (#128))
=======
// Type definition for `lore::lib::trigger::Trigger` struct
=======
// Type definition for `lore::models::index::ParentToChildrenValue` struct
export interface ParentToChildrenValue {
	is_parent: boolean;
	children: Array<BigNumberish>;
}

// Type definition for `lore::models::index::Player` struct
export interface Player {
	inst: BigNumberish;
	is_player: boolean;
	address: string;
	location: BigNumberish;
	story_line: BigNumberish;
	use_debug: boolean;
}

// Type definition for `lore::models::index::PlayerStory` struct
export interface PlayerStory {
	inst: BigNumberish;
	story: Array<BigNumberish>;
}

// Type definition for `lore::models::index::PlayerStoryValue` struct
export interface PlayerStoryValue {
	story: Array<BigNumberish>;
}

// Type definition for `lore::models::index::PlayerValue` struct
export interface PlayerValue {
	is_player: boolean;
	address: string;
	location: BigNumberish;
	story_line: BigNumberish;
	use_debug: boolean;
}

// Type definition for `lore::models::index::PropertyRegistry` struct
export interface PropertyRegistry {
	component_type: ComponentTypeEnum;
	properties: Array<ComponentProperty>;
}

// Type definition for `lore::models::index::PropertyRegistryValue` struct
export interface PropertyRegistryValue {
	properties: Array<ComponentProperty>;
}

// Type definition for `lore::models::index::StoryLine` struct
export interface StoryLine {
	inst: BigNumberish;
	key: BigNumberish;
	line: string;
}

// Type definition for `lore::models::index::StoryLineValue` struct
export interface StoryLineValue {
	line: string;
}

// Type definition for `lore::models::index::Trigger` struct
>>>>>>> ef7cc2d (chore: implemented names variable for action system and adjusted dropdown key list)
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
export interface Trigger {
	inst: BigNumberish;
	key: BigNumberish;
	name: string;
	trigger_type: TriggerTypeEnum;
	is_enabled: boolean;
	is_once: boolean;
	was_triggered: boolean;
}

// Type definition for `lore::models::index::TriggerIndex` struct
export interface TriggerIndex {
	trigger_type: TriggerTypeEnum;
	trigger_id: Array<[BigNumberish, BigNumberish]>;
}

<<<<<<< HEAD
<<<<<<< HEAD
// Type definition for `lore::models::index::TriggerIndexValue` struct
export interface TriggerIndexValue {
	trigger_id: Array<[BigNumberish, BigNumberish]>;
}

// Type definition for `lore::models::index::TriggerValue` struct
export interface TriggerValue {
	name: string;
	trigger_type: TriggerTypeEnum;
	is_enabled: boolean;
	is_once: boolean;
	was_triggered: boolean;
}

// Type definition for `lore::types::component_type::ActionMapContainer` struct
export interface ActionMapContainer {
	action: string;
	inst: BigNumberish;
	action_fn: ContainerActionsEnum;
}

// Type definition for `lore::types::component_type::ActionMapExit` struct
export interface ActionMapExit {
	action: string;
	inst: BigNumberish;
	action_fn: ExitActionsEnum;
}

// Type definition for `lore::types::component_type::ActionMapInventoryItem` struct
export interface ActionMapInventoryItem {
	action: string;
	inst: BigNumberish;
	action_fn: InventoryItemActionsEnum;
}

// Type definition for `lore::types::component_type::ActionMapReactable` struct
export interface ActionMapReactable {
	action: string;
	inst: BigNumberish;
	action_fn: ReactableActionsEnum;
	entrypoints: [BigNumberish, BigNumberish];
}

// Type definition for `lore::types::property_type::ComponentProperty` struct
=======
=======
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
// Type definition for `lore::lib::trigger::TriggerParameter` struct
export interface TriggerParameter {
	name: string;
	value: BigNumberish;
}

// Type definition for `lore::lib::variable_property::ComponentProperty` struct
<<<<<<< HEAD
>>>>>>> e854c5e (chore: Upgrade Dependencies, Controller Localhost & SSL certificate Localhost (#128))
=======
=======
// Type definition for `lore::models::index::TriggerIndexValue` struct
export interface TriggerIndexValue {
	trigger_id: Array<[BigNumberish, BigNumberish]>;
}

// Type definition for `lore::models::index::TriggerValue` struct
export interface TriggerValue {
	name: string;
	trigger_type: TriggerTypeEnum;
	is_enabled: boolean;
	is_once: boolean;
	was_triggered: boolean;
}

// Type definition for `lore::types::component_type::ActionMapContainer` struct
export interface ActionMapContainer {
	action: string;
	inst: BigNumberish;
	action_fn: ContainerActionsEnum;
}

// Type definition for `lore::types::component_type::ActionMapExit` struct
export interface ActionMapExit {
	action: string;
	inst: BigNumberish;
	action_fn: ExitActionsEnum;
}

// Type definition for `lore::types::component_type::ActionMapInspectable` struct
export interface ActionMapInspectable {
	action: string;
	inst: BigNumberish;
	action_fn: InspectableActionsEnum;
	entrypoint: BigNumberish;
}

// Type definition for `lore::types::component_type::ActionMapInventoryItem` struct
export interface ActionMapInventoryItem {
	action: string;
	inst: BigNumberish;
	action_fn: InventoryItemActionsEnum;
}

// Type definition for `lore::types::property_type::ComponentProperty` struct
>>>>>>> ef7cc2d (chore: implemented names variable for action system and adjusted dropdown key list)
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
export interface ComponentProperty {
	name: string;
	property_type: PropertyTypeEnum;
	access_flags: PropertyAccessEnum;
}

<<<<<<< HEAD
<<<<<<< HEAD
// Type definition for `lore::types::action_type::Operator` enum
export const operator = [
	'Equals',
	'NotEquals',
	'GreaterThan',
	'LessThan',
=======
=======
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
// Type definition for `lore::lib::variable_property::ComponentVariable` struct
export interface ComponentVariable {
	key: BigNumberish;
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

// Type definition for `lore::components::Components` enum
export const components = [
	'Area',
	'Container',
	'Entity',
	'Exit',
	'Inspectable',
	'InventoryItem',
	'Player',
<<<<<<< HEAD
>>>>>>> e854c5e (chore: Upgrade Dependencies, Controller Localhost & SSL certificate Localhost (#128))
=======
=======
// Type definition for `lore::types::action_type::Operator` enum
export const operator = [
	'Equals',
	'NotEquals',
	'GreaterThan',
	'LessThan',
>>>>>>> ef7cc2d (chore: implemented names variable for action system and adjusted dropdown key list)
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
] as const;
export type Operator = { [key in typeof operator[number]]: string };
export type OperatorEnum = CairoCustomEnum;

// Type definition for `lore::types::action_type::TriggerType` enum
export const triggerType = [
	'OnEnter',
	'OnExit',
	'OnInteract',
	'OnInspect',
	'OnUse',
	'OnTimer',
	'OnCondition',
] as const;
export type TriggerType = { [key in typeof triggerType[number]]: string };
export type TriggerTypeEnum = CairoCustomEnum;

// Type definition for `lore::types::command_type::TokenType` enum
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

// Type definition for `lore::types::component_type::ComponentType` enum
export const componentType = [
	'None',
	'Area',
	'Container',
	'Entity',
	'Exit',
<<<<<<< HEAD
	'Reactable',
=======
	'Inspectable',
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
	'InventoryItem',
	'Player',
	'Trigger',
	'Condition',
	'Effect',
	'Action',
] as const;
export type ComponentType = { [key in typeof componentType[number]]: string };
export type ComponentTypeEnum = CairoCustomEnum;

// Type definition for `lore::types::component_type::ContainerActions` enum
export const containerActions = [
	'Open',
	'Close',
	'Check',
] as const;
export type ContainerActions = { [key in typeof containerActions[number]]: string };
export type ContainerActionsEnum = CairoCustomEnum;

// Type definition for `lore::types::component_type::ExitActions` enum
export const exitActions = [
	'UseExit',
] as const;
export type ExitActions = { [key in typeof exitActions[number]]: string };
export type ExitActionsEnum = CairoCustomEnum;

<<<<<<< HEAD
=======
// Type definition for `lore::types::component_type::InspectableActions` enum
export const inspectableActions = [
	'SetVisible',
	'ReadRandomDescription',
	'ReadFirstDescription',
	'ReadSpecificDescription',
] as const;
export type InspectableActions = { [key in typeof inspectableActions[number]]: string };
export type InspectableActionsEnum = CairoCustomEnum;

>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
// Type definition for `lore::types::component_type::InventoryItemActions` enum
export const inventoryItemActions = [
	'UseItem',
	'PickupItem',
	'DropItem',
	'PutItem',
	'TakeOutItem',
] as const;
export type InventoryItemActions = { [key in typeof inventoryItemActions[number]]: string };
export type InventoryItemActionsEnum = CairoCustomEnum;

<<<<<<< HEAD
// Type definition for `lore::types::component_type::ReactableActions` enum
export const reactableActions = [
	'SetVisible',
	'ReadRandomDescription',
	'ReadFirstDescription',
	'ReadSpecificDescription',
] as const;
export type ReactableActions = { [key in typeof reactableActions[number]]: string };
export type ReactableActionsEnum = CairoCustomEnum;

=======
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
// Type definition for `lore::types::direction_type::Direction` enum
export const direction = [
	'North',
	'South',
	'East',
	'West',
	'NorthEast',
	'SouthEast',
	'NorthWest',
	'SouthWest',
	'Up',
	'Down',
] as const;
export type Direction = { [key in typeof direction[number]]: string };
export type DirectionEnum = CairoCustomEnum;

// Type definition for `lore::types::property_type::PropertyAccess` enum
export const propertyAccess = [
	'ReadOnly',
	'ReadWrite',
] as const;
export type PropertyAccess = { [key in typeof propertyAccess[number]]: string };
export type PropertyAccessEnum = CairoCustomEnum;

// Type definition for `lore::types::property_type::PropertyType` enum
export const propertyType = [
	'Boolean',
	'Felt252',
	'U8',
	'U32',
	'Enum',
	'ByteArray',
	'ContractAddress',
	'ArrayFelt252',
	'ArrayByteArray',
] as const;
export type PropertyType = { [key in typeof propertyType[number]]: string };
export type PropertyTypeEnum = CairoCustomEnum;

export interface SchemaType extends ISchemaType {
	lore: {
		ChildToParent: ChildToParent,
		ChildToParentValue: ChildToParentValue,
		Action: Action,
		ActionValue: ActionValue,
		Area: Area,
<<<<<<< HEAD
<<<<<<< HEAD
		AreaValue: AreaValue,
		ComponentVariable: ComponentVariable,
		ComponentVariableValue: ComponentVariableValue,
		Condition: Condition,
		ConditionValue: ConditionValue,
		Container: Container,
		ContainerValue: ContainerValue,
		DescriptionText: DescriptionText,
		DescriptionTextValue: DescriptionTextValue,
		Dict: Dict,
		DictValue: DictValue,
		Effect: Effect,
		EffectValue: EffectValue,
		Entity: Entity,
		EntityValue: EntityValue,
		Exit: Exit,
		ExitValue: ExitValue,
		InventoryItem: InventoryItem,
		InventoryItemValue: InventoryItemValue,
		ParentToChildren: ParentToChildren,
		ParentToChildrenValue: ParentToChildrenValue,
		Player: Player,
		PlayerStory: PlayerStory,
		PlayerStoryValue: PlayerStoryValue,
		PlayerValue: PlayerValue,
		PropertyRegistry: PropertyRegistry,
		PropertyRegistryValue: PropertyRegistryValue,
		Reactable: Reactable,
		ReactableValue: ReactableValue,
		StoryLine: StoryLine,
		StoryLineValue: StoryLineValue,
		Trigger: Trigger,
		TriggerIndex: TriggerIndex,
		TriggerIndexValue: TriggerIndexValue,
		TriggerValue: TriggerValue,
		ActionMapContainer: ActionMapContainer,
		ActionMapExit: ActionMapExit,
		ActionMapInventoryItem: ActionMapInventoryItem,
		ActionMapReactable: ActionMapReactable,
		ComponentProperty: ComponentProperty,
=======
=======
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
		ActionMapContainer: ActionMapContainer,
		Container: Container,
		ActionMapExit: ActionMapExit,
		Exit: Exit,
		ActionMapInspectable: ActionMapInspectable,
		Inspectable: Inspectable,
		ActionMapInventoryItem: ActionMapInventoryItem,
		InventoryItem: InventoryItem,
		Player: Player,
		PlayerStory: PlayerStory,
		Action: Action,
		Condition: Condition,
		Dict: Dict,
		Effect: Effect,
		EffectExecution: EffectExecution,
		EffectParameter: EffectParameter,
		Entity: Entity,
		ChildToParent: ChildToParent,
		ParentToChildren: ParentToChildren,
		Trigger: Trigger,
		TriggerIndex: TriggerIndex,
		TriggerParameter: TriggerParameter,
		ComponentProperty: ComponentProperty,
		ComponentVariable: ComponentVariable,
		PropertyRegistry: PropertyRegistry,
<<<<<<< HEAD
>>>>>>> e854c5e (chore: Upgrade Dependencies, Controller Localhost & SSL certificate Localhost (#128))
=======
=======
		AreaValue: AreaValue,
		ComponentVariable: ComponentVariable,
		ComponentVariableValue: ComponentVariableValue,
		Condition: Condition,
		ConditionValue: ConditionValue,
		Container: Container,
		ContainerValue: ContainerValue,
		DescriptionText: DescriptionText,
		DescriptionTextValue: DescriptionTextValue,
		Dict: Dict,
		DictValue: DictValue,
		Effect: Effect,
		EffectValue: EffectValue,
		Entity: Entity,
		EntityValue: EntityValue,
		Exit: Exit,
		ExitValue: ExitValue,
		Inspectable: Inspectable,
		InspectableValue: InspectableValue,
		InventoryItem: InventoryItem,
		InventoryItemValue: InventoryItemValue,
		ParentToChildren: ParentToChildren,
		ParentToChildrenValue: ParentToChildrenValue,
		Player: Player,
		PlayerStory: PlayerStory,
		PlayerStoryValue: PlayerStoryValue,
		PlayerValue: PlayerValue,
		PropertyRegistry: PropertyRegistry,
		PropertyRegistryValue: PropertyRegistryValue,
		StoryLine: StoryLine,
		StoryLineValue: StoryLineValue,
		Trigger: Trigger,
		TriggerIndex: TriggerIndex,
		TriggerIndexValue: TriggerIndexValue,
		TriggerValue: TriggerValue,
		ActionMapContainer: ActionMapContainer,
		ActionMapExit: ActionMapExit,
		ActionMapInspectable: ActionMapInspectable,
		ActionMapInventoryItem: ActionMapInventoryItem,
		ComponentProperty: ComponentProperty,
>>>>>>> ef7cc2d (chore: implemented names variable for action system and adjusted dropdown key list)
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
	},
}
export const schema: SchemaType = {
	lore: {
		ChildToParent: {
			inst: 0,
			is_child: false,
			parent: 0,
		},
<<<<<<< HEAD
<<<<<<< HEAD
		ChildToParentValue: {
			is_child: false,
			parent: 0,
=======
=======
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
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
		ActionMapInspectable: {
		action: "",
			inst: 0,
		action_fn: new CairoCustomEnum({ 
					SetVisible: "",
				ReadRandomDescription: undefined,
				ReadFirstDescription: undefined,
				ReadSpecificDescription: undefined, }),
			entrypoint: 0,
		},
		Inspectable: {
			inst: 0,
			is_inspectable: false,
			is_visible: false,
			description: [""],
			action_map: [{ action: "", inst: 0, action_fn: new CairoCustomEnum({ 
					SetVisible: "",
				ReadRandomDescription: undefined,
				ReadFirstDescription: undefined,
				ReadSpecificDescription: undefined, }), entrypoint: 0, }],
			already_shown: false,
		new_entry: "",
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
			already_used: false,
			multiple_use: false,
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
<<<<<<< HEAD
>>>>>>> e854c5e (chore: Upgrade Dependencies, Controller Localhost & SSL certificate Localhost (#128))
=======
=======
		ChildToParentValue: {
			is_child: false,
			parent: 0,
>>>>>>> ef7cc2d (chore: implemented names variable for action system and adjusted dropdown key list)
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
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
			executed: false,
			failing_response: [""],
			success_response: [""],
		},
<<<<<<< HEAD
<<<<<<< HEAD
=======
=======
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
		ActionValue: {
		name: "",
		description: "",
			is_enabled: false,
			trigger: [[0, 0]],
			conditions: [[0, 0]],
			effects: [[0, 0]],
			tags: [""],
			executed: false,
			failing_response: [""],
			success_response: [""],
		},
		Area: {
			inst: 0,
			is_area: false,
			is_spawn_point: false,
		},
		AreaValue: {
			is_area: false,
			is_spawn_point: false,
		},
		ComponentVariable: {
			inst: 0,
			key: 0,
			id: 0,
		component_type: new CairoCustomEnum({ 
					None: "",
				Area: undefined,
				Container: undefined,
				Entity: undefined,
				Exit: undefined,
				Reactable: undefined,
				InventoryItem: undefined,
				Player: undefined,
				Trigger: undefined,
				Condition: undefined,
				Effect: undefined,
				Action: undefined, }),
		property_name: "",
		value: "",
			last_updated: 0,
		},
		ComponentVariableValue: {
		component_type: new CairoCustomEnum({ 
					None: "",
				Area: undefined,
				Container: undefined,
				Entity: undefined,
				Exit: undefined,
<<<<<<< HEAD
				Reactable: undefined,
=======
				Inspectable: undefined,
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
				InventoryItem: undefined,
				Player: undefined,
				Trigger: undefined,
				Condition: undefined,
				Effect: undefined,
				Action: undefined, }),
		property_name: "",
		value: "",
			last_updated: 0,
		},
<<<<<<< HEAD
=======
>>>>>>> e854c5e (chore: Upgrade Dependencies, Controller Localhost & SSL certificate Localhost (#128))
=======
>>>>>>> ef7cc2d (chore: implemented names variable for action system and adjusted dropdown key list)
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
		Condition: {
			inst: 0,
			key: 0,
		name: "",
			target: 0,
		component: new CairoCustomEnum({ 
					None: "",
				Area: undefined,
				Container: undefined,
				Entity: undefined,
				Exit: undefined,
<<<<<<< HEAD
				Reactable: undefined,
=======
				Inspectable: undefined,
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
				InventoryItem: undefined,
				Player: undefined,
				Trigger: undefined,
				Condition: undefined,
				Effect: undefined,
				Action: undefined, }),
		property: "",
		operator: new CairoCustomEnum({ 
					Equals: "",
				NotEquals: undefined,
				GreaterThan: undefined,
				LessThan: undefined, }),
			value: [0],
		},
<<<<<<< HEAD
<<<<<<< HEAD
=======
=======
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
		ConditionValue: {
		name: "",
			target: 0,
		component: new CairoCustomEnum({ 
					None: "",
				Area: undefined,
				Container: undefined,
				Entity: undefined,
				Exit: undefined,
<<<<<<< HEAD
				Reactable: undefined,
=======
				Inspectable: undefined,
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
				InventoryItem: undefined,
				Player: undefined,
				Trigger: undefined,
				Condition: undefined,
				Effect: undefined,
				Action: undefined, }),
		property: "",
		operator: new CairoCustomEnum({ 
					Equals: "",
				NotEquals: undefined,
				GreaterThan: undefined,
				LessThan: undefined, }),
			value: [0],
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
		DescriptionText: {
			inst: 0,
			key: 0,
		text: "",
		},
		DescriptionTextValue: {
		text: "",
		},
<<<<<<< HEAD
=======
>>>>>>> e854c5e (chore: Upgrade Dependencies, Controller Localhost & SSL certificate Localhost (#128))
=======
>>>>>>> ef7cc2d (chore: implemented names variable for action system and adjusted dropdown key list)
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
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
		Effect: {
			inst: 0,
			key: 0,
		name: "",
			target: 0,
		component: new CairoCustomEnum({ 
					None: "",
				Area: undefined,
				Container: undefined,
				Entity: undefined,
				Exit: undefined,
				Reactable: undefined,
				InventoryItem: undefined,
				Player: undefined,
				Trigger: undefined,
				Condition: undefined,
				Effect: undefined,
				Action: undefined, }),
		property: "",
<<<<<<< HEAD
<<<<<<< HEAD
			value: [["", 0]],
		},
		EffectValue: {
		name: "",
			target: 0,
		component: new CairoCustomEnum({ 
					None: "",
				Area: undefined,
				Container: undefined,
				Entity: undefined,
				Exit: undefined,
				Reactable: undefined,
				InventoryItem: undefined,
				Player: undefined,
				Trigger: undefined,
				Condition: undefined,
				Effect: undefined,
				Action: undefined, }),
		property: "",
			value: [["", 0]],
		},
=======
=======
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
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
		EffectParameter: {
		name: "",
			value: 0,
		},
<<<<<<< HEAD
>>>>>>> e854c5e (chore: Upgrade Dependencies, Controller Localhost & SSL certificate Localhost (#128))
=======
=======
			value: [["", 0]],
		},
		EffectValue: {
		name: "",
			target: 0,
		component: new CairoCustomEnum({ 
					None: "",
				Area: undefined,
				Container: undefined,
				Entity: undefined,
				Exit: undefined,
				Inspectable: undefined,
				InventoryItem: undefined,
				Player: undefined,
				Trigger: undefined,
				Condition: undefined,
				Effect: undefined,
				Action: undefined, }),
		property: "",
			value: [["", 0]],
		},
>>>>>>> ef7cc2d (chore: implemented names variable for action system and adjusted dropdown key list)
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
		Entity: {
			inst: 0,
			is_entity: false,
		name: "",
			alt_names: [""],
			actions_keys: [0],
		},
<<<<<<< HEAD
<<<<<<< HEAD
=======
		ChildToParent: {
=======
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
		EntityValue: {
			is_entity: false,
		name: "",
			alt_names: [""],
			actions_keys: [0],
		},
		Exit: {
<<<<<<< HEAD
=======
		ChildToParent: {
>>>>>>> e854c5e (chore: Upgrade Dependencies, Controller Localhost & SSL certificate Localhost (#128))
=======
>>>>>>> ef7cc2d (chore: implemented names variable for action system and adjusted dropdown key list)
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
			inst: 0,
			is_exit: false,
			is_enterable: false,
			leads_to: 0,
		direction_type: new CairoCustomEnum({ 
					North: "",
				South: undefined,
				East: undefined,
				West: undefined,
				NorthEast: undefined,
				SouthEast: undefined,
				NorthWest: undefined,
				SouthWest: undefined,
				Up: undefined,
				Down: undefined, }),
			action_map: [{ action: "", inst: 0, action_fn: new CairoCustomEnum({ 
					UseExit: "", }), }],
		},
<<<<<<< HEAD
<<<<<<< HEAD
=======
=======
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
		ExitValue: {
			is_exit: false,
			is_enterable: false,
			leads_to: 0,
		direction_type: new CairoCustomEnum({ 
					North: "",
				South: undefined,
				East: undefined,
				West: undefined,
				NorthEast: undefined,
				SouthEast: undefined,
				NorthWest: undefined,
				SouthWest: undefined,
				Up: undefined,
				Down: undefined, }),
			action_map: [{ action: "", inst: 0, action_fn: new CairoCustomEnum({ 
					UseExit: "", }), }],
		},
<<<<<<< HEAD
=======
		Inspectable: {
			inst: 0,
			is_inspectable: false,
			is_visible: false,
			description: [0],
			action_map: [{ action: "", inst: 0, action_fn: new CairoCustomEnum({ 
					SetVisible: "",
				ReadRandomDescription: undefined,
				ReadFirstDescription: undefined,
				ReadSpecificDescription: undefined, }), entrypoint: 0, }],
			already_shown: false,
		new_entry: "",
		},
		InspectableValue: {
			is_inspectable: false,
			is_visible: false,
			description: [0],
			action_map: [{ action: "", inst: 0, action_fn: new CairoCustomEnum({ 
					SetVisible: "",
				ReadRandomDescription: undefined,
				ReadFirstDescription: undefined,
				ReadSpecificDescription: undefined, }), entrypoint: 0, }],
			already_shown: false,
		new_entry: "",
		},
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
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
			already_used: false,
			multiple_use: false,
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
			already_used: false,
			multiple_use: false,
		},
<<<<<<< HEAD
=======
>>>>>>> e854c5e (chore: Upgrade Dependencies, Controller Localhost & SSL certificate Localhost (#128))
=======
>>>>>>> ef7cc2d (chore: implemented names variable for action system and adjusted dropdown key list)
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
		ParentToChildren: {
			inst: 0,
			is_parent: false,
			children: [0],
		},
<<<<<<< HEAD
<<<<<<< HEAD
=======
=======
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
		ParentToChildrenValue: {
			is_parent: false,
			children: [0],
		},
		Player: {
			inst: 0,
			is_player: false,
			address: "",
			location: 0,
			story_line: 0,
			use_debug: false,
		},
		PlayerStory: {
			inst: 0,
			story: [0],
		},
		PlayerStoryValue: {
			story: [0],
		},
		PlayerValue: {
			is_player: false,
			address: "",
			location: 0,
			story_line: 0,
			use_debug: false,
		},
		PropertyRegistry: {
		component_type: new CairoCustomEnum({ 
					None: "",
				Area: undefined,
				Container: undefined,
				Entity: undefined,
				Exit: undefined,
<<<<<<< HEAD
				Reactable: undefined,
=======
				Inspectable: undefined,
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
				InventoryItem: undefined,
				Player: undefined,
				Trigger: undefined,
				Condition: undefined,
				Effect: undefined,
				Action: undefined, }),
			properties: [{ name: "", property_type: new CairoCustomEnum({ 
					Boolean: "",
				Felt252: undefined,
				U8: undefined,
				U32: undefined,
				Enum: undefined,
				ByteArray: undefined,
				ContractAddress: undefined,
				ArrayFelt252: undefined,
				ArrayByteArray: undefined, }), access_flags: new CairoCustomEnum({ 
					ReadOnly: "",
				ReadWrite: undefined, }), }],
		},
		PropertyRegistryValue: {
			properties: [{ name: "", property_type: new CairoCustomEnum({ 
					Boolean: "",
				Felt252: undefined,
				U8: undefined,
				U32: undefined,
				Enum: undefined,
				ByteArray: undefined,
				ContractAddress: undefined,
				ArrayFelt252: undefined,
				ArrayByteArray: undefined, }), access_flags: new CairoCustomEnum({ 
					ReadOnly: "",
				ReadWrite: undefined, }), }],
		},
<<<<<<< HEAD
		Reactable: {
			inst: 0,
			is_reactable: false,
			is_visible: false,
			description: [0],
			action_map: [{ action: "", inst: 0, action_fn: new CairoCustomEnum({ 
					SetVisible: "",
				ReadRandomDescription: undefined,
				ReadFirstDescription: undefined,
				ReadSpecificDescription: undefined, }), entrypoints: [0, 0], }],
			already_shown: false,
		new_entry: "",
		},
		ReactableValue: {
			is_reactable: false,
			is_visible: false,
			description: [0],
			action_map: [{ action: "", inst: 0, action_fn: new CairoCustomEnum({ 
					SetVisible: "",
				ReadRandomDescription: undefined,
				ReadFirstDescription: undefined,
				ReadSpecificDescription: undefined, }), entrypoints: [0, 0], }],
			already_shown: false,
		new_entry: "",
		},
=======
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
		StoryLine: {
			inst: 0,
			key: 0,
		line: "",
		},
		StoryLineValue: {
		line: "",
		},
<<<<<<< HEAD
=======
>>>>>>> e854c5e (chore: Upgrade Dependencies, Controller Localhost & SSL certificate Localhost (#128))
=======
>>>>>>> ef7cc2d (chore: implemented names variable for action system and adjusted dropdown key list)
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
		Trigger: {
			inst: 0,
			key: 0,
		name: "",
		trigger_type: new CairoCustomEnum({ 
					OnEnter: "",
				OnExit: undefined,
				OnInteract: undefined,
				OnInspect: undefined,
				OnUse: undefined,
				OnTimer: undefined,
				OnCondition: undefined, }),
			is_enabled: false,
			is_once: false,
			was_triggered: false,
		},
		TriggerIndex: {
		trigger_type: new CairoCustomEnum({ 
					OnEnter: "",
				OnExit: undefined,
				OnInteract: undefined,
				OnInspect: undefined,
				OnUse: undefined,
				OnTimer: undefined,
				OnCondition: undefined, }),
			trigger_id: [[0, 0]],
		},
<<<<<<< HEAD
<<<<<<< HEAD
		TriggerIndexValue: {
			trigger_id: [[0, 0]],
		},
		TriggerValue: {
		name: "",
		trigger_type: new CairoCustomEnum({ 
					OnEnter: "",
				OnExit: undefined,
				OnInteract: undefined,
				OnInspect: undefined,
				OnUse: undefined,
				OnTimer: undefined,
				OnCondition: undefined, }),
			is_enabled: false,
			is_once: false,
			was_triggered: false,
		},
		ActionMapContainer: {
		action: "",
			inst: 0,
		action_fn: new CairoCustomEnum({ 
					Open: "",
				Close: undefined,
				Check: undefined, }),
		},
		ActionMapExit: {
		action: "",
			inst: 0,
		action_fn: new CairoCustomEnum({ 
					UseExit: "", }),
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
		ActionMapReactable: {
		action: "",
			inst: 0,
		action_fn: new CairoCustomEnum({ 
					SetVisible: "",
				ReadRandomDescription: undefined,
				ReadFirstDescription: undefined,
				ReadSpecificDescription: undefined, }),
			entrypoints: [0, 0],
=======
		TriggerParameter: {
		name: "",
			value: 0,
>>>>>>> e854c5e (chore: Upgrade Dependencies, Controller Localhost & SSL certificate Localhost (#128))
=======
		TriggerParameter: {
		name: "",
			value: 0,
=======
		TriggerIndexValue: {
			trigger_id: [[0, 0]],
		},
		TriggerValue: {
		name: "",
		trigger_type: new CairoCustomEnum({ 
					OnEnter: "",
				OnExit: undefined,
				OnInteract: undefined,
				OnInspect: undefined,
				OnUse: undefined,
				OnTimer: undefined,
				OnCondition: undefined, }),
			is_enabled: false,
			is_once: false,
			was_triggered: false,
		},
		ActionMapContainer: {
		action: "",
			inst: 0,
		action_fn: new CairoCustomEnum({ 
					Open: "",
				Close: undefined,
				Check: undefined, }),
		},
		ActionMapExit: {
		action: "",
			inst: 0,
		action_fn: new CairoCustomEnum({ 
					UseExit: "", }),
		},
		ActionMapInspectable: {
		action: "",
			inst: 0,
		action_fn: new CairoCustomEnum({ 
					SetVisible: "",
				ReadRandomDescription: undefined,
				ReadFirstDescription: undefined,
				ReadSpecificDescription: undefined, }),
			entrypoint: 0,
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
>>>>>>> ef7cc2d (chore: implemented names variable for action system and adjusted dropdown key list)
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
		},
		ComponentProperty: {
		name: "",
		property_type: new CairoCustomEnum({ 
					Boolean: "",
				Felt252: undefined,
				U8: undefined,
				U32: undefined,
				Enum: undefined,
				ByteArray: undefined,
				ContractAddress: undefined,
				ArrayFelt252: undefined,
				ArrayByteArray: undefined, }),
		access_flags: new CairoCustomEnum({ 
					ReadOnly: "",
				ReadWrite: undefined, }),
		},
<<<<<<< HEAD
<<<<<<< HEAD
=======
=======
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
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
<<<<<<< HEAD
>>>>>>> e854c5e (chore: Upgrade Dependencies, Controller Localhost & SSL certificate Localhost (#128))
=======
=======
>>>>>>> ef7cc2d (chore: implemented names variable for action system and adjusted dropdown key list)
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
	},
};
export enum ModelsMapping {
	ChildToParent = 'lore-ChildToParent',
	ChildToParentValue = 'lore-ChildToParentValue',
	Action = 'lore-Action',
	ActionValue = 'lore-ActionValue',
	Area = 'lore-Area',
<<<<<<< HEAD
<<<<<<< HEAD
	AreaValue = 'lore-AreaValue',
	ComponentVariable = 'lore-ComponentVariable',
	ComponentVariableValue = 'lore-ComponentVariableValue',
	Condition = 'lore-Condition',
	ConditionValue = 'lore-ConditionValue',
	Container = 'lore-Container',
	ContainerValue = 'lore-ContainerValue',
	DescriptionText = 'lore-DescriptionText',
	DescriptionTextValue = 'lore-DescriptionTextValue',
	Dict = 'lore-Dict',
	DictValue = 'lore-DictValue',
	Effect = 'lore-Effect',
	EffectValue = 'lore-EffectValue',
	Entity = 'lore-Entity',
	EntityValue = 'lore-EntityValue',
	Exit = 'lore-Exit',
	ExitValue = 'lore-ExitValue',
	InventoryItem = 'lore-InventoryItem',
	InventoryItemValue = 'lore-InventoryItemValue',
	ParentToChildren = 'lore-ParentToChildren',
	ParentToChildrenValue = 'lore-ParentToChildrenValue',
	Player = 'lore-Player',
	PlayerStory = 'lore-PlayerStory',
	PlayerStoryValue = 'lore-PlayerStoryValue',
	PlayerValue = 'lore-PlayerValue',
	PropertyRegistry = 'lore-PropertyRegistry',
	PropertyRegistryValue = 'lore-PropertyRegistryValue',
	Reactable = 'lore-Reactable',
	ReactableValue = 'lore-ReactableValue',
	StoryLine = 'lore-StoryLine',
	StoryLineValue = 'lore-StoryLineValue',
	Trigger = 'lore-Trigger',
	TriggerIndex = 'lore-TriggerIndex',
	TriggerIndexValue = 'lore-TriggerIndexValue',
	TriggerValue = 'lore-TriggerValue',
	Operator = 'lore-Operator',
	TriggerType = 'lore-TriggerType',
	TokenType = 'lore-TokenType',
	ActionMapContainer = 'lore-ActionMapContainer',
	ActionMapExit = 'lore-ActionMapExit',
	ActionMapInventoryItem = 'lore-ActionMapInventoryItem',
	ActionMapReactable = 'lore-ActionMapReactable',
	ComponentType = 'lore-ComponentType',
	ContainerActions = 'lore-ContainerActions',
	ExitActions = 'lore-ExitActions',
	InventoryItemActions = 'lore-InventoryItemActions',
	ReactableActions = 'lore-ReactableActions',
	Direction = 'lore-Direction',
	ComponentProperty = 'lore-ComponentProperty',
	PropertyAccess = 'lore-PropertyAccess',
=======
=======
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
	ActionMapContainer = 'lore-ActionMapContainer',
	Container = 'lore-Container',
	ContainerActions = 'lore-ContainerActions',
	ActionMapExit = 'lore-ActionMapExit',
	Exit = 'lore-Exit',
	ExitActions = 'lore-ExitActions',
	ActionMapInspectable = 'lore-ActionMapInspectable',
	Inspectable = 'lore-Inspectable',
	InspectableActions = 'lore-InspectableActions',
	ActionMapInventoryItem = 'lore-ActionMapInventoryItem',
	InventoryItem = 'lore-InventoryItem',
	InventoryItemActions = 'lore-InventoryItemActions',
	Player = 'lore-Player',
	PlayerStory = 'lore-PlayerStory',
	Direction = 'lore-Direction',
	TokenType = 'lore-TokenType',
	Action = 'lore-Action',
	Condition = 'lore-Condition',
	Operator = 'lore-Operator',
	Dict = 'lore-Dict',
	Effect = 'lore-Effect',
	EffectExecution = 'lore-EffectExecution',
	EffectParameter = 'lore-EffectParameter',
	ExecutionStatus = 'lore-ExecutionStatus',
	Entity = 'lore-Entity',
	ChildToParent = 'lore-ChildToParent',
	ParentToChildren = 'lore-ParentToChildren',
	Trigger = 'lore-Trigger',
	TriggerIndex = 'lore-TriggerIndex',
	TriggerParameter = 'lore-TriggerParameter',
	TriggerType = 'lore-TriggerType',
	ComponentProperty = 'lore-ComponentProperty',
	ComponentVariable = 'lore-ComponentVariable',
	PropertyAccess = 'lore-PropertyAccess',
	PropertyRegistry = 'lore-PropertyRegistry',
<<<<<<< HEAD
>>>>>>> e854c5e (chore: Upgrade Dependencies, Controller Localhost & SSL certificate Localhost (#128))
=======
=======
	AreaValue = 'lore-AreaValue',
	ComponentVariable = 'lore-ComponentVariable',
	ComponentVariableValue = 'lore-ComponentVariableValue',
	Condition = 'lore-Condition',
	ConditionValue = 'lore-ConditionValue',
	Container = 'lore-Container',
	ContainerValue = 'lore-ContainerValue',
	DescriptionText = 'lore-DescriptionText',
	DescriptionTextValue = 'lore-DescriptionTextValue',
	Dict = 'lore-Dict',
	DictValue = 'lore-DictValue',
	Effect = 'lore-Effect',
	EffectValue = 'lore-EffectValue',
	Entity = 'lore-Entity',
	EntityValue = 'lore-EntityValue',
	Exit = 'lore-Exit',
	ExitValue = 'lore-ExitValue',
	Inspectable = 'lore-Inspectable',
	InspectableValue = 'lore-InspectableValue',
	InventoryItem = 'lore-InventoryItem',
	InventoryItemValue = 'lore-InventoryItemValue',
	ParentToChildren = 'lore-ParentToChildren',
	ParentToChildrenValue = 'lore-ParentToChildrenValue',
	Player = 'lore-Player',
	PlayerStory = 'lore-PlayerStory',
	PlayerStoryValue = 'lore-PlayerStoryValue',
	PlayerValue = 'lore-PlayerValue',
	PropertyRegistry = 'lore-PropertyRegistry',
	PropertyRegistryValue = 'lore-PropertyRegistryValue',
	StoryLine = 'lore-StoryLine',
	StoryLineValue = 'lore-StoryLineValue',
	Trigger = 'lore-Trigger',
	TriggerIndex = 'lore-TriggerIndex',
	TriggerIndexValue = 'lore-TriggerIndexValue',
	TriggerValue = 'lore-TriggerValue',
	Operator = 'lore-Operator',
	TriggerType = 'lore-TriggerType',
	TokenType = 'lore-TokenType',
	ActionMapContainer = 'lore-ActionMapContainer',
	ActionMapExit = 'lore-ActionMapExit',
	ActionMapInspectable = 'lore-ActionMapInspectable',
	ActionMapInventoryItem = 'lore-ActionMapInventoryItem',
	ComponentType = 'lore-ComponentType',
	ContainerActions = 'lore-ContainerActions',
	ExitActions = 'lore-ExitActions',
	InspectableActions = 'lore-InspectableActions',
	InventoryItemActions = 'lore-InventoryItemActions',
	Direction = 'lore-Direction',
	ComponentProperty = 'lore-ComponentProperty',
	PropertyAccess = 'lore-PropertyAccess',
>>>>>>> ef7cc2d (chore: implemented names variable for action system and adjusted dropdown key list)
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
	PropertyType = 'lore-PropertyType',
}