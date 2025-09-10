use dojo::{world::WorldStorage, model::ModelStorage, model::Model};
use starknet::ContractAddress;
use lore::{
    models::{
        entity::{Entity, EntityImpl},
        components::{Instance, Component},
        game_instance::{GameModelImpl, GameInstImpl},
        reactable::{Reactable, ReactableImpl},
        container::{Container, ContainerComponent},
    },
    types::{command_type::Command},
    constants::errors::Error,
};

pub type CounterType = u32;

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
    pub story_line: CounterType,
}

// stored by game instance always
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

const SINGLETON_PLAYER_INST: felt252 = 'player';

//---------------------------------
// Model Trait
//
#[generate_trait]
pub impl PlayerImpl of PlayerTrait {

    // used by prompt() and tests
    fn caller_as_player(ref world: WorldStorage, address: ContractAddress, game_id: u128) -> Player {
        // make sure base player exists
        let mut player: Player = match Self::get_player(@world, 0) {
            Option::Some(player) => player,
            Option::None => EntityImpl::create_player_entity(ref world, SINGLETON_PLAYER_INST, address),
        };
        // if playing game instance
        if (game_id != 0) {
            if (!GameModelImpl::<Player>::has_game_model(@world, player.inst, game_id)) {
                player = EntityImpl::create_player_game_instance(ref world, @player, game_id);
            } else {
                player = world.read_game_model(player.inst, game_id);
            }
        }
        (player)
    }

    fn get_player(world: @WorldStorage, game_id: u128) -> Option<Player> {
        let player: Player = world.read_game_model(SINGLETON_PLAYER_INST, game_id);
        if (!player.is_player) {
            return Option::None;
        }
        Option::Some(player)
    }

    fn describe_room(self: @Player, ref world: WorldStorage, game_id: u128) -> Result<(), Error> {
        let context = self.get_context(@world, game_id);
        let room = self.get_room(@world, game_id);
        if room.is_none() {
            return Result::Err(Error::NoRoom);
        }
        self.say(ref world, game_id, format!("{}", room.unwrap().name));
        for item in context {
            // Don't add the player to the description
            if (item.inst == *self.inst) {
                continue;
            }
            let reactable: Option<Reactable> = Component::get_component(@world, item.inst, game_id);
            match reactable {
                Option::Some(mut reactable) => {
                    if reactable.is_visible {
                        if reactable.already_shown {
                            self.say(ref world, game_id, format!("{}", reactable.new_entry));
                        } else {
                            let description = reactable.get_first_description(world);
                            self.say(ref world, game_id, format!("{}", description));
                            reactable.already_shown = true;
                            reactable.store(ref world, game_id);
                        }
                    }
                },
                Option::None => {},
            }
        };
        Result::Ok(())
    }

    fn move_to_room(mut self: Player, ref world: WorldStorage, room_id: felt252, game_id: u128) {
        self.location = room_id;
        let player_entity: Entity = EntityImpl::get_entity(@world, self.inst).unwrap();
        let room_entity: Entity = EntityImpl::get_entity(@world, room_id).unwrap();
        player_entity.set_parent(ref world, @room_entity);
        self.store(ref world, game_id);
        //world.write_model(@self);
        if self.use_debug {
            self.say(ref world, game_id, format!("You {:?} enter {:?}", player_entity, room_entity));
        }
    }

    // TODO: improve name and better description
    fn say(self: @Player, ref world: WorldStorage, game_id: u128, text: ByteArray) {
        let increase: CounterType = 1;
        
        // StoryLine is saved by player instance
        let game_inst: felt252 = GameInstImpl::game_inst(*self.inst, game_id);
        let mut player_story: PlayerStory = world.read_model(game_inst);
        player_story.story_line += increase;
        world.write_model(@player_story);

        // StoryLine is saved by player instance
        world.write_model(@StoryLine {
            inst: game_inst,
            key: player_story.story_line,
            line: text,
        });
    }

    fn add_command_text(self: @Player, ref world: WorldStorage, game_id: u128, text: ByteArray) {
        Self::say(self, ref world, game_id, text);
    }

