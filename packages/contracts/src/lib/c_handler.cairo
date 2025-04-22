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
        player::{Player, PlayerImpl}, area::{AreaComponent}, exit::{ExitComponent}, Component,
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
    let verbs = command.get_verbs();
    if verbs.len() == 0 {
        return Result::Err(Error::ActionFailed);
    }
    let mut executed: bool = false;
    let mut nouns = command.get_nouns();
    let mut directions = command.get_directions();
    if nouns.len() > 0 {
        for noun in nouns {
            let item = EntityImpl::get_entity(@world, @noun.target).unwrap();
            match InspectableComponent::get_component(world, item.inst) {
                Option::Some(c) => {
                    if c.clone().can_use_command(world, @player, @command) {
                        if c.clone().execute_command(world, @player, @command).is_ok() {
                            executed = true;
                            break;
                        }
                    }
                },
                Option::None => {},
            };
            match AreaComponent::get_component(world, item.inst) {
                Option::Some(c) => {
                    if c.can_use_command(world, @player, @command) {
                        if c.execute_command(world, @player, @command).is_ok() {
                            executed = true;
                            break;
                        }
                    }
                },
                Option::None => {},
            }
            match ExitComponent::get_component(world, item.inst) {
                Option::Some(c) => {
                    if c.can_use_command(world, @player, @command) {
                        if c.execute_command(world, @player, @command).is_ok() {
                            executed = true;
                            break;
                        }
                    }
                },
                Option::None => {},
            }
        };
    } else if directions.len() > 0 {
        let room = player.get_room(@world);
        if room.is_none() {
            return Result::Err(Error::ActionFailed);
        }

        let room_ung = room.unwrap();
        for _direction in directions {
            let item = EntityImpl::get_entity(@world, @room_ung.inst).unwrap();
            match ExitComponent::get_component(world, item.inst) {
                Option::Some(c) => {
                    if c.can_use_command(world, @player, @command) {
                        if c.execute_command(world, @player, @command).is_ok() {
                            executed = true;
                            break;
                        }
                    }
                },
                Option::None => {},
            }
        };
    }

    if executed {
        return Result::Ok(command);
    }

    // We haven't found any targets that have a verb mapped to the action
    // Are there any default actions we can do?
    let initialVerb: felt252 = verbs.at(0).text.to_felt252_word().unwrap();
    if initialVerb == 'look' {
        let res = player.describe_room(world);
        if res.is_err() {
            return Result::Err(Error::ActionFailed);
        };
        return Result::Ok(command);
    }
    Result::Err(Error::ActionFailed)
}

pub fn init_system_dictionary(world: WorldStorage) {
    add_to_dictionary(world, "system_initialized", TokenType::System, 2).unwrap();
    add_to_dictionary(world, "g_debug", TokenType::System, 2).unwrap();
    add_to_dictionary(world, "g_command", TokenType::System, 2).unwrap();
    add_to_dictionary(world, "g_move", TokenType::System, 2).unwrap();
    add_to_dictionary(world, "g_init_dict", TokenType::System, 2).unwrap();
    add_to_dictionary(world, "g_error", TokenType::System, 2).unwrap();
    add_to_dictionary(world, "g_level", TokenType::System, 2).unwrap();
    add_to_dictionary(world, "g_whereami", TokenType::System, 2).unwrap();
    add_to_dictionary(world, "g_look", TokenType::System, 2).unwrap();
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
        if (system_command == "g_debug") {
            let mut modifiedPlayer = player;
            modifiedPlayer.use_debug = !player.use_debug;
            if modifiedPlayer.use_debug {
                player.say(world, "+sys+you are in debug mode");
            } else {
                player.say(world, "+sys+you are no longer in debug mode");
            }
            modifiedPlayer.store(world);
            return Result::Ok(command);
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

