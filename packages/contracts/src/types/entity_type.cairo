//! Shinigami Layer 3: Types - Entity classification and type routing
//! 
//! This module defines entity and component types used throughout the LORE game engine
//! for organizing and routing entity-related operations.

use core::option::OptionTrait;

/// Primary entity types in the game world
#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum EntityType {
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

/// Component types that can be attached to entities
#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum ComponentType {
    PlayerComponent,
    AreaComponent,
    ItemComponent,
    ContainerComponent,
    ExitComponent,
    InspectableComponent,
    TriggerComponent,
    ConditionComponent,
    EffectComponent,
    ActionComponent,
}

/// Error types for entity type operations
#[derive(Drop, Serde, Debug)]
pub enum TypeError {
    InvalidEntityType,
    InvalidComponentType,
    IncompatibleTypes,
    UnknownType,
}

/// Entity metadata for type information
#[derive(Drop, Serde, Debug)]
pub struct EntityTypeInfo {
    pub entity_type: EntityType,
    pub display_name: ByteArray,
    pub description: ByteArray,
    pub default_components: Array<ComponentType>,
}

/// Component metadata for type information
#[derive(Drop, Serde, Debug)]
pub struct ComponentTypeInfo {
    pub component_type: ComponentType,
    pub display_name: ByteArray,
    pub description: ByteArray,
    pub required_entity_types: Array<EntityType>,
}

/// Gets the entity type from an entity instance (stub implementation)
/// 
/// # Arguments
/// * `entity_inst` - The entity instance ID
/// 
/// # Returns
/// * `Result<EntityType, TypeError>` - Entity type or error
/// 
/// # Note
/// This is a placeholder - actual implementation would query the entity storage
pub fn get_entity_type(entity_inst: u32) -> Result<EntityType, TypeError> {
    // In actual implementation, this would:
    // 1. Query the entity storage using entity_inst
    // 2. Retrieve the entity_type field
    // 3. Return the type or error if not found
    
    if entity_inst == 0 {
        return Result::Err(TypeError::InvalidEntityType);
    }
    
    // Placeholder logic based on instance ID ranges
    if entity_inst < 1000 {
        Result::Ok(EntityType::Player)
    } else if entity_inst < 10000 {
        Result::Ok(EntityType::Area)
    } else if entity_inst < 50000 {
        Result::Ok(EntityType::Item)
    } else {
        Result::Ok(EntityType::Container)
    }
}

/// Gets the default component types for an entity type
/// 
/// # Arguments
/// * `entity_type` - The entity type
/// 
/// # Returns
/// * `Array<ComponentType>` - Array of component types
pub fn get_component_types(entity_type: EntityType) -> Array<ComponentType> {
    match entity_type {
        EntityType::Player => array![
            ComponentType::PlayerComponent,
            ComponentType::InspectableComponent,
            ComponentType::ContainerComponent, // For inventory
        ],
        EntityType::Area => array![
            ComponentType::AreaComponent,
            ComponentType::InspectableComponent,
            ComponentType::ContainerComponent, // For room contents
        ],
        EntityType::Item => array![
            ComponentType::ItemComponent,
            ComponentType::InspectableComponent,
        ],
        EntityType::Container => array![
            ComponentType::ContainerComponent,
            ComponentType::InspectableComponent,
        ],
        EntityType::Exit => array![
            ComponentType::ExitComponent,
            ComponentType::InspectableComponent,
        ],
        EntityType::Inspectable => array![
            ComponentType::InspectableComponent,
        ],
        EntityType::Trigger => array![
            ComponentType::TriggerComponent,
        ],
        EntityType::Condition => array![
            ComponentType::ConditionComponent,
        ],
        EntityType::Effect => array![
            ComponentType::EffectComponent,
        ],
        EntityType::Action => array![
            ComponentType::ActionComponent,
        ],
    }
}

/// Validates if a component type is compatible with an entity type
/// 
/// # Arguments
/// * `entity_type` - The entity type
/// * `component_type` - The component type to check
/// 
/// # Returns
/// * `bool` - true if compatible, false otherwise
pub fn validate_type_compatibility(entity_type: EntityType, component_type: ComponentType) -> bool {
    let compatible_components = get_component_types(entity_type);
    
    let mut i = 0;
    let mut is_compatible = false;
    while i < compatible_components.len() {
        if *compatible_components.at(i) == component_type {
            is_compatible = true;
            break;
        }
        i += 1;
    };
    
    is_compatible
}

