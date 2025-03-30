use super::super::components::player::PlayerTrait;
use dojo::{world::WorldStorage};

use lore::{ //
    lib::{ //
        entity::EntityImpl, //
        a_lexer::{Command, TokenType}, utils::ByteArrayTraitExt,
        dictionary::{init_dictionary, add_to_dictionary}, level_test::{create_test_level} //
    }, //
    constants::errors::Error, //
    components::{player::{Player, PlayerImpl}},
};

pub fn handle_command(
    mut command: Command, world: WorldStorage, player: Player,
) -> Result<Command, Error> {
    if system_command(command.clone(), world, player).is_err() {
        return Result::Err(Error::ActionFailed);
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
            return Result::Err(Error::ActionFailed);
        }
        if (system_command == "g_command") {
            println!("g_command: {:?}", system_command);
            player.say(world, format!("+sys+{:?}", command));
            return Result::Ok(command);
        }
        if (system_command == "g_move") {
            player.move_to_room(world, 2826);
            player.say(world, "+sys+forced move command");
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
            let room = EntityImpl::get_entity(world, 2826);
            player.say(world, format!("+sys+{:?}", room));
            return Result::Ok(command);
        }
        return Result::Err(Error::ActionFailed);
    }
    Result::Ok(command)
}

#[cfg(test)]
mod tests {
    use lore::systems::prompt::{IPromptDispatcherTrait};
    use super::*;
    use lore::tests::helpers;
    use lore::components::player::{caller_as_player};
    use lore::lib::a_lexer::{Token, TokenType, Command};
    use lore::lib::utils::ByteArrayTraitExt;

    #[test]
    fn CHandler_test_g_command_handling() {
        // Setup test environment
        let (world, _, prompt, player_1, _) = helpers::setup_core();
        prompt.prompt("g_command test");
        let player = caller_as_player(world, player_1);

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

