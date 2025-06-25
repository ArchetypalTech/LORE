//! Shinigami Layer 4: Models - Enhanced entity and component modeling
//! 
//! This module provides the models layer that extends LORE's existing component system
//! with enhanced entity lifecycle management, optimized data access patterns, and 
//! improved relationship modeling while maintaining full backward compatibility.

pub mod entity_lifecycle;
pub mod component_registry;
pub mod relationship_manager;
pub mod query_optimization;

// Re-export commonly used models and utilities for convenience
pub use entity_lifecycle::{
    EntityState, EntityTransition, LifecycleError,
    create_entity, update_entity, destroy_entity, get_entity_state
};
pub use component_registry::{
    RegistryError,
    register_component, get_component_info, list_components
};
pub use relationship_manager::{
    RelationType, RelationshipQuery, RelationshipResult, RelationshipError,
    create_relationship, query_relationships, get_related_entities
};
pub use query_optimization::{
    QueryCache, EntityQuery, QueryResult, CacheError,
    cached_entity_lookup, batch_entity_query, invalidate_cache
};