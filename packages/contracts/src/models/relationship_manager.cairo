//! Shinigami Layer 4: Models - Relationship Manager
//! 
//! This module provides enhanced relationship management for entities in LORE,
//! building on top of the existing parent-child entity system.

use dojo::{world::WorldStorage, model::ModelStorage};
use core::result::Result;
use core::option::OptionTrait;
use starknet::ContractAddress;
use lore::components::Component;

/// Enhanced relationship types for LORE entities
#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum RelationType {
    ParentChild,     // Existing LORE parent-child relationship
    Contains,        // Container contains item
    ConnectedTo,     // Room connects to room via exit
    OwnedBy,         // Item owned by player
    Supports,        // Surface supports item
    Triggers,        // Action triggers another action
    Requires,        // Entity requires another entity
    Blocks,          // Entity blocks access to another
    Activates,       // Entity activates another
    Custom,          // Custom relationship type
}

/// Relationship query structure
#[derive(Drop, Serde, Debug)]
pub struct RelationshipQuery {
    pub source: felt252,
    pub relation_type: Option<RelationType>,
    pub target: Option<felt252>,
    pub bidirectional: bool,
}

/// Relationship result
#[derive(Drop, Serde, Debug)]
pub struct RelationshipResult {
    pub source: felt252,
    pub target: felt252,
    pub relation_type: RelationType,
    pub strength: u32,
    pub created_at: u64,
    pub created_by: ContractAddress,
}

/// Error type for relationship operations
#[derive(Drop, Serde, Debug)]
pub enum RelationshipError {
    NotFound,
    InvalidRelation,
    CircularReference,
    RelationshipExists,
    InsufficientPermissions,
    InvalidEntity,
}

/// Entity relationship model following Dojo pattern
#[derive(Copy, Drop, Serde, Debug, Introspect)]
#[dojo::model]
pub struct EntityRelationship {
    #[key]
    pub source_inst: felt252,
    #[key]
    pub target_inst: felt252,
    #[key]
    pub relation_type: RelationType,
    pub is_active: bool,
    pub strength: u32,
    pub created_at: u64,
    pub updated_at: u64,
    pub created_by: ContractAddress,
    pub metadata: felt252,
}

/// Relationship index for faster queries
#[derive(Copy, Drop, Serde, Debug, Introspect)]
#[dojo::model]
pub struct RelationshipIndex {
    #[key]
    pub entity_inst: felt252,
    #[key]
    pub index_type: RelationIndexType,
    pub relationship_count: u32,
    pub last_updated: u64,
}

/// Types of relationship indexes
#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum RelationIndexType {
    Outgoing,  // Relationships where entity is source
    Incoming,  // Relationships where entity is target
    All,       // All relationships involving entity
}

/// Component implementation for EntityRelationship
pub impl EntityRelationshipComponent of Component<EntityRelationship> {
    type ComponentType = EntityRelationship;

    fn inst(self: @EntityRelationship) -> @felt252 {
        self.source_inst
    }

    fn has_component(self: @EntityRelationship, world: WorldStorage, inst: felt252) -> bool {
        *self.is_active
    }

    fn add_component(mut world: WorldStorage, inst: felt252) -> EntityRelationship {
        let current_time = starknet::get_block_timestamp();
        let caller = starknet::get_caller_address();
        
        let relationship = EntityRelationship {
            source_inst: inst,
            target_inst: 0, // Default, should be set properly
            relation_type: RelationType::Custom,
            is_active: true,
            strength: 1,
            created_at: current_time,
            updated_at: current_time,
            created_by: caller,
            metadata: 0,
        };
        
        relationship.store(world);
        relationship
    }

    fn get_component(world: WorldStorage, inst: felt252) -> Option<EntityRelationship> {
        // Note: This is a simplified implementation
        // In practice, you'd need specific source/target/relation_type to query
        Option::None
    }

    fn can_use_command(
        self: @EntityRelationship, world: WorldStorage, player: @lore::components::player::Player, command: @lore::lib::a_lexer::Command,
    ) -> bool {
        false // Relationships don't handle commands directly
    }

    fn execute_command(
        self: EntityRelationship, world: WorldStorage, player: @lore::components::player::Player, command: @lore::lib::a_lexer::Command,
    ) -> Result<(), lore::constants::errors::Error> {
        Result::Err(lore::constants::errors::Error::Unimplemented)
    }

    fn store(self: @EntityRelationship, mut world: WorldStorage) {
        world.write_model(self);
    }
}

