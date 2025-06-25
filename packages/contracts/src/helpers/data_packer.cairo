//! Shinigami Layer 1: Helpers - Storage optimization and data serialization
//! 
//! This module provides stateless functions for efficiently packing and unpacking
//! data structures to optimize storage costs in the LORE game engine.

use core::option::OptionTrait;

/// Entity data structure for packing
#[derive(Drop, Serde, Debug, Copy)]
pub struct EntityData {
    pub entity_type: u8,    // 8 bits for entity type (up to 256 types)
    pub flags: u8,          // 8 bits for boolean flags
    pub parent_inst: u32,   // 32 bits for parent instance
    pub data: u32,          // 32 bits for misc data
}

/// Relationship types for parent-child relationships
#[derive(Drop, Serde, Debug, Copy, PartialEq)]
pub enum RelationshipType {
    Contains,      // Parent contains child (inventory, room contents)
    ConnectedTo,   // Parent connects to child (exits)
    OwnedBy,       // Parent owns child (player ownership)
    AttachedTo,    // Parent has child attached (equipment, components)
}

/// Error types for data packing operations
#[derive(Drop, Serde, Debug)]
pub enum PackingError {
    InvalidData,
    OverflowError,
    UnpackingError,
}

/// Packs entity data into a single felt252 for storage efficiency
/// 
/// # Arguments
/// * `entity` - The entity data to pack
/// 
/// # Returns
/// * `felt252` - Packed data in a single storage slot
pub fn pack_entity_data(entity: EntityData) -> felt252 {
    // Pack data into a felt252:
    // Bits 0-7:   entity_type (8 bits)
    // Bits 8-15:  flags (8 bits)
    // Bits 16-47: parent_inst (32 bits)
    // Bits 48-79: data (32 bits)
    // Remaining bits: reserved for future use
    
    let mut packed: u256 = 0;
    
    // Pack entity_type in lowest 8 bits
    packed = packed | entity.entity_type.into();
    
    // Pack flags in next 8 bits
    packed = packed | (entity.flags.into() * 0x100);
    
    // Pack parent_inst in next 32 bits
    packed = packed | (entity.parent_inst.into() * 0x10000);
    
    // Pack data in next 32 bits
    packed = packed | (entity.data.into() * 0x100000000);
    
    // Convert to felt252 (safe because we're using less than 252 bits)
    packed.try_into().unwrap()
}

/// Unpacks entity data from a felt252
/// 
/// # Arguments
/// * `packed` - The packed data
/// 
/// # Returns
/// * `EntityData` - Unpacked entity data structure
pub fn unpack_entity_data(packed: felt252) -> EntityData {
    let packed_u256: u256 = packed.into();
    
    // Extract entity_type from lowest 8 bits
    let entity_type = (packed_u256 & 0xFF).try_into().unwrap();
    
    // Extract flags from next 8 bits
    let flags = ((packed_u256 / 0x100) & 0xFF).try_into().unwrap();
    
    // Extract parent_inst from next 32 bits
    let parent_inst = ((packed_u256 / 0x10000) & 0xFFFFFFFF).try_into().unwrap();
    
    // Extract data from next 32 bits
    let data = ((packed_u256 / 0x100000000) & 0xFFFFFFFF).try_into().unwrap();
    
    EntityData {
        entity_type,
        flags,
        parent_inst,
        data,
    }
}

