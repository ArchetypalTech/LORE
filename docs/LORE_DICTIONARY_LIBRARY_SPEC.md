# LORE Dictionary Library - Technical Specification
# Component-Based Dojo Library for Interactive Fiction

**Document Version:** 1.0
**Date:** 2025-06-25
**Status:** Implementation Ready
**Project Type:** Standalone Dojo Library Package

---

## Overview

The LORE Dictionary Library is a reusable Dojo library that provides natural language processing components for interactive fiction games. Following the Arcade achievement library pattern, this library exposes **components** (business logic) that consuming projects can integrate into their own systems, rather than providing standalone systems.

**Key Design Principle:** Pure library approach - no systems layer, only composable components that integrate seamlessly into consuming projects' own system architectures.

---

## Project Architecture

### Project Structure
```
lore-dictionary/
├── Scarb.toml                    # Library configuration & dependencies
├── README.md                     # Integration guide & examples
├── src/
│   ├── lib.cairo                 # Main library exports
│   ├── models/                   # Dojo models for dictionary data
│   │   ├── dict.cairo            # Core dictionary entry model
│   │   ├── semantic_group.cairo  # Semantic value groupings
│   │   └── word_metadata.cairo   # Extended word information
│   ├── components/               # Business logic - THE CORE VALUE
│   │   ├── dictionary_service.cairo    # Main dictionary operations component
│   │   ├── lookup_engine.cairo         # Core lookup & classification component
│   │   ├── batch_processor.cairo       # Bulk operations component
│   │   └── text_analyzer.cairo         # Advanced text processing component
│   ├── helpers/                  # Pure utility functions
│   │   ├── text_utils.cairo      # Text normalization & parsing
│   │   ├── classification.cairo  # Word type classification
│   │   └── validation.cairo      # Input validation
│   └── types/                    # Type definitions
│       ├── token_type.cairo      # TokenType enum & related
│       ├── errors.cairo          # Error type definitions
│       └── events.cairo          # Event definitions
├── examples/                     # Integration examples
│   ├── basic_usage.cairo         # Simple lookup example
│   ├── game_integration.cairo    # Full game integration
│   └── custom_vocabulary.cairo   # Extending with game words
└── tests/                        # Comprehensive test suite
    ├── unit/                     # Unit tests for each module
    ├── integration/              # Cross-module tests
    └── fixtures/                 # Test data & mocks
```

### Library Configuration (`Scarb.toml`)
```toml
[package]
name = "lore_dictionary"
version = "0.0.1"
edition = "2023_11"

[lib]

[dependencies]
dojo = "1.5.0"

[dev-dependencies]
dojo_cairo_test = "1.5.0"
cairo_test = "2.10.1"

[[target.dojo]]
build-external-contracts = ["lore_dictionary::models::*"]
```

---

## Layer 1: Types Layer (`src/types/`)

### Purpose
Shared type definitions, enums, and constants that form the foundation of the library.

### Module: `types/token_type.cairo`

**Purpose:** Core grammatical classification system for interactive fiction

**Public Types:**
```cairo
#[derive(Serde, Copy, Drop, Debug, Introspect, PartialEq)]
pub enum TokenType {
    Unknown,      // Unclassified words
    Verb,         // Action words (go, take, look)
    Direction,    // Movement directions (north, up, out)
    Article,      // Articles (the, a, an)
    Preposition,  // Spatial relations (in, on, under)
    Pronoun,      // References (it, this, that)
    Adjective,    // Descriptors (red, heavy, small)
    Noun,         // Objects and entities (sword, door, key)
    Quantifier,   // Amounts (one, two, all, some)
    Interrogative,// Question words (what, where, how)
    System,       // Game commands (inventory, help, quit)
}

#[derive(Drop, Serde, Debug)]
pub struct TokenClassification {
    pub token_type: TokenType,
    pub confidence: u8,         // 0-100 confidence score
    pub alternatives: Array<TokenType>,
    pub semantic_value: felt252,
}

#[derive(Drop, Serde, Debug)]
pub struct WordDefinition {
    pub word: ByteArray,
    pub token_type: TokenType,
    pub n_value: felt252,
    pub metadata: WordMetadata,
}
```

