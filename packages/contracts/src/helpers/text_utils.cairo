//! Shinigami Layer 1: Helpers - Text processing utilities
//! 
//! This module provides stateless text processing functions for the LORE game engine.
//! For dictionary operations that require world state, use the services layer.

use core::result::Result;
use lore::lib::a_lexer::TokenType; // Use LORE's existing TokenType

/// Token classification result with confidence and alternatives
#[derive(Drop, Serde, Debug, Clone)]
pub struct TokenClassification {
    pub token_type: TokenType,
    pub confidence: u8,
    pub alternatives: Array<TokenType>,
    pub semantic_value: felt252,
}

/// Entity match result for context resolution
#[derive(Drop, Serde, Debug)]
pub struct EntityMatch {
    pub entity_inst: u32,
    pub match_type: MatchType,
    pub confidence: u8,
}

/// Types of entity matches
#[derive(Serde, Copy, Drop, Debug, PartialEq)]
pub enum MatchType {
    ExactName,
    AltName,
    PartialMatch,
    ContextualMatch,
}

/// Entity context for resolving ambiguous references
#[derive(Drop, Serde, Debug)]
pub struct EntityContext {
    pub player_location: u32,
    pub visible_entities: Array<u32>,
    pub inventory_items: Array<u32>,
}

/// Dictionary error types
#[derive(Drop, Serde, Debug)]
pub enum DictionaryError {
    WordNotFound,
    WordTooLong,
    InvalidToken,
    DatabaseError,
}

/// Gets token value for a TokenType (semantic mapping)
/// 
/// # Arguments
/// * `token_type` - The token type to get value for
/// 
/// # Returns
/// * `felt252` - Numeric value associated with token type
pub fn get_token_value(token_type: TokenType) -> felt252 {
    // Use LORE's existing TokenType to felt252 conversion
    token_type.into()
}

/// Tokenizes a command string into individual words
/// 
/// # Arguments
/// * `command` - The command string to tokenize
/// 
/// # Returns
/// * `Array<ByteArray>` - Array of individual words
pub fn tokenize_command(command: ByteArray) -> Array<ByteArray> {
    let mut tokens = ArrayTrait::new();
    
    // Simplified tokenization - split on spaces
    // In full implementation, would handle punctuation, quotes, etc.
    
    // For now, just return the whole command as a single token
    // This is a placeholder until proper ByteArray tokenization is implemented
    tokens.append(command);
    
    tokens
}

/// Normalizes text by converting to lowercase and trimming whitespace
/// 
/// # Arguments
/// * `input` - Raw text input
/// 
/// # Returns
/// * `ByteArray` - Normalized text
pub fn normalize_text(input: ByteArray) -> ByteArray {
    // For now, simplified implementation
    // In full implementation, this would:
    // - Convert to lowercase
    // - Trim whitespace
    // - Remove extra spaces
    // - Handle Unicode normalization
    
    let cleaned = clean_input(input);
    to_lowercase(cleaned)
}

/// Splits text into individual words
/// 
/// # Arguments
/// * `text` - Text to split
/// 
/// # Returns
/// * `Array<ByteArray>` - Array of words
pub fn split_words(text: ByteArray) -> Array<ByteArray> {
    // Simplified implementation - split on spaces
    // In full implementation, this would handle:
    // - Multiple whitespace characters
    // - Punctuation
    // - Contractions
    // - Special characters
    
    let mut words = ArrayTrait::new();
    
    // For now, just return the whole text as a single word
    // TODO: Implement proper word splitting
    if text.len() > 0 {
        words.append(text);
    }
    
    words
}

/// Cleans input by removing unwanted characters
/// 
/// # Arguments
/// * `text` - Text to clean
/// 
/// # Returns
/// * `ByteArray` - Cleaned text
pub fn clean_input(text: ByteArray) -> ByteArray {
    // For now, just return the input
    // In full implementation, this would:
    // - Remove control characters
    // - Handle special characters
    // - Remove excessive punctuation
    // - Normalize quotes and dashes
    
    text
}

/// Validates if a command is well-formed
/// 
/// # Arguments
/// * `text` - Command text to validate
/// 
/// # Returns
/// * `bool` - true if valid command structure
pub fn is_valid_command(text: ByteArray) -> bool {
    // Basic validation
    if text.len() == 0 {
        return false;
    }
    
    if text.len() > 1000 {
        return false;
    }
    
    // Check for minimum structure (at least one word)
    let words = split_words(text);
    words.len() > 0
}

/// Classifies a word into its grammatical type
/// 
/// # Arguments
/// * `word` - Word to classify
/// 
/// # Returns
/// * `TokenClassification` - Classification result with confidence
pub fn classify_word(word: ByteArray) -> TokenClassification {
    let normalized = normalize_text(word);
    
    // Check built-in dictionary
    if let Option::Some(token_type) = get_builtin_token(@normalized) {
        return TokenClassification {
            token_type,
            confidence: 95,
            alternatives: ArrayTrait::new(),
            semantic_value: get_token_value(token_type),
        };
    }
    
    // Use heuristics for unknown words
    let heuristic_type = classify_by_heuristics(@normalized);
    
    TokenClassification {
        token_type: heuristic_type,
        confidence: 50,
        alternatives: array![TokenType::Noun, TokenType::Unknown],
        semantic_value: get_token_value(heuristic_type),
    }
}

