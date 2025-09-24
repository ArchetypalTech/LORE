use dojo::{world::WorldStorage, model::{ModelStorage, Model}};
use starknet::ContractAddress;
use lore::{
    models::{
        entity::{Entity, EntityImpl},
        components::{Instance, Component},
        game_instance::{GameModelImpl, GameInstImpl},
        reactable::{Reactable, ReactableImpl},
        container::{Container, ContainerComponent},
        index::{DescriptionText},
        token_config::{GameTokenInfoTrait},
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
    /// The game instance being played
    pub game_id: u128,
    /// The location of the player
    pub location: felt252,
    /// If the player is in debug mode
    pub use_debug: bool,
}

// story by game instance
#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct PlayerStory {
    #[key]
    pub game_id: u128,
    /// Properties ///
    /// Current story line - latest
    pub story_line: CounterType,
}

// story by game instance
#[derive(Clone, Drop, Serde, Debug, Introspect, PartialEq)]
#[dojo::model]
pub struct StoryLine {
    /// Unique identifier (Player or PlayerStory)
    #[key]
    pub game_id: u128,
    /// Unique identifier of the line
    #[key]
    pub key: CounterType,
    /// Story line
    pub line: ByteArray,
    /// Line type
    pub line_type: StoryLineType,
}

#[derive(Copy, Drop, Serde, Debug, PartialEq, Introspect, DojoStore, Default)]
pub enum StoryLineType {
    #[default]
    Undefined,
    Command,
    Response,
    SysResponse,
    Debug,
}

const SINGLETON_PLAYER_INST: felt252 = 'Player';


//---------------------------------
// Model Trait
//
#[generate_trait]
pub impl PlayerImpl of PlayerTrait {

    // used by prompt() and tests
    fn get_player_for_account(ref world: WorldStorage, address: ContractAddress, game_id: u128) -> Option<Player> {
        // find player singleton
       (match Self::get_player(@world, 0) {
            Option::Some(singleton_player) => {
                Option::Some(
                    if (game_id == 0) {
                        // requesting singleton player
                        (singleton_player)
                    } else if (!GameModelImpl::<Player>::has_game_model(@world, SINGLETON_PLAYER_INST, game_id)) {
                        // create new game instance player
                        (Self::create_player_game_instance(ref world, @singleton_player, address, game_id))
                    } else {
                        // read existing game instance player
                        (world.read_game_model(SINGLETON_PLAYER_INST, game_id))
                    }
                )
            },
            Option::None => {
                (Option::None)
            },
        })
    }

    fn get_player(world: @WorldStorage, game_id: u128) -> Option<Player> {
        let inst: felt252 = SINGLETON_PLAYER_INST;
        let player: Player = world.read_game_model(inst, game_id);
        if (!player.is_player) {
            return Option::None;
        }
        Option::Some(player)
    }

    // used by test only!!!
    fn caller_as_player(ref world: WorldStorage, address: ContractAddress, game_id: u128) -> Player {
        // make sure base player exists
        if Self::get_player(@world, 0).is_none() {
            Self::create_player_entity(ref world);
        }
        (Self::get_player_for_account(ref world, address, game_id).unwrap())
    }
    fn create_player_entity(ref world: WorldStorage) -> Player {
        // create player entity
        let mut entity: Entity = EntityImpl::create_entity(ref world, "Player");
        entity.inst = SINGLETON_PLAYER_INST;
        world.write_model(@entity);
        // create the player component
        let mut player: Player = Component::add_component(ref world, entity.inst);
        // player.address = address; // ideally, should be the deployer
        player.game_id = 0;
        player.location = 700111;
        player.store(ref world, 0);
        // create the reactable
        let mut reactable: Reactable = Component::add_component(ref world, entity.inst);
        reactable.description = array![0];
        reactable.store(ref world, 0);
        // (reactable) player description
        let descr1 = DescriptionText { inst: entity.inst, key: 0, text: "Looks like a visitor" };
        world.write_model(@descr1);
        // initialize player story
        player.say(ref world, "You feel light, and shiny, in the head");
        // return the player
        (player)
    }