/// Converts entity type to string representation
/// 
/// # Arguments
/// * `entity_type` - The entity type to convert
/// 
/// # Returns
/// * `ByteArray` - String representation
pub fn entity_type_to_string(entity_type: EntityType) -> ByteArray {
    match entity_type {
        EntityType::Player => "Player",
        EntityType::Area => "Area",
        EntityType::Item => "Item",
        EntityType::Container => "Container",
        EntityType::Exit => "Exit",
        EntityType::Inspectable => "Inspectable",
        EntityType::Trigger => "Trigger",
        EntityType::Condition => "Condition",
        EntityType::Effect => "Effect",
        EntityType::Action => "Action",
    }
}

/// Converts component type to string representation
/// 
/// # Arguments
/// * `component_type` - The component type to convert
/// 
/// # Returns
/// * `ByteArray` - String representation
pub fn component_type_to_string(component_type: ComponentType) -> ByteArray {
    match component_type {
        ComponentType::PlayerComponent => "PlayerComponent",
        ComponentType::AreaComponent => "AreaComponent",
        ComponentType::ItemComponent => "ItemComponent",
        ComponentType::ContainerComponent => "ContainerComponent",
        ComponentType::ExitComponent => "ExitComponent",
        ComponentType::InspectableComponent => "InspectableComponent",
        ComponentType::TriggerComponent => "TriggerComponent",
        ComponentType::ConditionComponent => "ConditionComponent",
        ComponentType::EffectComponent => "EffectComponent",
        ComponentType::ActionComponent => "ActionComponent",
    }
}

/// Converts entity type to numeric value for storage
/// 
/// # Arguments
/// * `entity_type` - The entity type to convert
/// 
/// # Returns
/// * `u8` - Numeric representation
pub fn entity_type_to_u8(entity_type: EntityType) -> u8 {
    match entity_type {
        EntityType::Player => 0,
        EntityType::Area => 1,
        EntityType::Item => 2,
        EntityType::Container => 3,
        EntityType::Exit => 4,
        EntityType::Inspectable => 5,
        EntityType::Trigger => 6,
        EntityType::Condition => 7,
        EntityType::Effect => 8,
        EntityType::Action => 9,
    }
}

/// Converts numeric value to entity type
/// 
/// # Arguments
/// * `value` - Numeric value to convert
/// 
/// # Returns
/// * `Option<EntityType>` - Entity type if valid, None otherwise
pub fn u8_to_entity_type(value: u8) -> Option<EntityType> {
    match value {
        0 => Option::Some(EntityType::Player),
        1 => Option::Some(EntityType::Area),
        2 => Option::Some(EntityType::Item),
        3 => Option::Some(EntityType::Container),
        4 => Option::Some(EntityType::Exit),
        5 => Option::Some(EntityType::Inspectable),
        6 => Option::Some(EntityType::Trigger),
        7 => Option::Some(EntityType::Condition),
        8 => Option::Some(EntityType::Effect),
        9 => Option::Some(EntityType::Action),
        _ => Option::None,
    }
}

/// Converts component type to numeric value for storage
/// 
/// # Arguments
/// * `component_type` - The component type to convert
/// 
/// # Returns
/// * `u8` - Numeric representation
pub fn component_type_to_u8(component_type: ComponentType) -> u8 {
    match component_type {
        ComponentType::PlayerComponent => 0,
        ComponentType::AreaComponent => 1,
        ComponentType::ItemComponent => 2,
        ComponentType::ContainerComponent => 3,
        ComponentType::ExitComponent => 4,
        ComponentType::InspectableComponent => 5,
        ComponentType::TriggerComponent => 6,
        ComponentType::ConditionComponent => 7,
        ComponentType::EffectComponent => 8,
        ComponentType::ActionComponent => 9,
    }
}

