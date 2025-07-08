// Here you can find all the defined models.
// The models structs can be found in  `models/models_structs/actionMap.cairo` file.

use starknet::ContractAddress;
use lore::{
    models::models_structs::actionMap::{
        ActionMapInspectable, ActionMapExit, ActionMapContainer, ActionMapInventoryItem,
    },
    types::otherTypes::{DirectionType},
};

#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct Entity {
    #[key]
    pub inst: felt252,
    pub is_entity: bool,
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
    /// If the area is a spawn point for players
    pub is_spawn_point: bool,
}

#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct Inspectable {
    #[key]
    pub inst: felt252,
    pub is_inspectable: bool,
    /// If the inspectable is visible
    pub is_visible: bool,
    /// Array of descriptions for the inspectable
    pub description: Array<ByteArray>,
    /// Array of action maps for the inspectable
    pub action_map: Array<ActionMapInspectable>,
    /// For the first description, if we want to show a different one
    pub already_shown: bool,
    /// New first description
    pub new_entry: ByteArray,
}

#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct Exit {
    #[key]
    pub inst: felt252,
    pub is_exit: bool,
    /// If the exit is enterable
    pub is_enterable: bool,
    /// The leads to entity
    pub leads_to: felt252,
    /// The direction type
    pub direction_type: DirectionType,
    /// Array of action maps for the exit
    pub action_map: Array<ActionMapExit>,
}

#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct Container {
    #[key]
    pub inst: felt252,
    pub is_container: bool,
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
    /// The owner of the inventory item
    pub owner_id: felt252,
    /// If the inventory item can be picked up
    pub can_be_picked_up: bool,
    /// If the inventory item can go in a container
    pub can_go_in_container: bool,
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
    /// The address of the player
    pub address: ContractAddress,
    /// The location of the player
    pub location: felt252,
    /// If the player is in debug mode
    pub use_debug: bool,
}

#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct PlayerStory {
    #[key]
    pub inst: felt252,
    /// Array of story lines
    pub story: Array<ByteArray>,
}