**Public Functions:**
```cairo
pub fn token_type_to_string(token_type: TokenType) -> ByteArray
pub fn string_to_token_type(token_str: ByteArray) -> Option<TokenType>
pub fn get_default_semantic_value(token_type: TokenType) -> felt252
```

### Module: `types/errors.cairo`

**Purpose:** Comprehensive error handling for all library operations

**Public Types:**
```cairo
#[derive(Drop, Serde, Debug)]
pub enum DictionaryError {
    WordTooLong,           // Word exceeds 31 character limit
    WordAlreadyExists,     // Word conflicts with existing entry
    InvalidTokenType,      // Invalid token type for word
    StorageError,          // World state write failed
    BatchSizeLimit,        // Too many words in batch operation
    ValidationFailed,      // Input validation failed
    ClassificationFailed,  // Unable to classify word
    SemanticValueConflict, // Conflicting semantic values
}

#[derive(Drop, Serde, Debug)]
pub enum LookupError {
    WordNotFound,
    InvalidInput,
    StorageReadFailed,
    ContextMismatch,
}

#[derive(Drop, Serde, Debug)]
pub enum ValidationError {
    EmptyInput,
    InvalidCharacters,
    ExceedsLength,
    InvalidFormat,
}
```

### Module: `types/events.cairo`

**Purpose:** Event definitions for dictionary operations

**Public Types:**
```cairo
#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct WordAdded {
    #[key]
    pub word_hash: felt252,
    pub word: ByteArray,
    pub token_type: TokenType,
    pub n_value: felt252,
    pub added_by: ContractAddress,
    pub timestamp: u64,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct WordLookup {
    #[key]
    pub requester: ContractAddress,
    pub word: ByteArray,
    pub found: bool,
    pub token_type: TokenType,
    pub timestamp: u64,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct BatchProcessed {
    #[key]
    pub batch_id: felt252,
    pub words_processed: u32,
    pub successful: u32,
    pub failed: u32,
    pub processed_by: ContractAddress,
    pub timestamp: u64,
}
```

---

## Layer 2: Models Layer (`src/models/`)

### Purpose
Dojo models for persistent dictionary data storage. These models integrate into consuming projects' worlds.

### Module: `models/dict.cairo`

**Purpose:** Core dictionary entry persistence

**Dojo Model:**
```cairo
#[derive(Clone, Drop, Serde, Introspect, Debug)]
#[dojo::model]
pub struct Dict {
    #[key]
    pub dict_key: felt252,        // Hash of normalized word (primary key)
    pub word: ByteArray,          // Original word text
    pub token_type: TokenType,    // Grammatical classification
    pub n_value: felt252,         // Semantic grouping value
    pub confidence: u8,           // Classification confidence (0-100)
    pub usage_count: u32,         // Number of times looked up
    pub created_at: u64,          // Creation timestamp
    pub modified_at: u64,         // Last modification timestamp
}
```

**Storage Functions:**
```cairo
pub fn get_dict_entry(world: WorldStorage, dict_key: felt252) -> Option<Dict>
pub fn set_dict_entry(world: WorldStorage, entry: Dict)
pub fn delete_dict_entry(world: WorldStorage, dict_key: felt252)
pub fn increment_usage_count(world: WorldStorage, dict_key: felt252)
```

### Module: `models/semantic_group.cairo`

**Purpose:** Semantic value grouping information

**Dojo Model:**
```cairo
#[derive(Clone, Drop, Serde, Introspect, Debug)]
#[dojo::model]
pub struct SemanticGroup {
    #[key]
    pub n_value: felt252,         // Semantic value (primary key)
    pub group_name: ByteArray,    // Human-readable group name
    pub description: ByteArray,   // Group description
    pub token_type: TokenType,    // Primary token type for this group
    pub word_count: u32,          // Number of words in group
    pub is_core_group: bool,      // Whether this is a core/system group
    pub created_at: u64,          // Creation timestamp
}
```

