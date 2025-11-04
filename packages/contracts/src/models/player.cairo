use dojo::{world::WorldStorage, model::{ModelStorage, Model}};
use starknet::ContractAddress;
use lore::{
    models::{
        entity::{Entity, EntityImpl, ParentToChildren},
        components::{Component},
        game_instance::{Instance, GameModelImpl, GameInstImpl},
        reactable::{Reactable, ReactableImpl},
        container::{Container, ContainerComponent},
        area::{Area, AreaComponent},
        description_text::{DescriptionText},
        game_token_info::{GameTokenInfoTrait},
        hub::{HubTrait},
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
    /// If the player is dead
    pub is_dead: bool,
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
    Error,
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
                    if game_id == 0 {
                        // requesting singleton player
                        singleton_player
                    } else if !GameModelImpl::<Player>::has_game_model(@world, SINGLETON_PLAYER_INST, game_id) {
                        // create new game instance player
                        Self::create_player_game_instance(ref world, @singleton_player, address, game_id)
                    } else {
                        // read existing game instance player
                        world.read_game_model(SINGLETON_PLAYER_INST, game_id)
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
        let descr1: DescriptionText = DescriptionText { inst: entity.inst, key: 0, text: "Looks like a visitor" };
        world.write_model(@descr1);
        // initialize player story
        player.say(ref world, "You feel light, and shiny, in the head");
        // return the player
        (player)
    }

    fn create_player_game_instance(ref world: WorldStorage, base_player: @Player, address: ContractAddress, game_id: u128) -> Player {
        // clone a new game instance player
        let mut new_player: Player = *base_player;
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
        let context: Array<Entity> = self.get_context(@world);
        let room: Option<Entity> = self.get_room_entity(@world);
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
            if let Some(mut reactable) = reactable {
                if reactable.is_visible {
                    if reactable.already_shown {
                        self.say(ref world, format!("{}", reactable.new_entry));
                    } else {
                        let description: ByteArray = reactable.get_first_description(world, *self.game_id);
                        self.say(ref world, format!("{}", description));
                        reactable.already_shown = true;
                        reactable.store(ref world, *self.game_id);
                    }
                }
            }
        };
        Result::Ok(())
    }

    fn move_to_room(mut self: Player, ref world: WorldStorage, room_id: felt252) -> bool {
        // get room's entity
        let room_entity: Option<Entity> = EntityImpl::get_entity(@world, room_id);
        if (room_entity.is_none()) {
            self.log_error(ref world, format!("unknown room 0x{:x}", room_id));
            return false;
        }
        // get the room's Area
        let area: Option<Area> = AreaComponent::get_component(@world, room_id, self.game_id);
        if let Some(area) = area {
            if (area.preserve_children) {
                // reset the room's children on this game instance
                GameModelImpl::<ParentToChildren>::reset_game_model(ref world, room_id, self.game_id);
            }
        }
        // move player inside the room
        let room_entity: Entity = room_entity.unwrap();
        let mut player_entity: Entity = self.entity(@world);
        // move player to trail if needed
        if (player_entity.trail_id != room_entity.trail_id) {
            player_entity.trail_id = room_entity.trail_id;
            world.write_model(@player_entity);
        }
        player_entity.set_parent(ref world, @room_entity, self.game_id);
        // set player's location
        self.location = room_id;
        self.store(ref world, self.game_id);
        // debug
        if self.use_debug {
            self.say(ref world, format!("You {:?} enter {:?}", player_entity, room_entity));
        }
        // Save player progress
        GameTokenInfoTrait::set_room(ref world, self.game_id, room_entity.inst);
        // moved!
        (true)
    }

    fn say(self: @Player, ref world: WorldStorage, text: ByteArray) {
        Self::_log_story_line(self, ref world, text, StoryLineType::Response);
    }

    fn log_command(self: @Player, ref world: WorldStorage, text: ByteArray) {
        Self::_log_story_line(self, ref world, text, StoryLineType::Command);
    }

    fn log_sys(self: @Player, ref world: WorldStorage, text: ByteArray) {
        Self::_log_story_line(self, ref world, text, StoryLineType::SysResponse);
    }

    fn log_debug(self: @Player, ref world: WorldStorage, text: ByteArray) {
        Self::_log_story_line(self, ref world, text, StoryLineType::Debug);
    }

    fn log_error(self: @Player, ref world: WorldStorage, text: ByteArray) {
        Self::_log_story_line(self, ref world, text, StoryLineType::Error);
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
        let parent: Option<Entity> = player_entity.get_parent(world, *self.game_id);
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
                self._append_children_to_context(world, @room, ref context);
// println!("get_context({})... len:{}", room.inst, context.len());
                (context)
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
                // Go over 1st level children
                let children_1: Span<Entity> = self._append_children_to_context(world, @room, ref context);
                for child_1 in children_1 {
                    // Go over 2nd level children
                    let children_2: Span<Entity> = self._append_children_to_context(world, child_1, ref context);
                    for child_2 in children_2 {
                        // Go over 3rd level children
                         self._append_children_to_context(world, child_2, ref context);
                    };
                };
// println!("get_full_context({})... len:{}", room.inst, context.len());
                context
            },
            Option::None => array![],
        }
    }

    //
    // Append all children to context
    fn _append_children_to_context(self: @Player, world: @WorldStorage, parent: @Entity, ref context: Array<Entity>) -> Span<Entity> {
        // Go over entity children
        let children: Span<Entity> = parent.get_children(world, *self.game_id);
        for child in children {
            context.append(child.clone());
        };
        // Add Trails inside Hub as if they were children
        if let Some(hub) = world.get_hub_component(*parent.inst) {
            hub.append_trails_as_children(world, ref context);
        }
        // return children for recursion
        (children)
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
            game_token_info::{GameTokenInfo},
            reactable::{Reactable, ReactableComponent},
            description_text::{DescriptionText},
            area::{Area, AreaComponent},
            exit::{Exit, ExitComponent},
        },
    };
    use lore::models::reactable::tests::{Reactable_create_prefab};

    #[test]
    fn test_player_create() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let game_id: u128 = 0;
        let player: Player = PlayerImpl::caller_as_player(ref sys.world, helpers::PLAYER_1, game_id);
        assert(player.is_player, 'player is player');

        let entity: Entity = PlayerComponent::entity(@player, @sys.world);
        assert(entity.inst == player.inst, 'entity.inst == player.inst');

        assert(PlayerInstance::has_component(@sys.world, player.inst), 'has_component()');
        let component: Option<Player> = PlayerComponent::get_component(@sys.world, player.inst, 0);
        assert(component.is_some(), 'component.is_some()');
        assert(component.unwrap().inst() == player.inst, 'component.is_some()');

        let reactable: Option<Reactable> = ReactableComponent::get_component(@sys.world, player.inst, 0);
        assert(reactable.is_some(), 'reactable.is_some()');
        assert(reactable.unwrap().inst() == player.inst, 'reactable.is_some()');
    }

    #[test]
    fn test_player_story_line() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let game_id: u128 = 123;
        let player: Player = PlayerImpl::caller_as_player(ref sys.world, helpers::PLAYER_1, game_id);
        assert(player.is_player, 'player is player');

        player.say(ref sys.world, "hello");
        let story: PlayerStory = sys.world.read_model(game_id);
        // ("story: {:?}", story);
        let story_key: u32 = 2;
        assert(story.story_line == 2, 'story has two entries'); // first entry is intro text
        let test_text: ByteArray = "hello";

        let story_line: StoryLine = sys.world.read_model((story.game_id, story_key));
        assert(story_line.line == test_text, 'story has "hello"');
        assert(story_line.line_type == StoryLineType::Response, 'command has "hello"');
    }

    fn _player_location(world: @WorldStorage, player: @Player) -> felt252 {
        let player: Player = world.read_game_model(*player.inst, *player.game_id);
        (player.location)
    }

    #[test]
    fn test_player_room_ok() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        // create some rooms
        let room_1_entity: Entity = EntityImpl::create_entity(ref sys.world, "room_1");
        let room_2_entity: Entity = EntityImpl::create_entity(ref sys.world, "room_2");
        let _room_1_reactable: Reactable = Reactable_create_prefab(ref sys.world, room_1_entity.inst, "ROOM1");
        let _room_2_reactable: Reactable = Reactable_create_prefab(ref sys.world, room_2_entity.inst, "ROOM2");
        assert_ne!(room_1_entity.inst, 0, "room_1_entity.inst > 0");
        assert_ne!(room_2_entity.inst, 0, "room_2_entity.inst > 0");
        assert_ne!(room_1_entity.inst, room_2_entity.inst, "room_1_entity.inst != room_2_entity.inst");
        // create base player
        let default_room_id: felt252 = 700111;
        let player: Player = PlayerImpl::caller_as_player(ref sys.world, helpers::PLAYER_1, 0);
        // mint game instance for players
        let game_id_1: u128 = 1;
        let game_id_2: u128 = 2;
        helpers::set_caller(helpers::PLAYER_1);
        sys.prompt.prompt("", Option::None);
        helpers::set_caller(helpers::PLAYER_2);
        sys.prompt.prompt("", Option::None);
        helpers::set_caller(helpers::OWNER());
        let player_1: Player = PlayerImpl::get_player(@sys.world, game_id_1).unwrap();
        let player_2: Player = PlayerImpl::get_player(@sys.world, game_id_2).unwrap();
        assert!(player.is_player, "is_player");
        assert!(player_1.is_player, "is_player");
        assert!(player_2.is_player, "is_player");
        assert_eq!(player.inst, 'Player');
        assert_eq!(player.inst, player_1.inst);
        assert_eq!(player.inst, player_2.inst);
        assert_eq!(player_1.game_id, game_id_1);
        assert_eq!(player_2.game_id, game_id_2);
        assert_eq!(_player_location(@sys.world, @player), default_room_id, "before move");
        assert_eq!(_player_location(@sys.world, @player_1), default_room_id, "before move");
        assert_eq!(_player_location(@sys.world, @player_2), default_room_id, "before move");
        assert!(player.get_room_entity(@sys.world).is_none(), "before move");
        assert!(player_1.get_room_entity(@sys.world).is_none(), "before move");
        assert!(player_2.get_room_entity(@sys.world).is_none(), "before move");
        // change room 2 description
        sys.world.write_model(@DescriptionText { inst: room_2_entity.inst, key: 0, text: "something else" });
        //
        // move game instance players
        let token_info_1: GameTokenInfo = sys.world.read_model(game_id_1);
        let token_info_2: GameTokenInfo = sys.world.read_model(game_id_2);
        assert_eq!(token_info_1.room_name, "Nowhere", "clean token info");
        assert_eq!(token_info_2.room_name, "Nowhere", "clean token info");
        player_1.move_to_room(ref sys.world, room_2_entity.inst);
        player_2.move_to_room(ref sys.world, room_1_entity.inst);
        assert_eq!(_player_location(@sys.world, @player), default_room_id, "moved game inst");
        assert_eq!(_player_location(@sys.world, @player_1), room_2_entity.inst, "moved game inst");
        assert_eq!(_player_location(@sys.world, @player_2), room_1_entity.inst, "moved game inst");
        assert_eq!(player.get_room_entity(@sys.world).is_none(), true, "moved game inst");
        assert_eq!(player_1.get_room_entity(@sys.world).unwrap().inst, room_2_entity.inst, "moved game inst");
        assert_eq!(player_2.get_room_entity(@sys.world).unwrap().inst, room_1_entity.inst, "moved game inst");
        // player token room
        let token_info_1: GameTokenInfo = sys.world.read_model(game_id_1);
        let token_info_2: GameTokenInfo = sys.world.read_model(game_id_2);
        assert_eq!(token_info_1.room_name, room_2_entity.name.clone(), "new act");
        assert_eq!(token_info_2.room_name, room_1_entity.name.clone(), "new act");
    }

    #[test]
    fn test_player_room_preserve() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        // create some rooms
        let (room_1_entity, area_1): (Entity, Area) = helpers::create_area_entity(ref sys, "This is Room 1", "ROOM1", Option::None);
        let (room_2_entity, mut area_2): (Entity, Area) = helpers::create_area_entity(ref sys, "This is Room 2", "ROOM2", Option::None);
        // create exits
        let (_exit_1_entity, _exit_to_room_2): (Entity, Exit) = helpers::create_exit_in_area(ref sys, "Exit To Room 2", "to_room_2", @room_1_entity, area_2.inst);
        let (_exit_2_entity, _exit_to_room_1): (Entity, Exit) = helpers::create_exit_in_area(ref sys, "Exit To Room 1", "to_room_1", @room_2_entity, area_1.inst);
        //
        // create player
        let game_id: u128 = 1;
        let player: Player = PlayerImpl::caller_as_player(ref sys.world, helpers::PLAYER_1, 0);
        helpers::set_caller(helpers::PLAYER_1);
        sys.prompt.prompt("", Option::None); // creates game token
        // place in Room 1
        helpers::set_caller(helpers::OWNER());
        player.move_to_room(ref sys.world, room_1_entity.inst);
        //
        // move to room 2
        helpers::set_caller(helpers::PLAYER_1);
        sys.prompt.prompt("g_game_id", Option::None);
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "+sys+game-1", "g_game_id");
        sys.prompt.prompt("use to_room_2", Option::None);
        sys.prompt.prompt("look around", Option::None);
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "to_room_1", "look 2");
        // move to room 1
        sys.prompt.prompt("use to_room_1", Option::None);
        sys.prompt.prompt("look around", Option::None);
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "to_room_2", "look 1");
        //
        // add new entity to room 2
        assert_eq!(room_2_entity.get_children_count(@sys.world, 0), 1, "after add");
        helpers::set_caller(helpers::OWNER());
        let mut new_entity: Entity = EntityImpl::create_entity(ref sys.world, "New Entity");
        let _: Reactable = Reactable_create_prefab(ref sys.world, new_entity.inst, "new_entity");
        new_entity.set_parent(ref sys.world, @room_2_entity, 0);
        helpers::set_caller(helpers::PLAYER_1);
        // one more children
        assert_eq!(room_2_entity.get_children_count(@sys.world, 0), 2, "after add");
        assert_eq!(room_2_entity.get_children_count(@sys.world, game_id), 1, "after add");
        //
        // enter room 2, look around... new entity not present
        sys.prompt.prompt("use to_room_2", Option::None);
        assert_eq!(room_2_entity.get_children_count(@sys.world, game_id), 1+1, "use after add");
        sys.prompt.prompt("look around", Option::None);
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "to_room_1", "use after add");
        sys.prompt.prompt("use to_room_1", Option::None);
        //
        // enable preserve_children
        helpers::set_caller(helpers::OWNER());
        area_2.preserve_children = true;
        sys.world.write_model(@area_2);
        helpers::set_caller(helpers::PLAYER_1);
        //
        // enter room 2, look around... new entity not present
        sys.prompt.prompt("use to_room_2", Option::None);
        assert_eq!(room_2_entity.get_children_count(@sys.world, game_id), 2+1, "after preserve");
        let token_info: GameTokenInfo = sys.world.read_model(game_id);
        assert_eq!(token_info.room_name, room_2_entity.name.clone(), "after to_room_2");
        sys.prompt.prompt("look around", Option::None);
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "new_entity", "after preserve");
        sys.prompt.prompt("use to_room_1", Option::None);
        let token_info: GameTokenInfo = sys.world.read_model(game_id);
        assert_eq!(token_info.room_name, room_1_entity.name.clone(), "after to_room_1");
    }

    #[test]
    fn test_player_say() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let game_id_0: u128 = 0;
        let game_id_1: u128 = 123;
        let game_id_2: u128 = 456;
        let player_0: Player = PlayerImpl::caller_as_player(ref sys.world, helpers::PLAYER_1, 0);
        let player_1: Player = PlayerImpl::caller_as_player(ref sys.world, helpers::PLAYER_1, game_id_1);
        assert_eq!(player_0.game_id, game_id_0, "story_start");
        assert_eq!(player_1.game_id, game_id_1, "story_start");
        assert_eq!(helpers::game_story_len(@sys.world, game_id_0), 1, "story_start");
        assert_eq!(helpers::game_story_len(@sys.world, game_id_1), 1, "story_start");
        assert_eq!(helpers::game_story_len(@sys.world, game_id_2), 0, "story_start");
        // say something...
        player_0.say(ref sys.world, "hello");
        player_1.say(ref sys.world, "sys.world");
        player_1.say(ref sys.world, "sys.world");
        assert_eq!(helpers::game_story_len(@sys.world, game_id_0), 2, "said");
        assert_eq!(helpers::game_story_len(@sys.world, game_id_1), 3, "said");
        assert_eq!(helpers::game_story_len(@sys.world, game_id_2), 0, "said");
        // create new player
        let player_2: Player = PlayerImpl::caller_as_player(ref sys.world, helpers::PLAYER_1, game_id_2);
        assert_eq!(player_2.game_id, game_id_2, "story_start");
        assert_eq!(helpers::game_story_len(@sys.world, game_id_2), 1, "new_player");
        // say more...
        player_1.say(ref sys.world, "burp");
        player_2.say(ref sys.world, "blah");
        player_2.say(ref sys.world, "blah");
        player_2.say(ref sys.world, "blah");
        player_2.say(ref sys.world, "blah");
        player_2.say(ref sys.world, "blah");
        assert_eq!(helpers::game_story_len(@sys.world, game_id_0), 2, "said_more");
        assert_eq!(helpers::game_story_len(@sys.world, game_id_1), 4, "said_more");
        assert_eq!(helpers::game_story_len(@sys.world, game_id_2), 6, "said_more");
    }
}
