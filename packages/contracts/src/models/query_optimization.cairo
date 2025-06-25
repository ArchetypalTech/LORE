//! Shinigami Layer 4: Models - Query Optimization
//! 
//! This module provides query optimization and caching for entity operations,
//! built on top of LORE's existing entity system for performance enhancement.

use dojo::{world::WorldStorage, model::ModelStorage};
use core::result::Result;
use core::option::OptionTrait;
use starknet::ContractAddress;
use lore::components::Component;

/// Query cache entry following Dojo model pattern
#[derive(Copy, Drop, Serde, Debug, Introspect)]
#[dojo::model]
pub struct QueryCache {
    #[key]
    pub cache_id: felt252,
    pub is_active: bool,
    pub query_hash: felt252,
    pub result_count: u32,
    pub created_at: u64,
    pub last_accessed: u64,
    pub access_count: u32,
    pub ttl_seconds: u64,
    pub cache_type: CacheType,
}

/// Cached query result data
#[derive(Copy, Drop, Serde, Debug, Introspect)]
#[dojo::model]
pub struct CachedResult {
    #[key]
    pub cache_id: felt252,
    #[key]
    pub result_index: u32,
    pub entity_inst: felt252,
    pub entity_data: felt252,
    pub is_valid: bool,
}

/// Types of cached queries
#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum CacheType {
    EntityLookup,
    ComponentQuery,
    RelationshipQuery,
    ContextQuery,
    CustomQuery,
}

/// Entity query structure
#[derive(Drop, Serde, Debug)]
pub struct EntityQuery {
    pub query_type: CacheType,
    pub entity_inst: felt252,
    pub component_types: Array<felt252>,
    pub filters: Array<QueryFilter>,
    pub max_results: u32,
    pub use_cache: bool,
}

/// Query filter for advanced querying
#[derive(Drop, Serde, Debug)]
pub struct QueryFilter {
    pub property: ByteArray,
    pub operator: FilterOperator,
    pub value: felt252,
}

/// Filter operators
#[derive(Serde, Copy, Drop, Debug, PartialEq)]
pub enum FilterOperator {
    Equals,
    NotEquals,
    GreaterThan,
    LessThan,
    Contains,
}

/// Query result structure
#[derive(Drop, Serde, Debug)]
pub struct QueryResult {
    pub entities: Array<felt252>,
    pub total_count: u32,
    pub cached: bool,
    pub cache_hit_ratio: u32,
    pub query_time_ms: u64,
    pub cache_id: Option<felt252>,
}

/// Error types for cache operations
#[derive(Drop, Serde, Debug)]
pub enum CacheError {
    CacheMiss,
    InvalidQuery,
    CacheExpired,
    CacheFull,
    InvalidCacheId,
    PermissionDenied,
}

/// Component implementation for QueryCache
pub impl QueryCacheComponent of Component<QueryCache> {
    type ComponentType = QueryCache;

    fn inst(self: @QueryCache) -> @felt252 {
        self.cache_id
    }

    fn has_component(self: @QueryCache, world: WorldStorage, inst: felt252) -> bool {
        *self.is_active
    }

    fn add_component(mut world: WorldStorage, inst: felt252) -> QueryCache {
        let current_time = starknet::get_block_timestamp();
        
        let cache = QueryCache {
            cache_id: inst,
            is_active: true,
            query_hash: 0,
            result_count: 0,
            created_at: current_time,
            last_accessed: current_time,
            access_count: 0,
            ttl_seconds: 300, // 5 minutes default
            cache_type: CacheType::EntityLookup,
        };
        
        cache.store(world);
        cache
    }

    fn get_component(world: WorldStorage, inst: felt252) -> Option<QueryCache> {
        let cache: QueryCache = world.read_model(inst);
        if (!cache.is_active) {
            return Option::None;
        }
        
        // Check if cache has expired
        let current_time = starknet::get_block_timestamp();
        if (current_time > cache.created_at + cache.ttl_seconds) {
            return Option::None;
        }
        
        Option::Some(cache)
    }

    fn can_use_command(
        self: @QueryCache, world: WorldStorage, player: @lore::components::player::Player, command: @lore::lib::a_lexer::Command,
    ) -> bool {
        false // Cache doesn't handle commands
    }

    fn execute_command(
        self: QueryCache, world: WorldStorage, player: @lore::components::player::Player, command: @lore::lib::a_lexer::Command,
    ) -> Result<(), lore::constants::errors::Error> {
        Result::Err(lore::constants::errors::Error::Unimplemented)
    }

    fn store(self: @QueryCache, mut world: WorldStorage) {
        world.write_model(self);
    }
}

