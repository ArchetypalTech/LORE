use starknet::{ContractAddress, get_caller_address};
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
        token_config::{PlayerAccountTrait},
    },
    types::command_type::{Command, TokenType, Token},
    lib::{
        a_lexer::CommandImpl,
        utils::ByteArrayTraitExt,
        dictionary::{init_dictionary, add_to_dictionary},
        level_test::{create_test_level},
        dns::{DnsTrait, IGameTokenDispatcherTrait},
    },
    constants::errors::Error,
};

pub fn handle_command(
    command: @Command, ref world: WorldStorage, ref player: Player,
) -> Result<(), Error> {
    let sys_command = command.is_system_command();
    if sys_command {
        return system_command(command, ref world, ref player);
    }
    let verbs = command.get_verbs();
    if verbs.len() == 0 {
        return Result::Err(Error::ActionFailed);
    }
    let mut nouns = command.get_nouns();
    let mut directions = command.get_directions();
    let mut executed: Option<bool> = Option::None;
    let mut result: Result::<(), Error> = Result::Err(Error::ActionFailed);
    if nouns.len() > 0 {
        for noun in nouns {
            let item: Entity = EntityImpl::get_entity(@world, *noun.target).unwrap();
            if player.use_debug {
                player.log_debug(ref world, format!("item: {:?}", item));
            }
            match ReactableComponent::get_component(@world, item.inst, player.game_id) {
                Option::Some(c) => {
                    if c.clone().can_use_command(@world, @player, command) {
                        let res = c.clone().execute_command(ref world, @player, command);
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
            match AreaComponent::get_component(@world, item.inst, player.game_id) {
                Option::Some(c) => {
                    if c.can_use_command(@world, @player, command) {
                        let res = c.execute_command(ref world, @player, command);
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
            match ExitComponent::get_component(@world, item.inst, player.game_id) {
                Option::Some(c) => {
                    if c.can_use_command(@world, @player, command) {
                        let res = c.execute_command(ref world, @player, command);
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
            match InventoryItemComponent::get_component(@world, item.inst, player.game_id) {
                Option::Some(c) => {
                    if c.can_use_command(@world, @player, command) {
                        let res = c.execute_command(ref world, @player, command);
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
            match ContainerComponent::get_component(@world, item.inst, player.game_id) {
                Option::Some(c) => {
                    if c.can_use_command(@world, @player, command) {
                        let res = c.execute_command(ref world, @player, command);
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
            let exit: Option<Exit> = Component::get_component(@world, item.inst, player.game_id);
            // @dev: not guaranteed there's a noun
            match exit {
                Option::Some(exit) => {
                    if exit.can_use_command(@world, @player, command) {
                        let res = exit.execute_command(ref world, @player, command);
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
                Result::Ok(())
            } else {
                result
            };
        },
        Option::None => {},
    };

    // We haven't found any targets that have a verb mapped to the action
    // Are there any default actions we can do?
    // if command is just one token,
    let tokens = command.tokens.clone().span();
    if tokens.len() == 1 {
        let initialVerb: felt252 = verbs.at(0).text.to_felt252_word().unwrap();
        if initialVerb == 'look' {
            let res = player.describe_room(ref world);
            if res.is_err() {
                return Result::Err(res.unwrap_err());
            };
            return Result::Ok(());
        }
        if initialVerb == 'inventory' {
            let personal_container = player.get_personal_container(ref world);
            if personal_container.is_none() {
                return Result::Err(Error::NoPersonalContainer);
            }
            let container_component: Container = personal_container.unwrap();
            let noun: ByteArray = "Your";
            let done = container_component.check_container(ref world, @player, @noun);
            if !done {
                return Result::Err(Error::ActionFailed);
            }
            return Result::Ok(());
        }
    } else {
        if tokens.len() == 2 {
            let initialVerb: felt252 = verbs.at(0).text.to_felt252_word().unwrap();
            let secondToken: Token = tokens.at(1).clone();
            if initialVerb == 'look' {
                let around: ByteArray = "around";
                let at: ByteArray = "at";
                if secondToken.text == around {
                    let res = player.describe_room(ref world);
                    if res.is_err() {
                        return Result::Err(res.unwrap_err());
                    };
                    return Result::Ok(());
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
    add_to_dictionary(world, "g_game_id", TokenType::System, 2).unwrap();
    add_to_dictionary(world, "g_create_game", TokenType::System, 2).unwrap();
    add_to_dictionary(world, "g_load_game", TokenType::System, 2).unwrap();
}

fn system_command(
    command: @Command, ref world: WorldStorage, ref player: Player,
) -> Result<(), Error> {
    let mut system_command: ByteArray = "";
    let tokens = command.tokens.clone().span();
    for token in tokens {
        if token.token_type == @TokenType::System {
            system_command = token.text.clone();
            break;
        }
    };
    if system_command != "" {
        // println!("not zero: {:?}", system_command);
        if (system_command == "g_error") {
            return Result::Err(Error::TestError);
        }
        if (system_command == "g_debug") {
            player.use_debug = !player.use_debug;
            if player.use_debug {
                player.log_sys(ref world, "+sys+you are in debug mode");
            } else {
                player.log_sys(ref world, "+sys+you are no longer in debug mode");
            }
            player.store(ref world, player.game_id);
            return Result::Ok(());
        }
        if (system_command == "g_command") {
            // println!("g_command: {:?}", system_command);
            player.log_sys(ref world, format!("+sys+{:?}", command));
            return Result::Ok(());
        }
        if (system_command == "g_move") {
            player.move_to_room(ref world, 2826);
            player.log_sys(ref world, "+sys+forced move command");
            let room = player.get_room_entity(@world);
            if room.is_none() {
                return Result::Err(Error::ActionFailed);
            }
            let reactable: Reactable = Component::get_component(@world, room.unwrap().inst, player.game_id).unwrap();
            player.log_sys(ref world, format!("+sys+{:?}", reactable));
            return Result::Ok(());
        }
        if (system_command == "g_init_dict") {
            init_dictionary(world);
            init_system_dictionary(world);
            player.log_sys(ref world, "+sys+dictionary re-initialized");
            return Result::Ok(());
        }
        if (system_command == "g_level") {
            create_test_level(ref world);
            player.log_sys(ref world, "+sys+created test level");
            return Result::Ok(());
        }
        if (system_command == "g_whereami") {
            player.log_sys(ref world, "+sys+you are here:");
            let room = player.get_room_entity(@world);
            player.log_sys(ref world, format!("+sys+{:?}", room));
            player.log_sys(ref world, format!("+sys+{:?}", player.entity(@world).get_parent(@world, player.game_id)));
            return Result::Ok(());
        }
        if (system_command == "g_look") {
            player.log_sys(ref world, "+sys+you see this:");
            let context = player.get_context(@world);
            let room = player.get_room_entity(@world);
            if room.is_none() {
                return Result::Err(Error::ActionFailed);
            }
            player.log_sys(ref world, format!("{}", room.unwrap().name));
            for item in context {
                let reactable: Option<Reactable> = Component::get_component(@world, item.inst, player.game_id);
                if reactable.is_some() {
                    let description = reactable.unwrap().get_random_description(command, world);
                    player.log_sys(ref world, format!("{}", description));
                }
            };
            return Result::Ok(());
        }
        if (system_command == "g_game_id") {
            player.log_sys(ref world, format!("+sys+game-{:?}", player.game_id));
            return Result::Ok(());
        }
        if (system_command == "g_create_game") {
            let player_address: ContractAddress = get_caller_address();
            let game_id: u128 = world.game_token_dispatcher().create_game(player_address);
            player.log_sys(ref world, format!("+sys+created game-{:?}", game_id));
            // force create new player
            let player = PlayerImpl::get_player_for_account(ref world, player_address, game_id);
            if (player.is_none()) {
                return Result::Err(Error::NoPlayerComponent);
            }
            return Result::Ok(());
        }
        if (system_command == "g_load_game") {
            let player_address: ContractAddress = get_caller_address();
            let game_id: u256 = tokens.at(1).text.to_felt252_decimal().unwrap().into();
            // validate ownership
            if (!world.game_token_dispatcher().is_owner_of(player_address, game_id)) {
                player.log_sys(ref world, format!("+sys+not your game"));
                return Result::Err(Error::NotYourGame);
            }
            // switch game...
            PlayerAccountTrait::switch_game_id(ref world, player_address, game_id.low);
            player.log_sys(ref world, format!("+sys+loaded game-{:?}", game_id));
            return Result::Ok(());
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
        let (mut world, _, _, _, player_1, _) = helpers::setup_core();
        create_test_level(ref world);
        let game_id: u128 = 0;
        let mut player = PlayerImpl::caller_as_player(ref world, player_1, game_id);
        player.move_to_room(ref world, 2826);

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
        let result = handle_command(@command, ref world, @player);

        // Verify the command was handled successfully
        assert(result.is_ok(), 'Command not handled');
    }
}

