// Here you can find the trigger, condition, effect types and structs

#[derive(Copy, Drop, Serde, Debug, PartialEq, Introspect)]
pub struct TriggerContext {
    /// The entity that triggered the action (usually the player)
    pub doer: felt252,
    /// Primary target of the action (e.g., item being picked up, area being entered)
    pub target1: felt252,
    /// Secondary target (e.g., container being opened, item being used on)
    pub target2: felt252,
    /// Inventory object involved (e.g., item being moved to/from inventory)
    pub inventory_object: felt252,
}

#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum TriggerType {
    OnEnter,
    OnExit,
    OnInteract,
    OnInspect,
    OnUse,
    OnTimer,
    OnCondition,
}


#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum ConditionType {
    HasItem,
    InLocation,
    PropertyEquals,
    TimeRange,
    RandomChance,
    Custom,
}

#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum Operator {
    Equals,
    NotEquals,
    GreaterThan,
    LessThan,
}

#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum EffectType {
    ModifyProperty,
    AddItem,
    RemoveItem,
    MoveEntity,
    SendMessage,
    TriggerAction,
    AddQuantity,
    RemoveQuantity,
}


// Implementation into U8 //

pub impl IntoTriggerTypeU8 of core::traits::Into<TriggerType, u8> {
    #[inline]
    fn into(self: TriggerType) -> u8 {
        match self {
            TriggerType::OnEnter => 0,
            TriggerType::OnExit => 1,
            TriggerType::OnInteract => 2,
            TriggerType::OnInspect => 3,
            TriggerType::OnUse => 4,
            TriggerType::OnTimer => 5,
            TriggerType::OnCondition => 6,
        }
    }
}

pub impl IntoOperatorU8 of core::traits::Into<Operator, u8> {
    #[inline]
    fn into(self: Operator) -> u8 {
        match self {
            Operator::Equals => 0,
            Operator::NotEquals => 1,
            Operator::GreaterThan => 2,
            Operator::LessThan => 3,
        }
    }
}

pub impl IntoConditionTypeU8 of core::traits::Into<ConditionType, u8> {
    #[inline]
    fn into(self: ConditionType) -> u8 {
        match self {
            ConditionType::HasItem => 0,
            ConditionType::InLocation => 1,
            ConditionType::PropertyEquals => 2,
            ConditionType::TimeRange => 3,
            ConditionType::RandomChance => 4,
            ConditionType::Custom => 5,
        }
    }
}

pub impl IntoEffectTypeU8 of core::traits::Into<EffectType, u8> {
    #[inline]
    fn into(self: EffectType) -> u8 {
        match self {
            EffectType::ModifyProperty => 0,
            EffectType::AddItem => 1,
            EffectType::RemoveItem => 2,
            EffectType::MoveEntity => 3,
            EffectType::SendMessage => 4,
            EffectType::TriggerAction => 5,
            EffectType::AddQuantity => 6,
            EffectType::RemoveQuantity => 7,
        }
    }
}

// Implementation into Felt252 //

pub impl IntoTriggerTypeFelt252 of core::traits::Into<TriggerType, felt252> {
    #[inline]
    fn into(self: TriggerType) -> felt252 {
        match self {
            TriggerType::OnEnter => 0,
            TriggerType::OnExit => 1,
            TriggerType::OnInteract => 2,
            TriggerType::OnInspect => 3,
            TriggerType::OnUse => 4,
            TriggerType::OnTimer => 5,
            TriggerType::OnCondition => 6,
        }
    }
}

// Implementation into Types //

pub impl IntoU8TriggerType of core::traits::Into<u8, TriggerType> {
    #[inline]
    fn into(self: u8) -> TriggerType {
        match self {
            0 => TriggerType::OnEnter,
            1 => TriggerType::OnExit,
            2 => TriggerType::OnInteract,
            3 => TriggerType::OnInspect,
            4 => TriggerType::OnUse,
            5 => TriggerType::OnTimer,
            6 => TriggerType::OnCondition,
            _ => TriggerType::OnEnter,
        }
    }
}

pub impl IntoU8Operator of core::traits::Into<u8, Operator> {
    #[inline]
    fn into(self: u8) -> Operator {
        match self {
            0 => Operator::Equals,
            1 => Operator::NotEquals,
            2 => Operator::GreaterThan,
            3 => Operator::LessThan,
            _ => Operator::Equals,
        }
    }
}

pub impl IntoU8ConditionType of core::traits::Into<u8, ConditionType> {
    #[inline]
    fn into(self: u8) -> ConditionType {
        match self {
            0 => ConditionType::HasItem,
            1 => ConditionType::InLocation,
            2 => ConditionType::PropertyEquals,
            3 => ConditionType::TimeRange,
            4 => ConditionType::RandomChance,
            5 => ConditionType::Custom,
            _ => ConditionType::HasItem,
        }
    }
}

pub impl IntoU8EffectType of core::traits::Into<u8, EffectType> {
    #[inline]
    fn into(self: u8) -> EffectType {
        match self {
            0 => EffectType::ModifyProperty,
            1 => EffectType::AddItem,
            2 => EffectType::RemoveItem,
            3 => EffectType::MoveEntity,
            4 => EffectType::SendMessage,
            5 => EffectType::TriggerAction,
            6 => EffectType::AddQuantity,
            7 => EffectType::RemoveQuantity,
            _ => EffectType::ModifyProperty,
        }
    }
}

pub impl IntoFelt252TriggerType of core::traits::Into<felt252, TriggerType> {
    #[inline]
    fn into(self: felt252) -> TriggerType {
        match self {
            0 => TriggerType::OnEnter,
            1 => TriggerType::OnExit,
            2 => TriggerType::OnInteract,
            3 => TriggerType::OnInspect,
            4 => TriggerType::OnUse,
            5 => TriggerType::OnTimer,
            6 => TriggerType::OnCondition,
            _ => TriggerType::OnEnter,
        }
    }
}
