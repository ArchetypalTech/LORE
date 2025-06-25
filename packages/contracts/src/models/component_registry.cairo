//! Shinigami Layer 4: Models - Component Registry
//! 
//! This module provides a registry system for tracking and managing components
//! in the LORE game engine, enabling dynamic component discovery and metadata management.

use dojo::{world::WorldStorage, model::ModelStorage};
use starknet::ContractAddress;
use core::option::OptionTrait;
use core::result::{Result, ResultTrait};
use lore::components::{Components, Component};

/// Error types for registry operations
#[derive(Drop, Serde, Debug)]
pub enum RegistryError {
    ComponentNotFound,
    ComponentAlreadyExists,
    InvalidDependency,
    CircularDependency,
    ConflictingComponent,
    RegistryNotInitialized,
    InsufficientPermissions,
    InvalidConfiguration,
}

/// Component registry entry following Dojo model pattern
#[derive(Drop, Serde, Debug, Introspect)]
#[dojo::model]
pub struct ComponentRegistryEntry {
    #[key]
    pub component_id: u32,
    pub is_registered: bool,
    pub component_type: Components,
    pub name: ByteArray,
    pub description: ByteArray,
    pub author: ContractAddress,
    pub version: u32,
    pub created_at: u64,
    pub is_active: bool,
}

/// Component metadata for extended information
#[derive(Drop, Serde, Debug, Introspect)]
#[dojo::model]
pub struct ComponentMetadata {
    #[key]
    pub component_id: u32,
    pub instance_count: u32,
    pub total_usage: u64,
    pub last_used: u64,
    pub dependency_count: u32,
    pub conflict_count: u32,
}

/// Component implementation for ComponentRegistryEntry
pub impl ComponentRegistryEntryComponent of Component<ComponentRegistryEntry> {
    type ComponentType = ComponentRegistryEntry;

    fn inst(self: @ComponentRegistryEntry) -> @felt252 {
        // Use component_id as instance identifier
        @((*self.component_id).into())
    }

    fn has_component(self: @ComponentRegistryEntry, world: WorldStorage, inst: felt252) -> bool {
        *self.is_registered
    }

    fn add_component(mut world: WorldStorage, inst: felt252) -> ComponentRegistryEntry {
        let component_id: u32 = inst.try_into().unwrap();
        let current_time = starknet::get_block_timestamp();
        let caller = starknet::get_caller_address();
        
        let mut entry = ComponentRegistryEntry {
            component_id,
            is_registered: true,
            component_type: Components::Entity, // Default
            name: "New Component",
            description: "Component registered via add_component",
            author: caller,
            version: 1,
            created_at: current_time,
            is_active: true,
        };
        
        entry.store(world);
        entry
    }

    fn get_component(world: WorldStorage, inst: felt252) -> Option<ComponentRegistryEntry> {
        let component_id: u32 = inst.try_into().unwrap();
        let entry: ComponentRegistryEntry = world.read_model(component_id);
        if (!entry.is_registered) {
            return Option::None;
        }
        Option::Some(entry)
    }

    fn can_use_command(
        self: @ComponentRegistryEntry, world: WorldStorage, player: @lore::components::player::Player, command: @lore::lib::a_lexer::Command,
    ) -> bool {
        false // Registry entries don't handle commands
    }

    fn execute_command(
        self: ComponentRegistryEntry, world: WorldStorage, player: @lore::components::player::Player, command: @lore::lib::a_lexer::Command,
    ) -> Result<(), lore::constants::errors::Error> {
        Result::Err(lore::constants::errors::Error::Unimplemented)
    }

    fn store(self: @ComponentRegistryEntry, mut world: WorldStorage) {
        world.write_model(self);
    }
}

/// Registers a new component in the registry
/// 
/// # Arguments
/// * `world` - World storage instance
/// * `component_id` - Unique component identifier
/// * `component_type` - Type of component to register
/// * `name` - Human-readable component name
/// * `description` - Component description
/// * `author` - Component author address
/// 
/// # Returns
/// * `Result<ComponentRegistryEntry, RegistryError>` - Registry entry or error
pub fn register_component(
    mut world: WorldStorage,
    component_id: u32,
    component_type: Components,
    name: ByteArray,
    description: ByteArray,
    author: ContractAddress
) -> Result<ComponentRegistryEntry, RegistryError> {
    // Check if component already exists
    let existing: ComponentRegistryEntry = world.read_model(component_id);
    if (existing.is_registered) {
        return Result::Err(RegistryError::ComponentAlreadyExists);
    }
    
    let current_time = starknet::get_block_timestamp();
    
    let entry = ComponentRegistryEntry {
        component_id,
        is_registered: true,
        component_type,
        name,
        description,
        author,
        version: 1,
        created_at: current_time,
        is_active: true,
    };
    
    entry.store(world);
    
    // Initialize metadata
    let metadata = ComponentMetadata {
        component_id,
        instance_count: 0,
        total_usage: 0,
        last_used: current_time,
        dependency_count: 0,
        conflict_count: 0,
    };
    
    world.write_model(@metadata);
    
    Result::Ok(entry)
}

