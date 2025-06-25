//! Shinigami Layer 1: Helpers - Pure Utility Functions
//! 
//! This module provides stateless utility functions for the LORE game engine.
//! All functions in this layer are pure utilities with no side effects,
//! focused on text processing, validation, data packing, random generation,
//! and property management specific to interactive fiction mechanics.

pub mod validation;
pub mod data_packer;
pub mod random_utils;
pub mod property_manager;
pub mod text_utils;

// Re-export commonly used functions and types for convenience
pub use validation::{validate_entity_inst, validate_command_input, sanitize_user_input, ValidationError};
pub use data_packer::{pack_entity_data, unpack_entity_data, pack_relationship_data, unpack_relationship_data, EntityData, RelationshipType};
pub use random_utils::{generate_seed, random_range, random_choice, random_text_choice, random_entity_instance};
pub use property_manager::{PropertyType, ComponentType as PropComponentType, validate_property_value, PropertyError};
pub use text_utils::{get_token_value, normalize_text, tokenize_command, TokenClassification, DictionaryError};