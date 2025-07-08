// Here you can find the models structs.
// Their corresponding action types can be found in `types/componentsActions.cairo` file.

use lore::types::componentsActions::{
    InspectableActions, ExitActions, ContainerActions, InventoryItemActions,
};

// Inspectable //
#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
pub struct ActionMapInspectable {
    /// The action verb
    pub action: ByteArray,
    /// The inst of the component that the action is attached to
    pub inst: felt252,
    ///  The types of actions
    pub action_fn: InspectableActions,
    /// The entrypoint to match the action with the description index
    pub entrypoint: u32,
}

// Exit //
#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
pub struct ActionMapExit {
    /// The action verb
    pub action: ByteArray,
    /// The inst of the component that the action is attached to
    pub inst: felt252,
    ///  The types of actions
    pub action_fn: ExitActions,
}

// Container //
#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
pub struct ActionMapContainer {
    /// The action verb
    pub action: ByteArray,
    /// The inst of the component that the action is attached to
    pub inst: felt252,
    ///  The types of actions
    pub action_fn: ContainerActions,
}

// InventoryItem //
#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
pub struct ActionMapInventoryItem {
    /// The action verb
    pub action: ByteArray,
    /// The inst of the component that the action is attached to
    pub inst: felt252,
    ///  The types of actions
    pub action_fn: InventoryItemActions,
}
