//! Shinigami Layer 3: Types - Movement and direction handling
//! 
//! This module defines direction types and related functions for the LORE game engine.
//! It provides comprehensive direction handling for 3D movement in interactive fiction.

use core::option::OptionTrait;

/// Direction enumeration for all possible movement directions
#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum DirectionType {
    North,
    South,
    East,
    West,
    Northeast,
    Northwest,
    Southeast,
    Southwest,
    Up,
    Down,
    In,
    Out,
}

/// Error types for direction operations
#[derive(Drop, Serde, Debug)]
pub enum DirectionError {
    InvalidDirection,
    ParseError,
    NoOppositeDirection,
}

/// Parses a direction from a word/string
/// 
/// # Arguments
/// * `word` - The word to parse as a direction
/// 
/// # Returns
/// * `Option<DirectionType>` - Parsed direction or None if invalid
pub fn parse_direction(word: ByteArray) -> Option<DirectionType> {
    // Convert to lowercase for consistent parsing
    let normalized = normalize_direction_word(word);
    
    // Full direction names
    if normalized == "north" {
        return Option::Some(DirectionType::North);
    }
    if normalized == "south" {
        return Option::Some(DirectionType::South);
    }
    if normalized == "east" {
        return Option::Some(DirectionType::East);
    }
    if normalized == "west" {
        return Option::Some(DirectionType::West);
    }
    if normalized == "northeast" {
        return Option::Some(DirectionType::Northeast);
    }
    if normalized == "northwest" {
        return Option::Some(DirectionType::Northwest);
    }
    if normalized == "southeast" {
        return Option::Some(DirectionType::Southeast);
    }
    if normalized == "southwest" {
        return Option::Some(DirectionType::Southwest);
    }
    if normalized == "up" {
        return Option::Some(DirectionType::Up);
    }
    if normalized == "down" {
        return Option::Some(DirectionType::Down);
    }
    if normalized == "in" {
        return Option::Some(DirectionType::In);
    }
    if normalized == "out" {
        return Option::Some(DirectionType::Out);
    }
    
    // Single letter abbreviations
    if normalized == "n" {
        return Option::Some(DirectionType::North);
    }
    if normalized == "s" {
        return Option::Some(DirectionType::South);
    }
    if normalized == "e" {
        return Option::Some(DirectionType::East);
    }
    if normalized == "w" {
        return Option::Some(DirectionType::West);
    }
    if normalized == "u" {
        return Option::Some(DirectionType::Up);
    }
    if normalized == "d" {
        return Option::Some(DirectionType::Down);
    }
    
    // Two letter abbreviations
    if normalized == "ne" {
        return Option::Some(DirectionType::Northeast);
    }
    if normalized == "nw" {
        return Option::Some(DirectionType::Northwest);
    }
    if normalized == "se" {
        return Option::Some(DirectionType::Southeast);
    }
    if normalized == "sw" {
        return Option::Some(DirectionType::Southwest);
    }
    
    Option::None
}

/// Gets the opposite direction for a given direction
/// 
/// # Arguments
/// * `direction` - The direction to get the opposite of
/// 
/// # Returns
/// * `DirectionType` - The opposite direction
pub fn get_opposite_direction(direction: DirectionType) -> DirectionType {
    match direction {
        DirectionType::North => DirectionType::South,
        DirectionType::South => DirectionType::North,
        DirectionType::East => DirectionType::West,
        DirectionType::West => DirectionType::East,
        DirectionType::Northeast => DirectionType::Southwest,
        DirectionType::Northwest => DirectionType::Southeast,
        DirectionType::Southeast => DirectionType::Northwest,
        DirectionType::Southwest => DirectionType::Northeast,
        DirectionType::Up => DirectionType::Down,
        DirectionType::Down => DirectionType::Up,
        DirectionType::In => DirectionType::Out,
        DirectionType::Out => DirectionType::In,
    }
}

/// Checks if a direction represents a valid room connection
/// In interactive fiction, some directions are conceptual rather than spatial
/// 
/// # Arguments
/// * `direction` - The direction to check
/// 
/// # Returns
/// * `bool` - true if direction can connect rooms
pub fn is_room_connection_direction(direction: DirectionType) -> bool {
    // All directions can connect rooms in interactive fiction
    // Even "in" and "out" can represent entering/exiting buildings
    true
}

