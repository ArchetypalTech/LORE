// Here you can find the generic methods for all the components.

use dojo::{world::WorldStorage, model::{Model}};
use lore::{
    models::entity::{Entity, EntityImpl},
    models::player::{Player},
    types::{command_type::Command},
    constants::errors::Error,
};


pub trait Component<T, +Model<T>> {
    type ComponentType;
    fn get_component(world: WorldStorage, inst: felt252) -> Option<T>;

    fn inst(self: @T) -> @felt252;

    fn entity(self: @T, world: @WorldStorage) -> Entity {
        EntityImpl::get_entity(world, Self::inst(self)).unwrap()
    }

    // used internall
    fn has_component(self: @T, world: WorldStorage, inst: felt252) -> bool;

    // used for tests only
    fn add_component(world: WorldStorage, inst: felt252) -> T;

    fn can_use_command(self: @T, world: @WorldStorage, player: @Player, command: @Command) -> bool;

    fn execute_command(
        self: T, ref world: WorldStorage, player: @Player, command: @Command,
    ) -> Result<(), Error>;

    fn store(self: @T, ref world: WorldStorage);
}