**Storage Functions:**
```cairo
pub fn get_semantic_group(world: WorldStorage, n_value: felt252) -> Option<SemanticGroup>
pub fn set_semantic_group(world: WorldStorage, group: SemanticGroup)
pub fn get_groups_by_token_type(world: WorldStorage, token_type: TokenType) -> Array<SemanticGroup>
pub fn increment_word_count(world: WorldStorage, n_value: felt252)
pub fn decrement_word_count(world: WorldStorage, n_value: felt252)
```

### Module: `models/word_metadata.cairo`

**Purpose:** Extended word information and statistics

**Dojo Model:**
```cairo
#[derive(Clone, Drop, Serde, Introspect, Debug)]
#[dojo::model]
pub struct WordMetadata {
    #[key]
    pub dict_key: felt252,            // Links to Dict model
    pub alternative_spellings: Array<ByteArray>,
    pub synonyms: Array<felt252>,     // Dict keys of synonymous words
    pub context_hints: Array<ByteArray>,
    pub added_by: ContractAddress,    // Who added this word
    pub last_used: u64,               // Last lookup timestamp
    pub popularity_score: u32,        // Derived popularity metric
    pub is_game_specific: bool,       // Whether word is game-specific
    pub source: ByteArray,            // Source (core, user, import)
}
```

---

## Layer 3: Helpers Layer (`src/helpers/`)

### Purpose
Pure utility functions with no state dependencies. Highly testable and reusable.

### Module: `helpers/text_utils.cairo`

**Purpose:** Text processing and normalization utilities

**Dependencies:** None

**Public Functions:**
```cairo
// Text normalization
pub fn normalize_text(text: ByteArray) -> ByteArray
pub fn clean_input(text: ByteArray) -> ByteArray
pub fn tokenize_input(text: ByteArray) -> Array<ByteArray>
pub fn extract_words(text: ByteArray) -> Array<ByteArray>

// Hash and key generation
pub fn calculate_word_hash(word: ByteArray) -> felt252
pub fn to_felt252_word(word: ByteArray) -> felt252

// Text analysis
pub fn calculate_similarity(word1: ByteArray, word2: ByteArray) -> u8
pub fn get_word_length(word: ByteArray) -> u32
pub fn is_valid_word(word: ByteArray) -> bool
pub fn extract_root_word(word: ByteArray) -> ByteArray

// Formatting
pub fn capitalize_word(word: ByteArray) -> ByteArray
pub fn to_lowercase(word: ByteArray) -> ByteArray
pub fn trim_whitespace(text: ByteArray) -> ByteArray
```

**Error Handling:** Returns `ValidationError` for invalid inputs, never panics

### Module: `helpers/classification.cairo`

**Purpose:** Word classification heuristics and confidence scoring

**Dependencies:** `types/token_type`

**Public Functions:**
```cairo
// Classification heuristics
pub fn classify_by_heuristics(word: ByteArray) -> TokenType
pub fn get_classification_confidence(word: ByteArray, token_type: TokenType) -> u8
pub fn suggest_alternative_types(word: ByteArray) -> Array<TokenType>

// Semantic value assignment
pub fn suggest_semantic_value(word: ByteArray, token_type: TokenType) -> felt252
pub fn validate_semantic_assignment(token_type: TokenType, n_value: felt252) -> bool

// Pattern matching
pub fn matches_verb_pattern(word: ByteArray) -> bool
pub fn matches_direction_pattern(word: ByteArray) -> bool
pub fn matches_noun_pattern(word: ByteArray) -> bool
pub fn has_article_characteristics(word: ByteArray) -> bool

// Confidence calculations
pub fn calculate_pattern_confidence(word: ByteArray, token_type: TokenType) -> u8
pub fn adjust_confidence_by_length(base_confidence: u8, word_length: u32) -> u8
```

### Module: `helpers/validation.cairo`

**Purpose:** Input validation and sanitization