    fn get_room(self: @Player, world: @WorldStorage, game_id: u128) -> Option<Entity> {
        let player_entity: Entity = EntityImpl::get_entity(world, *self.inst).unwrap();
        let parent = player_entity.get_parent(world);
        if parent.is_none() {
            return Option::None;
        }
        parent
    }

    // Get the 1st level context of the room
    fn get_context(self: @Player, world: @WorldStorage, game_id: u128) -> Array<Entity> {
        match self.get_room(world, game_id) {
            Option::Some(room) => {
                let mut context: Array<Entity> = array![];
                context.append(room.clone());
                let children = room.get_children(world);
                // Go over 1st level children
                for child in children.clone() {
                    context.append(child.clone());
                };
                context
            },
            Option::None => array![],
        }
    }

    // Get the full context of the room
    fn get_full_context(self: @Player, world: @WorldStorage, game_id: u128) -> Array<Entity> {
        match self.get_room(world, game_id) {
            Option::Some(room) => {
                let mut context: Array<Entity> = array![];
                context.append(room.clone());
                let children = room.get_children(world);
                // Go over 1st level children
                for child in children.clone() {
                    context.append(child.clone());
                    // Go over 2nd level children
                    let children_2 = child.get_children(world);
                    for child_2 in children_2 {
                        context.append(child_2.clone());
                        // Go over 3rd level children
                        let children_3 = child_2.get_children(world);
                        for child_3 in children_3 {
                            context.append(child_3);
                        }
                    };
                };
                context
            },
            Option::None => array![],
        }
    }

    // Get the player personal inventory container component
    fn get_personal_container(self: @Player, ref world: WorldStorage, game_id: u128) -> Option<Container> {
        (match ContainerComponent::get_component(@world, *self.inst, game_id) {
            Option::Some(c) => {
                (Option::Some(c))
            },
            Option::None => {
                self.say(ref world, game_id, format!("You don't have a personal inventory container"));
                (Option::None)
            },
        })
    }
}


//---------------------------------
// Component
//
pub impl PlayerInstance of Instance<Player> {
    #[inline(always)]
    fn inst(self: @Player) -> felt252 {
        (*self.inst)
    }
    #[inline(always)]
    fn set_inst(ref self: Player, new_inst: felt252) {
        self.inst = new_inst;
    }
    #[inline(always)]
    fn is_component(self: @Player) -> bool {
        (*self.is_player)
    }
    fn has_component(self: @WorldStorage, inst: felt252) -> bool {
        (inst != 0 && self.read_member(Model::<Player>::ptr_from_keys(inst), selector!("is_player")))
    }
}

pub impl PlayerComponent of Component<Player> {
    type ComponentType = Player;

    fn entity(self: @Player, world: @WorldStorage) -> Entity {
        EntityImpl::get_entity(world, self.inst()).unwrap()
    }

    fn get_component(world: @WorldStorage, inst: felt252, game_id: u128) -> Option<Player> {
        let player: Player = world.read_game_model(inst, game_id);
        if (player.is_component()) {
            Option::Some(player)
        } else {
            Option::None
        }
    }

    fn store(self: @Player, ref world: WorldStorage, game_id: u128) {
        world.write_game_model(self, game_id);
    }

    fn can_use_command(
        self: @Player, world: @WorldStorage, player: @Player, command: @Command,
    ) -> bool {
        true
    }

    fn execute_command(
        self: Player, ref world: WorldStorage, player: @Player, command: @Command,
    ) -> Result<(), Error> {
        // println!("Player execute_command");
        Result::Err(Error::Unimplemented)
    }

    // used for tests only
    fn add_component(ref world: WorldStorage, inst: felt252, game_id: u128) -> Player {
        let mut player: Player = world.read_model(inst);
        player.inst = inst;
        player.is_player = true;
        player.store(ref world, game_id);
        // Return the component
        player
    }
}


