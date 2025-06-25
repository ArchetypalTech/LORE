# LORE Dictionary Library Specification

## Overview

The LORE Dictionary Library is a reusable, dynamic word classification system built for interactive fiction games using the Cairo/Dojo framework. It provides efficient natural language processing capabilities while maintaining the flexibility to expand vocabulary dynamically.

## Architecture

### Layered Design

The dictionary follows a layered architecture within the Shinigami framework:

```
Layer 1 (Helpers)     - Pure text processing utilities
Layer 2 (Services)    - Dictionary service with world state access  
Layer 3 (Types)       - Token types and command classifications
```

### Core Components

#### 1. Dictionary Service (Layer 2)

**Location**: `src/services/dictionary.cairo`

**Purpose**: Bridges pure text processing with world state storage

**Key Functions**:
```cairo
// Core lookup operations
fn lookup_word(world: WorldStorage, word: ByteArray) -> Option<Dict>
fn add_word(world: WorldStorage, word: ByteArray, token_type: TokenType, n_value: felt252) -> Result<(), DictionaryError>
fn batch_add_words(world: WorldStorage, words: Array<WordDefinition>) -> Result<(), DictionaryError>

// Advanced operations
fn get_semantic_group(world: WorldStorage, n_value: felt252) -> Array<ByteArray>
fn suggest_classification(word: ByteArray) -> Array<TokenClassification>
fn validate_word_format(word: ByteArray) -> Result<(), ValidationError>
```

#### 2. Enhanced Text Utils (Layer 1)

**Location**: `src/helpers/text_utils.cairo`

**Purpose**: Pure text processing functions that work with dictionary results

**Key Functions**:
```cairo
// Text normalization (pure functions)
fn normalize_text(text: ByteArray) -> ByteArray
fn clean_input(text: ByteArray) -> ByteArray
fn tokenize_command(command: ByteArray) -> Array<ByteArray>

// Classification helpers
fn classify_by_heuristics(word: @ByteArray) -> TokenType
fn get_word_confidence(word: @ByteArray, context: @CommandContext) -> u8
fn extract_compound_words(word: @ByteArray) -> Array<ByteArray>
```

#### 3. Token Types (Layer 3)

**Location**: `src/types/token_type.cairo`

Uses LORE's existing TokenType system:
```cairo
#[derive(Serde, Copy, Drop, Debug, Introspect, PartialEq)]
pub enum TokenType {
    Unknown,
    Verb,
    Direction, 
    Article,
    Preposition,
    Pronoun,
    Adjective,
    Noun,
    Quantifier,
    Interrogative,
    System,
}
```

## Data Model

### Dictionary Entry

```cairo
#[derive(Clone, Drop, Serde, Introspect, Debug)]
#[dojo::model]
pub struct Dict {
    #[key]
    pub dict_key: felt252,      // Hash of normalized word
    pub word: ByteArray,        // Original word text
    pub tokenType: TokenType,   // Grammatical classification
    pub n_value: felt252,       // Semantic grouping value
}
```

### Extended Classification

```cairo
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

#[derive(Drop, Serde, Debug)]
pub struct WordMetadata {
    pub added_by: ContractAddress,
    pub timestamp: u64,
    pub usage_count: u32,
    pub alternative_spellings: Array<ByteArray>,
}
```

## Semantic Value System

The `n_value` field groups semantically related words:

### Verbs (ActionType mapping)
- **1-50**: Movement actions (go=13, move=13, enter=7, exit=9)
- **51-100**: Interaction actions (take=25, get=25, drop=4, use=29)  
- **101-150**: Inspection actions (look=18, examine=8, read=22)
- **151-200**: Communication actions (say, tell, ask)
- **201-250**: System actions (inventory=14, help, quit)

### Directions (DirectionType mapping)
- **1**: North, **2**: South, **3**: East, **4**: West
- **5**: Up, **6**: Down, **7**: Around, **8**: Ahead/Behind

### Other Types
- **Articles**: All map to 1 (semantic equivalence)
- **Quantifiers**: Map to numeric value (one=1, two=2, all=256)
- **Prepositions**: Each has unique value for spatial relationships

## Word Management

### Adding New Words

**Process**:
1. Validate word format (length ≤ 31 chars, valid ByteArray)
2. Check for conflicts with existing words
3. Assign appropriate semantic value
4. Store in world state with metadata

**Example**:
```cairo
// Add a new verb with semantic grouping
add_word(world, "grab", TokenType::Verb, 25); // Same semantic value as "take"

// Add game-specific noun
add_word(world, "lightsaber", TokenType::Noun, 1001); // Game-specific item
```

### Conflict Resolution

**Word Reclassification**: Some words can be multiple types based on context
- "light" can be Adjective (light weight) or Noun (source of illumination)
- "run" can be Verb (to run) or Noun (a run in baseball)

**Resolution Strategy**:
1. Primary classification stored in dictionary
2. Context-aware lookup can suggest alternatives
3. Game logic determines final classification

### Batch Operations

For efficiency, support batch word additions:
```cairo
let fantasy_words = array![
    WordDefinition { word: "sword", token_type: TokenType::Noun, n_value: 2001, metadata: default_metadata() },
    WordDefinition { word: "shield", token_type: TokenType::Noun, n_value: 2002, metadata: default_metadata() },
    WordDefinition { word: "cast", token_type: TokenType::Verb, n_value: 151, metadata: default_metadata() },
];
batch_add_words(world, fantasy_words);
```

## Performance Considerations

### Lookup Optimization

