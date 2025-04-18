use super::super::lib::entity::EntityTrait;
use dojo::{world::WorldStorage, model::ModelStorage};

use starknet::ContractAddress;
use lore::{
    constants::errors::Error, lib::{entity::{EntityImpl, Entity}, a_lexer::Command},
    components::{Component, inspectable::{Inspectable, InspectableImpl}},
};

pub struct EntityKey {
    pub inst: felt252,
}

#[derive(Copy, Drop, Serde, Debug, Introspect)]
#[dojo::model]
pub struct Player {
    #[key]
    pub inst: felt252,
    pub is_player: bool,
    // properties
    pub address: ContractAddress,
    pub location: felt252,
    pub use_debug: bool,
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
    fn describe_room(mut self: @Player, mut world: WorldStorage) -> Result<(), Error> {
        let context = self.get_context(@world);
        let room = self.get_room(@world);
        if room.is_none() {
            return Result::Err(Error::ActionFailed);
        }
        self.say(world, format!("{}", room.unwrap().name));
        for item in context {
            let inspectable: Option<Inspectable> = Component::get_component(world, item.inst);
            if inspectable.is_some() {
                let description = inspectable.unwrap().get_random_description(world);
                self.say(world, format!("{}", description));
            }
        };
        Result::Ok(())
    }

    fn move_to_room(mut self: Player, mut world: WorldStorage, room_id: felt252) {
        self.location = room_id;
        let ent: Entity = EntityImpl::get_entity(@world, @self.inst).unwrap();
        let room = EntityImpl::get_entity(@world, @room_id).unwrap();
        ent.set_parent(world, @room);
        world.write_model(@self);
        if self.use_debug {
            self.clone().say(world, format!("You {:?} enter {:?}", ent, room));
        }
    }

    fn say(mut self: @Player, mut world: WorldStorage, text: ByteArray) {
        let mut playerStory: PlayerStory = world.read_model(*self.inst);
        let mut storyLine = playerStory.story.clone();
        storyLine.append(text);
        world.write_model(@PlayerStory { inst: *self.inst, story: storyLine });
    }

    fn add_command_text(mut self: @Player, mut world: WorldStorage, text: ByteArray) {
        let mut playerStory: PlayerStory = world.read_model(*self.inst);
        let mut storyLine = playerStory.story.clone();
        if (storyLine.len() > 10) {
            let _ = storyLine.pop_front();
        }
        storyLine.append(format!("> {}", text));
        world.write_model(@PlayerStory { inst: *self.inst, story: storyLine });
    }

    fn get_room(self: @Player, world: @WorldStorage) -> Option<Entity> {
        let player_entity: Entity = EntityImpl::get_entity(world, self.inst).unwrap();
        let parent = player_entity.get_parent(world);
        if parent.is_none() {
            return Option::None;
        }
        parent
    }

    fn get_context(self: @Player, world: @WorldStorage) -> Array<Entity> {
        match self.get_room(world) {
            Option::Some(room) => {
                let mut context: Array<Entity> = array![];
                context.append(room.clone());
                let children = room.get_children(world);
                for child in children.clone() {
                    context.append(child);
                };
                context
            },
            Option::None => array![],
        }
    }
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
        // player.action_map = array![("look", InspectableActions::read_description)];
        player.store(world);
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
        println!("Player execute_command");
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