    fn create_player_game_instance(ref world: WorldStorage, base_player: @Player, address: ContractAddress, game_id: u128) -> Player {
        // clone a new game instance player
        let mut new_player: Player = base_player.clone();
        new_player.address = address;
        new_player.game_id = game_id;
        world.write_game_model(@new_player, game_id);
        // initialize player story
        new_player.say(ref world, "You feel light, and shiny, in the head");
        // Save player progress
        GameTokenInfoTrait::set_room(ref world, game_id, new_player.location);
        // return the player
        (new_player)
    }

    fn describe_room(self: @Player, ref world: WorldStorage) -> Result<(), Error> {
        let context = self.get_context(@world);
        let room = self.get_room_entity(@world);
        if room.is_none() {
            return Result::Err(Error::NoRoom);
        }
        self.say(ref world, format!("{}", room.unwrap().name));
        for item in context {
            // Don't add the player to the description
            if (item.inst == *self.inst) {
                continue;
            }
            let reactable: Option<Reactable> = Component::get_component(@world, item.inst, *self.game_id);
            match reactable {
                Option::Some(mut reactable) => {
                    if reactable.is_visible {
                        if reactable.already_shown {
                            self.say(ref world, format!("{}", reactable.new_entry));
                        } else {
                            let description = reactable.get_first_description(world);
                            self.say(ref world, format!("{}", description));
                            reactable.already_shown = true;
                            reactable.store(ref world, *self.game_id);
                        }
                    }
                },
                Option::None => {},
            }
        };
        Result::Ok(())
    }

    fn move_to_room(mut self: Player, ref world: WorldStorage, room_id: felt252) {
        self.location = room_id;
        let player_entity: Entity = self.entity(@world);
        let room_entity: Entity = EntityImpl::get_entity(@world, room_id).unwrap();
        player_entity.set_parent(ref world, @room_entity, self.game_id);
        self.store(ref world, self.game_id);
        if self.use_debug {
            self.say(ref world, format!("You {:?} enter {:?}", player_entity, room_entity));
        }
        // Save player progress
        // TODO: find act number
        GameTokenInfoTrait::set_room(ref world, self.game_id, room_entity.inst);
    }

    fn say(self: @Player, ref world: WorldStorage, text: ByteArray) {
        Self::_log_story_line(self, ref world, text, StoryLineType::Response);
    }

    fn log_command(self: @Player, ref world: WorldStorage, text: ByteArray) {
        Self::_log_story_line(self, ref world, text, StoryLineType::Command);
    }

    fn log_debug(self: @Player, ref world: WorldStorage, text: ByteArray) {
        Self::_log_story_line(self, ref world, text, StoryLineType::Debug);
    }

    fn log_sys(self: @Player, ref world: WorldStorage, text: ByteArray) {
        Self::_log_story_line(self, ref world, text, StoryLineType::SysResponse);
    }

    fn _log_story_line(self: @Player, ref world: WorldStorage, text: ByteArray, line_type: StoryLineType) {
        if text == "" { return; }

        // PlayerStory is saved by player instance
        let increase: CounterType = 1;
        let mut player_story: PlayerStory = world.read_model(*self.game_id);
        player_story.story_line += increase;
        world.write_model(@player_story);

        // StoryLine is saved by player instance
        world.write_model(@StoryLine {
            game_id: *self.game_id,
            key: player_story.story_line,
            line: text,
            line_type,
        });
    }

    fn get_room_entity(self: @Player, world: @WorldStorage) -> Option<Entity> {
        let player_entity: Entity = self.entity(world);
        let parent = player_entity.get_parent(world, *self.game_id);
        if parent.is_none() {
            return Option::None;
        }
        parent
    }

    // Get the 1st level context of the room
    fn get_context(self: @Player, world: @WorldStorage) -> Array<Entity> {
        match self.get_room_entity(world) {
            Option::Some(room) => {
                let mut context: Array<Entity> = array![];
                context.append(room.clone());
                let children = room.get_children(world, *self.game_id);
                // Go over 1st level children
                for child in children {
                    context.append(child.clone());
                };
                context
            },
            Option::None => array![],
        }
    }