/// Converts numeric value to component type
/// 
/// # Arguments
/// * `value` - Numeric value to convert
/// 
/// # Returns
/// * `Option<ComponentType>` - Component type if valid, None otherwise
pub fn u8_to_component_type(value: u8) -> Option<ComponentType> {
    match value {
        0 => Option::Some(ComponentType::PlayerComponent),
        1 => Option::Some(ComponentType::AreaComponent),
        2 => Option::Some(ComponentType::ItemComponent),
        3 => Option::Some(ComponentType::ContainerComponent),
        4 => Option::Some(ComponentType::ExitComponent),
        5 => Option::Some(ComponentType::InspectableComponent),
        6 => Option::Some(ComponentType::TriggerComponent),
        7 => Option::Some(ComponentType::ConditionComponent),
        8 => Option::Some(ComponentType::EffectComponent),
        9 => Option::Some(ComponentType::ActionComponent),
        _ => Option::None,
    }
}

/// Gets detailed information about an entity type
/// 
/// # Arguments
/// * `entity_type` - The entity type to get info for
/// 
/// # Returns
/// * `EntityTypeInfo` - Detailed information about the entity type
pub fn get_entity_type_info(entity_type: EntityType) -> EntityTypeInfo {
    match entity_type {
        EntityType::Player => EntityTypeInfo {
            entity_type,
            display_name: "Player",
            description: "A player character in the game world",
            default_components: get_component_types(entity_type),
        },
        EntityType::Area => EntityTypeInfo {
            entity_type,
            display_name: "Area",
            description: "A location or room in the game world",
            default_components: get_component_types(entity_type),
        },
        EntityType::Item => EntityTypeInfo {
            entity_type,
            display_name: "Item",
            description: "A portable object that can be taken and used",
            default_components: get_component_types(entity_type),
        },
        EntityType::Container => EntityTypeInfo {
            entity_type,
            display_name: "Container",
            description: "An object that can hold other items",
            default_components: get_component_types(entity_type),
        },
        EntityType::Exit => EntityTypeInfo {
            entity_type,
            display_name: "Exit",
            description: "A passage connecting two areas",
            default_components: get_component_types(entity_type),
        },
        EntityType::Inspectable => EntityTypeInfo {
            entity_type,
            display_name: "Inspectable",
            description: "An object that can be examined for descriptions",
            default_components: get_component_types(entity_type),
        },
        EntityType::Trigger => EntityTypeInfo {
            entity_type,
            display_name: "Trigger",
            description: "An event trigger for the action system",
            default_components: get_component_types(entity_type),
        },
        EntityType::Condition => EntityTypeInfo {
            entity_type,
            display_name: "Condition",
            description: "A logical condition for the action system",
            default_components: get_component_types(entity_type),
        },
        EntityType::Effect => EntityTypeInfo {
            entity_type,
            display_name: "Effect",
            description: "An effect that modifies game state",
            default_components: get_component_types(entity_type),
        },
        EntityType::Action => EntityTypeInfo {
            entity_type,
            display_name: "Action",
            description: "A composite action containing triggers, conditions, and effects",
            default_components: get_component_types(entity_type),
        },
    }
}

/// Gets all entity types as an array
/// 
/// # Returns
/// * `Array<EntityType>` - Array of all entity types
pub fn get_all_entity_types() -> Array<EntityType> {
    array![
        EntityType::Player,
        EntityType::Area,
        EntityType::Item,
        EntityType::Container,
        EntityType::Exit,
        EntityType::Inspectable,
        EntityType::Trigger,
        EntityType::Condition,
        EntityType::Effect,
        EntityType::Action,
    ]
}

/// Gets all component types as an array
/// 
/// # Returns
/// * `Array<ComponentType>` - Array of all component types
pub fn get_all_component_types() -> Array<ComponentType> {
    array![
        ComponentType::PlayerComponent,
        ComponentType::AreaComponent,
        ComponentType::ItemComponent,
        ComponentType::ContainerComponent,
        ComponentType::ExitComponent,
        ComponentType::InspectableComponent,
        ComponentType::TriggerComponent,
        ComponentType::ConditionComponent,
        ComponentType::EffectComponent,
        ComponentType::ActionComponent,
    ]
}

