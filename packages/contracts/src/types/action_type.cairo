//! Shinigami Layer 3: Types - Action system type definitions
//! 
//! This module defines types for LORE's trigger-condition-effect action system,
//! based on the actual implementation in the existing codebase.

use core::option::OptionTrait;

/// Trigger types that can activate actions (based on LORE's existing trigger system)
#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum TriggerType {
    OnEnter,
    OnExit,
    OnInteract,
    OnInspect,
    OnUse,
    OnTake,
    OnDrop,
    OnTimer,
    OnCondition,
    OnCommand,
}

/// Condition types for logical evaluation (based on LORE's condition system)
#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum ConditionType {
    HasItem,
    InLocation,
    PropertyEquals,
    PropertyGreater,
    PropertyLess,
    ItemInContainer,
    TimeRange,
    RandomChance,
    EntityExists,
    Custom,
}

/// Effect types that modify game state (based on LORE's effect system)
#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum EffectType {
    ModifyProperty,
    AddItem,
    RemoveItem,
    MoveEntity,
    SendMessage,
    TriggerAction,
    CreateEntity,
    DestroyEntity,
    ChangeDescription,
    EnableAction,
}

/// Action execution status
#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum ActionStatus {
    Pending,
    InProgress,
    Completed,
    Failed,
    Disabled,
}

/// Trigger context information for action evaluation
#[derive(Drop, Serde, Debug)]
pub struct TriggerContext {
    pub triggering_entity: u32,     // Entity that triggered the action
    pub target_entity: Option<u32>, // Target entity (if applicable)
    pub player_inst: u32,           // Player performing the action
    pub command_text: ByteArray,    // Original command text
    pub timestamp: u64,             // When the trigger occurred
}

/// Condition evaluation context
#[derive(Drop, Serde, Debug)]
pub struct ConditionContext {
    pub evaluator: u32,             // Entity evaluating the condition
    pub target: Option<u32>,        // Target entity for evaluation
    pub property_name: ByteArray,   // Property being checked
    pub expected_value: felt252,    // Expected value for comparison
    pub current_time: u64,          // Current game time
}

/// Effect execution context
#[derive(Drop, Serde, Debug)]
pub struct EffectContext {
    pub executor: u32,              // Entity executing the effect
    pub target: u32,                // Target entity for the effect
    pub property_name: ByteArray,   // Property to modify (if applicable)
    pub value: felt252,             // Value for the effect
    pub message: ByteArray,         // Message for player (if applicable)
}

/// Result of action execution
#[derive(Drop, Serde, Debug)]
pub struct ActionResult {
    pub success: bool,              // Whether action succeeded
    pub status: ActionStatus,       // Current action status
    pub message: ByteArray,         // Response message for player
    pub triggered_actions: Array<(felt252, felt252)>, // Additional actions triggered
    pub state_changes: Array<StateChange>, // Changes made to game state
}

/// Represents a change to game state
#[derive(Drop, Serde, Debug)]
pub struct StateChange {
    pub entity_inst: u32,          // Entity that was modified
    pub property_name: ByteArray,  // Property that changed
    pub old_value: felt252,        // Previous value
    pub new_value: felt252,        // New value
    pub change_type: ChangeType,   // Type of change
}

/// Types of state changes
#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum ChangeType {
    PropertyModified,   // Property value changed
    EntityMoved,        // Entity location changed
    EntityCreated,      // New entity created
    EntityDestroyed,    // Entity removed
    RelationshipAdded,  // New relationship established
    RelationshipRemoved, // Relationship broken
}

/// Converts trigger type to string representation
/// 
/// # Arguments
/// * `trigger_type` - The trigger type to convert
/// 
/// # Returns
/// * `ByteArray` - String representation
pub fn trigger_type_to_string(trigger_type: TriggerType) -> ByteArray {
    match trigger_type {
        TriggerType::OnEnter => "OnEnter",
        TriggerType::OnExit => "OnExit",
        TriggerType::OnInteract => "OnInteract",
        TriggerType::OnInspect => "OnInspect",
        TriggerType::OnUse => "OnUse",
        TriggerType::OnTake => "OnTake",
        TriggerType::OnDrop => "OnDrop",
        TriggerType::OnTimer => "OnTimer",
        TriggerType::OnCondition => "OnCondition",
        TriggerType::OnCommand => "OnCommand",
    }
}

