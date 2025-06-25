//! Shinigami Layer 3: Types - Command classification and routing
//! 
//! This module defines command types and parsing structures for LORE's natural language
//! command processing system, based on the existing lexer and command handler.

use core::option::OptionTrait;
use super::direction_type::DirectionType;

/// High-level command categories for routing (based on LORE's command system)
#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum CommandType {
    Movement,
    Interaction,
    Inspection,
    Inventory,
    Communication,
    System,
    Debug,
    Unknown,
}

/// Interaction command subtypes
#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum InteractionType {
    Take,
    Drop,
    Use,
    Open,
    Close,
    Enter,
    Exit,
    Push,
    Pull,
    Turn,
    Touch,
    Taste,
    Smell,
    Listen,
    Give,
    Put,
    Insert,
}

/// Inspection command subtypes
#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum InspectionType {
    Look,
    LookAt,
    Examine,
    Read,
    Search,
    Inspect,
    Check,
    Stare,
    Show,
}

/// Inventory command subtypes
#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum InventoryType {
    ShowInventory,
    Wearing,
    Equipment,
}

/// Communication command subtypes
#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum CommunicationType {
    Say,
    Tell,
    Ask,
    Yell,
    Whisper,
}

/// System command subtypes
#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum SystemType {
    Help,
    Quit,
    Save,
    Load,
    Restart,
    Score,
    Time,
    About,
    Credits,
}

/// Debug command subtypes
#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum DebugType {
    Teleport,
    Spawn,
    Delete,
    SetProperty,
    GetProperty,
    ListEntities,
    TestAction,
}

/// Command parsing parameters
#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum ParameterType {
    TargetEntity,
    Direction,
    Text,
    Number,
    Property,
    Value,
    Optional,
}

/// Error types for command parsing
#[derive(Drop, Serde, Debug)]
pub enum ParseError {
    UnknownCommand,     // Command not recognized
    MissingParameter,   // Required parameter missing
    InvalidParameter,   // Parameter format invalid
    AmbiguousTarget,    // Multiple possible targets
    NoValidTarget,      // No target found
    CommandDisabled,    // Command is disabled
    InsufficientPermissions, // Player lacks permissions
}

/// Parsed command structure
#[derive(Drop, Serde, Debug)]
pub struct ParsedCommand {
    pub command_type: CommandType,          // Type of command
    pub primary_target: Option<u32>,        // Main target entity
    pub secondary_target: Option<u32>,      // Secondary target (for "put X in Y")
    pub direction: Option<DirectionType>,   // Direction (for movement)
    pub text_parameter: ByteArray,          // Text parameter (for communication)
    pub numeric_parameter: Option<u32>,     // Numeric parameter
    pub property_name: ByteArray,           // Property name (for debug commands)
    pub confidence: u8,                     // Parsing confidence (0-100)
    pub alternatives: Array<CommandType>,   // Alternative interpretations
}

/// Player context for command validation
#[derive(Drop, Serde, Debug)]
pub struct PlayerContext {
    pub current_area: u32,              // Player's current location
    pub visible_entities: Array<u32>,   // Entities player can see
    pub inventory_items: Array<u32>,    // Items in inventory
    pub accessible_exits: Array<u32>,   // Available exits
    pub debug_mode: bool,               // Whether debug commands allowed
    pub permissions: Array<SystemType>, // System commands allowed
}

/// Parses tokens into a command type
/// 
/// # Arguments
/// * `tokens` - Array of parsed tokens from the lexer
/// 
/// # Returns
/// * `Result<CommandType, ParseError>` - Parsed command type or error
pub fn parse_command_type(tokens: Array<felt252>) -> Result<CommandType, ParseError> {
    if tokens.len() == 0 {
        return Result::Err(ParseError::UnknownCommand);
    }
    
    // In a full implementation, this would:
    // 1. Analyze the first token (verb)
    // 2. Look for direction tokens
    // 3. Classify based on verb type
    // 4. Handle multi-word commands
    
    // Simplified implementation for now
    let first_token = *tokens.at(0);
    
    // Movement commands (directions)
    if first_token == 1 || first_token == 2 || first_token == 3 || first_token == 4 ||
       first_token == 5 || first_token == 6 || first_token == 7 || first_token == 8 ||
       first_token == 9 || first_token == 10 || first_token == 11 || first_token == 12 {
        return Result::Ok(CommandType::Movement);
    }
    
    // Look commands
    if first_token == 18 {
        return Result::Ok(CommandType::Inspection);
    }
    
    // Inventory commands
    if first_token == 14 {
        return Result::Ok(CommandType::Inventory);
    }
    
    // Take commands
    if first_token == 25 {
        return Result::Ok(CommandType::Interaction);
    }
    
    Result::Err(ParseError::UnknownCommand)
}

/// Gets required parameters for a command type
/// 
/// # Arguments
/// * `command_type` - The command type
/// 
/// # Returns
/// * `Array<ParameterType>` - Required parameters
pub fn get_required_parameters(command_type: CommandType) -> Array<ParameterType> {
    match command_type {
        CommandType::Movement => array![],
        CommandType::Interaction => array![ParameterType::TargetEntity],
        CommandType::Inspection => array![],
        CommandType::Inventory => array![],
        CommandType::Communication => array![ParameterType::Text],
        CommandType::System => array![],
        CommandType::Debug => array![ParameterType::TargetEntity],
        CommandType::Unknown => array![],
    }
}