/// Packs relationship data into a single felt252
/// 
/// # Arguments
/// * `parent` - Parent entity instance
/// * `child` - Child entity instance
/// * `relationship_type` - Type of relationship
/// 
/// # Returns
/// * `felt252` - Packed relationship data
pub fn pack_relationship_data(parent: u32, child: u32, relationship_type: RelationshipType) -> felt252 {
    // Pack relationship data:
    // Bits 0-31:  parent instance (32 bits)
    // Bits 32-63: child instance (32 bits)
    // Bits 64-71: relationship type (8 bits)
    // Remaining bits: reserved
    
    let mut packed: u256 = 0;
    
    // Pack parent in lowest 32 bits
    packed = packed | parent.into();
    
    // Pack child in next 32 bits
    packed = packed | (child.into() * 0x100000000);
    
    // Pack relationship type in next 8 bits
    let rel_type_val: u8 = match relationship_type {
        RelationshipType::Contains => 0,
        RelationshipType::ConnectedTo => 1,
        RelationshipType::OwnedBy => 2,
        RelationshipType::AttachedTo => 3,
    };
    packed = packed | (rel_type_val.into() * 0x10000000000000000);
    
    packed.try_into().unwrap()
}

/// Unpacks relationship data from a felt252
/// 
/// # Arguments
/// * `packed` - The packed relationship data
/// 
/// # Returns
/// * `(u32, u32, RelationshipType)` - Tuple of (parent, child, relationship_type)
pub fn unpack_relationship_data(packed: felt252) -> (u32, u32, RelationshipType) {
    let packed_u256: u256 = packed.into();
    
    // Extract parent from lowest 32 bits
    let parent = (packed_u256 & 0xFFFFFFFF).try_into().unwrap();
    
    // Extract child from next 32 bits
    let child = ((packed_u256 / 0x100000000) & 0xFFFFFFFF).try_into().unwrap();
    
    // Extract relationship type from next 8 bits
    let rel_type_val: u8 = ((packed_u256 / 0x10000000000000000) & 0xFF).try_into().unwrap();
    let relationship_type = match rel_type_val {
        0 => RelationshipType::Contains,
        1 => RelationshipType::ConnectedTo,
        2 => RelationshipType::OwnedBy,
        3 => RelationshipType::AttachedTo,
        _ => RelationshipType::Contains, // Default fallback
    };
    
    (parent, child, relationship_type)
}

/// Calculates the storage cost for data of a given size
/// 
/// # Arguments
/// * `data_size` - Size of data in bytes
/// 
/// # Returns
/// * `u32` - Estimated storage cost in gas units
pub fn calculate_storage_cost(data_size: u32) -> u32 {
    // Simplified storage cost calculation
    // In Starknet, each storage slot costs gas to write
    // Each felt252 is one storage slot
    
    let slots_needed = (data_size + 31) / 32; // Round up to nearest 32 bytes
    let base_cost_per_slot = 2000; // Approximate gas cost per storage write
    
    slots_needed * base_cost_per_slot
}

/// Packs boolean flags into a single u8 using multiplication (Cairo doesn't support bit shifts)
/// 
/// # Arguments
/// * `flags` - Array of up to 8 boolean flags
/// 
/// # Returns
/// * `u8` - Packed flags
pub fn pack_flags(flags: Array<bool>) -> u8 {
    let mut packed: u8 = 0;
    let mut i = 0;
    let powers_of_2 = array![1, 2, 4, 8, 16, 32, 64, 128];
    
    while i < flags.len() && i < 8 {
        if *flags.at(i) {
            packed = packed | *powers_of_2.at(i);
        }
        i += 1;
    };
    
    packed
}

/// Unpacks boolean flags from a u8
/// 
/// # Arguments
/// * `packed` - Packed flags
/// 
/// # Returns
/// * `Array<bool>` - Array of 8 boolean flags
pub fn unpack_flags(packed: u8) -> Array<bool> {
    let mut flags = ArrayTrait::new();
    let powers_of_2 = array![1, 2, 4, 8, 16, 32, 64, 128];
    let mut i = 0;
    
    while i < 8 {
        flags.append((packed & *powers_of_2.at(i)) != 0);
        i += 1;
    };
    
    flags
}

