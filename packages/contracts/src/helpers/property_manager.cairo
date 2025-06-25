//! Shinigami Layer 1: Helpers - Dynamic property system management
//! 
//! This module provides stateless functions for managing the dynamic property system
//! used throughout the LORE game engine. It handles property registration, validation,
//! and serialization without maintaining any state itself.

use core::option::OptionTrait;

/// Property types supported by the dynamic property system
#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum PropertyType {
    Boolean,
    Integer,
    Felt252,
    Direction,
    ContractAddress,
    ByteArray,
    Array,
    Custom,
}

/// Component types that can have dynamic properties
#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum ComponentType {
    Player,
    Area,
    Item,
    Container,
    Exit,
    Inspectable,
    Trigger,
    Condition,
    Effect,
    Action,
}

/// Property access flags for controlling read/write permissions
#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub struct PropertyAccess {
    pub readable: bool,
    pub writable: bool,
    pub system_only: bool,
    pub player_visible: bool,
}

/// Property definition structure
#[derive(Clone, Drop, Serde, Debug, PartialEq, Introspect)]
pub struct PropertyDefinition {
    pub name: ByteArray,
    pub property_type: PropertyType,
    pub default_value: felt252,
    pub constraints: PropertyConstraints,
    pub access: PropertyAccess,
}

/// Constraints for property values
#[derive(Clone, Drop, Serde, Debug, PartialEq, Introspect)]
pub struct PropertyConstraints {
    pub min_value: Option<felt252>,
    pub max_value: Option<felt252>,
    pub allowed_values: Array<felt252>,
    pub max_length: Option<u32>, // For ByteArray and Array types
}

/// Error types for property operations
#[derive(Drop, Serde, Debug)]
pub enum PropertyError {
    InvalidPropertyType,
    PropertyNotFound,
    InvalidValue,
    ConstraintViolation,
    AccessDenied,
    SerializationError,
    DeserializationError,
}

/// Registry for component properties
#[derive(Clone, Drop, Serde, Debug, PartialEq, Introspect)]
pub struct ComponentPropertyRegistry {
    pub component_type: ComponentType,
    pub properties: Array<PropertyDefinition>,
}

/// Registers a property for a specific component type
/// 
/// # Arguments
/// * `component_type` - The type of component
/// * `property_name` - Name of the property
/// * `property_type` - Type of the property
/// 
/// # Returns
/// * `Result<(), PropertyError>` - Success or error
pub fn register_property(
    component_type: ComponentType,
    property_name: ByteArray,
    property_type: PropertyType
) -> Result<(), PropertyError> {
    // Validate property name
    if property_name.len() == 0 {
        return Result::Err(PropertyError::InvalidPropertyType);
    }
    
    if property_name.len() > 64 {
        return Result::Err(PropertyError::InvalidPropertyType);
    }
    
    // In a full implementation, this would register the property in storage
    // For now, we just validate the inputs
    
    Result::Ok(())
}

/// Gets the property registry for a component type
/// 
/// # Arguments
/// * `component_type` - The component type to get properties for
/// 
/// # Returns
/// * `Array<PropertyDefinition>` - Array of property definitions
pub fn get_property_registry(component_type: ComponentType) -> Array<PropertyDefinition> {
    // In a full implementation, this would read from storage
    // For now, return predefined properties based on component type
    
    match component_type {
        ComponentType::Player => get_player_properties(),
        ComponentType::Area => get_area_properties(),
        ComponentType::Item => get_item_properties(),
        ComponentType::Container => get_container_properties(),
        ComponentType::Exit => get_exit_properties(),
        ComponentType::Inspectable => get_inspectable_properties(),
        ComponentType::Trigger => get_trigger_properties(),
        ComponentType::Condition => get_condition_properties(),
        ComponentType::Effect => get_effect_properties(),
        ComponentType::Action => get_action_properties(),
    }
}