/// Creates a new relationship between entities
/// 
/// # Arguments
/// * `world` - World storage instance
/// * `source` - Source entity instance
/// * `target` - Target entity instance
/// * `relation_type` - Type of relationship
/// * `strength` - Relationship strength (1-100)
/// * `creator` - Address creating the relationship
/// 
/// # Returns
/// * `Result<EntityRelationship, RelationshipError>` - Created relationship or error
pub fn create_relationship(
    mut world: WorldStorage,
    source: felt252,
    target: felt252,
    relation_type: RelationType,
    strength: u32,
    creator: ContractAddress
) -> Result<EntityRelationship, RelationshipError> {
    // Validate entities exist (simplified check)
    if (source == 0 || target == 0) {
        return Result::Err(RelationshipError::InvalidEntity);
    }
    
    // Check for circular reference
    if (source == target) {
        return Result::Err(RelationshipError::CircularReference);
    }
    
    // Check if relationship already exists
    let existing: EntityRelationship = world.read_model((source, target, relation_type));
    if (existing.is_active) {
        return Result::Err(RelationshipError::RelationshipExists);
    }
    
    let current_time = starknet::get_block_timestamp();
    
    let relationship = EntityRelationship {
        source_inst: source,
        target_inst: target,
        relation_type,
        is_active: true,
        strength,
        created_at: current_time,
        updated_at: current_time,
        created_by: creator,
        metadata: 0,
    };
    
    relationship.store(world);
    
    // Update relationship indexes
    update_relationship_index(world, source, RelationIndexType::Outgoing);
    update_relationship_index(world, target, RelationIndexType::Incoming);
    
    Result::Ok(relationship)
}

/// Queries relationships based on criteria
/// 
/// # Arguments
/// * `world` - World storage instance
/// * `query` - Query parameters
/// 
/// # Returns
/// * `Array<RelationshipResult>` - Array of matching relationships
pub fn query_relationships(world: WorldStorage, query: RelationshipQuery) -> Array<RelationshipResult> {
    let mut results = array![];
    
    // Simplified implementation - in practice would use proper indexing
    // This is a placeholder that returns empty results
    
    results
}

/// Gets all entities related to a given entity
/// 
/// # Arguments
/// * `world` - World storage instance
/// * `inst` - Entity instance ID
/// * `relation_types` - Optional filter by relation types
/// 
/// # Returns
/// * `Array<RelationshipResult>` - Array of related entities
pub fn get_related_entities(
    world: WorldStorage,
    inst: felt252,
    relation_types: Option<Array<RelationType>>
) -> Array<RelationshipResult> {
    let mut results = array![];
    
    // Simplified implementation - would use proper relationship queries
    // This is a placeholder that returns empty results
    
    results
}

/// Updates relationship index for an entity
fn update_relationship_index(
    mut world: WorldStorage,
    entity_inst: felt252,
    index_type: RelationIndexType
) {
    let mut index: RelationshipIndex = world.read_model((entity_inst, index_type));
    
    index.entity_inst = entity_inst;
    index.index_type = index_type;
    index.relationship_count += 1;
    index.last_updated = starknet::get_block_timestamp();
    
    world.write_model(@index);
}

/// Removes a relationship between entities
/// 
/// # Arguments
/// * `world` - World storage instance
/// * `source` - Source entity
/// * `target` - Target entity
/// * `relation_type` - Relationship type
/// * `remover` - Address removing the relationship
/// 
/// # Returns
/// * `Result<(), RelationshipError>` - Success or error
pub fn remove_relationship(
    mut world: WorldStorage,
    source: felt252,
    target: felt252,
    relation_type: RelationType,
    remover: ContractAddress
) -> Result<(), RelationshipError> {
    let mut relationship: EntityRelationship = world.read_model((source, target, relation_type));
    
    if (!relationship.is_active) {
        return Result::Err(RelationshipError::NotFound);
    }
    
    relationship.is_active = false;
    relationship.updated_at = starknet::get_block_timestamp();
    
    relationship.store(world);
    
    Result::Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use lore::tests::helpers;
    
    #[test]
    fn test_relationship_creation() {
        let (world, _, _, _, _) = helpers::setup_core();
        let creator = starknet::contract_address_const::<0x123>();
        
        let result = create_relationship(
            world,
            123,  // source
            456,  // target
            RelationType::Contains,
            50,   // strength
            creator
        );
        
        assert(result.is_ok(), 'relationship creation should succeed');
        
        let relationship = result.unwrap();
        assert(relationship.source_inst == 123, 'source should match');
        assert(relationship.target_inst == 456, 'target should match');
        assert(relationship.relation_type == RelationType::Contains, 'type should match');
    }
    
    #[test]
    fn test_circular_reference_prevention() {
        let (world, _, _, _, _) = helpers::setup_core();
        let creator = starknet::contract_address_const::<0x123>();
        
        let result = create_relationship(
            world,
            123,  // source
            123,  // target (same as source)
            RelationType::Contains,
            50,
            creator
        );
        
        assert(result.is_err(), 'circular reference should be prevented');
    }
    
    #[test]
    fn test_invalid_entity_handling() {
        let (world, _, _, _, _) = helpers::setup_core();
        let creator = starknet::contract_address_const::<0x123>();
        
        let result = create_relationship(
            world,
            0,    // invalid source
            456,
            RelationType::Contains,
            50,
            creator
        );
        
        assert(result.is_err(), 'invalid entity should be rejected');
    }
    
    #[test]
    fn test_relationship_removal() {
        let (world, _, _, _, _) = helpers::setup_core();
        let creator = starknet::contract_address_const::<0x123>();
        
        // Create relationship
        let _ = create_relationship(world, 123, 456, RelationType::Contains, 50, creator);
        
        // Remove relationship
        let result = remove_relationship(world, 123, 456, RelationType::Contains, creator);
        assert(result.is_ok(), 'relationship removal should succeed');
        
        // Try to remove again
        let result2 = remove_relationship(world, 123, 456, RelationType::Contains, creator);
        assert(result2.is_err(), 'removing non-existent relationship should fail');
    }
}