// Here you can find the direction type

#[derive(Serde, Copy, Drop, Debug, Introspect, PartialEq)]
pub enum Direction {
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

pub impl IntoDirectionU8 of core::traits::Into<Direction, u8> {
    #[inline]
    fn into(self: Direction) -> u8 {
        match self {
            Direction::North => 0,
            Direction::South => 1,
            Direction::East => 2,
            Direction::West => 3,
            Direction::NorthEast => 4,
            Direction::SouthEast => 5,
            Direction::NorthWest => 6,
            Direction::SouthWest => 7,
            Direction::Up => 8,
            Direction::Down => 9,
        }
    }
}

// Implementation into felt252 //
pub impl IntoDirectionFelt252 of core::traits::Into<Direction, felt252> {
    #[inline]
    fn into(self: Direction) -> felt252 {
        match self {
            Direction::North => 0,
            Direction::South => 1,
            Direction::East => 2,
            Direction::West => 3,
            Direction::NorthEast => 4,
            Direction::SouthEast => 5,
            Direction::NorthWest => 6,
            Direction::SouthWest => 7,
            Direction::Up => 8,
            Direction::Down => 9,
        }
    }
}

// Implementation into ByteArray //
pub impl IntoDirectionByteArray of core::traits::Into<Direction, ByteArray> {
    #[inline]
    fn into(self: Direction) -> ByteArray {
        match self {
            Direction::North => "north",
            Direction::South => "south",
            Direction::East => "east",
            Direction::West => "west",
            Direction::NorthEast => "north-east",
            Direction::SouthEast => "south-east",
            Direction::NorthWest => "north-west",
            Direction::SouthWest => "south-west",
            Direction::Up => "up",
            Direction::Down => "down",
        }
    }
}

// Implementation into Direction //
pub impl IntoU8Direction of core::traits::Into<u8, Direction> {
    #[inline]
    fn into(self: u8) -> Direction {
        match self {
            0 => Direction::North,
            1 => Direction::South,
            2 => Direction::East,
            3 => Direction::West,
            4 => Direction::NorthEast,
            5 => Direction::SouthEast,
            6 => Direction::NorthWest,
            7 => Direction::SouthWest,
            8 => Direction::Up,
            9 => Direction::Down,
            _ => Direction::North,
        }
    }
}

pub impl IntoFelt252Direction of core::traits::Into<felt252, Direction> {
    #[inline]
    fn into(self: felt252) -> Direction {
        match self {
            0 => Direction::North,
            1 => Direction::South,
            2 => Direction::East,
            3 => Direction::West,
            4 => Direction::NorthEast,
            5 => Direction::SouthEast,
            6 => Direction::NorthWest,
            7 => Direction::SouthWest,
            8 => Direction::Up,
            9 => Direction::Down,
            _ => Direction::North,
        }
    }
}
