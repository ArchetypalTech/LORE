//! Shinigami Layer 4: Models - Entity Lifecycle Management
//! 
//! This module provides enhanced entity lifecycle management on top of LORE's 
//! existing entity system, adding state tracking, validation, and transition management.

use dojo::{world::WorldStorage, model::ModelStorage};
use starknet::ContractAddress;
use core::option::OptionTrait;
use core::result::{Result, ResultTrait};
use lore::components::Component;

/// Enhanced entity states for lifecycle management
#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum EntityState {
    Uninitialized,
    Active,
    Disabled,
    Archived,
    Destroyed,
}

/// Entity lifecycle transitions
#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum EntityTransition {
    Create,
    Activate,
    Disable,
    Archive,
    Destroy,
    Restore,
}

/// Error types for lifecycle operations
#[derive(Drop, Serde, Debug)]
pub enum LifecycleError {
    EntityNotFound,
    InvalidTransition,
    InsufficientPermissions,
    ComponentConflict,
    ValidationFailed,
    StorageError,
}

/// Entity lifecycle tracking model following Lore's Dojo pattern
#[derive(Copy, Drop, Serde, Debug, Introspect)]
#[dojo::model]
pub struct EntityLifecycle {
    #[key]
    pub inst: felt252,
    pub is_lifecycle_tracked: bool,
    pub state: EntityState,
    pub created_at: u64,
    pub updated_at: u64,
    pub created_by: ContractAddress,
    pub transition_count: u32,
}

/// Entity state history tracking
#[derive(Copy, Drop, Serde, Debug, Introspect)]
#[dojo::model]
pub struct EntityStateHistory {
    #[key]
    pub inst: felt252,
    #[key]
    pub transition_id: u32,
    pub from_state: EntityState,
    pub to_state: EntityState,
    pub transition_type: EntityTransition,
    pub timestamp: u64,
    pub triggered_by: ContractAddress,
}

/// Component implementation for EntityLifecycle following LORE pattern
pub impl EntityLifecycleComponent of Component<EntityLifecycle> {
    type ComponentType = EntityLifecycle;

    fn inst(self: @EntityLifecycle) -> @felt252 {
        self.inst
    }

    fn has_component(self: @EntityLifecycle, world: WorldStorage, inst: felt252) -> bool {
        let lifecycle: EntityLifecycle = world.read_model(inst);
        lifecycle.is_lifecycle_tracked
    }

    fn add_component(mut world: WorldStorage, inst: felt252) -> EntityLifecycle {
        let current_time = starknet::get_block_timestamp();
        let caller = starknet::get_caller_address();
        
        let mut lifecycle = EntityLifecycle {
            inst,
            is_lifecycle_tracked: true,
            state: EntityState::Active,
            created_at: current_time,
            updated_at: current_time,
            created_by: caller,
            transition_count: 0,
        };
        
        lifecycle.store(world);
        lifecycle
    }

    fn get_component(world: WorldStorage, inst: felt252) -> Option<EntityLifecycle> {
        let lifecycle: EntityLifecycle = world.read_model(inst);
        if (!lifecycle.has_component(world, inst)) {
            return Option::None;
        }
        Option::Some(lifecycle)
    }

    fn can_use_command(
        self: @EntityLifecycle, world: WorldStorage, player: @lore::components::player::Player, command: @lore::lib::a_lexer::Command,
    ) -> bool {
        // Lifecycle tracking doesn't handle commands directly
        false
    }

    fn execute_command(
        self: EntityLifecycle, world: WorldStorage, player: @lore::components::player::Player, command: @lore::lib::a_lexer::Command,
    ) -> Result<(), lore::constants::errors::Error> {
        Result::Err(lore::constants::errors::Error::Unimplemented)
    }

    fn store(self: @EntityLifecycle, mut world: WorldStorage) {
        world.write_model(self);
    }
}