**Dependencies:** None

**Public Functions:**
```cairo
// Input validation
pub fn validate_word_format(word: ByteArray) -> Result<(), ValidationError>
pub fn validate_token_type(token_type: TokenType) -> Result<(), ValidationError>
pub fn validate_semantic_value(n_value: felt252) -> Result<(), ValidationError>
pub fn validate_batch_size(batch_size: u32) -> Result<(), ValidationError>

// Sanitization
pub fn sanitize_word_input(word: ByteArray) -> ByteArray
pub fn sanitize_batch_input(words: Array<ByteArray>) -> Array<ByteArray>

// Constraint checking
pub fn check_word_length_limits(word: ByteArray) -> bool
pub fn check_character_whitelist(word: ByteArray) -> bool
pub fn check_semantic_value_range(n_value: felt252, token_type: TokenType) -> bool

// Preprocessing
pub fn preprocess_for_storage(word: ByteArray) -> Result<ByteArray, ValidationError>
pub fn preprocess_for_lookup(word: ByteArray) -> Result<ByteArray, ValidationError>
```

---

## Layer 4: Components Layer (`src/components/`)

### Purpose
Business logic orchestration - the core value proposition of the library. These components are what consuming projects primarily use.

### Module: `components/dictionary_service.cairo`

**Purpose:** Main dictionary operations component - primary interface for consuming projects

**Dependencies:** `models/dict`, `helpers/text_utils`, `helpers/validation`, `types/*`

**Public Functions:**
```cairo
// Core lookup operations
pub fn lookup_word(world: WorldStorage, word: ByteArray) -> Option<Dict>
pub fn lookup_multiple_words(world: WorldStorage, words: Array<ByteArray>) -> Array<Option<Dict>>
pub fn lookup_with_fallback(world: WorldStorage, word: ByteArray) -> LookupResult

// Word management
pub fn add_word(world: WorldStorage, word: ByteArray, token_type: TokenType, n_value: felt252) -> Result<(), DictionaryError>
pub fn update_word(world: WorldStorage, dict_key: felt252, token_type: TokenType, n_value: felt252) -> Result<(), DictionaryError>
pub fn remove_word(world: WorldStorage, dict_key: felt252) -> Result<(), DictionaryError>

// Batch operations
pub fn batch_add_words(world: WorldStorage, words: Array<WordDefinition>) -> Result<BatchResult, DictionaryError>
pub fn batch_update_words(world: WorldStorage, updates: Array<WordUpdate>) -> Result<BatchResult, DictionaryError>

// Query operations
pub fn get_words_by_type(world: WorldStorage, token_type: TokenType) -> Array<Dict>
pub fn get_words_by_semantic_value(world: WorldStorage, n_value: felt252) -> Array<Dict>
pub fn get_word_count(world: WorldStorage) -> u32
pub fn get_word_statistics(world: WorldStorage) -> DictionaryStats
```

**Data Structures:**
```cairo
pub struct LookupResult {
    pub found: bool,
    pub entry: Option<Dict>,
    pub suggestions: Array<Dict>,
    pub confidence: u8,
}

pub struct BatchResult {
    pub total_processed: u32,
    pub successful: u32,
    pub failed: u32,
    pub error_details: Array<(u32, DictionaryError)>,
}

pub struct WordUpdate {
    pub dict_key: felt252,
    pub new_token_type: Option<TokenType>,
    pub new_n_value: Option<felt252>,
    pub new_confidence: Option<u8>,
}

pub struct DictionaryStats {
    pub total_words: u32,
    pub words_by_type: Array<(TokenType, u32)>,
    pub most_popular_words: Array<Dict>,
    pub recent_additions: Array<Dict>,
}
```

### Module: `components/lookup_engine.cairo`

**Purpose:** Advanced search and classification engine

**Dependencies:** `models/*`, `helpers/*`, `components/dictionary_service`