/// Validates a property value against its type and constraints
/// 
/// # Arguments
/// * `property_type` - The expected property type
/// * `value` - The value to validate
/// 
/// # Returns
/// * `bool` - true if valid, false otherwise
pub fn validate_property_value(property_type: PropertyType, value: felt252) -> bool {
    match property_type {
        PropertyType::Boolean => {
            // Boolean values should be 0 or 1
            value == 0 || value == 1
        },
        PropertyType::Integer => {
            // All felt252 values are valid integers in this context
            true
        },
        PropertyType::Felt252 => {
            // All felt252 values are valid
            true
        },
        PropertyType::Direction => {
            // Direction values should be in valid range (0-11 for 12 directions)
            let dir_val: u32 = value.try_into().unwrap_or(999);
            dir_val <= 11
        },
        PropertyType::ContractAddress => {
            // Should be a valid contract address (non-zero)
            value != 0
        },
        PropertyType::ByteArray => {
            // For ByteArray, we'd need additional validation
            // For now, accept all values
            true
        },
        PropertyType::Array => {
            // For Array, we'd need additional validation
            // For now, accept all values
            true
        },
        PropertyType::Custom => {
            // Custom types need specific validation
            // For now, accept all values
            true
        },
    }
}

/// Serializes a property value to ByteArray format
/// 
/// # Arguments
/// * `property_type` - The property type
/// * `value` - The value to serialize
/// 
/// # Returns
/// * `ByteArray` - Serialized value
pub fn serialize_property(property_type: PropertyType, value: felt252) -> ByteArray {
    match property_type {
        PropertyType::Boolean => {
            if value == 0 {
                "false"
            } else {
                "true"
            }
        },
        PropertyType::Integer => {
            // Convert felt252 to string representation
            format_felt252_to_string(value)
        },
        PropertyType::Felt252 => {
            // Serialize as hex string
            format!("0x{:x}", value)
        },
        PropertyType::Direction => {
            // Convert direction enum to string
            format_direction_to_string(value)
        },
        PropertyType::ContractAddress => {
            // Serialize as hex address
            format!("0x{:x}", value)
        },
        PropertyType::ByteArray => {
            // For ByteArray, we'd need to reconstruct the original
            // For now, return a placeholder
            "ByteArray"
        },
        PropertyType::Array => {
            // For Array, we'd need to reconstruct the original
            // For now, return a placeholder
            "Array"
        },
        PropertyType::Custom => {
            // Custom serialization
            "Custom"
        },
    }
}

/// Deserializes a property value from ByteArray format
/// 
/// # Arguments
/// * `property_type` - The property type
/// * `data` - The serialized data
/// 
/// # Returns
/// * `Result<felt252, PropertyError>` - Deserialized value or error
pub fn deserialize_property(property_type: PropertyType, data: ByteArray) -> Result<felt252, PropertyError> {
    match property_type {
        PropertyType::Boolean => {
            if data == "true" {
                Result::Ok(1)
            } else if data == "false" {
                Result::Ok(0)
            } else {
                Result::Err(PropertyError::DeserializationError)
            }
        },
        PropertyType::Integer => {
            // Parse string to felt252
            parse_string_to_felt252(data)
        },
        PropertyType::Felt252 => {
            // Parse hex string to felt252
            parse_hex_string_to_felt252(data)
        },
        PropertyType::Direction => {
            // Parse direction string to enum value
            parse_direction_from_string(data)
        },
        PropertyType::ContractAddress => {
            // Parse hex address to felt252
            parse_hex_string_to_felt252(data)
        },
        PropertyType::ByteArray => {
            // Would need complex deserialization
            Result::Err(PropertyError::DeserializationError)
        },
        PropertyType::Array => {
            // Would need complex deserialization
            Result::Err(PropertyError::DeserializationError)
        },
        PropertyType::Custom => {
            // Custom deserialization
            Result::Err(PropertyError::DeserializationError)
        },
    }
}

