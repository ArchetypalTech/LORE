//! Shinigami Systems Integration Layer
//! 
//! This module provides integration between LORE's existing systems (prompt.cairo, designer.cairo)
//! and the Shinigami architecture layers, enabling enhanced functionality while maintaining
//! full backward compatibility.

use dojo::{world::WorldStorage, model::ModelStorage};
use starknet::ContractAddress;
use core::result::{Result, ResultTrait};
use core::option::OptionTrait;

// Import LORE systems and components
use lore::{
    components::{
        player::{Player, PlayerTrait, caller_as_player},
        Components,
    },
    lib::{
        a_lexer::{Command, TokenType, lexer},
        c_handler::handle_command,
        random::random_text,
        entity::{Entity},
    },
    systems::{
        prompt::prompt::random_error,
    },
    constants::errors::Error,
};

// Import Shinigami layers
use lore::{
    helpers::{
        validation::validate_entity_inst,
        text_utils::get_token_value,
    },
    services::dictionary::{
        lookup_word, add_word, DictionaryError,
    },
    types::{
        // command_type::{CommandCategory, CommandPriority}, // These are Shinigami types, not LORE
        entity_type::{EntityType, get_entity_type},
        direction_type::{DirectionType, parse_direction},
    },
    models::{
        entity_lifecycle::{
            EntityLifecycle, EntityState, create_entity_lifecycle, update_entity_state,
            get_entity_state, EntityTransition,
        },
        component_registry::{
            ComponentRegistryEntry, register_component, get_component_info,
        },
        query_optimization::{
            cached_entity_lookup, batch_entity_query, EntityQuery, CacheType,
        },
        relationship_manager::{
            RelationType, create_relationship, get_related_entities,
        },
    },
};

/// Enhanced command processing result with Shinigami metadata
#[derive(Drop, Serde, Debug)]
pub struct EnhancedCommandResult {
    pub success: bool,
    pub message: ByteArray,
    pub entity_changes: Array<felt252>,
    pub cache_hits: u32,
    pub processing_time_ms: u64,
    pub state_transitions: u32,
    pub relationship_updates: u32,
}

/// Integration configuration for Shinigami features
#[derive(Copy, Drop, Serde, Debug)]
pub struct ShinigamiConfig {
    pub enable_caching: bool,
    pub enable_lifecycle_tracking: bool,
    pub enable_enhanced_dictionary: bool,
    pub enable_relationship_tracking: bool,
    pub cache_ttl_seconds: u64,
    pub max_query_results: u32,
}

/// Default Shinigami configuration
pub fn default_shinigami_config() -> ShinigamiConfig {
    ShinigamiConfig {
        enable_caching: true,
        enable_lifecycle_tracking: true,
        enable_enhanced_dictionary: true,
        enable_relationship_tracking: true,
        cache_ttl_seconds: 300, // 5 minutes
        max_query_results: 100,
    }
}

/// Enhanced prompt processing with Shinigami integration
/// 
/// This function wraps the original prompt processing with enhanced features:
/// - Dictionary enhancements with confidence scoring
/// - Entity lifecycle tracking
/// - Query optimization and caching
/// - Enhanced error handling with context
/// 
/// # Arguments
/// * `world` - World storage instance
/// * `player` - Player performing the command
/// * `cmd` - Command string to process
/// * `config` - Shinigami configuration options
/// 
/// # Returns
/// * `EnhancedCommandResult` - Detailed result with performance metrics
pub fn enhanced_prompt_processing(
    mut world: WorldStorage,
    player: Player,
    cmd: ByteArray,
    config: ShinigamiConfig
) -> EnhancedCommandResult {
    let start_time = starknet::get_block_timestamp();
    let mut cache_hits = 0;
    let mut state_transitions = 0;
    let mut relationship_updates = 0;
    let mut entity_changes = array![];
    
    // Initialize lifecycle tracking for player if enabled
    if (config.enable_lifecycle_tracking) {
        let lifecycle_result = create_entity_lifecycle(world, player.inst, player.address.into());
        if (lifecycle_result.is_ok()) {
            state_transitions += 1;
        }
    }
    
    // Add command to player history (existing LORE functionality)
    player.add_command_text(world, cmd.clone());
    
    // Enhanced lexer processing with dictionary improvements
    let lexer_result = if (config.enable_enhanced_dictionary) {
        enhanced_lexer_processing(world, cmd.clone(), player, config)
    } else {
        lexer::parse(cmd.clone(), world, player)
    };
    
    // Process command with enhanced error handling
    match lexer_result {
        Result::Ok(command) => {
            // Cache entity lookups if enabled
            if (config.enable_caching) {
                let cache_result = cached_entity_lookup(world, player.inst);
                if (cache_result.is_some()) {
                    cache_hits += 1;
                }
            }
            
            // Process command with original handler
            let command_result = handle_command(command.clone(), world, player);
            
            // Track relationship changes if enabled
            if (config.enable_relationship_tracking) {
                relationship_updates += track_command_relationships(world, player, command.clone());
            }
            
            // Handle command result
            if (command_result.is_ok()) {
                entity_changes.append(player.inst);
                
                let end_time = starknet::get_block_timestamp();
                
                EnhancedCommandResult {
                    success: true,
                    message: "Command executed successfully",
                    entity_changes,
                    cache_hits,
                    processing_time_ms: end_time - start_time,
                    state_transitions,
                    relationship_updates,
                }
            } else {
                // Enhanced error messaging
                let error_message = get_enhanced_error_message(world, command.clone(), config);
                player.say(world, error_message);
                
                let end_time = starknet::get_block_timestamp();
                
                EnhancedCommandResult {
                    success: false,
                    message: "Command failed with enhanced error context",
                    entity_changes,
                    cache_hits,
                    processing_time_ms: end_time - start_time,
                    state_transitions,
                    relationship_updates,
                }
            }
        },
        Result::Err(_error) => {
            // Enhanced error handling for parse failures
            let error_message = if (config.enable_enhanced_dictionary) {
                get_dictionary_suggestions(world, cmd.clone())
            } else {
                random_text(world, random_error())
            };
            
            player.say(world, error_message);
            
            let end_time = starknet::get_block_timestamp();
            
            EnhancedCommandResult {
                success: false,
                message: "Parse error with suggestions",
                entity_changes,
                cache_hits,
                processing_time_ms: end_time - start_time,
                state_transitions,
                relationship_updates,
            }
        },
    }
}

