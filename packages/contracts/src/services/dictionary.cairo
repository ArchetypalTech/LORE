//! Shinigami Layer 2: Services - Dictionary Service
//!
//! This module provides the dictionary service layer that bridges LORE's existing
//! dictionary system with Shinigami's text processing utilities. It maintains
//! compatibility with existing code while adding enhanced functionality.

use dojo::{world::WorldStorage, model::ModelStorage};
use starknet::ContractAddress;
use core::option::OptionTrait;
use core::result::{Result, ResultTrait};
use lore::{
    constants::errors::Error,
    lib::{
        dictionary::{Dict, get_dict_entry, add_to_dictionary}, a_lexer::TokenType,
        utils::ByteArrayTraitExt,
    },
};

/// Enhanced word classification with confidence scoring
#[derive(Drop, Serde, Debug, Clone)]
pub struct TokenClassification {
    pub token_type: TokenType,
    pub confidence: u8, // 0-100 confidence score
    pub alternatives: Array<TokenType>,
    pub semantic_value: felt252,
}

/// Word definition for batch operations
#[derive(Drop, Serde, Debug)]
pub struct WordDefinition {
    pub word: ByteArray,
    pub token_type: TokenType,
    pub n_value: felt252,
    pub metadata: WordMetadata,
}

/// Metadata for dictionary entries
#[derive(Drop, Serde, Debug)]
pub struct WordMetadata {
    pub added_by: ContractAddress,
    pub timestamp: u64,
    pub usage_count: u32,
    pub alternative_spellings: Array<ByteArray>,
}

/// Enhanced error types for dictionary operations
#[derive(Drop, Serde, Debug)]
pub enum DictionaryError {
    WordTooLong, // Word exceeds 31 character limit
    WordAlreadyExists, // Word conflicts with existing entry
    InvalidTokenType, // Invalid token type for word
    StorageError, // World state write failed
    BatchSizeLimit, // Too many words in batch operation
    ConversionError // ByteArray to felt252 conversion failed
}

/// Dictionary service interface
pub trait DictionaryService {
    fn lookup_word(world: WorldStorage, word: ByteArray) -> Option<Dict>;
    fn add_word(
        world: WorldStorage, word: ByteArray, token_type: TokenType, n_value: felt252,
    ) -> Result<(), DictionaryError>;
    fn batch_add_words(
        world: WorldStorage, words: Array<WordDefinition>,
    ) -> Result<(), DictionaryError>;
    fn get_semantic_group(world: WorldStorage, n_value: felt252) -> Array<ByteArray>;
    fn suggest_classification(word: ByteArray) -> Array<TokenClassification>;
    fn validate_word_format(word: ByteArray) -> Result<(), DictionaryError>;
}

/// Enhanced dictionary lookup with error handling
///
/// # Arguments
/// * `world` - World storage instance
/// * `word` - Word to look up
///
/// # Returns
/// * `Option<Dict>` - Dictionary entry if found
pub fn lookup_word(world: WorldStorage, word: ByteArray) -> Option<Dict> {
    // Use existing LORE dictionary implementation
    get_dict_entry(world, word)
}

/// Enhanced word addition with validation
///
/// # Arguments
/// * `world` - World storage instance
/// * `word` - Word to add
/// * `token_type` - Grammatical classification
/// * `n_value` - Semantic group value
///
/// # Returns
/// * `Result<(), DictionaryError>` - Success or error
pub fn add_word(
    world: WorldStorage, word: ByteArray, token_type: TokenType, n_value: felt252,
) -> Result<(), DictionaryError> {
    // Validate word format
    validate_word_format(word.clone())?;

    // Check if word already exists
    if lookup_word(world, word.clone()).is_some() {
        return Result::Err(DictionaryError::WordAlreadyExists);
    }

    // Use existing LORE dictionary function with error mapping
    match add_to_dictionary(world, word, token_type, n_value) {
        Result::Ok(()) => Result::Ok(()),
        Result::Err(_) => Result::Err(DictionaryError::StorageError),
    }
}

