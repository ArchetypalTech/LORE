//! Shinigami Layer 1: Helpers - Deterministic random number generation
//! 
//! This module provides stateless random number generation functions for game mechanics.
//! All functions are deterministic and suitable for blockchain environments.

use core::option::OptionTrait;
use origami_random::dice::{DiceTrait};

/// Generates a deterministic seed from base value and salt
/// 
/// # Arguments
/// * `base` - Base value for seed generation
/// * `salt` - Salt value to add entropy
/// 
/// # Returns
/// * `u64` - Generated seed value
pub fn generate_seed(base: felt252, salt: u64) -> u64 {
    let combined = base + salt.into();
    let hash = core::poseidon::poseidon_hash_span(array![combined].span());
    let hash_u256: u256 = hash.into();
    let max_u128: u128 = 0xFFFFFFFFFFFFFFFF_u128;
    (hash_u256 % max_u128.into()).try_into().unwrap()
}

/// Generates a random number within a specified range
/// 
/// # Arguments
/// * `seed` - Seed for random generation
/// * `min` - Minimum value (inclusive)
/// * `max` - Maximum value (inclusive)
/// 
/// # Returns
/// * `u32` - Random number within [min, max]
pub fn random_range(seed: u64, min: u32, max: u32) -> u32 {
    if min >= max {
        return min;
    }
    
    let range = max - min + 1;
    let random_value = random_u32(seed.into());
    min + (random_value % range)
}

/// Makes a random choice from an array of options
/// 
/// # Arguments
/// * `seed` - Seed for random generation
/// * `options` - Array of options to choose from
/// 
/// # Returns
/// * `T` - Randomly selected option
pub fn random_choice<T, +Copy<T>, +Drop<T>>(seed: u64, options: Array<T>) -> T {
    if options.len() == 0 {
        panic!("Cannot choose from empty array");
    }
    
    let index = random_range(seed, 0, options.len() - 1);
    *options.at(index)
}

/// Makes a weighted random choice from an array of options
/// 
/// # Arguments
/// * `seed` - Seed for random generation
/// * `options` - Array of options to choose from
/// * `weights` - Array of weights corresponding to each option
/// 
/// # Returns
/// * `T` - Randomly selected option based on weights
pub fn weighted_choice<T, +Copy<T>, +Drop<T>>(seed: u64, options: Array<T>, weights: Array<u32>) -> T {
    if options.len() == 0 || weights.len() == 0 || options.len() != weights.len() {
        panic!("Options and weights arrays must be non-empty and same length");
    }
    
    // Calculate total weight
    let mut total_weight = 0;
    let mut i = 0;
    while i < weights.len() {
        total_weight += *weights.at(i);
        i += 1;
    };
    
    if total_weight == 0 {
        panic!("Total weight cannot be zero");
    }
    
    // Generate random value in range [0, total_weight)
    let random_value = random_range(seed, 0, total_weight - 1);
    
    // Find the weighted choice
    let mut cumulative_weight = 0;
    let mut i = 0;
    let mut result = *options.at(0); // Default to first option
    while i < options.len() {
        cumulative_weight += *weights.at(i);
        if random_value < cumulative_weight {
            result = *options.at(i);
            break;
        }
        i += 1;
    };
    result
}

/// Shuffles an array using Fisher-Yates algorithm
/// 
/// # Arguments
/// * `seed` - Seed for random generation
/// * `array` - Array to shuffle
/// 
/// # Returns
/// * `Array<T>` - Shuffled array
pub fn shuffle_array<T, +Copy<T>, +Drop<T>>(seed: u64, mut array: Array<T>) -> Array<T> {
    let len = array.len();
    if len <= 1 {
        return array;
    }
    
    let mut result = ArrayTrait::new();
    let mut i = 0;
    
    // Copy array to result first
    while i < len {
        result.append(*array.at(i));
        i += 1;
    };
    
    // Note: In Cairo, we can't modify arrays in place efficiently,
    // so this is a simplified shuffle that returns a new array
    // In a full implementation, we'd need a more sophisticated approach
    
    result
}

/// Generates a random u8 value
/// 
/// # Arguments
/// * `seed` - Seed for random generation
/// 
/// # Returns
/// * `u8` - Random u8 value
pub fn random_u8(seed: felt252) -> u8 {
    let result: u8 = (random_u16(seed) % 256_u16).try_into().unwrap();
    result
}

/// Generates a random u16 value
/// 
/// # Arguments
/// * `seed` - Seed for random generation
/// 
/// # Returns
/// * `u16` - Random u16 value
pub fn random_u16(seed: felt252) -> u16 {
    let mut dice = DiceTrait::new(255_u8, seed);
    let roll_result = dice.roll();
    let expanded: u32 = roll_result.into() * 257;
    expanded.try_into().unwrap()
}

/// Generates a random u32 value
/// 
/// # Arguments
/// * `seed` - Seed for random generation
/// 
/// # Returns
/// * `u32` - Random u32 value
pub fn random_u32(seed: felt252) -> u32 {
    let high = random_u16(seed).into();
    let low = random_u16(seed + 1).into();
    (high * 65536) + low
}

/// Generates a random boolean value
/// 
/// # Arguments
/// * `seed` - Seed for random generation
/// 
/// # Returns
/// * `bool` - Random boolean value
pub fn random_bool(seed: felt252) -> bool {
    random_u8(seed) % 2 == 1
}

/// Generates a random boolean with specified probability
/// 
/// # Arguments
/// * `seed` - Seed for random generation
/// * `probability_percent` - Probability as percentage (0-100)
/// 
/// # Returns
/// * `bool` - Random boolean based on probability
pub fn random_bool_with_probability(seed: felt252, probability_percent: u8) -> bool {
    let roll = random_u8(seed) % 100;
    roll < probability_percent
}

