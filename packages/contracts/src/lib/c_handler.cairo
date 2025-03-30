use super::super::components::player::PlayerTrait;
use dojo::{world::WorldStorage};

use lore::lib::a_lexer::{Command, TokenType};
use lore::lib::utils::ByteArrayTraitExt;
use lore::constants::errors::Error;
use lore::components::{player::{Player, PlayerImpl}};
use lore::lib::dictionary::{init_dictionary};

pub fn handle_command(
    mut command: Command, world: WorldStorage, player: Player,
) -> Result<Command, Error> {
    if system_command(command.clone(), world, player).is_err() {
        return Result::Err(Error::ActionFailed);
    }
    Result::Ok(command)
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
            player.say(world, format!("{}", '+sys+forced move command'));
            player.move_to_room(world, 2826);
            return Result::Ok(command);
        }
        if (system_command == "g_init_dict") {
            init_dictionary(world);
            player.say(world, "+sys+dictionary re-initialized");
            return Result::Ok(command);
        } else {
            return Result::Err(Error::ActionFailed);
        }
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
        assert(result.is_ok(), 'Command sb handled successfully');
    }
}