/// Validates property constraints
/// 
/// # Arguments
/// * `value` - The value to check
/// * `constraints` - The constraints to validate against
/// 
/// # Returns
/// * `bool` - true if constraints are satisfied
pub fn validate_constraints(value: felt252, constraints: PropertyConstraints) -> bool {
    // Check minimum value
    if let Option::Some(min_val) = constraints.min_value {
        let value_u256: u256 = value.into();
        let min_u256: u256 = min_val.into();
        if value_u256 < min_u256 {
            return false;
        }
    }
    
    // Check maximum value
    if let Option::Some(max_val) = constraints.max_value {
        let value_u256: u256 = value.into();
        let max_u256: u256 = max_val.into();
        if value_u256 > max_u256 {
            return false;
        }
    }
    
    // Check allowed values (if specified)
    if constraints.allowed_values.len() > 0 {
        let mut found = false;
        let mut i = 0;
        while i < constraints.allowed_values.len() {
            if value == *constraints.allowed_values.at(i) {
                found = true;
                break;
            }
            i += 1;
        };
        if !found {
            return false;
        }
    }
    
    true
}

// Helper functions for predefined component properties

fn get_player_properties() -> Array<PropertyDefinition> {
    let mut props = ArrayTrait::new();
    
    props.append(PropertyDefinition {
        name: "debug_mode",
        property_type: PropertyType::Boolean,
        default_value: 0,
        constraints: PropertyConstraints {
            min_value: Option::None,
            max_value: Option::None,
            allowed_values: array![0, 1],
            max_length: Option::None,
        },
        access: PropertyAccess {
            readable: true,
            writable: true,
            system_only: false,
            player_visible: false,
        },
    });
    
    props
}

fn get_area_properties() -> Array<PropertyDefinition> {
    let mut props = ArrayTrait::new();
    
    props.append(PropertyDefinition {
        name: "is_spawn_point",
        property_type: PropertyType::Boolean,
        default_value: 0,
        constraints: PropertyConstraints {
            min_value: Option::None,
            max_value: Option::None,
            allowed_values: array![0, 1],
            max_length: Option::None,
        },
        access: PropertyAccess {
            readable: true,
            writable: true,
            system_only: true,
            player_visible: false,
        },
    });
    
    props
}

fn get_item_properties() -> Array<PropertyDefinition> {
    ArrayTrait::new()
}

fn get_container_properties() -> Array<PropertyDefinition> {
    ArrayTrait::new()
}

fn get_exit_properties() -> Array<PropertyDefinition> {
    ArrayTrait::new()
}

fn get_inspectable_properties() -> Array<PropertyDefinition> {
    ArrayTrait::new()
}

fn get_trigger_properties() -> Array<PropertyDefinition> {
    ArrayTrait::new()
}

fn get_condition_properties() -> Array<PropertyDefinition> {
    ArrayTrait::new()
}

fn get_effect_properties() -> Array<PropertyDefinition> {
    ArrayTrait::new()
}

fn get_action_properties() -> Array<PropertyDefinition> {
    ArrayTrait::new()
}

// Helper functions for serialization/deserialization

fn format_felt252_to_string(value: felt252) -> ByteArray {
    // Simplified implementation - would need proper number-to-string conversion
    "number"
}

fn format_direction_to_string(value: felt252) -> ByteArray {
    let dir_val: u32 = value.try_into().unwrap_or(0);
    match dir_val {
        0 => "north",
        1 => "south",
        2 => "east",
        3 => "west",
        4 => "northeast",
        5 => "northwest",
        6 => "southeast",
        7 => "southwest",
        8 => "up",
        9 => "down",
        10 => "in",
        11 => "out",
        _ => "unknown",
    }
}

fn parse_string_to_felt252(data: ByteArray) -> Result<felt252, PropertyError> {
    // Simplified implementation - would need proper string-to-number conversion
    Result::Ok(0)
}