1. **Felt252 Keys**: O(1) lookup using `word.to_felt252_word()`
2. **Caching**: Frequently used words cached in game state
3. **Negative Lookups**: Failed lookups cached to avoid repeated world reads

### Storage Efficiency

1. **Semantic Grouping**: Related words share n_values to reduce storage
2. **Metadata Compression**: Optional metadata only stored when needed
3. **Batch Operations**: Multiple words added in single transaction

### Gas Cost Management

- Dictionary initialization: ~200k gas for 100 core words
- Single word lookup: ~5k gas
- Word addition: ~20k gas per word
- Batch addition: ~15k gas per word (20% savings)

## Integration Patterns

### With Shinigami Helpers

```cairo
// Text processing pipeline
fn process_command(world: WorldStorage, command: ByteArray) -> Result<ParsedCommand, ParseError> {
    // Layer 1: Pure text processing
    let normalized = normalize_text(command);
    let tokens = tokenize_command(normalized);
    
    // Layer 2: Dictionary lookup
    let mut classified_tokens = ArrayTrait::new();
    for token in tokens {
        if let Option::Some(dict_entry) = lookup_word(world, token) {
            classified_tokens.append(dict_entry);
        }
    }
    
    // Layer 3: Command classification
    parse_tokens_to_command(classified_tokens)
}
```

### With Command System

```cairo
// Integration with existing command handler
fn execute_command(world: WorldStorage, player: felt252, command: ByteArray) {
    match process_command(world, command) {
        Result::Ok(parsed_cmd) => {
            // Use existing LORE command execution
            execute_parsed_command(world, player, parsed_cmd)
        },
        Result::Err(error) => {
            // Enhanced error messages with word suggestions
            provide_command_suggestions(world, command, error)
        }
    }
}
```

## Error Handling

### Dictionary Errors

```cairo
#[derive(Drop, Serde, Debug)]
pub enum DictionaryError {
    WordTooLong,           // Word exceeds 31 character limit
    WordAlreadyExists,     // Word conflicts with existing entry
    InvalidTokenType,      // Invalid token type for word
    StorageError,          // World state write failed
    BatchSizeLimit,        // Too many words in batch operation
}
```

### Recovery Strategies

1. **Graceful Degradation**: Unknown words default to heuristic classification
2. **Suggestion System**: Provide similar word suggestions on failures
3. **Logging**: Track failed lookups for dictionary improvement

## Testing Strategy

### Unit Tests

```cairo
#[test]
fn test_word_lookup() {
    let (world, _, _, _, _) = setup_core();
    let entry = lookup_word(world, "look").unwrap();
    assert(entry.tokenType == TokenType::Verb, 'look is verb');
    assert(entry.n_value == 18, 'look has correct semantic value');
}

#[test]
fn test_batch_add_words() {
    let (world, _, _, _, _) = setup_core();
    let words = array![
        WordDefinition { word: "teleport", token_type: TokenType::Verb, n_value: 250, metadata: default_metadata() }
    ];
    assert(batch_add_words(world, words).is_ok(), 'batch add should succeed');
}
```

### Integration Tests

```cairo
#[test]
fn test_command_processing_pipeline() {
    let (world, _, _, _, _) = setup_core();
    let result = process_command(world, "take the sword");
    match result {
        Result::Ok(cmd) => {
            assert(cmd.primary_verb.n_value == 25, 'take verb recognized');
            // Additional assertions...
        },
        Result::Err(_) => panic!("Command processing should succeed");
    }
}
```

## Migration from Current System

### Phase 1: Compatibility Layer

Maintain existing `dictionary.cairo` interface while adding new functionality:

```cairo
// Legacy compatibility
pub fn get_dict_entry(world: WorldStorage, word: ByteArray) -> Option<Dict> {
    lookup_word(world, word)
}

pub fn add_to_dictionary(world: WorldStorage, word: ByteArray, tokenType: TokenType, n_value: felt252) -> Result<(), Error> {
    add_word(world, word, tokenType, n_value).map_err(|e| Error::DictionaryError)
}
```

### Phase 2: Enhanced Features

Add new capabilities while maintaining backward compatibility:
- Advanced text processing functions
- Batch operations
- Metadata tracking
- Performance optimizations

### Phase 3: Full Integration

Complete integration with Shinigami architecture:
- Move all dictionary operations to services layer
- Update all text processing to use enhanced utilities
- Add comprehensive testing and documentation

## Future Extensibility

### Planned Features

1. **Multi-language Support**: Unicode text processing, language-specific rules
2. **Contextual Classification**: AI-powered word disambiguation
3. **Synonym Networks**: Semantic relationship mapping
4. **User Dictionary**: Player-specific word customizations
5. **Import/Export**: Standard formats for word list exchange

### API Stability

- **Core interfaces**: Stable across minor versions
- **Extension points**: New functionality added through optional parameters
- **Deprecation policy**: 2 version deprecation cycle for breaking changes

## Governance

### Word Addition Process

1. **Proposal**: LORE team member proposes new word
2. **Review**: Validate against existing words and classifications  
3. **Testing**: Add to test environment for validation
4. **Approval**: Team consensus required for core dictionary changes
5. **Documentation**: Update word lists and changelog

### Quality Standards

- **Accuracy**: >95% correct classification for standard English words
- **Consistency**: Semantic values follow established patterns
- **Completeness**: Core interactive fiction vocabulary well-covered
- **Performance**: Lookup operations complete in <50ms

---

**Version**: 1.0  
**Last Updated**: January 2025  
**Maintainer**: LORE Team