/// Converts condition type to string representation
/// 
/// # Arguments
/// * `condition_type` - The condition type to convert
/// 
/// # Returns
/// * `ByteArray` - String representation
pub fn condition_type_to_string(condition_type: ConditionType) -> ByteArray {
    match condition_type {
        ConditionType::HasItem => "HasItem",
        ConditionType::InLocation => "InLocation",
        ConditionType::PropertyEquals => "PropertyEquals",
        ConditionType::PropertyGreater => "PropertyGreater",
        ConditionType::PropertyLess => "PropertyLess",
        ConditionType::ItemInContainer => "ItemInContainer",
        ConditionType::TimeRange => "TimeRange",
        ConditionType::RandomChance => "RandomChance",
        ConditionType::EntityExists => "EntityExists",
        ConditionType::Custom => "Custom",
    }
}

/// Converts effect type to string representation
/// 
/// # Arguments
/// * `effect_type` - The effect type to convert
/// 
/// # Returns
/// * `ByteArray` - String representation
pub fn effect_type_to_string(effect_type: EffectType) -> ByteArray {
    match effect_type {
        EffectType::ModifyProperty => "ModifyProperty",
        EffectType::AddItem => "AddItem",
        EffectType::RemoveItem => "RemoveItem",
        EffectType::MoveEntity => "MoveEntity",
        EffectType::SendMessage => "SendMessage",
        EffectType::TriggerAction => "TriggerAction",
        EffectType::CreateEntity => "CreateEntity",
        EffectType::DestroyEntity => "DestroyEntity",
        EffectType::ChangeDescription => "ChangeDescription",
        EffectType::EnableAction => "EnableAction",
    }
}

/// Converts trigger type to numeric value for storage
/// 
/// # Arguments
/// * `trigger_type` - The trigger type to convert
/// 
/// # Returns
/// * `u8` - Numeric representation
pub fn trigger_type_to_u8(trigger_type: TriggerType) -> u8 {
    match trigger_type {
        TriggerType::OnEnter => 0,
        TriggerType::OnExit => 1,
        TriggerType::OnInteract => 2,
        TriggerType::OnInspect => 3,
        TriggerType::OnUse => 4,
        TriggerType::OnTake => 5,
        TriggerType::OnDrop => 6,
        TriggerType::OnTimer => 7,
        TriggerType::OnCondition => 8,
        TriggerType::OnCommand => 9,
    }
}

/// Converts numeric value to trigger type
/// 
/// # Arguments
/// * `value` - Numeric value to convert
/// 
/// # Returns
/// * `Option<TriggerType>` - Trigger type if valid, None otherwise
pub fn u8_to_trigger_type(value: u8) -> Option<TriggerType> {
    match value {
        0 => Option::Some(TriggerType::OnEnter),
        1 => Option::Some(TriggerType::OnExit),
        2 => Option::Some(TriggerType::OnInteract),
        3 => Option::Some(TriggerType::OnInspect),
        4 => Option::Some(TriggerType::OnUse),
        5 => Option::Some(TriggerType::OnTake),
        6 => Option::Some(TriggerType::OnDrop),
        7 => Option::Some(TriggerType::OnTimer),
        8 => Option::Some(TriggerType::OnCondition),
        9 => Option::Some(TriggerType::OnCommand),
        _ => Option::None,
    }
}

/// Checks if a trigger type is player-initiated
/// 
/// # Arguments
/// * `trigger_type` - Trigger type to check
/// 
/// # Returns
/// * `bool` - true if player-initiated
pub fn is_player_triggered(trigger_type: TriggerType) -> bool {
    match trigger_type {
        TriggerType::OnEnter | TriggerType::OnExit | TriggerType::OnInteract | 
        TriggerType::OnInspect | TriggerType::OnUse | TriggerType::OnTake | 
        TriggerType::OnDrop | TriggerType::OnCommand => true,
        TriggerType::OnTimer | TriggerType::OnCondition => false,
    }
}

/// Checks if a condition type requires a target entity
/// 
/// # Arguments
/// * `condition_type` - Condition type to check
/// 
/// # Returns
/// * `bool` - true if target entity required
pub fn requires_target_entity(condition_type: ConditionType) -> bool {
    match condition_type {
        ConditionType::PropertyEquals | ConditionType::PropertyGreater | 
        ConditionType::PropertyLess | ConditionType::EntityExists => true,
        ConditionType::HasItem | ConditionType::InLocation | 
        ConditionType::ItemInContainer | ConditionType::TimeRange | 
        ConditionType::RandomChance | ConditionType::Custom => false,
    }
}