/// Gets component information from registry
/// 
/// # Arguments
/// * `world` - World storage instance
/// * `component_id` - Component ID to look up
/// 
/// # Returns
/// * `Option<ComponentRegistryEntry>` - Component entry if found
pub fn get_component_info(world: WorldStorage, component_id: u32) -> Option<ComponentRegistryEntry> {
    ComponentRegistryEntryComponent::get_component(world, component_id.into())
}

/// Lists all registered components by scanning for registered entries
/// Note: In a production system, this would be optimized with proper indexing
/// 
/// # Arguments
/// * `world` - World storage instance
/// * `max_components` - Maximum number of components to check
/// 
/// # Returns
/// * `Array<ComponentRegistryEntry>` - List of registered components
pub fn list_components(world: WorldStorage, max_components: u32) -> Array<ComponentRegistryEntry> {
    let mut components = array![];
    let mut i = 0;
    
    while i < max_components {
        let entry: ComponentRegistryEntry = world.read_model(i);
        if (entry.is_registered && entry.is_active) {
            components.append(entry);
        }
        i += 1;
    };
    
    components
}

/// Initializes the component registry with LORE's default components
/// 
/// # Arguments
/// * `world` - World storage instance
/// * `admin` - Admin address for initialization
/// 
/// # Returns
/// * `Result<(), RegistryError>` - Success or error
pub fn initialize_component_registry(
    world: WorldStorage,
    admin: ContractAddress
) -> Result<(), RegistryError> {
    // Register all LORE components
    register_component(world, 1, Components::Entity, "Entity", "Base entity component", admin)?;
    register_component(world, 2, Components::Area, "Area", "Spatial area/room component", admin)?;
    register_component(world, 3, Components::Container, "Container", "Item storage container", admin)?;
    register_component(world, 4, Components::Exit, "Exit", "Navigation exit/doorway", admin)?;
    register_component(world, 5, Components::Inspectable, "Inspectable", "Examinable object with descriptions", admin)?;
    register_component(world, 6, Components::InventoryItem, "Inventory Item", "Portable game object", admin)?;
    register_component(world, 7, Components::Player, "Player", "Player character component", admin)?;
    
    Result::Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use lore::tests::helpers;
    
    #[test]
    fn test_component_registration() {
        let (world, _, _, _, _) = helpers::setup_core();
        let admin = starknet::contract_address_const::<0x123>();
        
        let result = register_component(
            world,
            1,
            Components::Container,
            "Test Container",
            "A test container component",
            admin
        );
        assert(result.is_ok(), 'registration should succeed');
        
        let entry = result.unwrap();
        assert(entry.component_type == Components::Container, 'type should match');
        assert(entry.name == "Test Container", 'name should match');
        
        let info = get_component_info(world, 1);
        assert(info.is_some(), 'component should be found');
    }
    
    #[test]
    fn test_duplicate_registration() {
        let (world, _, _, _, _) = helpers::setup_core();
        let admin = starknet::contract_address_const::<0x123>();
        
        // First registration should succeed
        let result1 = register_component(
            world,
            1,
            Components::Container,
            "Test Container",
            "A test container component",
            admin
        );
        assert(result1.is_ok(), 'first registration should succeed');
        
        // Second registration should fail
        let result2 = register_component(
            world,
            1,
            Components::Player,
            "Test Player",
            "A test player component",
            admin
        );
        assert(result2.is_err(), 'duplicate registration should fail');
    }
    
    #[test]
    fn test_component_listing() {
        let (world, _, _, _, _) = helpers::setup_core();
        let admin = starknet::contract_address_const::<0x123>();
        
        // Register a few components
        let _ = register_component(world, 1, Components::Container, "Container", "Container component", admin);
        let _ = register_component(world, 2, Components::Player, "Player", "Player component", admin);
        
        let components = list_components(world, 10);
        assert(components.len() == 2, 'should have 2 components');
    }
    
    #[test]
    fn test_component_interface() {
        let (world, _, _, _, _) = helpers::setup_core();
        let component_id = 1;
        
        // Test add_component
        let entry = ComponentRegistryEntryComponent::add_component(world, component_id.into());
        assert(entry.is_registered, 'should be registered');
        assert(entry.component_id == component_id, 'component_id should match');
        
        // Test get_component
        let retrieved = ComponentRegistryEntryComponent::get_component(world, component_id.into());
        assert(retrieved.is_some(), 'should retrieve component');
        
        let retrieved = retrieved.unwrap();
        assert(retrieved.component_id == component_id, 'retrieved component_id should match');
    }
    
    #[test]
    fn test_registry_initialization() {
        let (world, _, _, _, _) = helpers::setup_core();
        let admin = starknet::contract_address_const::<0x123>();
        
        let result = initialize_component_registry(world, admin);
        assert(result.is_ok(), 'initialization should succeed');
    }
}