fn parse_hex_string_to_felt252(data: ByteArray) -> Result<felt252, PropertyError> {
    // Simplified implementation - would need proper hex parsing
    Result::Ok(0)
}

fn parse_direction_from_string(data: ByteArray) -> Result<felt252, PropertyError> {
    if data == "north" {
        Result::Ok(0)
    } else if data == "south" {
        Result::Ok(1)
    } else if data == "east" {
        Result::Ok(2)
    } else if data == "west" {
        Result::Ok(3)
    } else if data == "northeast" {
        Result::Ok(4)
    } else if data == "northwest" {
        Result::Ok(5)
    } else if data == "southeast" {
        Result::Ok(6)
    } else if data == "southwest" {
        Result::Ok(7)
    } else if data == "up" {
        Result::Ok(8)
    } else if data == "down" {
        Result::Ok(9)
    } else if data == "in" {
        Result::Ok(10)
    } else if data == "out" {
        Result::Ok(11)
    } else {
        Result::Err(PropertyError::DeserializationError)
    }
}

#[cfg(test)]
mod tests {
    use super::{
        PropertyType, ComponentType, validate_property_value, serialize_property,
        deserialize_property, register_property, get_property_registry,
        PropertyError
    };
    
    #[test]
    fn test_validate_property_value() {
        // Boolean validation
        assert!(validate_property_value(PropertyType::Boolean, 0));
        assert!(validate_property_value(PropertyType::Boolean, 1));
        assert!(!validate_property_value(PropertyType::Boolean, 2));
        
        // Direction validation
        assert!(validate_property_value(PropertyType::Direction, 0));
        assert!(validate_property_value(PropertyType::Direction, 11));
        assert!(!validate_property_value(PropertyType::Direction, 12));
        
        // Integer validation (all felt252 values are valid)
        assert!(validate_property_value(PropertyType::Integer, 12345));
    }
    
    #[test]
    fn test_serialize_property() {
        let bool_true = serialize_property(PropertyType::Boolean, 1);
        assert!(bool_true == "true");
        
        let bool_false = serialize_property(PropertyType::Boolean, 0);
        assert!(bool_false == "false");
        
        let direction = serialize_property(PropertyType::Direction, 0);
        assert!(direction == "north");
    }
    
    #[test]
    fn test_deserialize_property() {
        match deserialize_property(PropertyType::Boolean, "true") {
            Result::Ok(value) => assert!(value == 1),
            Result::Err(_) => panic!("Should deserialize true to 1"),
        }
        
        match deserialize_property(PropertyType::Boolean, "false") {
            Result::Ok(value) => assert!(value == 0),
            Result::Err(_) => panic!("Should deserialize false to 0"),
        }
        
        match deserialize_property(PropertyType::Direction, "north") {
            Result::Ok(value) => assert!(value == 0),
            Result::Err(_) => panic!("Should deserialize north to 0"),
        }
    }
    
    #[test]
    fn test_register_property() {
        let result = register_property(ComponentType::Player, "test_prop", PropertyType::Boolean);
        match result {
            Result::Ok(_) => {},
            Result::Err(_) => panic!("Valid property registration should succeed"),
        }
        
        // Test empty name
        let result = register_property(ComponentType::Player, "", PropertyType::Boolean);
        match result {
            Result::Ok(_) => panic!("Empty property name should fail"),
            Result::Err(PropertyError::InvalidPropertyType) => {},
            Result::Err(_) => panic!("Wrong error type for empty name"),
        }
    }
    
    #[test]
    fn test_get_property_registry() {
        let player_props = get_property_registry(ComponentType::Player);
        assert!(player_props.len() > 0); // Should have at least debug_mode
        
        let area_props = get_property_registry(ComponentType::Area);
        assert!(area_props.len() > 0); // Should have at least is_spawn_point
    }
}