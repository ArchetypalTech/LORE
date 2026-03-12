import type { SchemaType as ISchemaType } from "@dojoengine/sdk";

import { CairoCustomEnum, BigNumberish } from 'starknet';

// Type definition for `lore::models::action::Action` struct
export interface Action {
	inst: BigNumberish;
	key: BigNumberish;
	name: string;
	description: string;
	is_enabled: boolean;
	executor: BigNumberish;
	trigger: Array<[BigNumberish, BigNumberish]>;
	conditions: Array<[BigNumberish, BigNumberish]>;
	effects: Array<[BigNumberish, BigNumberish]>;
	tags: Array<string>;
	failing_response: Array<string>;
	success_response: Array<string>;
}

// Type definition for `lore::models::action::ActionExecuted` struct
export interface ActionExecuted {
	game_id: BigNumberish;
	inst: BigNumberish;
	key: BigNumberish;
	is_executed: boolean;
}

// Type definition for `lore::models::actions_config::ActionsConfig` struct
export interface ActionsConfig {
	key: BigNumberish;
	sn_contract: string;
	action_cost_amount: BigNumberish;
	initial_free_actions_count: BigNumberish;
	max_free_actions_count: BigNumberish;
	free_action_claim_interval: BigNumberish;
	trail_reward_actions_count: BigNumberish;
}

// Type definition for `lore::models::actions_config::ActionsReward` struct
export interface ActionsReward {
	player_address: string;
	collected_actions_amount: BigNumberish;
	claimed_actions_amount: BigNumberish;
}

// Type definition for `lore::models::area::Area` struct
export interface Area {
	inst: BigNumberish;
	is_area: boolean;
	is_spawn_point: boolean;
	progress_percentage: BigNumberish;
	preserve_children: boolean;
}

// Type definition for `lore::models::condition::Condition` struct
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

// Type definition for `lore::models::container::Container` struct
export interface Container {
	inst: BigNumberish;
	is_container: boolean;
	can_be_opened: boolean;
	can_receive_items: boolean;
	is_open: boolean;
	num_slots: BigNumberish;
	action_map: Array<ActionMapContainer>;
}

// Type definition for `lore::models::description_text::DescriptionText` struct
export interface DescriptionText {
	inst: BigNumberish;
	key: BigNumberish;
	text: string;
}

// Type definition for `lore::models::dictionary::Dict` struct
export interface Dict {
	dict_key: BigNumberish;
	word: string;
	tokenType: TokenTypeEnum;
	n_value: BigNumberish;
}

// Type definition for `lore::models::effect::Effect` struct
export interface Effect {
	inst: BigNumberish;
	key: BigNumberish;
	name: string;
	target: BigNumberish;
	effect_type: EffectTypeEnum;
	component: ComponentTypeEnum;
	property: string;
	value: Array<[string, BigNumberish]>;
	n_value: BigNumberish;
	hex_value: BigNumberish;
}

// Type definition for `lore::models::entity::ChildToParent` struct
export interface ChildToParent {
	inst: BigNumberish;
	is_child: boolean;
	parent: BigNumberish;
}

// Type definition for `lore::models::entity::Entity` struct
export interface Entity {
	inst: BigNumberish;
	is_entity: boolean;
	trail_id: BigNumberish;
	name: string;
	creator_address: string;
	alt_names: Array<string>;
	actions_keys: Array<BigNumberish>;
}

// Type definition for `lore::models::entity::ParentToChildren` struct
export interface ParentToChildren {
	inst: BigNumberish;
	is_parent: boolean;
	children: Array<BigNumberish>;
}

// Type definition for `lore::models::exit::Exit` struct
export interface Exit {
	inst: BigNumberish;
	is_exit: boolean;
	is_enterable: boolean;
	leads_to: BigNumberish;
	direction_type: DirectionEnum;
	action_map: Array<ActionMapExit>;
}

