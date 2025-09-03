use dojo::{world::WorldStorage};
use lore::{
    models::{
        entity::{Entity, EntityImpl},
        index::{Reactable, Exit, Container, Player},
        area::AreaComponent,
        exit::ExitComponent,
        reactable::ReactableComponent,
        inventoryItem::InventoryItemComponent,
        container::ContainerComponent,
        player::PlayerComponent,
        components::Component,
    },
    new_components::{
        player_trait::PlayerImpl,
        reactable_trait::ReactableImpl,
        container_trait::ContainerImpl,
        condition_trait::ConditionImpl,
        action_trait::ActionImpl,
    },
    types::command_type::{Command, TokenType, Token},
    lib::{
        a_lexer::CommandImpl, utils::ByteArrayTraitExt,
        dictionary::{init_dictionary, add_to_dictionary}, level_test::{create_test_level},
    },
    constants::errors::Error,
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
    let mut result: Result::<Command, Error> = Result::Err(Error::ActionFailed);
    let mut found_error = false;
    if nouns.len() > 0 {
        for noun in nouns {
            let item: Entity = EntityImpl::get_entity(@world, @noun.target).unwrap();
            if player.use_debug {
                player.say(world, format!("item: {:?}", item));
            }
            match ReactableComponent::get_component(world, item.inst) {
                Option::Some(c) => {
                    if c.clone().can_use_command(world, @player, @command) {
                        let res = c.clone().execute_command(world, @player, @command);
                        if res.is_ok() {
                            executed = true;
                            break;
                        }
                        if res.is_err() {
                            let error = Result::Err(res.unwrap_err());
                            // println!("Error: {:?}", error);
                            result = error;
                            found_error = true;
                            break;
                        }
                    }
                },
                Option::None => {},
            }
            match AreaComponent::get_component(world, item.inst) {
                Option::Some(c) => {
                    if c.can_use_command(world, @player, @command) {
                        let res = c.execute_command(world, @player, @command);
                        if res.is_ok() {
                            executed = true;
                            break;
                        }

                        if res.is_err() {
                            let error = Result::Err(res.unwrap_err());
                            // println!("Error: {:?}", error);
                            result = error;
                            found_error = true;
                            break;
                        }
                    }
                },
                Option::None => {},
            }
            // @dev: guaranteed there's a noun
            match ExitComponent::get_component(world, item.inst) {
                Option::Some(c) => {
                    if c.can_use_command(world, @player, @command) {
                        let res = c.execute_command(world, @player, @command);
                        if res.is_ok() {
                            executed = true;
                            break;
                        }

                        if res.is_err() {
                            let error = Result::Err(res.unwrap_err());
                            // println!("Error: {:?}", error);
                            result = error;
                            found_error = true;
                            break;
                        }
                    }
                },
                Option::None => {},
            }
            match InventoryItemComponent::get_component(world, item.inst) {
                Option::Some(c) => {
                    if c.can_use_command(world, @player, @command) {
                        let res = c.execute_command(world, @player, @command);
                        if res.is_ok() {
                            executed = true;
                            break;
                        }

                        if res.is_err() {
                            let rest = Result::Err(res.unwrap_err());
                            result = rest;
                            found_error = true;
                            // println!("result: {:?}", result);
                            break;
                        }
                    }
                },
                Option::None => {},
            }
            match ContainerComponent::get_component(world, item.inst) {
                Option::Some(c) => {
                    if c.can_use_command(world, @player, @command) {
                        let res = c.execute_command(world, @player, @command);
                        if res.is_ok() {
                            executed = true;
                            break;
                        }
                        if res.is_err() {
                            let error = Result::Err(res.unwrap_err());
                            // println!("result: {:?}", error);
                            result = error;
                            found_error = true;
                            break;
                        }
                    }
                },
                Option::None => {},
            };
        };
    } else if directions.len() > 0 {
        let context = player.get_context(@world);
        for item in context {
            let exit: Option<Exit> = Component::get_component(world, item.inst);

            // @dev: not guaranteed there's a noun
            if exit.is_some() {
                let exit = exit.unwrap();
                if exit.can_use_command(world, @player, @command) {
                    let res = exit.execute_command(world, @player, @command);
                    if res.is_ok() {
                        executed = true;
                        break;
                    }
                    if res.is_err() {
                        let error = Result::Err(res.unwrap_err());
                        // println!("result: {:?}", error);
                        result = error;
                        found_error = true;
                        break;
                    }
                }
            }
        };
    }

    //println!("executed: {:?}", executed);
    if executed {
        return Result::Ok(command);
    }

    if found_error {
        return result;
    }

    // We haven't found any targets that have a verb mapped to the action
    // Are there any default actions we can do?
    // if command is just one token,
    if command.tokens.len() == 1 {
        let initialVerb: felt252 = verbs.at(0).text.to_felt252_word().unwrap();
        if initialVerb == 'look' {
            let res = player.describe_room(world);
            if res.is_err() {
                return Result::Err(res.unwrap_err());
            };
            return Result::Ok(command);
        }
        if initialVerb == 'inventory' {
            let personal_container = player.get_personal_container(@world);
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
                    let res = player.describe_room(world);
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
            modifiedPlayer.store(world);
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
            let reactable: Reactable = Component::get_component(world, room.unwrap().inst).unwrap();
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
                let reactable: Option<Reactable> = Component::get_component(world, item.inst);
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
        models::player::caller_as_player, types::command_type::{Command, Token, TokenType},
        lib::utils::ByteArrayTraitExt,
    };

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