/// Converts direction to human-readable string
/// 
/// # Arguments
/// * `direction` - The direction to convert
/// 
/// # Returns
/// * `ByteArray` - Human-readable direction name
pub fn direction_to_string(direction: DirectionType) -> ByteArray {
    match direction {
        DirectionType::North => "north",
        DirectionType::South => "south",
        DirectionType::East => "east",
        DirectionType::West => "west",
        DirectionType::Northeast => "northeast",
        DirectionType::Northwest => "northwest",
        DirectionType::Southeast => "southeast",
        DirectionType::Southwest => "southwest",
        DirectionType::Up => "up",
        DirectionType::Down => "down",
        DirectionType::In => "in",
        DirectionType::Out => "out",
    }
}

/// Converts direction to single letter abbreviation
/// 
/// # Arguments
/// * `direction` - The direction to convert
/// 
/// # Returns
/// * `ByteArray` - Single letter abbreviation
pub fn direction_to_abbreviation(direction: DirectionType) -> ByteArray {
    match direction {
        DirectionType::North => "n",
        DirectionType::South => "s",
        DirectionType::East => "e",
        DirectionType::West => "w",
        DirectionType::Northeast => "ne",
        DirectionType::Northwest => "nw",
        DirectionType::Southeast => "se",
        DirectionType::Southwest => "sw",
        DirectionType::Up => "u",
        DirectionType::Down => "d",
        DirectionType::In => "in",
        DirectionType::Out => "out",
    }
}

/// Converts direction to numeric value for storage
/// 
/// # Arguments
/// * `direction` - The direction to convert
/// 
/// # Returns
/// * `u8` - Numeric representation (0-11)
pub fn direction_to_u8(direction: DirectionType) -> u8 {
    match direction {
        DirectionType::North => 0,
        DirectionType::South => 1,
        DirectionType::East => 2,
        DirectionType::West => 3,
        DirectionType::Northeast => 4,
        DirectionType::Northwest => 5,
        DirectionType::Southeast => 6,
        DirectionType::Southwest => 7,
        DirectionType::Up => 8,
        DirectionType::Down => 9,
        DirectionType::In => 10,
        DirectionType::Out => 11,
    }
}

/// Converts numeric value to direction
/// 
/// # Arguments
/// * `value` - Numeric value (0-11)
/// 
/// # Returns
/// * `Option<DirectionType>` - Direction if valid, None otherwise
pub fn u8_to_direction(value: u8) -> Option<DirectionType> {
    match value {
        0 => Option::Some(DirectionType::North),
        1 => Option::Some(DirectionType::South),
        2 => Option::Some(DirectionType::East),
        3 => Option::Some(DirectionType::West),
        4 => Option::Some(DirectionType::Northeast),
        5 => Option::Some(DirectionType::Northwest),
        6 => Option::Some(DirectionType::Southeast),
        7 => Option::Some(DirectionType::Southwest),
        8 => Option::Some(DirectionType::Up),
        9 => Option::Some(DirectionType::Down),
        10 => Option::Some(DirectionType::In),
        11 => Option::Some(DirectionType::Out),
        _ => Option::None,
    }
}

/// Checks if direction is a cardinal direction (N, S, E, W)
/// 
/// # Arguments
/// * `direction` - Direction to check
/// 
/// # Returns
/// * `bool` - true if cardinal direction
pub fn is_cardinal_direction(direction: DirectionType) -> bool {
    match direction {
        DirectionType::North | DirectionType::South | DirectionType::East | DirectionType::West => true,
        _ => false,
    }
}

/// Checks if direction is a diagonal direction (NE, NW, SE, SW)
/// 
/// # Arguments
/// * `direction` - Direction to check
/// 
/// # Returns
/// * `bool` - true if diagonal direction
pub fn is_diagonal_direction(direction: DirectionType) -> bool {
    match direction {
        DirectionType::Northeast | DirectionType::Northwest | DirectionType::Southeast | DirectionType::Southwest => true,
        _ => false,
    }
}

/// Checks if direction is vertical (Up, Down)
/// 
/// # Arguments
/// * `direction` - Direction to check
/// 
/// # Returns
/// * `bool` - true if vertical direction
pub fn is_vertical_direction(direction: DirectionType) -> bool {
    match direction {
        DirectionType::Up | DirectionType::Down => true,
        _ => false,
    }
}

/// Checks if direction is special (In, Out)
/// 
/// # Arguments
/// * `direction` - Direction to check
/// 
/// # Returns
/// * `bool` - true if special direction
pub fn is_special_direction(direction: DirectionType) -> bool {
    match direction {
        DirectionType::In | DirectionType::Out => true,
        _ => false,
    }
}

/// Gets all possible directions as an array
/// 
/// # Returns
/// * `Array<DirectionType>` - Array of all directions
pub fn get_all_directions() -> Array<DirectionType> {
    array![
        DirectionType::North,
        DirectionType::South,
        DirectionType::East,
        DirectionType::West,
        DirectionType::Northeast,
        DirectionType::Northwest,
        DirectionType::Southeast,
        DirectionType::Southwest,
        DirectionType::Up,
        DirectionType::Down,
        DirectionType::In,
        DirectionType::Out,
    ]
}

