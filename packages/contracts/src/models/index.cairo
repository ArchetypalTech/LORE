// Here you can find all the defined models.

use starknet::ContractAddress;
use lore::{
    types::{
        action_type::{TriggerType, Operator}, command_type::{TokenType},
        component_type::{
            ComponentType, ActionMapReactable, ActionMapExit, ActionMapContainer,
            ActionMapInventoryItem,
        },
        direction_type::Direction, property_type::{ComponentProperty},
    },
};

#[derive(Clone, Drop, Serde, Introspect)]
#[dojo::model]
pub struct ParentToChildren {
    #[key]
    pub inst: felt252,
    pub is_parent: bool,
    /// Properties ///
    /// The children entities
    pub children: Array<felt252>,
}

#[derive(Clone, Drop, Serde, Introspect)]
#[dojo::model]
pub struct ChildToParent {
    #[key]
    pub inst: felt252,
    pub is_child: bool,
    /// Properties ///
    /// The parent entity
    pub parent: felt252,
}

#[derive(Clone, Drop, Serde, Introspect, Debug)]
#[dojo::model]
pub struct Dict {
    #[key]
    pub dict_key: felt252,
    pub word: ByteArray,
    pub tokenType: TokenType,
    pub n_value: felt252,
}

#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct Entity {
    #[key]
    pub inst: felt252,
    pub is_entity: bool,
    /// Properties ///
    /// Name of the entity
    pub name: ByteArray,
    /// Alternative names of the entity
    pub alt_names: Array<ByteArray>,
    /// Holds the keys of the actions that are attached to this entity
    pub actions_keys: Array<felt252>,
}

#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct Area {
    #[key]
    pub inst: felt252,
    pub is_area: bool,
    /// Properties ///
    /// If the area is a spawn point for players
    pub is_spawn_point: bool,
}

#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct Reactable {
    #[key]
    pub inst: felt252,
    pub is_reactable: bool,
    /// Properties ///
    /// If the reactable is visible
    pub is_visible: bool,
    /// Array of descriptions for the reactable
    pub description: Array<u32>,
    /// Array of action maps for the reactable
    pub action_map: Array<ActionMapReactable>,
    /// For the first description, if we want to show a different one
    pub already_shown: bool,
    /// New first description
    pub new_entry: ByteArray,
}

#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct DescriptionText {
    /// Unique identifier from the Entity it is attached to
    #[key]
    pub inst: felt252,
    /// Unique identifier of the description
    #[key]
    pub key: u32,
    /// Description text
    pub text: ByteArray,
}

#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct Exit {
    #[key]
    pub inst: felt252,
    pub is_exit: bool,
    /// Properties ///
    /// If the exit is enterable
    pub is_enterable: bool,
    /// The leads to entity
    pub leads_to: felt252,
    /// The direction type
    pub direction_type: Direction,
    /// Array of action maps for the exit
    pub action_map: Array<ActionMapExit>,
}

#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct Container {
    #[key]
    pub inst: felt252,
    pub is_container: bool,
    /// Properties ///
    /// If the container can be opened
    pub can_be_opened: bool,
    /// If the container can receive items
    pub can_receive_items: bool,
    /// If the container is open
    pub is_open: bool,
    /// Total number of slots of the container
    pub num_slots: u32,
    // pub accept_tags: Array<Tag>,
    pub action_map: Array<ActionMapContainer>,
}

#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct InventoryItem {
    #[key]
    pub inst: felt252,
    pub is_inventory_item: bool,
    /// Properties ///
    /// The owner of the inventory item
    pub owner_id: felt252,
    /// If the inventory item can be picked up
    pub can_be_picked_up: bool,
    /// If the inventory item can go in a container
    pub can_go_in_container: bool,
    /// The quantity of the inventory item
    pub quantity: u32,
    /// Array of action maps for the inventory item
    pub action_map: Array<ActionMapInventoryItem>,
    /// If the inventory item has already been used
    pub already_used: bool,
    /// If the inventory item can be used multiple times
    pub multiple_use: bool,
}

#[derive(Copy, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct Player {
    #[key]
    pub inst: felt252,
    pub is_player: bool,
    /// Properties ///
    /// The address of the player
    pub address: ContractAddress,
    /// The location of the player
    pub location: felt252,
    /// Current story line
    pub story_line: CounterType,
    /// If the player is in debug mode
    pub use_debug: bool,
}

#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct PlayerStory {
    #[key]
    pub inst: felt252,
    /// Properties ///
    /// Array of story lines (story lines keys)
    pub story: Array<CounterType>,
}