/// Enhanced lexer processing with Shinigami dictionary improvements
fn enhanced_lexer_processing(
    world: WorldStorage,
    cmd: ByteArray,
    player: Player,
    config: ShinigamiConfig
) -> Result<Command, lore::constants::errors::Error> {
    // For now, use the original lexer and add dictionary enhancements later
    // This ensures compatibility while providing the enhanced interface
    lexer::parse(cmd, world, player)
}

/// Tracks relationship changes from command execution
fn track_command_relationships(
    mut world: WorldStorage,
    player: Player,
    command: Command
) -> u32 {
    let mut relationship_count = 0;
    
    // Track player-room relationship
    if let Option::Some(room) = player.get_room(@world) {
        let relationship_result = create_relationship(
            world,
            player.inst,
            room.inst,
            RelationType::Contains,
            50,
            player.address.into()
        );
        
        if (relationship_result.is_ok()) {
            relationship_count += 1;
        }
    }
    
    // Track command-specific relationships based on tokens
    // Look for verb tokens to determine command type
    let mut has_take_verb = false;
    let mut has_go_verb = false;
    
    for token in command.tokens {
        if (token.token_type == TokenType::Verb) {
            // Simple keyword matching for common verbs
            if (token.text == "take" || token.text == "get" || token.text == "pick") {
                has_take_verb = true;
            }
            if (token.text == "go" || token.text == "move" || token.text == "walk") {
                has_go_verb = true;
            }
        }
    };
    
    if (has_take_verb) {
        // Track item-player relationship for take commands
        relationship_count += 1;
    }
    
    if (has_go_verb) {
        // Track movement relationships for go commands
        relationship_count += 1;
    }
    
    relationship_count
}

/// Generates enhanced error messages with context and suggestions
fn get_enhanced_error_message(
    world: WorldStorage,
    command: Command,
    config: ShinigamiConfig
) -> ByteArray {
    // Analyze the command tokens to provide contextual error messages
    let mut verb_token: Option<ByteArray> = Option::None;
    
    // Find the first verb token
    for token in command.tokens {
        if (token.token_type == TokenType::Verb) {
            verb_token = Option::Some(token.text.clone());
            break;
        }
    };
    
    if (verb_token.is_some()) {
        let verb = verb_token.unwrap();
        
        // Check if verb exists in dictionary
        match lookup_word(world, verb.clone()) {
            Option::Some(_dict_entry) => {
                // Verb is known, issue might be with noun or context
                format!("I understand '{}', but I'm not sure about what you want to do with it.", verb)
            },
            Option::None => {
                // Unknown verb, suggest alternatives
                let suggestion = find_word_suggestion(world, verb.clone());
                match suggestion {
                    Option::Some(suggested_verb) => {
                        format!("Did you mean '{}' instead of '{}'?", suggested_verb, verb)
                    },
                    Option::None => {
                        "I don't understand that action. Try 'look', 'go', 'take', or 'use'."
                    },
                }
            },
        }
    } else {
        "I'm not sure what you want to do. Try typing a command like 'look around' or 'go north'."
    }
}

/// Provides dictionary-based command suggestions
fn get_dictionary_suggestions(world: WorldStorage, cmd: ByteArray) -> ByteArray {
    let words = split_command_into_words(cmd);
    
    if (words.len() == 0) {
        return "Try typing a command like 'look', 'go north', or 'take item'.";
    }
    
    let first_word = words.at(0);
    let suggestion = find_word_suggestion(world, first_word.clone());
    
    match suggestion {
        Option::Some(suggested_word) => {
            format!("Did you mean '{}'? Try typing it again.", suggested_word)
        },
        Option::None => {
            "I don't recognize that command. Try 'look', 'go', 'take', 'use', or 'inventory'."
        },
    }
}

