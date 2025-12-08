#[derive(Serde, Copy, Drop, Debug, Introspect, PartialEq)]
pub enum Direction {
    None,
    North,
    South,
    East,
    West,
    Up,
    Down,
}

use lore::{lib::utils::ByteArrayTraitExt};

pub fn direction_one_letter(direction: @ByteArray) -> ByteArray {
    let mut text: ByteArray = "";
    if (direction.starts_with(@"n")) {
        text = "north";
    } else if (direction.starts_with(@"s")) {
        text = "south";
    } else if (direction.starts_with(@"e")) {
        text = "east";
    } else if direction.starts_with(@"w") {
        text = "west";
    } else if direction.starts_with(@"u") {
        text = "up";
    } else if direction.starts_with(@"d") {
        text = "down";
    }
    text
}


pub mod CONST {
    pub const ETH_TO_WEI: u256 = 1_000_000_000_000_000_000;
}

pub mod TIMESTAMP {
    pub const ONE_MINUTE: u64   = 60;
    pub const ONE_HOUR: u64     = 60 * 60;
    pub const ONE_DAY: u64      = 60 * 60 * 24;
    pub const ONE_WEEK: u64     = 60 * 60 * 24 * 7;
    pub const TWO_WEEKS: u64    = 60 * 60 * 24 * 14;
    pub const THREE_WEEKS: u64  = 60 * 60 * 24 * 21;
    pub const FOUR_WEEKS: u64   = 60 * 60 * 24 * 28;
}
