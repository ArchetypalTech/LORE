use dojo::{world::WorldStorage, model::ModelStorage};
use starknet::ContractAddress;
use lore::{
    models::{
        entity::{EntityImpl},
        components::{Component},
    },
    new_components::{
        reactable_trait::ReactableImpl,
    },
    types::{command_type::Command},
    constants::errors::Error,
};

#[derive(Copy, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct Player {
    #[key]
    pub inst: felt252,
    pub is_player: bool,
    /// Properties ///
    /// The address of the player
    pub address: ContractAddress,
    /// The location of the player
    pub location: felt252,
    /// Current story line
    pub story_line: CounterType,
    /// If the player is in debug mode
    pub use_debug: bool,
}

#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct PlayerStory {
    #[key]
    pub inst: felt252,
    /// Properties ///
    /// Array of story lines (story lines keys)
    pub story: Array<CounterType>,
}

pub type CounterType = u32;
#[derive(Clone, Drop, Serde, Debug, Introspect, PartialEq)]
#[dojo::model]
pub struct StoryLine {
    /// Unique identifier (Player or PlayerStory)
    #[key]
    pub inst: felt252,
    /// Unique identifier of the line
    #[key]
    pub key: CounterType,
    /// Story line
    pub line: ByteArray,
}

pub impl PlayerComponent of Component<Player> {
    type ComponentType = Player;

    fn inst(self: @Player) -> @felt252 {
        self.inst
    }

    fn has_component(self: @Player, world: WorldStorage, inst: felt252) -> bool {
        let player: Player = world.read_model(inst);
        player.is_player
    }

    fn add_component(mut world: WorldStorage, inst: felt252) -> Player {
        let mut player: Player = world.read_model(inst);
        player.inst = inst;
        player.is_player = true;
        player.store(world);
        // Return the component
        player
    }

    fn get_component(world: WorldStorage, inst: felt252) -> Option<Player> {
        let player: Player = world.read_model(inst);
        if (!player.has_component(world, inst)) {
            return Option::None;
        }
        let player: Player = world.read_model(inst);
        Option::Some(player)
    }

    fn can_use_command(
        self: @Player, world: WorldStorage, player: @Player, command: @Command,
    ) -> bool {
        true
    }

    fn execute_command(
        self: Player, world: WorldStorage, player: @Player, command: @Command,
    ) -> Result<(), Error> {
        // println!("Player execute_command");
        Result::Err(Error::Unimplemented)
    }

    fn store(self: @Player, mut world: WorldStorage) {
        world.write_model(self);
    }
}


pub fn create_player(mut world: WorldStorage, address: ContractAddress) -> Player {
    EntityImpl::create_player_entity(world, address)
}

pub fn get_player(world: WorldStorage, address: ContractAddress) -> Option<Player> {
    let inst: felt252 = address.into();
    let player: Player = world.read_model(inst);
    if (!player.is_player) {
        return Option::None;
    }
    Option::Some(player)
}

pub fn caller_as_player(world: WorldStorage, address: ContractAddress) -> Player {
    match get_player(world, address) {
        Option::Some(player) => player,
        Option::None => create_player(world, address),
    }
}

#[cfg(test)]
mod tests {
    use dojo::{model::ModelStorage};
    use super::*;
    use lore::{
        new_components::player_trait::{PlayerImpl},
        tests::helpers,
    };

    #[test]
    fn Player_test_create_player() {
        let (world, _, _, player_1, _) = helpers::setup_core();
        let player: Player = caller_as_player(world, player_1);
        assert(player.is_player, 'player is player');
    }

    #[test]
    fn Player_test_story_time() {
        let (world, _, _, player_1, _) = helpers::setup_core();
        let player: Player = caller_as_player(world, player_1);
        assert(player.is_player, 'player is player');

        player.say(world, "hello");
        let story: PlayerStory = world.read_model(player.inst);
        // ("story: {:?}", story);
        assert(story.story.len() == 2, 'story has two entries'); // first entry is intro text
        let test_text: ByteArray = "hello";

        let story_key: u32 = *story.story.at(story.story.len() - 1);
        let story_line: StoryLine = world.read_model((story.inst, story_key));
        assert(story_line.line == test_text, 'story has "hello"');
    }
}