pub type CounterType = u32;
#[derive(Clone, Drop, Serde, Debug, Introspect, PartialEq)]
#[dojo::model]
pub struct StoryLine {
    /// Unique identifier (Player or PlayerStory)
    #[key]
    pub inst: felt252,
    /// Unique identifier of the line
    #[key]
    pub key: CounterType,
    /// Story line
    pub line: ByteArray,
}

#[derive(Clone, Drop, Serde, Introspect, Debug, PartialEq)]
#[dojo::model]
pub struct PropertyRegistry {
    #[key]
    pub component_type: ComponentType,
    pub properties: Array<ComponentProperty>,
}

#[derive(Clone, Drop, Serde, Debug, Introspect, PartialEq)]
#[dojo::model]
pub struct Action {
    /// Unique identifier attached to the entity
    #[key]
    pub inst: felt252,
    /// Unique identifier of the action
    #[key]
    pub key: felt252,
    /// Properties ///
    /// Name of the action
    pub name: ByteArray,
    /// Optional description
    pub description: ByteArray,
    /// For toggling the entire action
    pub is_enabled: bool,
    /// When this action can occur, the id's of the triggers. Key is (trigger.inst, trigger.key)
    pub trigger: Array<(felt252, felt252)>,
    /// What must be true, the id's of the conditions. Key is (condition.inst, condition.key)
    pub conditions: Array<(felt252, felt252)>,
    /// What happens when triggered, the id's of the effects. Key is (effect.inst, effect.key)
    pub effects: Array<(felt252, felt252)>,
    /// For searching/filtering
    pub tags: Array<ByteArray>,
    /// Whether the action has been executed
    pub executed: bool,
    /// In case action fails, need a response
    pub failing_response: Array<ByteArray>,
    /// In case action succeeds, need a response
    pub success_response: Array<ByteArray>,
}

#[derive(Clone, Drop, Serde, Debug, Introspect, PartialEq)]
#[dojo::model]
pub struct Trigger {
    /// Unique identifier from the entity that is attached to
    #[key]
    pub inst: felt252,
    /// Unique identifier of the trigger
    #[key]
    pub key: felt252,
    /// Trigger name
    pub name: ByteArray,
    /// The type of trigger
    pub trigger_type: TriggerType,
    /// Whether the trigger is enabled
    pub is_enabled: bool,
    /// Whether the trigger only triggers once
    pub is_once: bool,
    /// Whether the trigger has already been triggered
    pub was_triggered: bool,
}

#[derive(Clone, Drop, Serde, Debug)]
#[dojo::model]
pub struct TriggerIndex {
    #[key]
    pub trigger_type: TriggerType,
    pub trigger_id: Array<(felt252, felt252)> // (inst, key)
}

#[derive(Clone, Drop, Serde, Debug, Introspect, PartialEq)]
#[dojo::model]
pub struct Condition {
    /// Unique identifier attached to the entity
    #[key]
    pub inst: felt252,
    /// Unique identifier of the condition
    #[key]
    pub key: felt252,
    /// Condition name
    pub name: ByteArray,
    /// The target inst.
    pub target: felt252,
    /// Which component to check
    pub component: ComponentType,
    /// Which property of the component to check
    pub property: ByteArray,
    /// How to compare the values
    pub operator: Operator,
    /// Value to compare against
    pub value: Array<felt252>,
}

#[derive(Clone, Drop, Serde, Debug, Introspect, PartialEq)]
#[dojo::model]
pub struct Effect {
    /// Unique identifier attached to the entity
    #[key]
    pub inst: felt252,
    /// Unique identifier of the effect
    #[key]
    pub key: felt252,
    /// Effect name
    pub name: ByteArray,
    /// Target entity
    pub target: felt252,
    /// Component to affect
    pub component: ComponentType,
    /// Property to modify
    pub property: ByteArray,
    /// New value to set, needs to be tuple array. First element is the value, second is the index
    /// (for texts).
    pub value: Array<(ByteArray, u32)>,
}

/// NOT USED YET ///

// ========== VARIABLE PROXY MODEL ==========
// DONT KNOW IF THIS IS NEEDED YET //
#[derive(Clone, Drop, Serde, Debug)]
#[dojo::model]
pub struct ComponentVariable {
    #[key]
    pub inst: felt252, // Entity inst
    #[key]
    pub key: felt252, // Component key
    #[key]
    pub id: felt252, // unique id 
    /// Properties ///
    /// The component type
    pub component_type: ComponentType,
    /// The property name
    pub property_name: ByteArray,
    /// The property value
    pub value: ByteArray,
    /// The last time the property was updated
    pub last_updated: u64,
}