/// Batch word addition for efficiency
///
/// # Arguments
/// * `world` - World storage instance
/// * `words` - Array of word definitions to add
///
/// # Returns
/// * `Result<(), DictionaryError>` - Success or error
pub fn batch_add_words(
    world: WorldStorage, words: Array<WordDefinition>,
) -> Result<(), DictionaryError> {
    // Limit batch size to prevent gas issues
    if words.len() > 100 {
        return Result::Err(DictionaryError::BatchSizeLimit);
    }

    // Validate all words first
    let mut i = 0;
    let mut validation_error: Option<DictionaryError> = Option::None;
    while i < words.len() && validation_error.is_none() {
        let word_def = words.at(i);
        match validate_word_format(word_def.word.clone()) {
            Result::Ok(()) => {},
            Result::Err(e) => { validation_error = Option::Some(e); },
        }
        i += 1;
    };

    if let Option::Some(error) = validation_error {
        return Result::Err(error);
    }

    // Add all words
    i = 0;
    let mut add_error: Option<DictionaryError> = Option::None;
    while i < words.len() && add_error.is_none() {
        let word_def = words.at(i);
        match add_word(world, word_def.word.clone(), *word_def.token_type, *word_def.n_value) {
            Result::Ok(()) => {},
            Result::Err(e) => { add_error = Option::Some(e); },
        }
        i += 1;
    };

    if let Option::Some(error) = add_error {
        return Result::Err(error);
    }

    Result::Ok(())
}

/// Get all words in a semantic group
///
/// # Arguments
/// * `world` - World storage instance
/// * `n_value` - Semantic group value
///
/// # Returns
/// * `Array<ByteArray>` - Words in the semantic group
pub fn get_semantic_group(world: WorldStorage, n_value: felt252) -> Array<ByteArray> {
    // This would require indexing by n_value in full implementation
    // For now, return empty array as placeholder
    ArrayTrait::new()
}

/// Suggest classification for unknown words using heuristics
///
/// # Arguments
/// * `word` - Word to classify
///
/// # Returns
/// * `Array<TokenClassification>` - Suggested classifications
pub fn suggest_classification(word: ByteArray) -> Array<TokenClassification> {
    let mut suggestions = ArrayTrait::new();

    // Basic heuristic: length-based classification
    if word.len() < 3 {
        suggestions
            .append(
                TokenClassification {
                    token_type: TokenType::Article,
                    confidence: 60,
                    alternatives: array![TokenType::Preposition, TokenType::Pronoun],
                    semantic_value: 1,
                },
            );
    } else if word.len() > 8 {
        suggestions
            .append(
                TokenClassification {
                    token_type: TokenType::Noun,
                    confidence: 70,
                    alternatives: array![TokenType::Adjective],
                    semantic_value: 1,
                },
            );
    } else {
        suggestions
            .append(
                TokenClassification {
                    token_type: TokenType::Verb,
                    confidence: 50,
                    alternatives: array![TokenType::Noun, TokenType::Adjective],
                    semantic_value: 1,
                },
            );
    }

    suggestions
}

/// Validate word format according to LORE constraints
///
/// # Arguments
/// * `word` - Word to validate
///
/// # Returns
/// * `Result<(), DictionaryError>` - Validation result
pub fn validate_word_format(word: ByteArray) -> Result<(), DictionaryError> {
    // Check length constraint (31 chars max for felt252 conversion)
    if word.len() >= 31 {
        return Result::Err(DictionaryError::WordTooLong);
    }

    // Check if word can be converted to felt252
    match word.to_felt252_word() {
        Result::Ok(_) => Result::Ok(()),
        Result::Err(_) => Result::Err(DictionaryError::ConversionError),
    }
}

/// Enhanced word lookup with classification confidence
///
/// # Arguments
/// * `world` - World storage instance
/// * `word` - Word to classify
///
/// # Returns
/// * `TokenClassification` - Classification with confidence
pub fn classify_word_with_confidence(world: WorldStorage, word: ByteArray) -> TokenClassification {
    match lookup_word(world, word.clone()) {
        Option::Some(entry) => TokenClassification {
            token_type: entry.tokenType,
            confidence: 95, // High confidence for dictionary words
            alternatives: ArrayTrait::new(),
            semantic_value: entry.n_value,
        },
        Option::None => {
            // Fallback to heuristic classification
            let suggestions = suggest_classification(word);
            if suggestions.len() > 0 {
                suggestions.at(0).clone()
            } else {
                TokenClassification {
                    token_type: TokenType::Unknown,
                    confidence: 10,
                    alternatives: ArrayTrait::new(),
                    semantic_value: 0,
                }
            }
        },
    }
}