/// Creates a new entity with lifecycle tracking
/// 
/// # Arguments
/// * `world` - World storage instance
/// * `inst` - Entity instance ID
/// * `creator` - Address of entity creator
/// 
/// # Returns
/// * `Result<EntityLifecycle, LifecycleError>` - New lifecycle component or error
pub fn create_entity_lifecycle(
    mut world: WorldStorage,
    inst: felt252,
    creator: ContractAddress
) -> Result<EntityLifecycle, LifecycleError> {
    let current_time = starknet::get_block_timestamp();
    
    let lifecycle = EntityLifecycle {
        inst,
        is_lifecycle_tracked: true,
        state: EntityState::Active,
        created_at: current_time,
        updated_at: current_time,
        created_by: creator,
        transition_count: 0,
    };
    
    lifecycle.store(world);
    
    // Record initial state in history
    let history = EntityStateHistory {
        inst,
        transition_id: 0,
        from_state: EntityState::Uninitialized,
        to_state: EntityState::Active,
        transition_type: EntityTransition::Create,
        timestamp: current_time,
        triggered_by: creator,
    };
    
    world.write_model(@history);
    
    Result::Ok(lifecycle)
}

/// Updates entity state with validation and permissions
/// 
/// # Arguments
/// * `world` - World storage instance
/// * `inst` - Entity instance ID
/// * `updater` - Address requesting update
/// * `transition` - Requested state transition
/// 
/// # Returns
/// * `Result<(), LifecycleError>` - Success or error
pub fn update_entity_state(
    mut world: WorldStorage,
    inst: felt252,
    updater: ContractAddress,
    transition: EntityTransition
) -> Result<(), LifecycleError> {
    let mut lifecycle: EntityLifecycle = world.read_model(inst);
    
    if (!lifecycle.is_lifecycle_tracked) {
        return Result::Err(LifecycleError::EntityNotFound);
    }
    
    let new_state = validate_transition(lifecycle.state, transition);
    if (new_state.is_none()) {
        return Result::Err(LifecycleError::InvalidTransition);
    }
    
    let new_state = new_state.unwrap();
    let current_time = starknet::get_block_timestamp();
    
    // Record state transition in history
    let history = EntityStateHistory {
        inst,
        transition_id: lifecycle.transition_count + 1,
        from_state: lifecycle.state,
        to_state: new_state,
        transition_type: transition,
        timestamp: current_time,
        triggered_by: updater,
    };
    
    world.write_model(@history);
    
    // Update lifecycle
    lifecycle.state = new_state;
    lifecycle.updated_at = current_time;
    lifecycle.transition_count += 1;
    
    lifecycle.store(world);
    
    Result::Ok(())
}

/// Gets current entity state
/// 
/// # Arguments
/// * `world` - World storage instance
/// * `inst` - Entity instance ID
/// 
/// # Returns
/// * `Option<EntityState>` - Current state or None if not found
pub fn get_entity_state(world: WorldStorage, inst: felt252) -> Option<EntityState> {
    let lifecycle: EntityLifecycle = world.read_model(inst);
    if (!lifecycle.is_lifecycle_tracked) {
        return Option::None;
    }
    Option::Some(lifecycle.state)
}

/// Gets entity lifecycle information
/// 
/// # Arguments
/// * `world` - World storage instance
/// * `inst` - Entity instance ID
/// 
/// # Returns
/// * `Option<EntityLifecycle>` - Lifecycle data or None if not found
pub fn get_entity_lifecycle(world: WorldStorage, inst: felt252) -> Option<EntityLifecycle> {
    EntityLifecycleComponent::get_component(world, inst)
}

