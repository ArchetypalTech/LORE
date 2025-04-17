use super::super::lib::utils::ByteArrayTrait;
use super::super::lib::a_lexer::CommandTrait;
use dojo::{world::{WorldStorage}, model::ModelStorage};

use lore::{
    constants::errors::Error,
    lib::{
        entity::{Entity, EntityImpl}, a_lexer::{Command, Token, CommandImpl},
        utils::ByteArrayTraitExt,
    },
    components::area::{AreaComponent},
};

use lore::constants::constants::Direction;
use super::{Component, player::{Player, PlayerImpl, PlayerTrait}};


#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum ExitActions {
    UseExit,
}

#[derive(Clone, Drop, Serde, Debug)]
#[dojo::model]
pub struct Exit {
    #[key]
    pub inst: felt252,
    pub is_exit: bool,
    // properties
    pub is_enterable: bool,
    pub leads_to: felt252,
    pub direction_type: Direction,
    pub action_map: Array<ActionMapExit>,
}

#[derive(Clone, Drop, Serde, Introspect, Debug)]
pub struct ActionMapExit {
    pub action: ByteArray,
    pub inst: felt252,
    pub action_fn: ExitActions,
}

#[generate_trait]
pub impl ExitImpl of ExitTrait {
    fn is_exit(self: Exit) -> bool {
        self.is_exit
    }

    fn can_player_enter(self: Exit) -> bool {
        self.is_enterable
    }
}

pub impl ExitComponent of Component<Exit> {
    type ComponentType = Exit;

    fn inst(self: @Exit) -> @felt252 {
        self.inst
    }

    fn entity(self: @Exit, world: @WorldStorage) -> Entity {
        EntityImpl::get_entity(world, self.inst).unwrap()
    }

    fn has_component(self: @Exit, world: WorldStorage, inst: felt252) -> bool {
        let exit: Exit = world.read_model(inst);
        exit.is_exit
    }

    fn add_component(mut world: WorldStorage, inst: felt252) -> Exit {
        let mut exit: Exit = world.read_model(inst);
        exit.inst = inst;
        exit.is_exit = true;
        exit
            .action_map =
                array![
                    ActionMapExit { action: "go", inst: 0, action_fn: ExitActions::UseExit },
                    ActionMapExit { action: "enter", inst: 0, action_fn: ExitActions::UseExit },
                    ActionMapExit { action: "use", inst: 0, action_fn: ExitActions::UseExit },
                ];
        exit.store(world);
        exit
    }

    fn get_component(world: WorldStorage, inst: felt252) -> Option<Exit> {
        let exit: Exit = world.read_model(inst);
        if (!exit.has_component(world, inst)) {
            return Option::None;
        }
        let exit: Exit = world.read_model(inst);
        Option::Some(exit)
    }

    fn can_use_command(
        self: @Exit, world: WorldStorage, player: @Player, command: @Command,
    ) -> bool {
        get_action_token(self, world, command).is_some()
    }

    fn execute_command(
        mut self: Exit, mut world: WorldStorage, player: @Player, command: @Command,
    ) -> Result<(), Error> {
        println!("Exit execute_command");
        let (action, _token) = get_action_token(@self, world, command).unwrap();
        let directions_token = command.get_directions();
        // player.say(world, format!("Command: {:?}", command));
        // player.say(world, format!("Action: {:?}", action));
        // player.say(world, format!("Token: {:?}", token));
        // player.say(world, format!("Directions: {:?}", directions_token));
        match action.action_fn {
            ExitActions::UseExit => {
                if *player.use_debug {
                    player.say(world, format!("You go to {:?}", self));
                }
                // check if there is a direction token
                if (directions_token.len() > 0) {
                    // Check if the destination room entity area value is the same as the direction
                    // token
                    return go_destination_by_direction(@self, world, player, command);
                } else {
                    // Default implementation
                    player.clone().move_to_room(world, self.leads_to);
                    player.say(world, format!(" Else - You are going to {:?}", self.leads_to));
                    let _ = player.describe_room(world);
                    return Result::Ok(());
                }
            },
        }
        Result::Err(Error::ActionFailed)
    }

    fn store(self: @Exit, mut world: WorldStorage) {
        world.write_model(self);
    }
}

fn go_destination_by_direction(
    self: @Exit, world: WorldStorage, player: @Player, command: @Command,
) -> Result<(), Error> {
    let directions_token = command.get_directions();
    // player.say(world,format!("You are trying to go to: {:?}", directions_token[0].text));
    // println!("you are trying to go to: {:?}", directions_token[0]);
    let destination_room = EntityImpl::get_entity(@world, self.leads_to).unwrap();
    match AreaComponent::get_component(world, destination_room.inst) {
        Option::Some(area) => {
            let area_dir = ByteArrayTraitExt::byte_array_from_direction(area.direction);
            let dir_text = direction_one_letter(directions_token[0].text);
            if (area_dir == dir_text) {
                player.clone().move_to_room(world, *self.leads_to);
                let _ = player.describe_room(world);
                return Result::Ok(());
            } else {
                player.say(world, format!("You can't go that way"));
                return Result::Err(Error::ActionFailed);
            }
        },
        Option::None => {},
    }
    Result::Err(Error::ActionFailed)
}

fn direction_one_letter(direction: @ByteArray) -> ByteArray {
    let mut text: ByteArray = "";
    if (direction.starts_with(@"n")) {
        text = "north";
    } else if (direction.starts_with(@"s")) {
        text = "south";
    } else if (direction.starts_with(@"e")) {
        text = "east";
    } else if direction.starts_with(@"w") {
        text = "west";
    } else if direction.starts_with(@"u") {
        text = "up";
    } else if direction.starts_with(@"d") {
        text = "down";
    }
    text
}

// @dev: wip how to access tokens
fn get_action_token(
    self: @Exit, world: WorldStorage, command: @Command,
) -> Option<(ActionMapExit, Token)> {
    let mut action_token: Option<(ActionMapExit, Token)> = Option::None;
    for token in command.tokens.clone() {
        for action in self.action_map.clone() {
            if (token.text == action.action) {
                action_token = Option::Some((action, token));
                break;
            }
        }
    };
    action_token
}
