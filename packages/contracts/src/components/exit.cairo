use super::super::lib::a_lexer::CommandTrait;
use dojo::{world::{WorldStorage}, model::ModelStorage};

use lore::{
    constants::errors::Error, constants,
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
        let direction_tokens = command.get_directions();

        let mut destination_inst: felt252 = 0;
        match action.action_fn {
            ExitActions::UseExit => {
                if *player.use_debug {
                    player.say(world, format!("You go to {:?}", self));
                }

                let mut matchesName = false;
                let nouns = command.get_nouns();
                let names = self.entity(@world).get_names();
                for noun in nouns {
                    for name in names.clone() {
                        if noun.text == name {
                            matchesName = true;
                            break;
                        }
                    }
                };

                let mut matchesDirection = false;
                if (direction_tokens.len() > 0
                    && matches_direction(@self, world, player, @direction_tokens).is_some()) {
                    matchesDirection = true;
                }

                // we need to either match by name or by direction
                if (!(matchesName || matchesDirection)) {
                    return Result::Err(Error::ActionFailed);
                }
                // if the exit is not enterable, we can't go there
                if (!self.clone().can_player_enter()) {
                    return Result::Err(Error::ActionFailed);
                }

                destination_inst = self.leads_to;
                player.clone().move_to_room(world, destination_inst);
                let _ = player.describe_room(world);
                return Result::Ok(());
            },
        }
        Result::Err(Error::ActionFailed)
    }

    fn store(self: @Exit, mut world: WorldStorage) {
        world.write_model(self);
    }
}

fn matches_direction(
    self: @Exit, world: WorldStorage, player: @Player, directions_token: @Array<Token>,
) -> Option<felt252> {
    if (directions_token.len() == 0) {
        return Option::None;
    }
    let exit_dir = ByteArrayTraitExt::byte_array_from_direction(*self.direction_type);
    let dir_text = constants::direction_one_letter(directions_token[0].text);
    println!("area_dir: {:?}", directions_token[0]);
    if (exit_dir == dir_text) {
        return Option::Some(*self.leads_to);
    }
    Option::None
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