// Type definition for `lore::models::game_instance::GameInstanceKeyMap` struct
export interface GameInstanceKeyMap {
	game_id: BigNumberish;
	inst: BigNumberish;
	key: BigNumberish;
	game_inst: BigNumberish;
}

// Type definition for `lore::models::game_instance::GameInstanceMap` struct
export interface GameInstanceMap {
	game_id: BigNumberish;
	inst: BigNumberish;
	game_inst: BigNumberish;
}

// Type definition for `lore::models::game_token_info::GameTokenInfo` struct
export interface GameTokenInfo {
	game_id: BigNumberish;
	minter_address: string;
	seed: BigNumberish;
	room_name: string;
	act_number: BigNumberish;
}

// Type definition for `lore::models::hub::Hub` struct
export interface Hub {
	inst: BigNumberish;
	is_hub: boolean;
	is_enabled: boolean;
	trails_insts: Array<BigNumberish>;
	grants_editor_access: boolean;
}

// Type definition for `lore::models::hub::Trail` struct
export interface Trail {
	inst: BigNumberish;
	is_trail: boolean;
	trail_id: BigNumberish;
	hub_inst: BigNumberish;
	is_published: boolean;
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

// Type definition for `lore::models::index::PropertyRegistry` struct
export interface PropertyRegistry {
	component_type: ComponentTypeEnum;
	properties: Array<ComponentProperty>;
}

// Type definition for `lore::models::inventory_item::InventoryItem` struct
export interface InventoryItem {
	inst: BigNumberish;
	is_inventory_item: boolean;
	owner_id: BigNumberish;
	can_be_picked_up: boolean;
	can_go_in_container: boolean;
	quantity: BigNumberish;
	action_map: Array<ActionMapInventoryItem>;
	already_used: boolean;
	multiple_use: boolean;
}

// Type definition for `lore::models::player::Player` struct
export interface Player {
	inst: BigNumberish;
	is_player: boolean;
	address: string;
	game_id: BigNumberish;
	location: BigNumberish;
	use_debug: boolean;
	is_dead: boolean;
}

// Type definition for `lore::models::player::PlayerStory` struct
export interface PlayerStory {
	game_id: BigNumberish;
	story_line: BigNumberish;
	free_actions_count: BigNumberish;
	sub_actions_count: BigNumberish;
	paid_actions_count: BigNumberish;
}

// Type definition for `lore::models::player::StoryLine` struct
export interface StoryLine {
	game_id: BigNumberish;
	key: BigNumberish;
	line: string;
	line_type: StoryLineTypeEnum;
	location: BigNumberish;
	timestamp: BigNumberish;
}

// Type definition for `lore::models::player_account::PlayerAccount` struct
export interface PlayerAccount {
	player_address: string;
	timestamp_joined: BigNumberish;
	timestamp_free_actions_claimed: BigNumberish;
	minted_actions_count: BigNumberish;
	purchase_count: BigNumberish;
	subscription_count: BigNumberish;
	current_game_id: BigNumberish;
}

// Type definition for `lore::models::player_account::PlayerBalances` struct
export interface PlayerBalances {
	player_address: string;
	free_actions_balance: BigNumberish;
	paid_actions_balance: BigNumberish;
	sub_actions_balance: BigNumberish;
}

// Type definition for `lore::models::reactable::Reactable` struct
export interface Reactable {
	inst: BigNumberish;
	is_reactable: boolean;
	is_visible: boolean;
	description: Array<BigNumberish>;
	action_map: Array<ActionMapReactable>;
	already_shown: boolean;
	new_entry: string;
}

// Type definition for `lore::models::trail_token_info::TrailProgress` struct
export interface TrailProgress {
	game_id: BigNumberish;
	trail_id: BigNumberish;
	percentage: BigNumberish;
	completed: boolean;
}

// Type definition for `lore::models::trail_token_info::TrailTokenInfo` struct
export interface TrailTokenInfo {
	trail_id: BigNumberish;
	minter_address: string;
	seed: BigNumberish;
	trail_inst: BigNumberish;
}

// Type definition for `lore::models::trigger::Trigger` struct
export interface Trigger {
	inst: BigNumberish;
	key: BigNumberish;
	name: string;
	trigger_type: TriggerTypeEnum;
	is_enabled: boolean;
	is_once: boolean;
}

// Type definition for `lore::models::trigger::TriggerExecuted` struct
export interface TriggerExecuted {
	game_id: BigNumberish;
	inst: BigNumberish;
	key: BigNumberish;
	is_executed: boolean;
}

// Type definition for `lore::models::trigger::TriggerIndex` struct
export interface TriggerIndex {
	trigger_type: TriggerTypeEnum;
	trigger_id: Array<[BigNumberish, BigNumberish]>;
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
export interface ComponentProperty {
	name: string;
	property_type: PropertyTypeEnum;
	access_flags: PropertyAccessEnum;
}

// Type definition for `achievement::events::index::TrophyCreation` struct
export interface TrophyCreation {
	id: BigNumberish;
	hidden: boolean;
	index: BigNumberish;
	points: BigNumberish;
	start: BigNumberish;
	end: BigNumberish;
	group: BigNumberish;
	icon: BigNumberish;
	title: BigNumberish;
	description: string;
	tasks: Array<Task>;
	data: string;
}

// Type definition for `achievement::events::index::TrophyProgression` struct
export interface TrophyProgression {
	player_id: BigNumberish;
	task_id: BigNumberish;
	count: BigNumberish;
	time: BigNumberish;
}

// Type definition for `achievement::types::index::Task` struct
export interface Task {
	id: BigNumberish;
	total: BigNumberish;
	description: string;
}

// Type definition for `lore::constants::appchain::AppchainMessageEvent` struct
export interface AppchainMessageEvent {
	uuid: BigNumberish;
	caller_address: string;
	from_address: string;
	to_address: string;
	block_number: BigNumberish;
	block_timestamp: BigNumberish;
	message_hash: BigNumberish;
	message_type: BigNumberish;
	payload: Array<BigNumberish>;
}

// Type definition for `lore::lib::access::AccessGrantedEvent` struct
export interface AccessGrantedEvent {
	address: string;
	role: BigNumberish;
	granted: boolean;
}

// Type definition for `lore::models::game_token_info::GameCreatedEvent` struct
export interface GameCreatedEvent {
	game_id: BigNumberish;
	recipient: string;
}

// Type definition for `lore::models::trail_token_info::TrailCreatedEvent` struct
export interface TrailCreatedEvent {
	trail_id: BigNumberish;
	recipient: string;
}

// Type definition for `nft_combo::erc721::erc721_combo::ERC721ComboComponent::BatchMetadataUpdate` struct
export interface BatchMetadataUpdate {
	from_token_id: BigNumberish;
	to_token_id: BigNumberish;
}

// Type definition for `nft_combo::erc721::erc721_combo::ERC721ComboComponent::MetadataUpdate` struct
export interface MetadataUpdate {
	token_id: BigNumberish;
}

// Type definition for `openzeppelin_access::accesscontrol::accesscontrol::AccessControlComponent::RoleAdminChanged` struct
export interface RoleAdminChanged {
	role: BigNumberish;
	previous_admin_role: BigNumberish;
	new_admin_role: BigNumberish;
}

// Type definition for `openzeppelin_access::accesscontrol::accesscontrol::AccessControlComponent::RoleGranted` struct
export interface RoleGranted {
	role: BigNumberish;
	account: string;
	sender: string;
}

// Type definition for `openzeppelin_access::accesscontrol::accesscontrol::AccessControlComponent::RoleRevoked` struct
export interface RoleRevoked {
	role: BigNumberish;
	account: string;
	sender: string;
}

// Type definition for `openzeppelin_token::erc20::erc20::ERC20Component::Approval` struct
export interface Approval {
	owner: string;
	spender: string;
	value: BigNumberish;
}

// Type definition for `openzeppelin_token::erc20::erc20::ERC20Component::Transfer` struct
export interface Transfer {
	from: string;
	to: string;
	value: BigNumberish;
}

// Type definition for `openzeppelin_token::erc721::erc721::ERC721Component::Approval` struct
export interface Approval {
	owner: string;
	approved: string;
	token_id: BigNumberish;
}

// Type definition for `openzeppelin_token::erc721::erc721::ERC721Component::ApprovalForAll` struct
export interface ApprovalForAll {
	owner: string;
	operator: string;
	approved: boolean;
}

// Type definition for `openzeppelin_token::erc721::erc721::ERC721Component::Transfer` struct
export interface Transfer {
	from: string;
	to: string;
	token_id: BigNumberish;
}

// Type definition for `lore::models::player::StoryLineType` enum
export const storyLineType = [
	'Undefined',
	'Command',
	'Response',
	'SysResponse',
	'Debug',
	'Error',
] as const;
export type StoryLineType = { [key in typeof storyLineType[number]]: string };
export type StoryLineTypeEnum = CairoCustomEnum;

// Type definition for `lore::types::action_type::EffectType` enum
export const effectType = [
	'ModifyProperty',
	'AddItem',
	'RemoveItem',
	'MoveEntity',
	'SendMessage',
	'TriggerAction',
	'AddQuantity',
	'RemoveQuantity',
] as const;
export type EffectType = { [key in typeof effectType[number]]: string };
export type EffectTypeEnum = CairoCustomEnum;

// Type definition for `lore::types::action_type::Operator` enum
export const operator = [
	'Equals',
	'NotEquals',
	'GreaterThan',
	'LessThan',
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
	'Reactable',
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

// Type definition for `lore::types::component_type::ReactableActions` enum
export const reactableActions = [
	'SetVisible',
	'ReadRandomDescription',
	'ReadFirstDescription',
	'ReadSpecificDescription',
] as const;
export type ReactableActions = { [key in typeof reactableActions[number]]: string };
export type ReactableActionsEnum = CairoCustomEnum;

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

// Type definition for `lore::constants::errors::Error` enum
export const error = [
	'Unimplemented',
	'WordTooLong',
	'LexerFailed',
	'TestError',
	'ActionFailed',
	'NotSystemAction',
	'EntityNotFound',
	'NoDictionaryMatch',
	'None',
	'TriggerNotFound',
	'NameTooLong',
	'FailedToUpdateTriggerIndex',
	'FailedToRemoveTriggerIndex',
	'TriggerNotMeetConditions',
	'OnceUseOnly',
	'ConditionFailed',
	'NotInTheSameTrail',
	'EffectFailed',
	'EffectNotFound',
	'ReadOnlyVariable',
	'NoPropertyRegistry',
	'NoComponent',
	'NoAreaComponent',
	'NoExitComponent',
	'NoReactableComponent',
	'NoInventoryItemComponent',
	'NoContainerComponent',
	'NoPlayerComponent',
	'NoTargetEntity',
	'NameNotMatch',
	'DirectionNotMatch',
	'Unenterable',
	'FailToReactTo',
	'NoTarget',
	'NotOpen',
	'ContainerFull',
	'CantStore',
	'NoPersonalContainer',
	'NoContainer',
	'CantBePicked',
	'CantBeStored',
	'AlreadyStored',
	'NotStored',
	'NotEditor',
	'NoRoom',
	'NotYourGame',
	'InvalidTrail',
	'InsufficientActionsBalance',
	'InsufficientActionsToClaim',
] as const;
export type Error = { [key in typeof error[number]]: string };
export type ErrorEnum = CairoCustomEnum;

// Type definition for `lore::types::command_type::CommandType` enum
export const commandType = [
	'Unknown',
	'System',
	'Action',
] as const;
export type CommandType = { [key in typeof commandType[number]]: string };
export type CommandTypeEnum = CairoCustomEnum;

export interface SchemaType extends ISchemaType {
	lore: {
		Action: Action,
		ActionExecuted: ActionExecuted,
		ActionsConfig: ActionsConfig,
		ActionsReward: ActionsReward,
		Area: Area,
		Condition: Condition,
		Container: Container,
		DescriptionText: DescriptionText,
		Dict: Dict,
		Effect: Effect,
		ChildToParent: ChildToParent,
		Entity: Entity,
		ParentToChildren: ParentToChildren,
		Exit: Exit,
		GameInstanceKeyMap: GameInstanceKeyMap,
		GameInstanceMap: GameInstanceMap,
		GameTokenInfo: GameTokenInfo,
		Hub: Hub,
		Trail: Trail,
		ComponentVariable: ComponentVariable,
		PropertyRegistry: PropertyRegistry,
		InventoryItem: InventoryItem,
		Player: Player,
		PlayerStory: PlayerStory,
		StoryLine: StoryLine,
		PlayerAccount: PlayerAccount,
		PlayerBalances: PlayerBalances,
		Reactable: Reactable,
		TrailProgress: TrailProgress,
		TrailTokenInfo: TrailTokenInfo,
		Trigger: Trigger,
		TriggerExecuted: TriggerExecuted,
		TriggerIndex: TriggerIndex,
		ActionMapContainer: ActionMapContainer,
		ActionMapExit: ActionMapExit,
		ActionMapInventoryItem: ActionMapInventoryItem,
		ActionMapReactable: ActionMapReactable,
		ComponentProperty: ComponentProperty,
		TrophyCreation: TrophyCreation,
		TrophyProgression: TrophyProgression,
		Task: Task,
		AppchainMessageEvent: AppchainMessageEvent,
		AccessGrantedEvent: AccessGrantedEvent,
		GameCreatedEvent: GameCreatedEvent,
		TrailCreatedEvent: TrailCreatedEvent,
		BatchMetadataUpdate: BatchMetadataUpdate,
		MetadataUpdate: MetadataUpdate,
		RoleAdminChanged: RoleAdminChanged,
		RoleGranted: RoleGranted,
		RoleRevoked: RoleRevoked,
		Approval: Approval,
		Transfer: Transfer,
		ApprovalForAll: ApprovalForAll,
	},
}
export const schema: SchemaType = {
	lore: {
		Action: {
			inst: 0,
			key: 0,
		name: "",
		description: "",
			is_enabled: false,
			executor: 0,
			trigger: [[0, 0]],
			conditions: [[0, 0]],
			effects: [[0, 0]],
			tags: [""],
			failing_response: [""],
			success_response: [""],
		},
		ActionExecuted: {
			game_id: 0,
			inst: 0,
			key: 0,
			is_executed: false,
		},
		ActionsConfig: {
			key: 0,
			sn_contract: "",
			action_cost_amount: 0,
			initial_free_actions_count: 0,
			max_free_actions_count: 0,
			free_action_claim_interval: 0,
			trail_reward_actions_count: 0,
		},
		ActionsReward: {
			player_address: "",
			collected_actions_amount: 0,
			claimed_actions_amount: 0,
		},
		Area: {
			inst: 0,
			is_area: false,
			is_spawn_point: false,
			progress_percentage: 0,
			preserve_children: false,
		},
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
				Reactable: undefined,
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
		DescriptionText: {
			inst: 0,
			key: 0,
		text: "",
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
		Effect: {
			inst: 0,
			key: 0,
		name: "",
			target: 0,
		effect_type: new CairoCustomEnum({ 
					ModifyProperty: "",
				AddItem: undefined,
				RemoveItem: undefined,
				MoveEntity: undefined,
				SendMessage: undefined,
				TriggerAction: undefined,
				AddQuantity: undefined,
				RemoveQuantity: undefined, }),
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
			n_value: 0,
			hex_value: 0,
		},
		ChildToParent: {
			inst: 0,
			is_child: false,
			parent: 0,
		},
		Entity: {
			inst: 0,
			is_entity: false,
			trail_id: 0,
		name: "",
			creator_address: "",
			alt_names: [""],
			actions_keys: [0],
		},
		ParentToChildren: {
			inst: 0,
			is_parent: false,
			children: [0],
		},
		Exit: {
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
		GameInstanceKeyMap: {
			game_id: 0,
			inst: 0,
			key: 0,
			game_inst: 0,
		},
		GameInstanceMap: {
			game_id: 0,
			inst: 0,
			game_inst: 0,
		},
		GameTokenInfo: {
			game_id: 0,
			minter_address: "",
			seed: 0,
		room_name: "",
			act_number: 0,
		},
		Hub: {
			inst: 0,
			is_hub: false,
			is_enabled: false,
			trails_insts: [0],
			grants_editor_access: false,
		},
		Trail: {
			inst: 0,
			is_trail: false,
			trail_id: 0,
			hub_inst: 0,
			is_published: false,
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
		PropertyRegistry: {
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
		InventoryItem: {
			inst: 0,
			is_inventory_item: false,
			owner_id: 0,
			can_be_picked_up: false,
			can_go_in_container: false,
			quantity: 0,
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
			game_id: 0,
			location: 0,
			use_debug: false,
			is_dead: false,
		},
		PlayerStory: {
			game_id: 0,
			story_line: 0,
			free_actions_count: 0,
			sub_actions_count: 0,
			paid_actions_count: 0,
		},
		StoryLine: {
			game_id: 0,
			key: 0,
		line: "",
		line_type: new CairoCustomEnum({ 
					Undefined: "",
				Command: undefined,
				Response: undefined,
				SysResponse: undefined,
				Debug: undefined,
				Error: undefined, }),
			location: 0,
			timestamp: 0,
		},
		PlayerAccount: {
			player_address: "",
			timestamp_joined: 0,
			timestamp_free_actions_claimed: 0,
			minted_actions_count: 0,
			purchase_count: 0,
			subscription_count: 0,
			current_game_id: 0,
		},
		PlayerBalances: {
			player_address: "",
			free_actions_balance: 0,
			paid_actions_balance: 0,
			sub_actions_balance: 0,
		},
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
		TrailProgress: {
			game_id: 0,
			trail_id: 0,
			percentage: 0,
			completed: false,
		},
		TrailTokenInfo: {
			trail_id: 0,
			minter_address: "",
			seed: 0,
			trail_inst: 0,
		},
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
		},
		TriggerExecuted: {
			game_id: 0,
			inst: 0,
			key: 0,
			is_executed: false,
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
		TrophyCreation: {
			id: 0,
			hidden: false,
			index: 0,
			points: 0,
			start: 0,
			end: 0,
			group: 0,
			icon: 0,
			title: 0,
		description: "",
			tasks: [{ id: 0, total: 0, description: "", }],
		data: "",
		},
		TrophyProgression: {
			player_id: 0,
			task_id: 0,
			count: 0,
			time: 0,
		},
		Task: {
			id: 0,
			total: 0,
		description: "",
		},
		AppchainMessageEvent: {
			uuid: 0,
			caller_address: "",
			from_address: "",
			to_address: "",
			block_number: 0,
			block_timestamp: 0,
			message_hash: 0,
			message_type: 0,
			payload: [0],
		},
		AccessGrantedEvent: {
			address: "",
			role: 0,
			granted: false,
		},
		GameCreatedEvent: {
			game_id: 0,
			recipient: "",
		},
		TrailCreatedEvent: {
			trail_id: 0,
			recipient: "",
		},
		BatchMetadataUpdate: {
		from_token_id: 0,
		to_token_id: 0,
		},
		MetadataUpdate: {
		token_id: 0,
		},
		RoleAdminChanged: {
			role: 0,
			previous_admin_role: 0,
			new_admin_role: 0,
		},
		RoleGranted: {
			role: 0,
			account: "",
			sender: "",
		},
		RoleRevoked: {
			role: 0,
			account: "",
			sender: "",
		},
		Approval: {
			owner: "",
			spender: "",
		value: 0,
		},
		Transfer: {
			from: "",
			to: "",
		value: 0,
		},
		Approval: {
			owner: "",
			approved: "",
		token_id: 0,
		},
		ApprovalForAll: {
			owner: "",
			operator: "",
			approved: false,
		},
		Transfer: {
			from: "",
			to: "",
		token_id: 0,
		},
	},
};
export enum ModelsMapping {
	Action = 'lore-Action',
	ActionExecuted = 'lore-ActionExecuted',
	ActionsConfig = 'lore-ActionsConfig',
	ActionsReward = 'lore-ActionsReward',
	Area = 'lore-Area',
	Condition = 'lore-Condition',
	Container = 'lore-Container',
	DescriptionText = 'lore-DescriptionText',
	Dict = 'lore-Dict',
	Effect = 'lore-Effect',
	ChildToParent = 'lore-ChildToParent',
	Entity = 'lore-Entity',
	ParentToChildren = 'lore-ParentToChildren',
	Exit = 'lore-Exit',
	GameInstanceKeyMap = 'lore-GameInstanceKeyMap',
	GameInstanceMap = 'lore-GameInstanceMap',
	GameTokenInfo = 'lore-GameTokenInfo',
	Hub = 'lore-Hub',
	Trail = 'lore-Trail',
	ComponentVariable = 'lore-ComponentVariable',
	PropertyRegistry = 'lore-PropertyRegistry',
	InventoryItem = 'lore-InventoryItem',
	Player = 'lore-Player',
	PlayerStory = 'lore-PlayerStory',
	StoryLine = 'lore-StoryLine',
	StoryLineType = 'lore-StoryLineType',
	PlayerAccount = 'lore-PlayerAccount',
	PlayerBalances = 'lore-PlayerBalances',
	Reactable = 'lore-Reactable',
	TrailProgress = 'lore-TrailProgress',
	TrailTokenInfo = 'lore-TrailTokenInfo',
	Trigger = 'lore-Trigger',
	TriggerExecuted = 'lore-TriggerExecuted',
	TriggerIndex = 'lore-TriggerIndex',
	EffectType = 'lore-EffectType',
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
	PropertyType = 'lore-PropertyType',
	TrophyCreation = 'achievement-TrophyCreation',
	TrophyProgression = 'achievement-TrophyProgression',
	Task = 'achievement-Task',
	AppchainMessageEvent = 'lore-AppchainMessageEvent',
	AccessGrantedEvent = 'lore-AccessGrantedEvent',
	GameCreatedEvent = 'lore-GameCreatedEvent',
	TrailCreatedEvent = 'lore-TrailCreatedEvent',
	Error = 'lore-Error',
	CommandType = 'lore-CommandType',
	BatchMetadataUpdate = 'nft_combo-BatchMetadataUpdate',
	ContractURIUpdated = 'nft_combo-ContractURIUpdated',
	MetadataUpdate = 'nft_combo-MetadataUpdate',
	RoleAdminChanged = 'openzeppelin_access-RoleAdminChanged',
	RoleGranted = 'openzeppelin_access-RoleGranted',
	RoleRevoked = 'openzeppelin_access-RoleRevoked',
	Approval = 'openzeppelin_token-Approval',
	Transfer = 'openzeppelin_token-Transfer',
	ApprovalForAll = 'openzeppelin_token-ApprovalForAll',
}