/// Checks if an effect type modifies entity state
/// 
/// # Arguments
/// * `effect_type` - Effect type to check
/// 
/// # Returns
/// * `bool` - true if modifies state
pub fn modifies_entity_state(effect_type: EffectType) -> bool {
    match effect_type {
        EffectType::ModifyProperty | EffectType::AddItem | EffectType::RemoveItem | 
        EffectType::MoveEntity | EffectType::CreateEntity | EffectType::DestroyEntity | 
        EffectType::ChangeDescription | EffectType::EnableAction => true,
        EffectType::SendMessage | EffectType::TriggerAction => false,
    }
}

/// Gets all trigger types as an array
/// 
/// # Returns
/// * `Array<TriggerType>` - Array of all trigger types
pub fn get_all_trigger_types() -> Array<TriggerType> {
    array![
        TriggerType::OnEnter,
        TriggerType::OnExit,
        TriggerType::OnInteract,
        TriggerType::OnInspect,
        TriggerType::OnUse,
        TriggerType::OnTake,
        TriggerType::OnDrop,
        TriggerType::OnTimer,
        TriggerType::OnCondition,
        TriggerType::OnCommand,
    ]
}

/// Gets all condition types as an array
/// 
/// # Returns
/// * `Array<ConditionType>` - Array of all condition types
pub fn get_all_condition_types() -> Array<ConditionType> {
    array![
        ConditionType::HasItem,
        ConditionType::InLocation,
        ConditionType::PropertyEquals,
        ConditionType::PropertyGreater,
        ConditionType::PropertyLess,
        ConditionType::ItemInContainer,
        ConditionType::TimeRange,
        ConditionType::RandomChance,
        ConditionType::EntityExists,
        ConditionType::Custom,
    ]
}

/// Gets all effect types as an array
/// 
/// # Returns
/// * `Array<EffectType>` - Array of all effect types
pub fn get_all_effect_types() -> Array<EffectType> {
    array![
        EffectType::ModifyProperty,
        EffectType::AddItem,
        EffectType::RemoveItem,
        EffectType::MoveEntity,
        EffectType::SendMessage,
        EffectType::TriggerAction,
        EffectType::CreateEntity,
        EffectType::DestroyEntity,
        EffectType::ChangeDescription,
        EffectType::EnableAction,
    ]
}

#[cfg(test)]
mod tests {
    use super::{
        TriggerType, ConditionType, EffectType, ActionStatus, ChangeType,
        trigger_type_to_string, condition_type_to_string, effect_type_to_string,
        trigger_type_to_u8, u8_to_trigger_type, is_player_triggered,
        requires_target_entity, modifies_entity_state
    };
    
    #[test]
    fn test_trigger_type_conversions() {
        let trigger = TriggerType::OnInteract;
        let as_string = trigger_type_to_string(trigger);
        assert!(as_string == "OnInteract");
        
        let as_u8 = trigger_type_to_u8(trigger);
        match u8_to_trigger_type(as_u8) {
            Option::Some(converted) => assert!(converted == trigger),
            Option::None => panic!("Should convert back to original trigger type"),
        }
    }
    
    #[test]
    fn test_condition_type_string() {
        let condition = ConditionType::HasItem;
        let as_string = condition_type_to_string(condition);
        assert!(as_string == "HasItem");
    }
    
    #[test]
    fn test_effect_type_string() {
        let effect = EffectType::ModifyProperty;
        let as_string = effect_type_to_string(effect);
        assert!(as_string == "ModifyProperty");
    }
    
    #[test]
    fn test_is_player_triggered() {
        assert!(is_player_triggered(TriggerType::OnInteract));
        assert!(is_player_triggered(TriggerType::OnUse));
        assert!(!is_player_triggered(TriggerType::OnTimer));
        assert!(!is_player_triggered(TriggerType::OnCondition));
    }
    
    #[test]
    fn test_requires_target_entity() {
        assert!(requires_target_entity(ConditionType::PropertyEquals));
        assert!(requires_target_entity(ConditionType::EntityExists));
        assert!(!requires_target_entity(ConditionType::HasItem));
        assert!(!requires_target_entity(ConditionType::TimeRange));
    }
    
    #[test]
    fn test_modifies_entity_state() {
        assert!(modifies_entity_state(EffectType::ModifyProperty));
        assert!(modifies_entity_state(EffectType::MoveEntity));
        assert!(!modifies_entity_state(EffectType::SendMessage));
        assert!(!modifies_entity_state(EffectType::TriggerAction));
    }
    
    #[test]
    fn test_invalid_u8_conversion() {
        match u8_to_trigger_type(255) {
            Option::None => {},
            _ => panic!("Invalid u8 should return None"),
        }
    }
}