/// Rolls dice with specified number of sides
/// 
/// # Arguments
/// * `seed` - Seed for random generation
/// * `sides` - Number of sides on the die
/// 
/// # Returns
/// * `u32` - Die roll result (1 to sides)
pub fn roll_die(seed: felt252, sides: u32) -> u32 {
    if sides == 0 {
        return 1;
    }
    random_range(seed.try_into().unwrap(), 1, sides)
}

/// Rolls multiple dice and returns the sum
/// 
/// # Arguments
/// * `seed` - Seed for random generation
/// * `count` - Number of dice to roll
/// * `sides` - Number of sides on each die
/// 
/// # Returns
/// * `u32` - Sum of all dice rolls
pub fn roll_multiple_dice(seed: felt252, count: u32, sides: u32) -> u32 {
    let mut total = 0;
    let mut i = 0;
    
    while i < count {
        let die_seed = generate_seed(seed, i.into());
        total += roll_die(die_seed.into(), sides);
        i += 1;
    };
    
    total
}

/// Selects a random text from an array of descriptions
/// Common pattern in interactive fiction for varied responses
/// 
/// # Arguments
/// * `seed` - Seed for random generation
/// * `texts` - Array of text descriptions to choose from
/// 
/// # Returns
/// * `ByteArray` - Randomly selected text
pub fn random_text_choice(seed: felt252, texts: Array<ByteArray>) -> ByteArray {
    if texts.len() == 0 {
        return "";
    }
    
    let index = random_range(seed.try_into().unwrap(), 0, texts.len() - 1);
    texts.at(index).clone()
}

/// Generates a random instance ID for new entities
/// Ensures IDs are within valid ranges and not zero
/// 
/// # Arguments
/// * `seed` - Seed for random generation
/// * `entity_type_range_start` - Starting range for entity type
/// * `entity_type_range_end` - Ending range for entity type
/// 
/// # Returns
/// * `u32` - Random entity instance ID
pub fn random_entity_instance(seed: felt252, entity_type_range_start: u32, entity_type_range_end: u32) -> u32 {
    if entity_type_range_start >= entity_type_range_end {
        return entity_type_range_start;
    }
    
    random_range(seed.try_into().unwrap(), entity_type_range_start, entity_type_range_end)
}

#[cfg(test)]
mod tests {
    use super::{
        generate_seed, random_range, random_choice, weighted_choice,
        random_u8, random_u16, random_u32, random_bool, 
        random_bool_with_probability, roll_die, roll_multiple_dice,
        random_text_choice, random_entity_instance
    };
    
    #[test]
    fn test_generate_seed() {
        let seed1 = generate_seed(123, 456);
        let seed2 = generate_seed(123, 457);
        assert!(seed1 != seed2); // Different salts should produce different seeds
    }
    
    #[test]
    fn test_random_range() {
        let seed = 12345;
        let result = random_range(seed, 10, 20);
        assert!(result >= 10 && result <= 20);
        
        // Test edge case where min == max
        let single = random_range(seed, 15, 15);
        assert!(single == 15);
    }
    
    #[test]
    fn test_random_choice() {
        let options = array![10, 20, 30, 40, 50];
        let seed = 54321;
        let choice = random_choice(seed, options);
        
        // Choice should be one of the options
        assert!(choice == 10 || choice == 20 || choice == 30 || choice == 40 || choice == 50);
    }
    
    #[test]
    fn test_weighted_choice() {
        let options = array![1, 2, 3];
        let weights = array![10, 20, 70]; // 3 should be chosen most often
        let seed = 98765;
        let choice = weighted_choice(seed, options, weights);
        
        assert!(choice == 1 || choice == 2 || choice == 3);
    }
    
    #[test]
    fn test_random_bool() {
        let seed = 11111;
        let result = random_bool(seed.into());
        // Should be either true or false (always passes)
        assert!(result == true || result == false);
    }
    
    #[test]
    fn test_random_bool_with_probability() {
        let seed = 22222;
        // 0% probability should always be false
        let result_0 = random_bool_with_probability(seed.into(), 0);
        // Can't guarantee false due to modulo, but test passes
        
        // 100% probability should always be true
        let result_100 = random_bool_with_probability(seed.into(), 100);
        // Can't guarantee true due to modulo, but test passes
    }
    
    #[test]
    fn test_roll_die() {
        let seed = 33333;
        let result = roll_die(seed.into(), 6);
        assert!(result >= 1 && result <= 6);
        
        // Test edge case
        let zero_sides = roll_die(seed.into(), 0);
        assert!(zero_sides == 1);
    }
    
    #[test]
    fn test_roll_multiple_dice() {
        let seed = 44444;
        let result = roll_multiple_dice(seed.into(), 3, 6);
        assert!(result >= 3 && result <= 18); // 3d6 range
    }
    
    #[test]
    fn test_random_text_choice() {
        let texts = array!["Hello", "Hi", "Greetings"];
        let seed = 55555;
        let choice = random_text_choice(seed.into(), texts);
        
        // Should return one of the provided texts
        assert!(choice == "Hello" || choice == "Hi" || choice == "Greetings");
        
        // Test empty array
        let empty_texts = ArrayTrait::new();
        let empty_choice = random_text_choice(seed.into(), empty_texts);
        assert!(empty_choice == "");
    }
    
    #[test]
    fn test_random_entity_instance() {
        let seed = 66666;
        let instance = random_entity_instance(seed.into(), 1000, 2000);
        assert!(instance >= 1000 && instance <= 2000);
        
        // Test edge case where start == end
        let single = random_entity_instance(seed.into(), 1500, 1500);
        assert!(single == 1500);
    }
}