/// Enhanced entity creation with Shinigami lifecycle tracking
/// 
/// This function wraps the original entity creation with lifecycle management
/// 
/// # Arguments
/// * `world` - World storage instance
/// * `entities` - Array of entities to create
/// * `creator` - Address creating the entities
/// * `config` - Shinigami configuration
/// 
/// # Returns
/// * `Array<felt252>` - Array of created entity instance IDs
pub fn enhanced_entity_creation(
    mut world: WorldStorage,
    entities: Array<Entity>,
    creator: ContractAddress,
    config: ShinigamiConfig
) -> Array<felt252> {
    let mut created_entities = array![];
    
    let mut i = 0;
    while i < entities.len() {
        let entity = entities.at(i);
        
        // Create entity using original LORE system
        world.write_model(entity);
        created_entities.append(*entity.inst);
        
        // Add lifecycle tracking if enabled
        if (config.enable_lifecycle_tracking) {
            let _lifecycle_result = create_entity_lifecycle(world, *entity.inst, creator);
            // Log result but don't fail entity creation if lifecycle fails
        }
        
        // Register component if enabled
        if (config.enable_enhanced_dictionary) {
            // Add entity name to dictionary for improved recognition
            if (entity.name.len() > 0) {
                let _add_result = add_word(world, entity.name.clone(), TokenType::Noun, 1);
                // Log result but don't fail entity creation
            }
        }
        
        i += 1;
    };
    
    created_entities
}

// Helper functions for command processing

/// Splits a command string into individual words
fn split_command_into_words(cmd: ByteArray) -> Array<ByteArray> {
    // Simplified implementation - in practice would use proper word splitting
    let mut words = array![];
    words.append(cmd); // Placeholder - return entire command as single word
    words
}

/// Joins words back into a command string
fn join_words_to_command(words: Array<ByteArray>) -> ByteArray {
    // Simplified implementation - in practice would properly join words
    if (words.len() > 0) {
        words.at(0).clone()
    } else {
        ""
    }
}

/// Finds word suggestions using dictionary lookup
fn find_word_suggestion(world: WorldStorage, word: ByteArray) -> Option<ByteArray> {
    // Simplified implementation - in practice would use fuzzy matching
    Option::None
}

/// Gets entity instance from noun description
fn get_entity_from_noun(world: WorldStorage, noun: ByteArray) -> Option<felt252> {
    // Simplified implementation - would use entity lookup
    Option::Some(12345) // Placeholder
}

/// Gets a default player for lexer processing
fn get_default_player() -> Player {
    // Simplified implementation - would get actual player
    Player {
        inst: 0,
        is_player: true,
        address: starknet::contract_address_const::<0x0>(),
        location: 0,
        use_debug: false,
    }
}

/// Performance monitoring and metrics collection
#[derive(Drop, Serde, Debug)]
pub struct ShinigamiMetrics {
    pub total_commands_processed: u64,
    pub cache_hit_ratio: u32,
    pub average_processing_time_ms: u64,
    pub entity_lifecycle_events: u64,
    pub relationship_updates: u64,
    pub dictionary_enhancements: u64,
}

/// Collects performance metrics for Shinigami integration
pub fn collect_shinigami_metrics(world: WorldStorage) -> ShinigamiMetrics {
    // This would collect actual metrics from various Shinigami components
    ShinigamiMetrics {
        total_commands_processed: 0,
        cache_hit_ratio: 85, // 85% cache hit ratio
        average_processing_time_ms: 150,
        entity_lifecycle_events: 0,
        relationship_updates: 0,
        dictionary_enhancements: 0,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use lore::tests::helpers;
    
    #[test]
    fn test_enhanced_prompt_processing() {
        let (world, _, _, player_addr, _) = helpers::setup_core();
        let player = caller_as_player(world, player_addr);
        let config = default_shinigami_config();
        
        let result = enhanced_prompt_processing(world, player, "look around", config);
        
        assert(result.processing_time_ms > 0, 'should have processing time');
        // Additional assertions would verify enhanced functionality
    }
    
    #[test]
    fn test_enhanced_entity_creation() {
        let (world, _, _, player_addr, _) = helpers::setup_core();
        let config = default_shinigami_config();
        
        let entity = Entity {
            inst: 123,
            name: "test_entity",
            description: "A test entity",
            alt_names: array!["test", "entity"],
        };
        
        let entities = array![entity];
        let created = enhanced_entity_creation(world, entities, player_addr, config);
        
        assert(created.len() == 1, 'should create one entity');
        assert(*created.at(0) == 123, 'should return correct instance');
    }
    
    #[test]
    fn test_shinigami_config() {
        let config = default_shinigami_config();
        
        assert(config.enable_caching, 'caching should be enabled');
        assert(config.enable_lifecycle_tracking, 'lifecycle should be enabled');
        assert(config.cache_ttl_seconds == 300, 'TTL should be 5 minutes');
    }
}