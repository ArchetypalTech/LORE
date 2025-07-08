// Here you can find the components types
// As well the components structs as well their corresponding action types.

// Components //
#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum ComponentType {
    None,
    Area,
    Container,
    Entity,
    Exit,
    Inspectable,
    InventoryItem,
    Player,
    Trigger,
    Condition,
    Effect,
    Action,
}

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

#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum InspectableActions {
    SetVisible,
    ReadRandomDescription,
    ReadFirstDescription,
    ReadSpecificDescription,
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

#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum ExitActions {
    UseExit,
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

#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum ContainerActions {
    Open,
    Close,
    Check,
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

#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum InventoryItemActions {
    UseItem,
    PickupItem,
    DropItem,
    PutItem,
    TakeOutItem,
}

// Implementations into U8 //

pub impl IntoComponentTypeU8 of core::traits::Into<ComponentType, u8> {
    #[inline]
    fn into(self: ComponentType) -> u8 {
        match self {
            ComponentType::None => 0,
            ComponentType::Area => 1,
            ComponentType::Container => 2,
            ComponentType::Entity => 3,
            ComponentType::Exit => 4,
            ComponentType::Inspectable => 5,
            ComponentType::InventoryItem => 6,
            ComponentType::Player => 7,
            ComponentType::Trigger => 8,
            ComponentType::Condition => 9,
            ComponentType::Effect => 10,
            ComponentType::Action => 11,
        }
    }
}

pub impl IntoInspectableActionsU8 of core::traits::Into<InspectableActions, u8> {
    #[inline]
    fn into(self: InspectableActions) -> u8 {
        match self {
            InspectableActions::SetVisible => 0,
            InspectableActions::ReadRandomDescription => 1,
            InspectableActions::ReadFirstDescription => 2,
            InspectableActions::ReadSpecificDescription => 3,
        }
    }
}

pub impl IntoExitActionsU8 of core::traits::Into<ExitActions, u8> {
    #[inline]
    fn into(self: ExitActions) -> u8 {
        match self {
            ExitActions::UseExit => 0,
        }
    }
}

pub impl IntoContainerActionsU8 of core::traits::Into<ContainerActions, u8> {
    #[inline]
    fn into(self: ContainerActions) -> u8 {
        match self {
            ContainerActions::Open => 0,
            ContainerActions::Close => 1,
            ContainerActions::Check => 2,
        }
    }
}

pub impl IntoInventoryItemActionsU8 of core::traits::Into<InventoryItemActions, u8> {
    #[inline]
    fn into(self: InventoryItemActions) -> u8 {
        match self {
            InventoryItemActions::UseItem => 0,
            InventoryItemActions::PickupItem => 1,
            InventoryItemActions::DropItem => 2,
            InventoryItemActions::PutItem => 3,
            InventoryItemActions::TakeOutItem => 4,
        }
    }
}

// Implementations into Actions //

pub impl IntoU8ComponentType of core::traits::Into<u8, ComponentType> {
    #[inline]
    fn into(self: u8) -> ComponentType {
        match self {
            0 => ComponentType::None,
            1 => ComponentType::Area,
            2 => ComponentType::Container,
            3 => ComponentType::Entity,
            4 => ComponentType::Exit,
            5 => ComponentType::Inspectable,
            6 => ComponentType::InventoryItem,
            7 => ComponentType::Player,
            8 => ComponentType::Trigger,
            9 => ComponentType::Condition,
            10 => ComponentType::Effect,
            11 => ComponentType::Action,
            _ => ComponentType::None,
        }
    }
}

pub impl IntoU8InspectableAction of core::traits::Into<u8, InspectableActions> {
    #[inline]
    fn into(self: u8) -> InspectableActions {
        match self {
            0 => InspectableActions::SetVisible,
            1 => InspectableActions::ReadRandomDescription,
            2 => InspectableActions::ReadFirstDescription,
            3 => InspectableActions::ReadSpecificDescription,
            _ => InspectableActions::SetVisible,
        }
    }
}

pub impl IntoU8ExitAction of core::traits::Into<u8, ExitActions> {
    #[inline]
    fn into(self: u8) -> ExitActions {
        match self {
            0 => ExitActions::UseExit,
            _ => ExitActions::UseExit,
        }
    }
}

pub impl IntoU8ContainerAction of core::traits::Into<u8, ContainerActions> {
    #[inline]
    fn into(self: u8) -> ContainerActions {
        match self {
            0 => ContainerActions::Open,
            1 => ContainerActions::Close,
            2 => ContainerActions::Check,
            _ => ContainerActions::Open,
        }
    }
}

pub impl IntoU8InventoryItemAction of core::traits::Into<u8, InventoryItemActions> {
    #[inline]
    fn into(self: u8) -> InventoryItemActions {
        match self {
            0 => InventoryItemActions::UseItem,
            1 => InventoryItemActions::PickupItem,
            2 => InventoryItemActions::DropItem,
            3 => InventoryItemActions::PutItem,
            4 => InventoryItemActions::TakeOutItem,
            _ => InventoryItemActions::UseItem,
        }
    }
}