#[cfg(test)]
mod tests {
    use dojo::{model::ModelStorage};
    use super::*;
    use lore::{
        tests::helpers,
        models::{
            entity::{Entity, EntityImpl},
            reactable::{Reactable, ReactableComponent},
            index::{DescriptionText},
        },
    };
    use lore::models::reactable::tests::{Reactable_create_prefab};

    #[test]
    fn test_player_create() {
        let (mut world, _, _, player_1, _) = helpers::setup_core();
        let game_id: u128 = 0;
        let player: Player = PlayerImpl::caller_as_player(ref world, player_1, game_id);
        assert(player.is_player, 'player is player');

        let entity: Entity = PlayerComponent::entity(@player, @world);
        assert(entity.inst == player.inst, 'entity.inst == player.inst');

        assert(PlayerInstance::has_component(@world, player.inst), 'has_component()');
        let component: Option<Player> = PlayerComponent::get_component(@world, player.inst, 0);
        assert(component.is_some(), 'component.is_some()');
        assert(component.unwrap().inst() == player.inst, 'component.is_some()');

        let reactable: Option<Reactable> = ReactableComponent::get_component(@world, player.inst, 0);
        assert(reactable.is_some(), 'reactable.is_some()');
        assert(reactable.unwrap().inst() == player.inst, 'reactable.is_some()');
    }

    #[test]
    fn test_player_story_line() {
        let (mut world, _, _, player_1, _) = helpers::setup_core();
        let player: Player = PlayerImpl::caller_as_player(ref world, player_1, 0);
        assert(player.is_player, 'player is player');

        player.say(ref world, 0, "hello");
        let story: PlayerStory = world.read_model(player.inst);
        // ("story: {:?}", story);
        assert(story.story_line == 2, 'story has two entries'); // first entry is intro text
        let test_text: ByteArray = "hello";

        let story_key: u32 = story.story_line;
        let story_line: StoryLine = world.read_model((story.inst, story_key),);
        assert(story_line.line == test_text, 'story has "hello"');
    }

    #[test]
    fn test_player_room() {
        let (mut world, _, _, player_address_1, player_address_2) = helpers::setup_core();
        let game_id: u128 = 123;
        let player_1: Player = PlayerImpl::caller_as_player(ref world, player_address_1, 0);
        let player_2: Player = PlayerImpl::caller_as_player(ref world, player_address_2, 0);
        let player_1_game: Player = PlayerImpl::caller_as_player(ref world, player_address_1, game_id);
        let player_2_game: Player = PlayerImpl::caller_as_player(ref world, player_address_2, game_id);
        assert!(player_1.is_player, "player_1 is player");
        assert!(player_2.is_player, "player_2 is player");
        assert!(player_1_game.is_player, "player_1_game is player");
        assert!(player_2_game.is_player, "player_2_game is player");
        // create some rooms
        let room_1_entity: Entity = EntityImpl::create_entity(ref world, "room_1");
        let room_2_entity: Entity = EntityImpl::create_entity(ref world, "room_2");
        let _room_1_reactable: Reactable = Reactable_create_prefab(ref world, room_1_entity.inst);
        let _room_2_reactable: Reactable = Reactable_create_prefab(ref world, room_2_entity.inst);
        assert_ne!(room_1_entity.inst, 0, "room_1_entity.inst > 0");
        assert_ne!(room_2_entity.inst, 0, "room_2_entity.inst > 0");
        assert_ne!(room_1_entity.inst, room_2_entity.inst, "room_1_entity.inst != room_2_entity.inst");
        // change room 2 description
        world.write_model(@DescriptionText { inst: room_2_entity.inst, key: 0, text: "something else" });
        //
        // move to rooms
        player_1.move_to_room(ref world, room_1_entity.inst, 0);
        player_2.move_to_room(ref world, room_2_entity.inst, 0);
        assert_eq!(GameModelImpl::<Player>::read_game_model(@world, player_1.inst, 0).location, room_1_entity.inst, "moved inst");
        assert_eq!(GameModelImpl::<Player>::read_game_model(@world, player_2.inst, 0).location, room_2_entity.inst, "moved inst");
        assert_eq!(GameModelImpl::<Player>::read_game_model(@world, player_1.inst, game_id).location, room_1_entity.inst, "moved inst");
        assert_eq!(GameModelImpl::<Player>::read_game_model(@world, player_2.inst, game_id).location, room_2_entity.inst, "moved inst");
        assert_eq!(player_1.get_room(@world, 0).unwrap().inst, room_1_entity.inst, "moved inst");
        assert_eq!(player_2.get_room(@world, 0).unwrap().inst, room_2_entity.inst, "moved inst");
        assert_eq!(player_1.get_room(@world, game_id).unwrap().inst, room_1_entity.inst, "moved inst");
        assert_eq!(player_2.get_room(@world, game_id).unwrap().inst, room_2_entity.inst, "moved inst");
        //
        // move game instance players
        player_1.move_to_room(ref world, room_2_entity.inst, game_id);
        player_2.move_to_room(ref world, room_1_entity.inst, game_id);
        assert_eq!(GameModelImpl::<Player>::read_game_model(@world, player_1.inst, 0).location, room_1_entity.inst, "moved game inst");
        assert_eq!(GameModelImpl::<Player>::read_game_model(@world, player_2.inst, 0).location, room_2_entity.inst, "moved game inst");
        assert_eq!(GameModelImpl::<Player>::read_game_model(@world, player_1.inst, game_id).location, room_2_entity.inst, "moved game inst");
        assert_eq!(GameModelImpl::<Player>::read_game_model(@world, player_2.inst, game_id).location, room_1_entity.inst, "moved game inst");
        assert_eq!(player_1.get_room(@world, 0).unwrap().inst, room_1_entity.inst, "moved game inst");
        assert_eq!(player_2.get_room(@world, 0).unwrap().inst, room_2_entity.inst, "moved game inst");
        assert_eq!(player_1.get_room(@world, game_id).unwrap().inst, room_2_entity.inst, "moved game inst");
        assert_eq!(player_2.get_room(@world, game_id).unwrap().inst, room_1_entity.inst, "moved game inst");
    }

