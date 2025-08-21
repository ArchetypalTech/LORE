// Here you can find the ComponentProperty struct,
// the property types and the property access types

#[derive(Clone, Drop, Serde, Introspect, Debug, PartialEq)]
pub struct ComponentProperty {
    pub name: ByteArray,
    pub property_type: PropertyType,
    pub access_flags: PropertyAccess,
}

#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum PropertyType {
    Boolean,
    Felt252,
    U8,
    U32,
    Enum,
    ByteArray,
    ContractAddress,
    ArrayFelt252,
    ArrayByteArray,
}

#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum PropertyAccess {
    ReadOnly,
    ReadWrite,
}

// Implementation into U8 //

pub impl IntoPropertyTypeU8 of core::traits::Into<PropertyType, u8> {
    #[inline]
    fn into(self: PropertyType) -> u8 {
        match self {
            PropertyType::Boolean => 0,
            PropertyType::Felt252 => 1,
            PropertyType::U8 => 2,
            PropertyType::U32 => 3,
            PropertyType::Enum => 4,
            PropertyType::ByteArray => 5,
            PropertyType::ContractAddress => 6,
            PropertyType::ArrayFelt252 => 7,
            PropertyType::ArrayByteArray => 8,
        }
    }
}

pub impl IntoPropertyAccessU8 of core::traits::Into<PropertyAccess, u8> {
    fn into(self: PropertyAccess) -> u8 {
        match self {
            PropertyAccess::ReadOnly => 0,
            PropertyAccess::ReadWrite => 1,
        }
    }
}

// Implementation into PropertyType //

pub impl IntoU8PropertyType of core::traits::Into<u8, PropertyType> {
    #[inline]
    fn into(self: u8) -> PropertyType {
        match self {
            0 => PropertyType::Boolean,
            1 => PropertyType::Felt252,
            2 => PropertyType::U8,
            3 => PropertyType::U32,
            4 => PropertyType::Enum,
            5 => PropertyType::ByteArray,
            6 => PropertyType::ContractAddress,
            7 => PropertyType::ArrayFelt252,
            8 => PropertyType::ArrayByteArray,
            _ => PropertyType::Boolean,
        }
    }
}

// Implementation into PropertyAccess //

pub impl IntoU8PropertyAccess of core::traits::Into<u8, PropertyAccess> {
    #[inline]
    fn into(self: u8) -> PropertyAccess {
        match self {
            0 => PropertyAccess::ReadOnly,
            1 => PropertyAccess::ReadWrite,
            _ => PropertyAccess::ReadOnly,
        }
    }
}
