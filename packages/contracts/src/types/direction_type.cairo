// Here you can find the direction type

#[derive(Serde, Copy, Drop, Debug, Introspect, PartialEq)]
pub enum DirectionType {
    North,
    South,
    East,
    West,
    NorthEast,
    SouthEast,
    NorthWest,
    SouthWest,
    Up,
    Down,
}

// Implementation into U8 //

pub impl IntoDirectionTypeU8 of core::traits::Into<DirectionType, u8> {
    #[inline]
    fn into(self: DirectionType) -> u8 {
        match self {
            DirectionType::North => 0,
            DirectionType::South => 1,
            DirectionType::East => 2,
            DirectionType::West => 3,
            DirectionType::NorthEast => 4,
            DirectionType::SouthEast => 5,
            DirectionType::NorthWest => 6,
            DirectionType::SouthWest => 7,
            DirectionType::Up => 8,
            DirectionType::Down => 9,
        }
    }
}

// Implementation into DirectionType //
pub impl IntoU8DirectionType of core::traits::Into<u8, DirectionType> {
    #[inline]
    fn into(self: u8) -> DirectionType {
        match self {
            0 => DirectionType::North,
            1 => DirectionType::South,
            2 => DirectionType::East,
            3 => DirectionType::West,
            4 => DirectionType::NorthEast,
            5 => DirectionType::SouthEast,
            6 => DirectionType::NorthWest,
            7 => DirectionType::SouthWest,
            8 => DirectionType::Up,
            9 => DirectionType::Down,
            _ => DirectionType::North,
        }
    }
}