/// Get default metadata for word entries
///
/// # Returns
/// * `WordMetadata` - Default metadata structure
pub fn default_metadata() -> WordMetadata {
    WordMetadata {
        added_by: starknet::contract_address_const::<0>(),
        timestamp: 0,
        usage_count: 0,
        alternative_spellings: ArrayTrait::new(),
    }
}

/// Check if a word exists in the dictionary
///
/// # Arguments
/// * `world` - World storage instance
/// * `word` - Word to check
///
/// # Returns
/// * `bool` - True if word exists
pub fn word_exists(world: WorldStorage, word: ByteArray) -> bool {
    lookup_word(world, word).is_some()
}

/// Get word statistics for analytics
///
/// # Arguments
/// * `world` - World storage instance
///
/// # Returns
/// * `(u32, u32, u32)` - Total words, verbs, nouns
pub fn get_dictionary_stats(world: WorldStorage) -> (u32, u32, u32) {
    // This would require full dictionary scanning in real implementation
    // For now, return placeholder values
    (100, 40, 20) // Approximate counts from LORE's current dictionary
}

/// Initialize dictionary with LORE's core vocabulary
///
/// # Arguments
/// * `world` - World storage instance
///
/// # Returns
/// * `Result<(), DictionaryError>` - Initialization result
pub fn initialize_core_dictionary(world: WorldStorage) -> Result<(), DictionaryError> {
    // Use LORE's existing initialization if not already done
    lore::lib::dictionary::initialize_dictionary(world);
    Result::Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use lore::tests::helpers;

    #[test]
    fn test_lookup_word() {
        let (world, _, _, _, _) = helpers::setup_core();
        let entry = lookup_word(world, "look").unwrap();
        assert(entry.tokenType == TokenType::Verb, 'look is verb');
        assert(entry.n_value == 18, 'look has correct n_value');
    }

    #[test]
    fn test_add_word() {
        let (world, _, _, _, _) = helpers::setup_core();
        let result = add_word(world, "teleport", TokenType::Verb, 250);
        assert(result.is_ok(), 'word addition should succeed');

        let entry = lookup_word(world, "teleport").unwrap();
        assert(entry.tokenType == TokenType::Verb, 'teleport is verb');
        assert(entry.n_value == 250, 'teleport has correct n_value');
    }

    #[test]
    fn test_validate_word_format() {
        // Valid word
        let result = validate_word_format("test");
        assert(result.is_ok(), 'valid word should pass');

        // Word too long (over 31 characters)
        let long_word = "supercalifragilisticexpialidocious";
        let result = validate_word_format(long_word);
        assert(result.is_err(), 'long word should fail');
    }

    #[test]
    fn test_batch_add_words() {
        let (world, _, _, _, _) = helpers::setup_core();

        let words = array![
            WordDefinition {
                word: "sword",
                token_type: TokenType::Noun,
                n_value: 2001,
                metadata: default_metadata(),
            },
            WordDefinition {
                word: "shield",
                token_type: TokenType::Noun,
                n_value: 2002,
                metadata: default_metadata(),
            },
        ];

        let result = batch_add_words(world, words);
        assert(result.is_ok(), 'batch add should succeed');

        // Verify words were added
        assert(word_exists(world, "sword"), 'sword should exist');
        assert(word_exists(world, "shield"), 'shield should exist');
    }

    #[test]
    fn test_suggest_classification() {
        let suggestions = suggest_classification("unknown");
        assert(suggestions.len() > 0, 'should have suggestions');

        let first = suggestions.at(0);
        assert(first.confidence > 0, 'should have confidence score');
    }

    #[test]
    fn test_classify_word_with_confidence() {
        let (world, _, _, _, _) = helpers::setup_core();

        // Known word
        let classification = classify_word_with_confidence(world, "look");
        assert(classification.token_type == TokenType::Verb, 'look is verb');
        assert(classification.confidence == 95, 'word has high confidence');

        // Unknown word
        let classification = classify_word_with_confidence(world, "nonexistent");
        assert(classification.confidence < 95, 'word has lower confidence');
    }
}
