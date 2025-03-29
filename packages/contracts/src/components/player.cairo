use dojo::{world::WorldStorage, model::ModelStorage};

use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, Debug, Introspect)]
#[dojo::model]
pub struct Player {
    #[key]
    pub inst: felt252,
    pub is_player: bool,
    // properties
    pub address: ContractAddress,
    pub location: felt252,
}

#[derive(Clone, Drop, Serde, Debug, Introspect)]
#[dojo::model]
pub struct PlayerStory {
    #[key]
    pub inst: felt252,
    pub story: Array<ByteArray>,
}

#[generate_trait]
pub impl PlayerImpl of PlayerTrait {
    fn move_to_room(mut self: Player, mut world: WorldStorage, room_id: felt252) {
        self.location = room_id;
        world.write_model(@self);
    }

    fn say(mut self: Player, mut world: WorldStorage, text: ByteArray) {
        let mut playerStory: PlayerStory = world.read_model(self.inst);
        let mut storyLine = playerStory.story.clone();
        storyLine.append(text);
        world.write_model(@PlayerStory { inst: self.inst, story: storyLine });
    }

    fn add_command_text(mut self: Player, mut world: WorldStorage, text: ByteArray) {
        let mut playerStory: PlayerStory = world.read_model(self.inst);
        let mut storyLine = playerStory.story.clone();
        storyLine.append(format!("> {}", text));
        world.write_model(@PlayerStory { inst: self.inst, story: storyLine });
    }
}

pub fn create_player(mut world: WorldStorage, address: ContractAddress) -> Player {
    let start_room = 2826;
    let player = Player { inst: address.into(), is_player: true, address, location: start_room };
    world.write_model(@player);
    player.say(world, "You feel light, and shiny, in the head");
    player
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
    use super::{Player, PlayerTrait, PlayerStory};
    use super::{caller_as_player};
    use lore::tests::helpers;

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
        println!("story: {:?}", story);
        assert(story.story.len() == 2, 'story has two entries'); // first entry is intro text
        let test_text: ByteArray = "hello";
        assert(story.story.at(story.story.len() - 1) == @test_text, 'story has "hello"');
    }
}