/// Validates if a state transition is allowed
/// 
/// # Arguments
/// * `current` - Current entity state
/// * `transition` - Requested transition
/// 
/// # Returns
/// * `Option<EntityState>` - New state if valid, None if invalid
fn validate_transition(current: EntityState, transition: EntityTransition) -> Option<EntityState> {
    match (current, transition) {
        // Create: Only from Uninitialized
        (EntityState::Uninitialized, EntityTransition::Create) => Option::Some(EntityState::Active),
        
        // Activate: From Disabled or Archived
        (EntityState::Disabled, EntityTransition::Activate) => Option::Some(EntityState::Active),
        (EntityState::Archived, EntityTransition::Restore) => Option::Some(EntityState::Active),
        
        // Disable: From Active
        (EntityState::Active, EntityTransition::Disable) => Option::Some(EntityState::Disabled),
        
        // Archive: From Active or Disabled
        (EntityState::Active, EntityTransition::Archive) => Option::Some(EntityState::Archived),
        (EntityState::Disabled, EntityTransition::Archive) => Option::Some(EntityState::Archived),
        
        // Destroy: From any state except already destroyed
        (EntityState::Uninitialized, EntityTransition::Destroy) => Option::Some(EntityState::Destroyed),
        (EntityState::Active, EntityTransition::Destroy) => Option::Some(EntityState::Destroyed),
        (EntityState::Disabled, EntityTransition::Destroy) => Option::Some(EntityState::Destroyed),
        (EntityState::Archived, EntityTransition::Destroy) => Option::Some(EntityState::Destroyed),
        
        // Invalid transitions
        _ => Option::None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use lore::tests::helpers;
    
    #[test]
    fn test_entity_lifecycle_creation() {
        let (world, _, _, _, _) = helpers::setup_core();
        let creator = starknet::contract_address_const::<0x123>();
        let inst = 12345;
        
        let result = create_entity_lifecycle(world, inst, creator);
        assert(result.is_ok(), 'lifecycle creation should succeed');
        
        let lifecycle = result.unwrap();
        assert(lifecycle.state == EntityState::Active, 'entity should be active');
        assert(lifecycle.created_by == creator, 'creator should match');
        
        let state = get_entity_state(world, inst);
        assert(state == Option::Some(EntityState::Active), 'state should be retrievable');
    }
    
    #[test]
    fn test_state_transitions() {
        let (world, _, _, _, _) = helpers::setup_core();
        let creator = starknet::contract_address_const::<0x123>();
        let inst = 12345;
        
        let _ = create_entity_lifecycle(world, inst, creator);
        
        // Test valid transition
        let result = update_entity_state(world, inst, creator, EntityTransition::Disable);
        assert(result.is_ok(), 'disable transition should succeed');
        
        let state = get_entity_state(world, inst);
        assert(state == Option::Some(EntityState::Disabled), 'entity should be disabled');
        
        // Test invalid transition
        let result = update_entity_state(world, inst, creator, EntityTransition::Create);
        assert(result.is_err(), 'invalid transition should fail');
    }
    
    #[test]
    fn test_component_interface() {
        let (world, _, _, _, _) = helpers::setup_core();
        let inst = 12345;
        
        // Test add_component
        let lifecycle = EntityLifecycleComponent::add_component(world, inst);
        assert(lifecycle.is_lifecycle_tracked, 'should be tracked');
        assert(lifecycle.inst == inst, 'inst should match');
        
        // Test get_component
        let retrieved = EntityLifecycleComponent::get_component(world, inst);
        assert(retrieved.is_some(), 'should retrieve component');
        
        let retrieved = retrieved.unwrap();
        assert(retrieved.inst == inst, 'retrieved inst should match');
    }
    
    #[test]
    fn test_invalid_transitions() {
        // Test invalid transition validation
        let result = validate_transition(EntityState::Active, EntityTransition::Create);
        assert(result.is_none(), 'invalid transition should return None');
        
        let result = validate_transition(EntityState::Destroyed, EntityTransition::Activate);
        assert(result.is_none(), 'cannot activate destroyed entity');
    }
    
    #[test]
    fn test_valid_transitions() {
        // Test valid transitions
        let result = validate_transition(EntityState::Active, EntityTransition::Disable);
        assert(result == Option::Some(EntityState::Disabled), 'should transition to disabled');
        
        let result = validate_transition(EntityState::Disabled, EntityTransition::Activate);
        assert(result == Option::Some(EntityState::Active), 'should transition to active');
    }
}