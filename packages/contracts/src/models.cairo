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
    EntityState, EntityTransition, LifecycleError, EntityLifecycle, EntityStateHistory,
    create_entity_lifecycle, update_entity_state, get_entity_state, get_entity_lifecycle
};
pub use component_registry::{
    RegistryError, ComponentRegistryEntry, ComponentMetadata,
    register_component, get_component_info, list_components, initialize_component_registry
};
pub use relationship_manager::{
    RelationType, RelationshipQuery, RelationshipResult, RelationshipError,
    EntityRelationship, RelationshipIndex, RelationIndexType,
    create_relationship, query_relationships, get_related_entities, remove_relationship
};
pub use query_optimization::{
    QueryCache, CachedResult, CacheType, EntityQuery, QueryResult, CacheError,
    QueryFilter, FilterOperator,
    cached_entity_lookup, batch_entity_query, invalidate_cache, cleanup_expired_cache
};