**Public Functions:**
```cairo
// Advanced search
pub fn fuzzy_search(world: WorldStorage, partial_word: ByteArray, limit: u32) -> Array<Dict>
pub fn phonetic_search(world: WorldStorage, sound_like: ByteArray) -> Array<Dict>
pub fn semantic_search(world: WorldStorage, n_value: felt252, token_type: TokenType) -> Array<Dict>

// Context-aware lookup
pub fn lookup_with_context(world: WorldStorage, word: ByteArray, context: GameContext) -> ContextualLookupResult
pub fn resolve_ambiguity(world: WorldStorage, word: ByteArray, context_clues: Array<ByteArray>) -> Array<Dict>
pub fn get_context_suggestions(world: WorldStorage, partial: ByteArray, context: GameContext) -> Array<Dict>

// Classification and suggestion
pub fn classify_unknown_word(world: WorldStorage, word: ByteArray) -> TokenClassification
pub fn suggest_corrections(world: WorldStorage, misspelled: ByteArray) -> Array<Dict>
pub fn get_completion_suggestions(world: WorldStorage, prefix: ByteArray, max_suggestions: u32) -> Array<ByteArray>

// Performance optimization
pub fn warm_cache(world: WorldStorage, frequently_used: Array<ByteArray>)
pub fn preload_semantic_group(world: WorldStorage, n_value: felt252)
pub fn optimize_lookup_order(words: Array<ByteArray>) -> Array<ByteArray>
```

**Data Structures:**
```cairo
pub struct GameContext {
    pub player_location: u32,
    pub visible_entities: Array<u32>,
    pub inventory_items: Array<u32>,
    pub recent_actions: Array<ByteArray>,
    pub game_state: felt252,
}

pub struct ContextualLookupResult {
    pub primary_match: Option<Dict>,
    pub contextual_matches: Array<(Dict, u8)>, // (entry, context_score)
    pub disambiguation_needed: bool,
    pub context_suggestions: Array<ByteArray>,
}

pub struct FuzzySearchOptions {
    pub max_edit_distance: u8,
    pub min_similarity_score: u8,
    pub prefer_common_words: bool,
    pub include_semantic_matches: bool,
}
```

### Module: `components/batch_processor.cairo`

**Purpose:** Efficient bulk operations and data import/export

**Dependencies:** `components/dictionary_service`, `helpers/validation`

**Public Functions:**
```cairo
// Batch validation
pub fn validate_batch(words: Array<WordDefinition>) -> ValidationResult
pub fn preview_batch_conflicts(world: WorldStorage, words: Array<WordDefinition>) -> ConflictReport
pub fn estimate_batch_gas_cost(words: Array<WordDefinition>) -> u32

// Batch processing
pub fn process_batch_with_options(world: WorldStorage, words: Array<WordDefinition>, options: BatchOptions) -> BatchResult
pub fn process_incremental_batch(world: WorldStorage, words: Array<WordDefinition>, chunk_size: u32) -> IncrementalBatchResult
pub fn resume_failed_batch(world: WorldStorage, batch_id: felt252) -> BatchResult

// Data import/export
pub fn import_from_standard_format(world: WorldStorage, data: ByteArray, format: ImportFormat) -> Result<BatchResult, DictionaryError>
pub fn export_to_standard_format(world: WorldStorage, filter: ExportFilter, format: ExportFormat) -> ByteArray
pub fn create_vocabulary_backup(world: WorldStorage) -> ByteArray
pub fn restore_from_backup(world: WorldStorage, backup_data: ByteArray) -> Result<RestoreResult, DictionaryError>

// Conflict resolution
pub fn handle_word_conflicts(existing: Dict, incoming: WordDefinition, strategy: ConflictStrategy) -> ConflictResolution
pub fn merge_vocabularies(world: WorldStorage, external_vocab: Array<WordDefinition>, merge_strategy: MergeStrategy) -> MergeResult
```