    // Get the full context of the room
    fn get_full_context(self: @Player, world: @WorldStorage) -> Array<Entity> {
        match self.get_room_entity(world) {
            Option::Some(room) => {
                let mut context: Array<Entity> = array![];
                context.append(room.clone());
                let children = room.get_children(world, *self.game_id);
                // Go over 1st level children
                for child in children {
                    context.append(child.clone());
                    // Go over 2nd level children
                    let children_2 = child.get_children(world, *self.game_id);
                    for child_2 in children_2 {
                        context.append(child_2.clone());
                        // Go over 3rd level children
                        let children_3 = child_2.get_children(world, *self.game_id);
                        for child_3 in children_3 {
                            context.append(child_3.clone());
                        }
                    };
                };
                context
            },
            Option::None => array![],
        }
    }

    // Get the player personal inventory container component
    fn get_personal_container(self: @Player, ref world: WorldStorage) -> Option<Container> {
        (match ContainerComponent::get_component(@world, *self.inst, *self.game_id) {
            Option::Some(c) => {
                (Option::Some(c))
            },
            Option::None => {
                self.say(ref world, format!("You don't have a personal inventory container"));
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
    fn add_component(ref world: WorldStorage, inst: felt252) -> Player {
        let mut player: Player = world.read_model(inst);
        player.inst = inst;
        player.is_player = true;
        player.store(ref world, 0);
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
        systems::prompt::{IPromptDispatcherTrait},
        models::{
            entity::{Entity, EntityImpl},
            token_config::{GameTokenInfo},
            reactable::{Reactable, ReactableComponent},
            index::{DescriptionText},
        },
    };
    use lore::models::reactable::tests::{Reactable_create_prefab};

    #[test]
    fn test_player_create() {
        let (mut world, _, _, _, player_1, _) = helpers::setup_core();
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
        let (mut world, _, _, _, player_1, _) = helpers::setup_core();
        let game_id: u128 = 123;
        let player: Player = PlayerImpl::caller_as_player(ref world, player_1, game_id);
        assert(player.is_player, 'player is player');

        player.say(ref world, "hello");
        let story: PlayerStory = world.read_model(game_id);
        // ("story: {:?}", story);
        let story_key: u32 = 2;
        assert(story.story_line == 2, 'story has two entries'); // first entry is intro text
        let test_text: ByteArray = "hello";

        let story_line: StoryLine = world.read_model((story.game_id, story_key));
        assert(story_line.line == test_text, 'story has "hello"');
        assert(story_line.line_type == StoryLineType::Response, 'command has "hello"');
    }

    fn _player_location(world: @WorldStorage, player: @Player) -> felt252 {
        let player: Player = world.read_game_model(*player.inst, *player.game_id);
        (player.location)
    }

    #[test]
    fn test_player_room() {
        let (mut world, _, prompt, _, player_address_1, player_address_2) = helpers::setup_core();
        // create some rooms
        let room_1_entity: Entity = EntityImpl::create_entity(ref world, "room_1");
        let room_2_entity: Entity = EntityImpl::create_entity(ref world, "room_2");
        let _room_1_reactable: Reactable = Reactable_create_prefab(ref world, room_1_entity.inst);
        let _room_2_reactable: Reactable = Reactable_create_prefab(ref world, room_2_entity.inst);
        assert_ne!(room_1_entity.inst, 0, "room_1_entity.inst > 0");
        assert_ne!(room_2_entity.inst, 0, "room_2_entity.inst > 0");
        assert_ne!(room_1_entity.inst, room_2_entity.inst, "room_1_entity.inst != room_2_entity.inst");
        // create base player
        let default_room_id: felt252 = 700111;
        let player: Player = PlayerImpl::caller_as_player(ref world, player_address_1, 0);
        helpers::set_caller(player_address_1);
        // mint game instance for players
        let game_id_1: u128 = 1;
        let game_id_2: u128 = 2;
        prompt.prompt("", Option::None);
        helpers::set_caller(player_address_2);
        prompt.prompt("", Option::None);
        helpers::set_caller(helpers::OWNER());
        let player_1: Player = PlayerImpl::get_player(@world, game_id_1).unwrap();
        let player_2: Player = PlayerImpl::get_player(@world, game_id_2).unwrap();
        assert!(player.is_player, "is_player");
        assert!(player_1.is_player, "is_player");
        assert!(player_2.is_player, "is_player");
        assert_eq!(player.inst, 'Player');
        assert_eq!(player.inst, player_1.inst);
        assert_eq!(player.inst, player_2.inst);
        assert_eq!(player_1.game_id, game_id_1);
        assert_eq!(player_2.game_id, game_id_2);
        assert_eq!(_player_location(@world, @player), default_room_id, "before move");
        assert_eq!(_player_location(@world, @player_1), default_room_id, "before move");
        assert_eq!(_player_location(@world, @player_2), default_room_id, "before move");
        assert!(player.get_room_entity(@world).is_none(), "before move");
        assert!(player_1.get_room_entity(@world).is_none(), "before move");
        assert!(player_2.get_room_entity(@world).is_none(), "before move");
        // change room 2 description
        world.write_model(@DescriptionText { inst: room_2_entity.inst, key: 0, text: "something else" });
        //
        // move game instance players
        player_1.move_to_room(ref world, room_2_entity.inst);
        player_2.move_to_room(ref world, room_1_entity.inst);
        assert_eq!(_player_location(@world, @player), default_room_id, "moved game inst");
        assert_eq!(_player_location(@world, @player_1), room_2_entity.inst, "moved game inst");
        assert_eq!(_player_location(@world, @player_2), room_1_entity.inst, "moved game inst");
        assert_eq!(player.get_room_entity(@world).is_none(), true, "moved game inst");
        assert_eq!(player_1.get_room_entity(@world).unwrap().inst, room_2_entity.inst, "moved game inst");
        assert_eq!(player_2.get_room_entity(@world).unwrap().inst, room_1_entity.inst, "moved game inst");
        // player token room
        let token_info_1: GameTokenInfo = world.read_model(game_id_1);
        let token_info_2: GameTokenInfo = world.read_model(game_id_2);
        assert_eq!(token_info_1.room_name, room_2_entity.name.clone(), "new act");
        assert_eq!(token_info_2.room_name, room_1_entity.name.clone(), "new act");
    }

    fn _story_len(world: @WorldStorage, game_id: u128) -> u32 {
        let story: PlayerStory = world.read_model(game_id);
        (story.story_line)
    }

    #[test]
    fn test_player_say() {
        let (mut world, _, _, _, player_address, _) = helpers::setup_core();
        let game_id_0: u128 = 0;
        let game_id_1: u128 = 123;
        let game_id_2: u128 = 456;
        let player_0: Player = PlayerImpl::caller_as_player(ref world, player_address, 0);
        let player_1: Player = PlayerImpl::caller_as_player(ref world, player_address, game_id_1);
        assert_eq!(player_0.game_id, game_id_0, "story_start");
        assert_eq!(player_1.game_id, game_id_1, "story_start");
        assert_eq!(_story_len(@world, game_id_0), 1, "story_start");
        assert_eq!(_story_len(@world, game_id_1), 1, "story_start");
        assert_eq!(_story_len(@world, game_id_2), 0, "story_start");
        // say something...
        player_0.say(ref world, "hello");
        player_1.say(ref world, "world");
        player_1.say(ref world, "world");
        assert_eq!(_story_len(@world, game_id_0), 2, "said");
        assert_eq!(_story_len(@world, game_id_1), 3, "said");
        assert_eq!(_story_len(@world, game_id_2), 0, "said");
        // create new player
        let player_2: Player = PlayerImpl::caller_as_player(ref world, player_address, game_id_2);
        assert_eq!(player_2.game_id, game_id_2, "story_start");
        assert_eq!(_story_len(@world, game_id_2), 1, "new_player");
        // say more...
        player_1.say(ref world, "burp");
        player_2.say(ref world, "blah");
        player_2.say(ref world, "blah");
        player_2.say(ref world, "blah");
        player_2.say(ref world, "blah");
        player_2.say(ref world, "blah");
        assert_eq!(_story_len(@world, game_id_0), 2, "said_more");
        assert_eq!(_story_len(@world, game_id_1), 4, "said_more");
        assert_eq!(_story_len(@world, game_id_2), 6, "said_more");
    }
}
