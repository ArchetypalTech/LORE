use dojo::{world::WorldStorage};
use lore::{
    models::{
        entity::{Entity, EntityImpl},
        area::{AreaComponent},
        exit::{Exit, ExitComponent},
        reactable::{Reactable, ReactableImpl, ReactableComponent},
        inventory_item::{InventoryItemComponent},
        container::{Container, ContainerImpl, ContainerComponent},
        player::{Player, PlayerImpl},
        components::{Component},
        action::{ActionImpl},
        condition::{ConditionImpl},
    },
    types::command_type::{Command, TokenType, Token},
    lib::{
        a_lexer::CommandImpl,
        utils::ByteArrayTraitExt,
        dictionary::{init_dictionary, add_to_dictionary},
        level_test::{create_test_level},
    },
    constants::errors::Error,
};

pub fn handle_command(
    mut command: Command, ref world: WorldStorage, player: Player,
) -> Result<Command, Error> {
    let sys_command = command.is_system_command();
    if sys_command {
        return system_command(command.clone(), ref world, player);
    }
    let verbs = command.get_verbs();
    if verbs.len() == 0 {
        return Result::Err(Error::ActionFailed);
    }
    let mut nouns = command.get_nouns();
    let mut directions = command.get_directions();
    let mut executed: Option<bool> = Option::None;
    let mut result: Result::<Command, Error> = Result::Err(Error::ActionFailed);
    if nouns.len() > 0 {
        for noun in nouns {
            let item: Entity = EntityImpl::get_entity(@world, noun.target).unwrap();
            if player.use_debug {
                player.say(world, format!("item: {:?}", item));
            }
            match ReactableComponent::get_component(@world, item.inst, command.game_id) {
                Option::Some(c) => {
                    if c.clone().can_use_command(@world, @player, @command) {
                        let res = c.clone().execute_command(ref world, @player, @command);
                        match res {
                            Result::Ok(()) => {
                                executed = Option::Some(true);
                            },
                            Result::Err(e) => {
                                executed = Option::Some(false);
                                result = Result::Err(e);
                            },
                        }
                        break;
                    }
                },
                Option::None => {},
            }
            match AreaComponent::get_component(@world, item.inst, command.game_id) {
                Option::Some(c) => {
                    if c.can_use_command(@world, @player, @command) {
                        let res = c.execute_command(ref world, @player, @command);
                        match res {
                            Result::Ok(()) => {
                                executed = Option::Some(true);
                            },
                            Result::Err(e) => {
                                executed = Option::Some(false);
                                result = Result::Err(e);
                            },
                        }
                        break;
                    }
                },
                Option::None => {},
            }
            // @dev: guaranteed there's a noun
            match ExitComponent::get_component(@world, item.inst, command.game_id) {
                Option::Some(c) => {
                    if c.can_use_command(@world, @player, @command) {
                        let res = c.execute_command(ref world, @player, @command);
                        match res {
                            Result::Ok(()) => {
                                executed = Option::Some(true);
                            },
                            Result::Err(e) => {
                                executed = Option::Some(false);
                                result = Result::Err(e);
                            },
                        }
                        break;
                    }
                },
                Option::None => {},
            }
            match InventoryItemComponent::get_component(@world, item.inst, command.game_id) {
                Option::Some(c) => {
                    if c.can_use_command(@world, @player, @command) {
                        let res = c.execute_command(ref world, @player, @command);
                        match res {
                            Result::Ok(()) => {
                                executed = Option::Some(true);
                            },
                            Result::Err(e) => {
                                executed = Option::Some(false);
                                result = Result::Err(e);
                            },
                        }
                        break;
                    }
                },
                Option::None => {},
            }
            match ContainerComponent::get_component(@world, item.inst, command.game_id) {
                Option::Some(c) => {
                    if c.can_use_command(@world, @player, @command) {
                        let res = c.execute_command(ref world, @player, @command);
                        match res {
                            Result::Ok(()) => {
                                executed = Option::Some(true);
                            },
                            Result::Err(e) => {
                                executed = Option::Some(false);
                                result = Result::Err(e);
                            },
                        }
                        break;
                    }
                },
                Option::None => {},
            };
        };
    } else if directions.len() > 0 {
        let context = player.get_context(@world);
        for item in context {
            let exit: Option<Exit> = Component::get_component(@world, item.inst, command.game_id);
            // @dev: not guaranteed there's a noun
            match exit {
                Option::Some(exit) => {
                    if exit.can_use_command(@world, @player, @command) {
                        let res = exit.execute_command(ref world, @player, @command);
                        match res {
                            Result::Ok(()) => {
                                executed = Option::Some(true);
                            },
                            Result::Err(e) => {
                                executed = Option::Some(false);
                                result = Result::Err(e);
                            },
                        }
                        break;
                    }
                },
                Option::None => {},
            }
        };
    }

    //println!("executed: {:?}", executed);
    match executed {
        Option::Some(executed) => {
            return if (executed) {
                Result::Ok(command)
            } else {
                result
            };
        },
        Option::None => {},
    };

    // We haven't found any targets that have a verb mapped to the action
    // Are there any default actions we can do?
    // if command is just one token,
    if command.tokens.len() == 1 {
        let initialVerb: felt252 = verbs.at(0).text.to_felt252_word().unwrap();
        if initialVerb == 'look' {
            let res = player.describe_room(world, command.game_id);
            if res.is_err() {
                return Result::Err(res.unwrap_err());
            };
            return Result::Ok(command);
        }
        if initialVerb == 'inventory' {
            let personal_container = player.get_personal_container(@world, command.game_id);
            if personal_container.is_none() {
                return Result::Err(Error::NoPersonalContainer);
            }
            let container_component: Container = personal_container.unwrap();
            let noun: ByteArray = "Your";
            let done = container_component.check_container(@world, @player, @noun);
            if !done {
                return Result::Err(Error::ActionFailed);
            }
            return Result::Ok(command);
        }
    } else {
        if command.tokens.len() == 2 {
            let initialVerb: felt252 = verbs.at(0).text.to_felt252_word().unwrap();
            let secondToken: Token = command.tokens.at(1).clone();
            if initialVerb == 'look' {
                let around: ByteArray = "around";
                let at: ByteArray = "at";
                if secondToken.text == around {
                    let res = player.describe_room(world, command.game_id);
                    if res.is_err() {
                        return Result::Err(res.unwrap_err());
                    };
                    return Result::Ok(command);
                }
                if secondToken.text == at {
                    return Result::Err(Error::NoTarget);
                }
            }
            // if initial verb is not look
            // return error
            return Result::Err(Error::ActionFailed);
        }
        // if command is more than one token and haven't been handled yet
        // return error
        return Result::Err(Error::ActionFailed);
    }

    result
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
    mut command: Command, ref world: WorldStorage, player: Player,
) -> Result<Command, Error> {
    let mut system_command: ByteArray = "";
    for token in command.clone().tokens {
        if token.token_type == TokenType::System {
            system_command = token.text;
            break;
        }
    };
    if system_command != "" {
        // println!("not zero: {:?}", system_command);
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
            modifiedPlayer.store(ref world, command.game_id);
            return Result::Ok(command);
        }
        if (system_command == "g_command") {
            // println!("g_command: {:?}", system_command);
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
            let reactable: Reactable = Component::get_component(@world, room.unwrap().inst, command.game_id).unwrap();
            player.say(world, format!("+sys+{:?}", reactable));
            return Result::Ok(command);
        }
        if (system_command == "g_init_dict") {
            init_dictionary(world);
            init_system_dictionary(world);
            player.say(world, "+sys+dictionary re-initialized");
            return Result::Ok(command);
        }
        if (system_command == "g_level") {
            create_test_level(ref world, command.game_id);
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
                let reactable: Option<Reactable> = Component::get_component(@world, item.inst, command.game_id);
                if reactable.is_some() {
                    let description = reactable.unwrap().get_random_description(@command, world);
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
    use lore::{
        models::player::{PlayerImpl},
        types::command_type::{Command, Token, TokenType},
        lib::utils::ByteArrayTraitExt,
    };

    #[test]
    fn CHandler_test_g_command_handling() {
        // Setup test environment
        let (mut world, _, _, player_1, _) = helpers::setup_core();
        let game_id: u128 = 0;
        create_test_level(ref world, game_id);
        let player = PlayerImpl::caller_as_player(ref world, player_1, game_id);
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
            game_id,
        };
        // Handle the command
        let result = handle_command(command.clone(), ref world, player.clone());

        // Verify the command was handled successfully
        assert(result.is_ok(), 'Command not handled');
    }
}

