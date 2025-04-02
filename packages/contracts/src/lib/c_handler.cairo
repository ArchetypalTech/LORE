use super::a_lexer::CommandTrait;
use super::super::components::player::PlayerTrait;
use dojo::{world::WorldStorage};

use lore::{ //
    lib::{ //
        entity::{EntityImpl}, //
        a_lexer::{Command, CommandImpl, TokenType},
        utils::ByteArrayTraitExt, dictionary::{init_dictionary, add_to_dictionary},
        level_test::{create_test_level} //
    }, //
    constants::errors::Error, //
    components::{
        player::{Player, PlayerImpl}, area::{Area, AreaComponent}, Component,
        inspectable::{Inspectable, InspectableImpl, InspectableComponent},
    } //
};

pub fn handle_command(
    mut command: Command, world: WorldStorage, player: Player,
) -> Result<Command, Error> {
    let sys_command = command.is_system_command();
    if sys_command {
        return system_command(command.clone(), world, player);
    }
    let context = player.get_context(@world);
    let mut executed: bool = false;
    for item in context {
        match InspectableComponent::get_component(world, item.inst) {
            Option::Some(inspectable) => {
                if inspectable.can_use_command(world, @player, @command) {
                    if inspectable.execute_command(world, @player, @command).is_ok() {
                        executed = true;
                        break;
                    }
                }
            },
            Option::None => {},
        }
        match AreaComponent::get_component(world, item.inst) {
            Option::Some(area) => {
                if area.can_use_command(world, @player, @command) {
                    if area.execute_command(world, @player, @command).is_ok() {
                        executed = true;
                        break;
                    }
                }
            },
            Option::None => {},
        }
    };
    if executed {
        return Result::Ok(command);
    }
    Result::Ok(command)
}

pub fn init_system_dictionary(world: WorldStorage) {
    add_to_dictionary(world, "system_initialized", TokenType::System, 2).unwrap();
    add_to_dictionary(world, "g_move", TokenType::System, 2).unwrap();
    add_to_dictionary(world, "g_init_dict", TokenType::System, 2).unwrap();
    add_to_dictionary(world, "g_command", TokenType::System, 2).unwrap();
    add_to_dictionary(world, "g_error", TokenType::System, 2).unwrap();
    add_to_dictionary(world, "g_level", TokenType::System, 2).unwrap();
    add_to_dictionary(world, "g_whereami", TokenType::System, 2).unwrap();
    add_to_dictionary(world, "g_look", TokenType::System, 2).unwrap();
}

fn get_sys_command(mut command: @Command) -> Option<ByteArray> {
    let mut system_command: ByteArray = "";
    for token in command.clone().tokens {
        if token.token_type == TokenType::System {
            system_command = token.text;
            break;
        }
    };
    if system_command == "" {
        return Option::None;
    }
    Option::Some(system_command)
}

fn system_command(
    mut command: Command, world: WorldStorage, player: Player,
) -> Result<Command, Error> {
    let mut system_command: ByteArray = "";
    for token in command.clone().tokens {
        if token.token_type == TokenType::System {
            system_command = token.text;
            break;
        }
    };
    if system_command != "" {
        println!("not zero: {:?}", system_command);
        if (system_command == "g_error") {
            return Result::Err(Error::TestError);
        }
        if (system_command == "g_command") {
            println!("g_command: {:?}", system_command);
            player.say(world, format!("+sys+{:?}", command));
            return Result::Ok(command);
        }
        if (system_command == "g_move") {
            player.move_to_room(world, 2826);
            player.say(world, "+sys+forced move command");
            let room = player.get_room(@world);
            if room.is_none() {
                return Result::Err(Error::ActionFailed);
            }
            let inspectable: Inspectable = Component::get_component(world, room.unwrap().inst)
                .unwrap();
            player.say(world, format!("+sys+{:?}", inspectable));
            return Result::Ok(command);
        }
        if (system_command == "g_init_dict") {
            init_dictionary(world);
            init_system_dictionary(world);
            player.say(world, "+sys+dictionary re-initialized");
            return Result::Ok(command);
        }
        if (system_command == "g_level") {
            create_test_level(world);
            player.say(world, "+sys+created test level");
            return Result::Ok(command);
        }
        if (system_command == "g_whereami") {
            player.say(world, "+sys+you are here:");
            let room = player.get_room(@world);
            player.say(world, format!("+sys+{:?}", room));
            player.say(world, format!("+sys+{:?}", player.entity(@world).get_parent(@world)));
            return Result::Ok(command);
        }
        if (system_command == "g_look") {
            player.say(world, "+sys+you see this:");
            let context = player.get_context(@world);
            let room = player.get_room(@world);
            if room.is_none() {
                return Result::Err(Error::ActionFailed);
            }
            player.say(world, format!("{}", room.unwrap().name));
            for item in context {
                let inspectable: Option<Inspectable> = Component::get_component(world, item.inst);
                if inspectable.is_some() {
                    let description = inspectable.unwrap().get_random_description(world);
                    player.say(world, format!("{}", description));
                }
            };
            return Result::Ok(command);
        }
        return Result::Err(Error::NotSystemAction);
    }
    Result::Err(Error::NotSystemAction)
}

#[cfg(test)]
mod tests {
    use super::*;
    use lore::tests::helpers;
    use lore::components::player::{caller_as_player};
    use lore::lib::a_lexer::{Token, TokenType, Command};
    use lore::lib::utils::ByteArrayTraitExt;

    #[test]
    fn CHandler_test_g_command_handling() {
        // Setup test environment
        let (world, _, _, player_1, _) = helpers::setup_core();
        create_test_level(world);
        let player = caller_as_player(world, player_1);
        player.move_to_room(world, 2826);

        // Create a test command with g_command system token
        let mut command = Command {
            command_id: 1,
            text: "g_command test",
            words: array!["g_command", "test"],
            token_count: 2,
            action_type: 0,
            tokens: array![
                Token {
                    position: 0,
                    text: "g_command",
                    token_type: TokenType::System,
                    token_value: 2,
                    target: 0,
                },
                Token {
                    position: 1,
                    text: "test",
                    token_type: TokenType::Unknown,
                    token_value: 0,
                    target: 0,
                },
            ],
        };
        // Handle the command
        let result = handle_command(command.clone(), world, player.clone());

        // Verify the command was handled successfully
        assert(result.is_ok(), 'Command not handled');
    }
}

