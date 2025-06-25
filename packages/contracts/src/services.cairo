//! Shinigami Layer 2: Services - Business logic and world state integration
//! 
//! This module provides service layer functionality that bridges pure utility functions
//! with world state management. Services handle complex business logic while maintaining
//! clean separation between stateless helpers and stateful operations.

pub mod dictionary;

// Re-export commonly used services and types for convenience
pub use dictionary::{
    DictionaryService, lookup_word, add_word, batch_add_words, 
    get_semantic_group, suggest_classification, validate_word_format,
    DictionaryError, WordDefinition, WordMetadata, TokenClassification
};