pub mod area;
pub mod container;
pub mod exit;
pub mod inspectable;
pub mod inventoryItem;
pub mod player;

use dojo::{world::WorldStorage};
use lore::lib::a_lexer::{Command};
use lore::lib::entity::{Entity};

pub trait Component<T> {
    fn entity(self: T, world: WorldStorage) -> Entity;
    fn has_component(self: T, world: WorldStorage, inst: felt252) -> bool;
    fn add_component(world: WorldStorage, inst: felt252) -> T;
    fn get_component(world: WorldStorage, inst: felt252) -> Option<T>;
    fn can_use_command(
        self: T, world: WorldStorage, player: player::Player, command: Command,
    ) -> bool;
    fn execute_command(self: T, world: WorldStorage, player: player::Player, command: Command);
}

pub enum Components {
    Area,
    Container,
    Entity,
    Exit,
    Inspectable,
    InventoryItem,
    Player,
}
// #[generate_trait]
// pub impl ComponentsImpl of ComponentsTrait {
//     fn get_component<T, +ComponentTrait<T>>(
//         self: T, world: WorldStorage, inst: felt252,
//     ) -> ComponentTrait:: {
//         match self {
//             Components::Area => {},
//             Components::Container => Container::get_container(world, inst),
//             Components::Entity => Entity::get_entity(world, inst),
//             Components::Exit => Exit::get_exit(world, inst),
//             Components::Inspectable => Inspectable::get_inspectable(world, inst),
//             Components::InventoryItem => InventoryItem::get_inventory_item(world, inst),
//             Components::Player => Player::get_player(world, inst),
//         }
//     }
// }


