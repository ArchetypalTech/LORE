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