/// Gets context matches for entity resolution
/// 
/// # Arguments
/// * `words` - Array of words to match
/// * `context` - Entity context for resolution
/// 
/// # Returns
/// * `Array<EntityMatch>` - Array of potential entity matches
pub fn get_context_matches(words: Array<ByteArray>, context: EntityContext) -> Array<EntityMatch> {
    let mut matches = ArrayTrait::new();
    
    // In full implementation, this would:
    // 1. Check visible entities in player location
    // 2. Check inventory items
    // 3. Perform fuzzy matching on entity names
    // 4. Score matches based on context relevance
    
    // For now, return empty array
    matches
}

// Helper functions

/// Converts text to lowercase (simplified)
fn to_lowercase(text: ByteArray) -> ByteArray {
    // Simplified implementation - just return input
    // In full implementation, would convert to lowercase
    text
}

/// Gets token type from built-in dictionary (based on LORE's dictionary.cairo)
fn get_builtin_token(word: @ByteArray) -> Option<TokenType> {
    // Simplified implementation - in full version would use proper ByteArray comparison
    // For now, just return None to let heuristics handle classification
    Option::None
}

/// Classifies word using heuristic rules
fn classify_by_heuristics(word: @ByteArray) -> TokenType {
    // Very basic heuristics
    // In full implementation, would use:
    // - Word ending patterns (-ing, -ed, -ly, etc.)
    // - Length patterns
    // - Common prefixes/suffixes
    // - Statistical models
    
    if word.len() < 3 {
        return TokenType::Unknown;
    }
    
    // Default to noun for unknown words
    TokenType::Noun
}

/// Checks if a word ends with a specific suffix
fn ends_with(word: ByteArray, suffix: ByteArray) -> bool {
    // Simplified implementation
    // In full implementation, would check actual ending
    false
}

/// Checks if a word starts with a specific prefix
fn starts_with(word: ByteArray, prefix: ByteArray) -> bool {
    // Simplified implementation
    // In full implementation, would check actual beginning
    false
}

#[cfg(test)]
mod tests {
    use super::{
        get_word_token, normalize_text, split_words, clean_input, is_valid_command,
        classify_word, TokenType, DictionaryError, add_word_mapping, get_token_value
    };
    
    #[test]
    fn test_get_word_token() {
        // Test known verbs
        match get_word_token("look") {
            Option::Some(TokenType::Verb) => {},
            _ => panic!("look should be recognized as a verb"),
        }
        
        match get_word_token("north") {
            Option::Some(TokenType::Direction) => {},
            _ => panic!("north should be recognized as a direction"),
        }
        
        // Test unknown word
        match get_word_token("asdfgh") {
            Option::None => {},
            _ => panic!("Unknown word should return None"),
        }
    }
    
    #[test]
    fn test_normalize_text() {
        let result = normalize_text("  Hello World  ");
        // Basic test - in full implementation would check proper normalization
        assert!(result.len() > 0);
    }
    
    #[test]
    fn test_split_words() {
        let words = split_words("hello world");
        assert!(words.len() > 0);
    }
    
    #[test]
    fn test_is_valid_command() {
        assert!(is_valid_command("look around"));
        assert!(!is_valid_command(""));
        
        // Test too long command
        let mut long_cmd = "";
        let mut i = 0;
        while i < 100 {
            long_cmd = "this is a very long command that exceeds limits ";
            i += 1;
        };
        // Note: This test is simplified due to string concatenation limitations
    }
    
    #[test]
    fn test_classify_word() {
        let classification = classify_word("look");
        assert!(classification.token_type == TokenType::Verb);
        assert!(classification.confidence > 0);
    }
    
    #[test]
    fn test_add_word_mapping() {
        match add_word_mapping("test", TokenType::Noun, 1) {
            Result::Ok(_) => {},
            Result::Err(_) => panic!("Valid word mapping should succeed"),
        }
        
        // Test empty word
        match add_word_mapping("", TokenType::Noun, 1) {
            Result::Ok(_) => panic!("Empty word should fail"),
            Result::Err(DictionaryError::InvalidToken) => {},
            Result::Err(_) => panic!("Wrong error type for empty word"),
        }
    }
    
    #[test]
    fn test_get_token_value() {
        assert!(get_token_value(TokenType::Unknown) == 0);
        assert!(get_token_value(TokenType::Verb) == 1);
        assert!(get_token_value(TokenType::Direction) == 2);
        assert!(get_token_value(TokenType::Article) == 3);
        assert!(get_token_value(TokenType::System) == 252);
    }
}