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

    fn entity(self: @T, world: @WorldStorage) -> Entity;

    fn inst(self: @T) -> felt252;
    fn has_component(world: @WorldStorage, inst: felt252) -> bool;
    fn get_component(world: @WorldStorage, inst: felt252) -> Option<T>;

    fn can_use_command(self: @T, world: @WorldStorage, player: @Player, command: @Command) -> bool;
    fn execute_command(self: T, ref world: WorldStorage, player: @Player, command: @Command) -> Result<(), Error>;

    fn store(self: @T, ref world: WorldStorage);

    // used for tests only
    fn add_component(ref world: WorldStorage, inst: felt252) -> T;
}