/// Checks if an entity type is a core gameplay type
/// 
/// # Arguments
/// * `entity_type` - Entity type to check
/// 
/// # Returns
/// * `bool` - true if core gameplay type
pub fn is_core_entity_type(entity_type: EntityType) -> bool {
    match entity_type {
        EntityType::Player | EntityType::Area | EntityType::Item | EntityType::Container | EntityType::Exit => true,
        _ => false,
    }
}

/// Checks if an entity type is part of the action system
/// 
/// # Arguments
/// * `entity_type` - Entity type to check
/// 
/// # Returns
/// * `bool` - true if action system type
pub fn is_action_system_type(entity_type: EntityType) -> bool {
    match entity_type {
        EntityType::Trigger | EntityType::Condition | EntityType::Effect | EntityType::Action => true,
        _ => false,
    }
}

#[cfg(test)]
mod tests {
    use super::{
        EntityType, ComponentType, get_entity_type, get_component_types,
        validate_type_compatibility, entity_type_to_string, component_type_to_string,
        entity_type_to_u8, u8_to_entity_type, component_type_to_u8, u8_to_component_type,
        get_entity_type_info, is_core_entity_type, is_action_system_type, TypeError
    };
    
    #[test]
    fn test_get_entity_type() {
        // Test valid entity instance
        match get_entity_type(500) {
            Result::Ok(EntityType::Player) => {},
            _ => panic!("Should return Player for instance 500"),
        }
        
        // Test invalid entity instance
        match get_entity_type(0) {
            Result::Err(TypeError::InvalidEntityType) => {},
            _ => panic!("Should return error for instance 0"),
        }
    }
    
    #[test]
    fn test_get_component_types() {
        let player_components = get_component_types(EntityType::Player);
        assert!(player_components.len() > 0);
        
        // Check that Player has PlayerComponent
        let mut has_player_component = false;
        let mut i = 0;
        while i < player_components.len() {
            if *player_components.at(i) == ComponentType::PlayerComponent {
                has_player_component = true;
                break;
            }
            i += 1;
        };
        assert!(has_player_component);
    }
    
    #[test]
    fn test_validate_type_compatibility() {
        // Valid compatibility
        assert!(validate_type_compatibility(EntityType::Player, ComponentType::PlayerComponent));
        assert!(validate_type_compatibility(EntityType::Area, ComponentType::AreaComponent));
        
        // Invalid compatibility
        assert!(!validate_type_compatibility(EntityType::Player, ComponentType::AreaComponent));
    }
    
    #[test]
    fn test_string_conversions() {
        assert!(entity_type_to_string(EntityType::Player) == "Player");
        assert!(component_type_to_string(ComponentType::PlayerComponent) == "PlayerComponent");
    }
    
    #[test]
    fn test_numeric_conversions() {
        // Test entity type conversions
        let original_entity = EntityType::Item;
        let as_u8 = entity_type_to_u8(original_entity);
        match u8_to_entity_type(as_u8) {
            Option::Some(converted) => assert!(converted == original_entity),
            Option::None => panic!("Should convert back to original entity type"),
        }
        
        // Test component type conversions
        let original_component = ComponentType::ItemComponent;
        let as_u8 = component_type_to_u8(original_component);
        match u8_to_component_type(as_u8) {
            Option::Some(converted) => assert!(converted == original_component),
            Option::None => panic!("Should convert back to original component type"),
        }
        
        // Test invalid conversions
        match u8_to_entity_type(255) {
            Option::None => {},
            _ => panic!("Invalid u8 should return None"),
        }
    }
    
    #[test]
    fn test_entity_type_info() {
        let info = get_entity_type_info(EntityType::Player);
        assert!(info.entity_type == EntityType::Player);
        assert!(info.display_name == "Player");
        assert!(info.default_components.len() > 0);
    }
    
    #[test]
    fn test_type_classification() {
        assert!(is_core_entity_type(EntityType::Player));
        assert!(is_core_entity_type(EntityType::Area));
        assert!(!is_core_entity_type(EntityType::Trigger));
        
        assert!(is_action_system_type(EntityType::Trigger));
        assert!(is_action_system_type(EntityType::Action));
        assert!(!is_action_system_type(EntityType::Player));
    }
}