**Data Structures:**
```cairo
pub struct BatchOptions {
    pub allow_duplicates: bool,
    pub overwrite_existing: bool,
    pub validate_semantics: bool,
    pub emit_events: bool,
    pub chunk_size: u32,
}

pub struct ConflictReport {
    pub total_conflicts: u32,
    pub duplicate_words: Array<ByteArray>,
    pub semantic_conflicts: Array<(ByteArray, felt252, felt252)>,
    pub type_conflicts: Array<(ByteArray, TokenType, TokenType)>,
}

pub enum ConflictStrategy {
    KeepExisting,
    OverwriteWithNew,
    MergeData,
    PromptUser,
}

pub struct IncrementalBatchResult {
    pub batch_id: felt252,
    pub chunks_processed: u32,
    pub chunks_remaining: u32,
    pub current_result: BatchResult,
    pub estimated_completion: u64,
}
```

### Module: `components/text_analyzer.cairo`

**Purpose:** Advanced text processing and linguistic analysis

**Dependencies:** `helpers/text_utils`, `helpers/classification`, `models/*`

**Public Functions:**
```cairo
// Text analysis
pub fn analyze_command_structure(world: WorldStorage, command: ByteArray) -> CommandAnalysis
pub fn extract_entities_from_text(world: WorldStorage, text: ByteArray) -> Array<EntityReference>
pub fn identify_intent(world: WorldStorage, command: ByteArray) -> IntentClassification

// Linguistic processing
pub fn detect_language_patterns(text: ByteArray) -> LanguagePatterns
pub fn extract_grammar_structure(words: Array<Dict>) -> GrammarStructure
pub fn suggest_sentence_improvements(world: WorldStorage, command: ByteArray) -> Array<ByteArray>

// Contextual understanding
pub fn build_semantic_network(world: WorldStorage, words: Array<ByteArray>) -> SemanticNetwork
pub fn find_semantic_relationships(world: WorldStorage, word1: ByteArray, word2: ByteArray) -> RelationshipType
pub fn generate_contextual_help(world: WorldStorage, partial_command: ByteArray) -> HelpSuggestions

// Learning and adaptation
pub fn update_usage_patterns(world: WorldStorage, command: ByteArray, success: bool)
pub fn learn_from_corrections(world: WorldStorage, original: ByteArray, corrected: ByteArray)
pub fn adapt_to_user_vocabulary(world: WorldStorage, user_commands: Array<ByteArray>)
```

**Data Structures:**
```cairo
pub struct CommandAnalysis {
    pub verb: Option<Dict>,
    pub direct_object: Option<Dict>,
    pub indirect_object: Option<Dict>,
    pub prepositions: Array<Dict>,
    pub adjectives: Array<Dict>,
    pub confidence: u8,
    pub ambiguities: Array<Ambiguity>,
}

pub struct EntityReference {
    pub word: ByteArray,
    pub entity_type: EntityType,
    pub reference_type: ReferenceType,
    pub confidence: u8,
}

pub enum IntentClassification {
    Movement(DirectionType),
    Interaction(InteractionType),
    Inspection(InspectionType),
    System(SystemType),
    Unknown,
}

pub struct SemanticNetwork {
    pub nodes: Array<SemanticNode>,
    pub connections: Array<SemanticConnection>,
    pub clusters: Array<SemanticCluster>,
}
```

---

## Integration Patterns

### Basic Usage Pattern (Most Common)
```cairo
// In a consuming project's system (e.g., LORE's prompt.cairo)
use lore_dictionary::components::dictionary_service;
use lore_dictionary::helpers::text_utils;
use lore_dictionary::types::{TokenType, DictionaryError};

#[dojo::contract]
mod prompt {
    use super::{dictionary_service, text_utils, TokenType};

    #[external(v0)]
    fn prompt(ref self: ContractState, cmd: ByteArray) {
        let mut world = self.world(@"namespace");

        // Step 1: Normalize and tokenize input
        let normalized = text_utils::normalize_text(cmd);
        let tokens = text_utils::tokenize_input(normalized);

        // Step 2: Look up each token in dictionary
        let mut classified_tokens = ArrayTrait::new();
        for token in tokens {
            if let Option::Some(dict_entry) = dictionary_service::lookup_word(world, token) {
                classified_tokens.append(dict_entry);
            } else {
                // Handle unknown words with fallback classification
                let classification = helpers::classification::classify_by_heuristics(token);
                // Optionally add to dictionary for future use
                let _ = dictionary_service::add_word(world, token, classification, 0);
            }
        }

        // Step 3: Continue with game-specific command processing
        process_classified_tokens(classified_tokens);
    }
}
```