    fn _story_len(world: @WorldStorage, inst: felt252, game_id: u128) -> u32 {
        let game_inst: felt252 = GameInstImpl::game_inst(inst, game_id);
        let story: PlayerStory = world.read_model(game_inst);
        (story.story_line)
    }

    #[test]
    fn test_player_say() {
        let (mut world, _, _, player_address, _) = helpers::setup_core();
        let game_id_1: u128 = 123;
        let game_id_2: u128 = 456;
        let player: Player = PlayerImpl::caller_as_player(ref world, player_address, 0);
        let _player_1: Player = PlayerImpl::caller_as_player(ref world, player_address, game_id_1);
        assert_eq!(_story_len(@world, player.inst, 0), 1, "story_start");
        assert_eq!(_story_len(@world, player.inst, game_id_1), 1, "story_start");
        assert_eq!(_story_len(@world, player.inst, game_id_2), 0, "story_start");
        // say something...
        player.say(ref world, 0, "hello");
        player.say(ref world, game_id_1, "world");
        player.say(ref world, game_id_1, "world");
        assert_eq!(_story_len(@world, player.inst, 0), 2, "said");
        assert_eq!(_story_len(@world, player.inst, game_id_1), 3, "said");
        assert_eq!(_story_len(@world, player.inst, game_id_2), 0, "said");
        // create new player
        let _player_2: Player = PlayerImpl::caller_as_player(ref world, player_address, game_id_2);
        assert_eq!(_story_len(@world, player.inst, game_id_2), 1, "new_player");
        // say more...
        player.say(ref world, game_id_1, "burp");
        player.say(ref world, game_id_2, "burp");
        player.say(ref world, game_id_2, "blah");
        player.say(ref world, game_id_2, "blah");
        player.say(ref world, game_id_2, "blah");
        player.say(ref world, game_id_2, "blah");
        assert_eq!(_story_len(@world, player.inst, 0), 2, "said_more");
        assert_eq!(_story_len(@world, player.inst, game_id_1), 4, "said_more");
        assert_eq!(_story_len(@world, player.inst, game_id_2), 6, "said_more");
    }
}
