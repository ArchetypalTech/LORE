use dojo::{world::WorldStorage, model::ModelStorage};
use lore::{
    constants::{errors::Error, constants::Direction},
    lib::{entity::{EntityImpl}, a_lexer::{Command, Token, CommandTrait}},
};
use super::{Component, player::{Player, PlayerImpl, PlayerTrait}};

#[derive(Clone, Drop, Serde, Introspect, Debug)]
#[dojo::model]
pub struct Area {
    #[key]
    pub inst: felt252,
    pub is_area: bool,
    pub is_enterable: bool,
    //properties
    pub leads_to: felt252,
    pub direction: Direction,
    pub action_map: Array<DirectionMap>,
}

#[derive(Clone, Drop, Serde, Introspect, Debug)]
pub struct DirectionMap {
    pub action: ByteArray,
    pub inst: felt252,
    pub action_fn: DirectionActionsMap,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum DirectionActionsMap {
    UseDirection,
}

pub impl AreaComponent of Component<Area> {
    type ComponentType = Area;

    fn inst(self: @Area) -> @felt252 {
        self.inst
    }

    fn has_component(self: @Area, world: WorldStorage, inst: felt252) -> bool {
        let area: Area = world.read_model(inst);
        area.is_area
    }

    fn add_component(mut world: WorldStorage, inst: felt252) -> Area {
        let mut area: Area = world.read_model(inst);
        area.inst = inst;
        area.is_area = true;
        // area.action_map = array![("look", InspectableActions::read_description)];
        area
            .action_map =
                array![
                    DirectionMap {
                        action: "go", inst: 0, action_fn: DirectionActionsMap::UseDirection,
                    },
                    DirectionMap {
                        action: "exit", inst: 0, action_fn: DirectionActionsMap::UseDirection,
                    },
                ];
        area.store(world);
        world.write_model(@area);
        area
    }

    fn get_component(world: WorldStorage, inst: felt252) -> Option<Area> {
        let area: Area = world.read_model(inst);
        if (!area.has_component(world, inst)) {
            return Option::None;
        }
        let area: Area = world.read_model(inst);
        Option::Some(area)
    }

    fn can_use_command(
        self: @Area, world: WorldStorage, player: @Player, command: @Command,
    ) -> bool {
        true
    }

    fn execute_command(
        self: Area, world: WorldStorage, player: @Player, command: @Command,
    ) -> Result<(), Error> {
        println!("Area execute_command");
        let (action, token) = get_action_token(@self, world, command).unwrap();
        // Match the action to use for the Direction
        match action.action_fn {
            DirectionActionsMap::UseDirection => {
                if *player.use_debug {
                    player.say(world, format!("You go to {:?}", self));
                }
                // From command, retrive the direction. If valid go to leads_to
                println!("you are trying to go to the {:?}", token.token_type);
                player.say(world, format!("you are trying to go to the {:?}", token.token_type));
                // if valid_direction(token.clone(), command) {
                //     println!("valid_direction, you are going to the {:?}", token.token_type);
                player.clone().move_to_room(world, self.leads_to);
                let _ = player.describe_room(world);
                return Result::Ok(());
                // } else {
            //     return Result::Err(Error::ActionFailed);
            // }
            },
        }
        Result::Err(Error::Unimplemented)
    }

    fn store(self: @Area, mut world: WorldStorage) {
        world.write_model(self);
    }
}

// @dev: wip how to access tokens
fn get_action_token(
    self: @Area, world: WorldStorage, command: @Command,
) -> Option<(DirectionMap, Token)> {
    let mut action_token: Option<(DirectionMap, Token)> = Option::None;
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
// Compare token.target with command.get_directions()
// fn valid_direction(token: Token, command: @Command) -> bool {
//     let mut valid: bool = false;
//     for direction in command.get_directions() {
//         if token.token_type == direction.target {
//             valid = true;
//             break;
//         }
//     };
//     valid
// }