/// Validates if a command can be executed in the given context
/// 
/// # Arguments
/// * `command_type` - The command type to validate
/// * `context` - Player context for validation
/// 
/// # Returns
/// * `bool` - true if command is valid in context
pub fn validate_command_context(command_type: CommandType, context: PlayerContext) -> bool {
    match command_type {
        CommandType::Debug => context.debug_mode,
        CommandType::System => context.permissions.len() > 0,
        CommandType::Movement => context.accessible_exits.len() > 0,
        _ => true,
    }
}

/// Converts command type to string representation
/// 
/// # Arguments
/// * `command_type` - The command type to convert
/// 
/// # Returns
/// * `ByteArray` - String representation
pub fn command_type_to_string(command_type: CommandType) -> ByteArray {
    match command_type {
        CommandType::Movement => "Movement",
        CommandType::Interaction => "Interaction",
        CommandType::Inspection => "Inspection",
        CommandType::Inventory => "Inventory",
        CommandType::Communication => "Communication",
        CommandType::System => "System",
        CommandType::Debug => "Debug",
        CommandType::Unknown => "Unknown",
    }
}

/// Gets all interaction types as an array
/// 
/// # Returns
/// * `Array<InteractionType>` - Array of interaction types
pub fn get_all_interaction_types() -> Array<InteractionType> {
    array![
        InteractionType::Take,
        InteractionType::Drop,
        InteractionType::Use,
        InteractionType::Open,
        InteractionType::Close,
        InteractionType::Enter,
        InteractionType::Exit,
        InteractionType::Push,
        InteractionType::Pull,
        InteractionType::Turn,
        InteractionType::Touch,
        InteractionType::Taste,
        InteractionType::Smell,
        InteractionType::Listen,
        InteractionType::Give,
        InteractionType::Put,
        InteractionType::Insert,
    ]
}

/// Gets all inspection types as an array
/// 
/// # Returns
/// * `Array<InspectionType>` - Array of inspection types
pub fn get_all_inspection_types() -> Array<InspectionType> {
    array![
        InspectionType::Look,
        InspectionType::LookAt,
        InspectionType::Examine,
        InspectionType::Read,
        InspectionType::Search,
        InspectionType::Inspect,
        InspectionType::Check,
        InspectionType::Stare,
        InspectionType::Show,
    ]
}

/// Checks if a command type requires a target entity
/// 
/// # Arguments
/// * `command_type` - Command type to check
/// 
/// # Returns
/// * `bool` - true if target required
pub fn requires_target(command_type: CommandType) -> bool {
    let required_params = get_required_parameters(command_type);
    let mut needs_target = false;
    let mut i = 0;
    while i < required_params.len() {
        if *required_params.at(i) == ParameterType::TargetEntity {
            needs_target = true;
            break;
        }
        i += 1;
    };
    needs_target
}

#[cfg(test)]
mod tests {
    use super::{
        CommandType, InteractionType, InspectionType, InventoryType, SystemType, DebugType,
        ParameterType, ParseError, parse_command_type, get_required_parameters,
        validate_command_context, command_type_to_string, requires_target,
        PlayerContext
    };
    use super::super::direction_type::DirectionType;
    
    #[test]
    fn test_parse_command_type() {
        // Test look command
        let tokens = array![18];
        match parse_command_type(tokens) {
            Result::Ok(CommandType::Inspection) => {},
            _ => panic!("Should parse look command"),
        }
        
        // Test empty tokens
        let empty_tokens = ArrayTrait::new();
        match parse_command_type(empty_tokens) {
            Result::Err(ParseError::UnknownCommand) => {},
            _ => panic!("Empty tokens should return error"),
        }
    }
    
    #[test]
    fn test_get_required_parameters() {
        // Movement commands need no parameters
        let movement_params = get_required_parameters(CommandType::Movement);
        assert!(movement_params.len() == 0);
        
        // Interaction commands need target
        let interaction_params = get_required_parameters(CommandType::Interaction);
        assert!(interaction_params.len() == 1);
        assert!(*interaction_params.at(0) == ParameterType::TargetEntity);
    }
    
    #[test]
    fn test_validate_command_context() {
        let context = PlayerContext {
            current_area: 1,
            visible_entities: array![10, 20, 30],
            inventory_items: array![100, 200],
            accessible_exits: array![5, 6],
            debug_mode: false,
            permissions: array![SystemType::Help, SystemType::Score],
        };
        
        // Debug commands should fail without debug mode
        assert!(!validate_command_context(CommandType::Debug, context));
        
        // Movement should work with accessible exits
        assert!(validate_command_context(CommandType::Movement, context));
        
        // System commands should work if has permissions
        assert!(validate_command_context(CommandType::System, context));
    }
    
    #[test]
    fn test_command_type_to_string() {
        assert!(command_type_to_string(CommandType::Movement) == "Movement");
        assert!(command_type_to_string(CommandType::Interaction) == "Interaction");
        assert!(command_type_to_string(CommandType::Unknown) == "Unknown");
    }
    
    #[test]
    fn test_requires_target() {
        assert!(!requires_target(CommandType::Movement));
        assert!(requires_target(CommandType::Interaction));
        assert!(!requires_target(CommandType::Inventory));
    }
}