/// Gets all cardinal directions as an array
/// 
/// # Returns
/// * `Array<DirectionType>` - Array of cardinal directions
pub fn get_cardinal_directions() -> Array<DirectionType> {
    array![
        DirectionType::North,
        DirectionType::South,
        DirectionType::East,
        DirectionType::West,
    ]
}

/// Gets all diagonal directions as an array
/// 
/// # Returns
/// * `Array<DirectionType>` - Array of diagonal directions
pub fn get_diagonal_directions() -> Array<DirectionType> {
    array![
        DirectionType::Northeast,
        DirectionType::Northwest,
        DirectionType::Southeast,
        DirectionType::Southwest,
    ]
}

// Helper functions

/// Normalizes direction word for consistent parsing
fn normalize_direction_word(word: ByteArray) -> ByteArray {
    // Simplified implementation - in full version would convert to lowercase
    word
}

#[cfg(test)]
mod tests {
    use super::{
        DirectionType, parse_direction, get_opposite_direction, is_room_connection_direction,
        direction_to_string, direction_to_abbreviation, direction_to_u8, u8_to_direction,
        is_cardinal_direction, is_diagonal_direction, is_vertical_direction, is_special_direction
    };
    
    #[test]
    fn test_parse_direction() {
        // Test full names
        match parse_direction("north") {
            Option::Some(DirectionType::North) => {},
            _ => panic!("Should parse 'north' as North"),
        }
        
        // Test abbreviations
        match parse_direction("n") {
            Option::Some(DirectionType::North) => {},
            _ => panic!("Should parse 'n' as North"),
        }
        
        match parse_direction("ne") {
            Option::Some(DirectionType::Northeast) => {},
            _ => panic!("Should parse 'ne' as Northeast"),
        }
        
        // Test invalid direction
        match parse_direction("invalid") {
            Option::None => {},
            _ => panic!("Should return None for invalid direction"),
        }
    }
    
    #[test]
    fn test_get_opposite_direction() {
        assert!(get_opposite_direction(DirectionType::North) == DirectionType::South);
        assert!(get_opposite_direction(DirectionType::East) == DirectionType::West);
        assert!(get_opposite_direction(DirectionType::Up) == DirectionType::Down);
        assert!(get_opposite_direction(DirectionType::In) == DirectionType::Out);
        assert!(get_opposite_direction(DirectionType::Northeast) == DirectionType::Southwest);
    }
    
    #[test]
    fn test_is_room_connection_direction() {
        // All directions should be valid room connections in interactive fiction
        assert!(is_room_connection_direction(DirectionType::North));
        assert!(is_room_connection_direction(DirectionType::In));
        assert!(is_room_connection_direction(DirectionType::Up));
    }
    
    #[test]
    fn test_direction_to_string() {
        assert!(direction_to_string(DirectionType::North) == "north");
        assert!(direction_to_string(DirectionType::Northeast) == "northeast");
    }
    
    #[test]
    fn test_direction_to_abbreviation() {
        assert!(direction_to_abbreviation(DirectionType::North) == "n");
        assert!(direction_to_abbreviation(DirectionType::Northeast) == "ne");
    }
    
    #[test]
    fn test_direction_to_u8_and_back() {
        let original = DirectionType::Northeast;
        let as_u8 = direction_to_u8(original);
        match u8_to_direction(as_u8) {
            Option::Some(converted) => assert!(converted == original),
            Option::None => panic!("Should convert back to original direction"),
        }
        
        // Test invalid u8
        match u8_to_direction(255) {
            Option::None => {},
            _ => panic!("Invalid u8 should return None"),
        }
    }
    
    #[test]
    fn test_direction_classification() {
        assert!(is_cardinal_direction(DirectionType::North));
        assert!(is_cardinal_direction(DirectionType::West));
        assert!(!is_cardinal_direction(DirectionType::Northeast));
        
        assert!(is_diagonal_direction(DirectionType::Northeast));
        assert!(is_diagonal_direction(DirectionType::Southwest));
        assert!(!is_diagonal_direction(DirectionType::North));
        
        assert!(is_vertical_direction(DirectionType::Up));
        assert!(is_vertical_direction(DirectionType::Down));
        assert!(!is_vertical_direction(DirectionType::North));
        
        assert!(is_special_direction(DirectionType::In));
        assert!(is_special_direction(DirectionType::Out));
        assert!(!is_special_direction(DirectionType::North));
    }
}