### Advanced Usage Pattern (With Context)
```cairo
// Using advanced lookup engine with game context
use lore_dictionary::components::{dictionary_service, lookup_engine};
use lore_dictionary::types::GameContext;

fn process_contextual_command(world: WorldStorage, player_inst: u32, cmd: ByteArray) {
    // Build game context
    let context = GameContext {
        player_location: get_player_location(player_inst),
        visible_entities: get_visible_entities(player_inst),
        inventory_items: get_inventory_items(player_inst),
        recent_actions: get_recent_actions(player_inst),
        game_state: get_current_game_state(),
    };

    // Perform context-aware lookup
    let tokens = text_utils::tokenize_input(cmd);
    for token in tokens {
        let result = lookup_engine::lookup_with_context(world, token, context);
        if result.disambiguation_needed {
            // Handle ambiguous references
            handle_disambiguation(result.contextual_matches);
        }
    }
}
```

### Initialization Pattern
```cairo
// Setting up dictionary for a new game
use lore_dictionary::components::{dictionary_service, batch_processor};

fn initialize_game_dictionary(world: WorldStorage) {
    // Load core interactive fiction vocabulary
    let core_words = get_core_if_vocabulary();
    let _ = batch_processor::process_batch_with_options(
        world,
        core_words,
        BatchOptions {
            allow_duplicates: false,
            overwrite_existing: false,
            validate_semantics: true,
            emit_events: true,
            chunk_size: 50,
        }
    );

    // Add game-specific vocabulary
    let game_words = get_game_specific_vocabulary();
    let _ = dictionary_service::batch_add_words(world, game_words);
}
```

### Extension Pattern (Adding Game-Specific Words)
```cairo
// Extending dictionary with game-specific vocabulary
use lore_dictionary::types::{WordDefinition, TokenType, WordMetadata};

fn add_fantasy_vocabulary(world: WorldStorage) {
    let fantasy_words = array![
        WordDefinition {
            word: "lightsaber",
            token_type: TokenType::Noun,
            n_value: 2001, // Game-specific item range
            metadata: WordMetadata {
                alternative_spellings: array!["light-saber", "light saber"],
                synonyms: array![],
                context_hints: array!["weapon", "jedi", "force"],
                added_by: get_caller_address(),
                last_used: 0,
                popularity_score: 0,
                is_game_specific: true,
                source: "game_content",
            }
        },
        // Additional game words...
    ];

    let result = dictionary_service::batch_add_words(world, fantasy_words);
    assert!(result.is_ok(), "Failed to add fantasy vocabulary");
}
```

---

## Performance Considerations

### Lookup Optimization
1. **Felt252 Keys:** O(1) lookup using word hash as primary key
2. **Batch Operations:** Process multiple words in single transaction for efficiency
3. **Caching Strategy:** Frequently used words cached at component level
4. **Lazy Loading:** Semantic groups loaded on-demand

### Gas Cost Management
- **Dictionary lookup:** ~5k gas per word
- **Word addition:** ~20k gas per word
- **Batch addition:** ~15k gas per word (25% savings)
- **Complex analysis:** ~50k gas for full command analysis

### Storage Efficiency
1. **Semantic Grouping:** Related words share n_values to reduce redundancy
2. **Metadata Separation:** Optional metadata in separate model
3. **Compressed Events:** Minimal event data for indexing

---

## Testing Strategy

### Unit Tests (`tests/unit/`)
- Test each helper function independently
- Validate model storage and retrieval
- Component behavior verification
- Error handling coverage

### Integration Tests (`tests/integration/`)
- Full lookup workflows
- Batch processing end-to-end
- Cross-component interactions
- Performance benchmarks

