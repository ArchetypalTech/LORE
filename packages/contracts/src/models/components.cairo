use dojo::{world::WorldStorage, model::{Model}};
use lore::{
    models::entity::{Entity, EntityImpl},
    models::player::{Player},
    types::{command_type::Command},
    constants::errors::Error,
};

pub trait Instance<M, +Drop<M>,  +Model<M>> {
    fn inst(self: @M) -> felt252;
    fn is_component(self: @M) -> bool;
    fn has_component(self: @WorldStorage, inst: felt252) -> bool;
}

pub trait Component<M, +Drop<M>, +Model<M>> {
    type ComponentType;

    fn entity(self: @M, world: @WorldStorage) -> Entity;

    fn get_component(world: @WorldStorage, inst: felt252, game_id: u128) -> Option<M>;
    fn store(self: @M, ref world: WorldStorage, game_id: u128);

    fn can_use_command(self: @M, world: @WorldStorage, player: @Player, command: @Command) -> bool;
    fn execute_command(self: M, ref world: WorldStorage, player: @Player, command: @Command) -> Result<(), Error>;

    // used for tests only
    fn add_component(ref world: WorldStorage, inst: felt252, game_id: u128) -> M;
}
