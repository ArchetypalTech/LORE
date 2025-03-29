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
