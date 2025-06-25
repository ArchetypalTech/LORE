//! Shinigami Layer 1: Helpers - Input validation and sanitization
//! 
//! This module provides stateless validation functions for the LORE game engine.
//! All functions are pure utilities with no side effects.

use starknet::ContractAddress;

/// Custom error types for validation operations
#[derive(Drop, Serde, Debug)]
pub enum ValidationError {
    InvalidEntityInstance,
    InvalidCommandInput,
    InvalidEntityName,
    InvalidInput,
    RateLimitExceeded,
}

/// Action types for rate limiting
#[derive(Drop, Serde, Debug, PartialEq)]
pub enum ActionType {
    Move,
    Interact,
    Inspect,
    System,
    Create,
    Delete,
}

/// Result type for rate limit checking
#[derive(Drop, Serde, Debug)]
pub enum RateLimitError {
    ExceededCommandRate,
    ExceededActionRate,
    ExceededCreationRate,
}

/// Validates if an entity instance ID is valid
/// 
/// # Arguments
/// * `inst` - The entity instance ID to validate
/// 
/// # Returns
/// * `bool` - true if valid, false otherwise
pub fn validate_entity_inst(inst: u32) -> bool {
    // Entity instances must be non-zero and within reasonable bounds
    inst > 0 && inst < 0xFFFFFF // Max 24-bit entity IDs for storage efficiency
}

/// Validates and sanitizes command input from players
/// 
/// # Arguments
/// * `input` - Raw command input from player
/// 
/// # Returns
/// * `Result<ByteArray, ValidationError>` - Sanitized input or error
pub fn validate_command_input(input: ByteArray) -> Result<ByteArray, ValidationError> {
    // Check for empty input
    if input.len() == 0 {
        return Result::Err(ValidationError::InvalidCommandInput);
    }
    
    // Check for maximum command length (prevents DoS)
    if input.len() > 1000 {
        return Result::Err(ValidationError::InvalidCommandInput);
    }
    
    // Basic sanitization - remove leading/trailing whitespace
    let sanitized = sanitize_user_input(input);
    
    // Check if sanitized input is still valid
    if sanitized.len() == 0 {
        return Result::Err(ValidationError::InvalidCommandInput);
    }
    
    Result::Ok(sanitized)
}

/// Validates entity names for creation
/// 
/// # Arguments
/// * `name` - The entity name to validate
/// 
/// # Returns
/// * `Result<(), ValidationError>` - Success or validation error
pub fn validate_entity_name(name: ByteArray) -> Result<(), ValidationError> {
    // Entity names must not be empty
    if name.len() == 0 {
        return Result::Err(ValidationError::InvalidEntityName);
    }
    
    // Entity names must not be too long
    if name.len() > 100 {
        return Result::Err(ValidationError::InvalidEntityName);
    }
    
    // TODO: Add more sophisticated validation
    // - Check for invalid characters
    // - Check for reserved names
    // - Check for profanity (if needed)
    
    Result::Ok(())
}

/// Sanitizes user input by removing dangerous characters and normalizing whitespace
/// 
/// # Arguments
/// * `input` - Raw user input
/// 
/// # Returns
/// * `ByteArray` - Sanitized input
pub fn sanitize_user_input(input: ByteArray) -> ByteArray {
    // For now, we'll implement basic sanitization
    // In a full implementation, this would:
    // - Remove null bytes
    // - Normalize Unicode
    // - Trim whitespace
    // - Remove control characters
    
    // Simple implementation: just return input for now
    // TODO: Implement proper sanitization
    input
}

/// Checks rate limits for a caller and action type
/// 
/// # Arguments
/// * `caller` - The address performing the action
/// * `action` - The type of action being performed
/// 
/// # Returns
/// * `Result<(), RateLimitError>` - Success or rate limit error
pub fn check_rate_limits(caller: ContractAddress, action: ActionType) -> Result<(), RateLimitError> {
    // For now, we'll allow all actions
    // In a full implementation, this would:
    // - Track action timestamps per caller
    // - Enforce different limits per action type
    // - Use sliding window rate limiting
    
    // TODO: Implement actual rate limiting with storage
    Result::Ok(())
}

/// Validates that a value is within specified bounds
/// 
/// # Arguments
/// * `value` - The value to check
/// * `min` - Minimum allowed value
/// * `max` - Maximum allowed value
/// 
/// # Returns
/// * `bool` - true if within bounds, false otherwise
pub fn validate_range(value: u32, min: u32, max: u32) -> bool {
    value >= min && value <= max
}

/// Validates that an array length is within acceptable bounds
/// 
/// # Arguments
/// * `length` - The array length to validate
/// * `max_length` - Maximum allowed length
/// 
/// # Returns
/// * `bool` - true if valid length, false otherwise
pub fn validate_array_length(length: u32, max_length: u32) -> bool {
    length <= max_length
}

/// Validates a felt252 value for specific constraints
/// 
/// # Arguments
/// * `value` - The felt252 value to validate
/// 
/// # Returns
/// * `bool` - true if valid, false otherwise
pub fn validate_felt252(value: felt252) -> bool {
    // Basic validation - ensure it's not zero for entity references
    value != 0
}

#[cfg(test)]
mod tests {
    use super::{validate_entity_inst, validate_command_input, validate_entity_name, validate_range, validate_array_length, validate_felt252, ValidationError};
    
    #[test]
    fn test_validate_entity_inst() {
        // Valid instances
        assert!(validate_entity_inst(1));
        assert!(validate_entity_inst(1000));
        assert!(validate_entity_inst(0xFFFFFE));
        
        // Invalid instances
        assert!(!validate_entity_inst(0));
        assert!(!validate_entity_inst(0xFFFFFF));
    }
    
    #[test]
    fn test_validate_command_input() {
        // Valid input
        let valid_cmd = "look around";
        match validate_command_input(valid_cmd) {
            Result::Ok(_) => {},
            Result::Err(_) => panic!("Valid command should pass validation"),
        }
        
        // Empty input should fail
        let empty_cmd = "";
        match validate_command_input(empty_cmd) {
            Result::Ok(_) => panic!("Empty command should fail validation"),
            Result::Err(ValidationError::InvalidCommandInput) => {},
            Result::Err(_) => panic!("Wrong error type for empty command"),
        }
    }
    
    #[test]
    fn test_validate_entity_name() {
        // Valid name
        match validate_entity_name("sword") {
            Result::Ok(_) => {},
            Result::Err(_) => panic!("Valid name should pass validation"),
        }
        
        // Empty name should fail
        match validate_entity_name("") {
            Result::Ok(_) => panic!("Empty name should fail validation"),
            Result::Err(ValidationError::InvalidEntityName) => {},
            Result::Err(_) => panic!("Wrong error type for empty name"),
        }
    }
    
    #[test]
    fn test_validate_range() {
        assert!(validate_range(5, 1, 10));
        assert!(validate_range(1, 1, 10));
        assert!(validate_range(10, 1, 10));
        assert!(!validate_range(0, 1, 10));
        assert!(!validate_range(11, 1, 10));
    }
    
    #[test]
    fn test_validate_array_length() {
        assert!(validate_array_length(5, 10));
        assert!(validate_array_length(0, 10));
        assert!(validate_array_length(10, 10));
        assert!(!validate_array_length(11, 10));
    }
    
    #[test]
    fn test_validate_felt252() {
        assert!(validate_felt252(1));
        assert!(validate_felt252(0x123456));
        assert!(!validate_felt252(0));
    }
}