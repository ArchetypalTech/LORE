// Here you can find all the action types for the corresponding components.

#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum InspectableActions {
    SetVisible,
    ReadRandomDescription,
    ReadFirstDescription,
    ReadSpecificDescription,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum ExitActions {
    UseExit,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum ContainerActions {
    Open,
    Close,
    Check,
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