/// Performs cached entity lookup with automatic cache management
/// 
/// # Arguments
/// * `world` - World storage instance
/// * `inst` - Entity instance to look up
/// 
/// # Returns
/// * `Option<felt252>` - Entity instance if found
pub fn cached_entity_lookup(mut world: WorldStorage, inst: felt252) -> Option<felt252> {
    let cache_id = generate_cache_id(inst, 0);
    
    // Try to get from cache first
    if let Option::Some(cache) = QueryCacheComponent::get_component(world, cache_id) {
        // Update access statistics
        let mut updated_cache = cache;
        updated_cache.last_accessed = starknet::get_block_timestamp();
        updated_cache.access_count += 1;
        updated_cache.store(world);
        
        // Return cached result if valid
        let cached_result: CachedResult = world.read_model((cache_id, 0));
        if (cached_result.is_valid) {
            return Option::Some(cached_result.entity_inst);
        }
    }
    
    // Cache miss - perform actual lookup
    // In practice, this would query the entity system
    if (inst != 0) {
        // Create cache entry
        create_cache_entry(world, cache_id, CacheType::EntityLookup, array![inst]);
        Option::Some(inst)
    } else {
        Option::None
    }
}

/// Processes multiple entity queries with batch optimization
/// 
/// # Arguments
/// * `world` - World storage instance
/// * `queries` - Array of queries to process
/// 
/// # Returns
/// * `Array<QueryResult>` - Results for each query
pub fn batch_entity_query(mut world: WorldStorage, queries: Array<EntityQuery>) -> Array<QueryResult> {
    let mut results = array![];
    let mut i = 0;
    
    while i < queries.len() {
        let query = queries.at(i);
        let result = process_single_query(world, query);
        results.append(result);
        i += 1;
    };
    
    results
}

/// Invalidates a specific cache entry
/// 
/// # Arguments
/// * `world` - World storage instance
/// * `cache_id` - Cache ID to invalidate
/// 
/// # Returns
/// * `Result<(), CacheError>` - Success or error
pub fn invalidate_cache(mut world: WorldStorage, cache_id: felt252) -> Result<(), CacheError> {
    let mut cache: QueryCache = world.read_model(cache_id);
    
    if (!cache.is_active) {
        return Result::Err(CacheError::InvalidCacheId);
    }
    
    cache.is_active = false;
    cache.store(world);
    
    // Invalidate all cached results for this cache
    let mut i = 0;
    while i < cache.result_count {
        let mut cached_result: CachedResult = world.read_model((cache_id, i));
        cached_result.is_valid = false;
        world.write_model(@cached_result);
        i += 1;
    };
    
    Result::Ok(())
}

/// Creates a new cache entry with results
fn create_cache_entry(
    mut world: WorldStorage,
    cache_id: felt252,
    cache_type: CacheType,
    entities: Array<felt252>
) {
    let current_time = starknet::get_block_timestamp();
    
    let cache = QueryCache {
        cache_id,
        is_active: true,
        query_hash: cache_id, // Simplified
        result_count: entities.len(),
        created_at: current_time,
        last_accessed: current_time,
        access_count: 1,
        ttl_seconds: 300,
        cache_type,
    };
    
    cache.store(world);
    
    // Store cached results
    let mut i = 0;
    while i < entities.len() {
        let cached_result = CachedResult {
            cache_id,
            result_index: i,
            entity_inst: *entities.at(i),
            entity_data: 0, // Placeholder
            is_valid: true,
        };
        
        world.write_model(@cached_result);
        i += 1;
    };
}

/// Processes a single query with caching
fn process_single_query(mut world: WorldStorage, query: @EntityQuery) -> QueryResult {
    let cache_id = generate_cache_id(*query.entity_inst, cache_type_to_felt(*query.query_type));
    let start_time = starknet::get_block_timestamp();
    
    // Check cache if enabled
    if (*query.use_cache) {
        if let Option::Some(_cache) = QueryCacheComponent::get_component(world, cache_id) {
            // Return cached results
            let entities = get_cached_entities(world, cache_id);
            let entity_count = entities.len();
            return QueryResult {
                entities,
                total_count: entity_count,
                cached: true,
                cache_hit_ratio: 100,
                query_time_ms: 1, // Cached queries are fast
                cache_id: Option::Some(cache_id),
            };
        }
    }
    
    // Perform actual query (simplified implementation)
    let mut entities = array![];
    if (*query.entity_inst != 0) {
        entities.append(*query.entity_inst);
    }
    
    // Cache results if enabled
    let entity_count = entities.len();
    if (*query.use_cache) {
        create_cache_entry(world, cache_id, *query.query_type, entities.clone());
    }
    
    let end_time = starknet::get_block_timestamp();
    
    QueryResult {
        entities,
        total_count: entity_count,
        cached: false,
        cache_hit_ratio: 0,
        query_time_ms: end_time - start_time,
        cache_id: if (*query.use_cache) { Option::Some(cache_id) } else { Option::None },
    }
}