/// Packs text description indices for efficient storage
/// Used for storing multiple description variations for inspectable entities
/// 
/// # Arguments
/// * `primary_desc` - Index of primary description
/// * `alt_desc` - Index of alternative description  
/// * `first_time_desc` - Index of first-time description
/// * `repeat_desc` - Index of repeat description
/// 
/// # Returns
/// * `u32` - Packed description indices
pub fn pack_description_indices(primary_desc: u8, alt_desc: u8, first_time_desc: u8, repeat_desc: u8) -> u32 {
    let mut packed: u32 = 0;
    packed = packed | primary_desc.into();
    packed = packed | (alt_desc.into() * 256);        // 2^8
    packed = packed | (first_time_desc.into() * 65536); // 2^16
    packed = packed | (repeat_desc.into() * 16777216);  // 2^24
    packed
}

/// Unpacks text description indices
/// 
/// # Arguments
/// * `packed_indices` - Packed description indices
/// 
/// # Returns
/// * `(u8, u8, u8, u8)` - Tuple of (primary_desc, alt_desc, first_time_desc, repeat_desc)
pub fn unpack_description_indices(packed_indices: u32) -> (u8, u8, u8, u8) {
    let primary_desc = (packed_indices & 0xFF).try_into().unwrap();
    let alt_desc = ((packed_indices / 256) & 0xFF).try_into().unwrap();        // 2^8
    let first_time_desc = ((packed_indices / 65536) & 0xFF).try_into().unwrap(); // 2^16
    let repeat_desc = ((packed_indices / 16777216) & 0xFF).try_into().unwrap();  // 2^24
    (primary_desc, alt_desc, first_time_desc, repeat_desc)
}

#[cfg(test)]
mod tests {
    use super::{
        EntityData, RelationshipType, pack_entity_data, unpack_entity_data,
        pack_relationship_data, unpack_relationship_data, calculate_storage_cost,
        pack_flags, unpack_flags, pack_description_indices, unpack_description_indices
    };
    
    #[test]
    fn test_pack_unpack_entity_data() {
        let original = EntityData {
            entity_type: 42,
            flags: 0b10101010,
            parent_inst: 0x12345678,
            data: 0x87654321,
        };
        
        let packed = pack_entity_data(original);
        let unpacked = unpack_entity_data(packed);
        
        assert!(unpacked.entity_type == original.entity_type);
        assert!(unpacked.flags == original.flags);
        assert!(unpacked.parent_inst == original.parent_inst);
        assert!(unpacked.data == original.data);
    }
    
    #[test]
    fn test_pack_unpack_relationship_data() {
        let parent = 100;
        let child = 200;
        let rel_type = RelationshipType::Contains;
        
        let packed = pack_relationship_data(parent, child, rel_type);
        let (unpacked_parent, unpacked_child, unpacked_rel_type) = unpack_relationship_data(packed);
        
        assert!(unpacked_parent == parent);
        assert!(unpacked_child == child);
        assert!(unpacked_rel_type == rel_type);
    }
    
    #[test]
    fn test_calculate_storage_cost() {
        let cost = calculate_storage_cost(64);
        assert!(cost == 4000); // 2 slots * 2000 gas per slot
    }
    
    #[test]
    fn test_pack_unpack_flags() {
        let flags = array![true, false, true, false, true, false, true, false];
        let packed = pack_flags(flags);
        let unpacked = unpack_flags(packed);
        
        assert!(*unpacked.at(0) == true);
        assert!(*unpacked.at(1) == false);
        assert!(*unpacked.at(2) == true);
        assert!(*unpacked.at(3) == false);
    }
    
    #[test]
    fn test_pack_unpack_description_indices() {
        let primary = 10;
        let alt = 25;
        let first_time = 50;
        let repeat = 75;
        
        let packed = pack_description_indices(primary, alt, first_time, repeat);
        let (up, ua, uf, ur) = unpack_description_indices(packed);
        
        assert!(up == primary);
        assert!(ua == alt);
        assert!(uf == first_time);
        assert!(ur == repeat);
    }
}