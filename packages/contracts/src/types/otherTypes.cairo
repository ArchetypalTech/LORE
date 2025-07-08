// Here you can find types

#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum ComponentType {
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

#[derive(Serde, Copy, Drop, Debug, Introspect, PartialEq)]
pub enum DirectionType {
    None,
    North,
    South,
    East,
    West,
    Up,
    Down,
}

#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum PropertyAccessType {
    ReadOnly,
    ReadWrite,
}

#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum TriggerType {
    None,
    // Player Triggers //
    PlayerEntersArea,
    PlayerLeavesArea,
    // UseItem Inventory Item //
    UseItem,
}

/// TODO: Implement more operators later
#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum Operator {
    Equals,
    NotEquals,
}


// TODO: define if it will be needed later
#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum ParameterType {
    Boolean,
    Integer,
    Felt252,
    Direction,
    ContractAddress,
    String,
    ByteArray,
    Enum,
    EntityReference,
}

// TODO: define if it will be needed later
#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum ExecutionStatus {
    Success,
    Failure,
}