/// Gets cached entities for a cache ID
fn get_cached_entities(world: WorldStorage, cache_id: felt252) -> Array<felt252> {
    let mut entities = array![];
    let cache: QueryCache = world.read_model(cache_id);
    
    let mut i = 0;
    while i < cache.result_count {
        let cached_result: CachedResult = world.read_model((cache_id, i));
        if (cached_result.is_valid) {
            entities.append(cached_result.entity_inst);
        }
        i += 1;
    };
    
    entities
}

/// Generates a cache ID based on query parameters
fn generate_cache_id(entity_inst: felt252, query_type: felt252) -> felt252 {
    // Simplified hash function
    entity_inst + query_type * 1000
}

/// Converts CacheType to felt252 for hashing
fn cache_type_to_felt(cache_type: CacheType) -> felt252 {
    match cache_type {
        CacheType::EntityLookup => 1,
        CacheType::ComponentQuery => 2,
        CacheType::RelationshipQuery => 3,
        CacheType::ContextQuery => 4,
        CacheType::CustomQuery => 5,
    }
}

/// Clears expired cache entries
/// 
/// # Arguments
/// * `world` - World storage instance
/// * `max_entries_to_check` - Maximum number of cache entries to check
pub fn cleanup_expired_cache(mut world: WorldStorage, max_entries_to_check: u32) {
    let current_time = starknet::get_block_timestamp();
    let mut checked = 0;
    let mut cache_id = 1;
    
    while checked < max_entries_to_check {
        let cache: QueryCache = world.read_model(cache_id);
        
        if (cache.is_active && current_time > cache.created_at + cache.ttl_seconds) {
            let _ = invalidate_cache(world, cache_id);
        }
        
        cache_id += 1;
        checked += 1;
    };
}

#[cfg(test)]
mod tests {
    use super::*;
    use lore::tests::helpers;
    
    #[test]
    fn test_cached_entity_lookup() {
        let (world, _, _, _, _) = helpers::setup_core();
        
        // First lookup should create cache
        let result1 = cached_entity_lookup(world, 123);
        assert(result1 == Option::Some(123), 'first lookup should succeed');
        
        // Second lookup should use cache
        let result2 = cached_entity_lookup(world, 123);
        assert(result2 == Option::Some(123), 'second lookup should succeed');
    }
    
    #[test]
    fn test_cache_invalidation() {
        let (world, _, _, _, _) = helpers::setup_core();
        let cache_id = 1000;
        
        // Create cache entry
        create_cache_entry(world, cache_id, CacheType::EntityLookup, array![123, 456]);
        
        // Verify cache exists
        let cache = QueryCacheComponent::get_component(world, cache_id);
        assert(cache.is_some(), 'cache should exist');
        
        // Invalidate cache
        let result = invalidate_cache(world, cache_id);
        assert(result.is_ok(), 'invalidation should succeed');
        
        // Verify cache is invalidated
        let cache_after = QueryCacheComponent::get_component(world, cache_id);
        assert(cache_after.is_none(), 'cache should be invalidated');
    }
    
    #[test]
    fn test_batch_query_processing() {
        let (world, _, _, _, _) = helpers::setup_core();
        
        let mut queries = array![];
        queries.append(EntityQuery {
            query_type: CacheType::EntityLookup,
            entity_inst: 123,
            component_types: array![],
            filters: array![],
            max_results: 10,
            use_cache: true,
        });
        
        let results = batch_entity_query(world, queries);
        assert(results.len() == 1, 'should have one result');
        
        let result = results.at(0);
        assert(result.entities.len() == 1, 'should have one entity');
    }
    
    #[test]
    fn test_component_interface() {
        let (world, _, _, _, _) = helpers::setup_core();
        let cache_id = 500;
        
        // Test add_component
        let cache = QueryCacheComponent::add_component(world, cache_id);
        assert(cache.is_active, 'cache should be active');
        assert(cache.cache_id == cache_id, 'cache_id should match');
        
        // Test get_component
        let retrieved = QueryCacheComponent::get_component(world, cache_id);
        assert(retrieved.is_some(), 'should retrieve cache');
        
        let retrieved = retrieved.unwrap();
        assert(retrieved.cache_id == cache_id, 'retrieved cache_id should match');
    }
}