### Example Test Structure
```cairo
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_basic_word_lookup() {
        let (world, _, _, _, _) = setup_test_world();

        // Add test word
        let result = dictionary_service::add_word(
            world,
            "test",
            TokenType::Noun,
            1000
        );
        assert!(result.is_ok());

        // Test lookup
        let entry = dictionary_service::lookup_word(world, "test");
        assert!(entry.is_some());

        let dict = entry.unwrap();
        assert!(dict.word == "test");
        assert!(dict.token_type == TokenType::Noun);
        assert!(dict.n_value == 1000);
    }

    #[test]
    fn test_fuzzy_search() {
        let (world, _, _, _, _) = setup_test_world();
        setup_test_vocabulary(world);

        let results = lookup_engine::fuzzy_search(world, "loo", 5);
        assert!(results.len() > 0);

        // Should find "look" even with partial match
        let found_look = results.iter().any(|entry| entry.word == "look");
        assert!(found_look);
    }

    #[test]
    fn test_batch_processing() {
        let (world, _, _, _, _) = setup_test_world();

        let words = array![
            WordDefinition { /* ... */ },
            WordDefinition { /* ... */ },
        ];

        let result = batch_processor::process_batch_with_options(
            world,
            words,
            BatchOptions::default()
        );

        assert!(result.is_ok());
        let batch_result = result.unwrap();
        assert!(batch_result.successful == 2);
        assert!(batch_result.failed == 0);
    }
}
```

---

## Migration from Current System

### Phase 1: Integration Preparation
1. Add lore_dictionary to LORE's Scarb.toml dependencies
2. Create wrapper functions that map current dictionary calls to new components
3. Run parallel systems to validate compatibility

### Phase 2: Gradual Migration
1. Replace text processing utilities first (lowest risk)
2. Migrate lookup operations using compatibility layer
3. Update batch operations and advanced features
4. Remove legacy dictionary code

### Phase 3: Optimization
1. Remove compatibility wrappers
2. Optimize for LORE's specific usage patterns
3. Add LORE-specific extensions
4. Performance tuning and gas optimization

---

## Semantic Value System

The library maintains compatibility with LORE's existing semantic value system:

### Verb Categories (ActionType mapping)
- **1-50:** Movement actions (go=13, move=13, enter=7, exit=9)
- **51-100:** Interaction actions (take=25, get=25, drop=4, use=29)
- **101-150:** Inspection actions (look=18, examine=8, read=22)
- **151-200:** Communication actions (say, tell, ask)
- **201-250:** System actions (inventory=14, help, quit)

### Direction Categories (DirectionType mapping)
- **1:** North, **2:** South, **3:** East, **4:** West
- **5:** Up, **6:** Down, **7:** Around, **8:** Ahead/Behind

### Extension Ranges
- **1000-1999:** Game-specific nouns
- **2000-2999:** Game-specific items
- **3000-3999:** Game-specific locations
- **4000+:** User-defined categories

---

## Success Criteria

### Functional Requirements
- [ ] 100% compatibility with LORE's existing dictionary interface
- [ ] Support for 10,000+ word vocabulary without performance degradation
- [ ] Sub-50ms lookup times for common words
- [ ] Comprehensive error handling with graceful degradation
- [ ] Extensible architecture for game-specific vocabularies

### Quality Requirements
- [ ] >95% test coverage across all components
- [ ] Zero breaking changes to consuming projects
- [ ] Comprehensive documentation and examples
- [ ] Performance equal or better than embedded solutions
- [ ] Memory efficient storage and caching

### Integration Requirements
- [ ] Seamless integration with existing Dojo projects
- [ ] Clear migration path from embedded dictionary solutions
- [ ] Support for multiple simultaneous consuming projects
- [ ] Backward compatibility with previous library versions

---

**This specification provides implementation-ready blueprints for a production-quality Dojo dictionary library. Every component, function, and integration pattern is defined with sufficient detail for efficient development and testing.**
