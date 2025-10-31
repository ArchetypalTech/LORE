use starknet::{ContractAddress, get_caller_address};
use dojo::{world::WorldStorage, model::ModelStorage};
use lore::{
    models::{
        entity::{Entity, EntityImpl},
        area::{Area, AreaComponent},
        exit::{Exit, ExitComponent},
        reactable::{Reactable, ReactableImpl, ReactableComponent},
        inventory_item::{InventoryItem, InventoryItemComponent},
        container::{Container, ContainerImpl, ContainerComponent},
        player::{Player, PlayerImpl},
        components::{Component},
        action::{ActionImpl},
        condition::{ConditionImpl},
        game_token_info::{GameTokenInfo, PlayerGameTrait},
        trail_token_info::{TrailProgress, MAIN_TRAIL_ID},
        hub::{TrailTrait},
    },
    types::command_type::{
        Command, CommandImpl,
        TokenType, Token,
    },
    lib::{
        access::{AccessTrait},
        utils::ByteArrayTraitExt,
        level_test::{create_test_level},
        dns::{
            DnsTrait,
            ILexerDispatcherTrait,
            IGameTokenDispatcherTrait,
            ITrailTokenDispatcherTrait,
        },
    },
    constants::errors::Error,
};

pub fn handle_command(
    command: @Command, ref world: WorldStorage, ref player: Player,
) -> Result<(), Error> {
    let sys_command: bool = command.is_system_command();
    if sys_command {
        return system_command(command, ref world, ref player);
    }
    let verbs: Span<Token> = command.get_verbs();
    if verbs.is_empty() {
        player.say(ref world, format!("I don't recognize the VERB(s) in: \"{}\"", command.text));
        return Result::Err(Error::ActionFailed);
    }
    let mut nouns: Span<Token> = command.get_nouns();
    let mut directions: Span<Token> = command.get_directions();
    let mut executed: Option<bool> = Option::None;
    let mut result: Result::<(), Error> = Result::Err(Error::ActionFailed);
    if nouns.len() > 0 {
        for noun in nouns {
            let item: Option<Entity> = EntityImpl::get_entity(@world, *noun.target);
            if (item.is_none()) {
                player.say(ref world, format!("I've heard about {} but it's not here", noun.text));
                return Result::Err(Error::ActionFailed);
            }
            let item: Entity = item.unwrap();
            if player.use_debug {
                player.log_debug(ref world, format!("item: {:?}", item));
            }
            let c: Option<Reactable> = ReactableComponent::get_component(@world, item.inst, player.game_id);
            if let Some(c) = c {
                if c.clone().can_use_command(@world, @player, command) {
                    let res: Result<(), Error> = c.clone().execute_command(ref world, @player, command);
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
            }
            let c: Option<Area> = AreaComponent::get_component(@world, item.inst, player.game_id);
            if let Some(c) = c {
                    if c.can_use_command(@world, @player, command) {
                    let res: Result<(), Error> = c.execute_command(ref world, @player, command);
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
            }
            // @dev: guaranteed there's a noun
            let c: Option<Exit> = ExitComponent::get_component(@world, item.inst, player.game_id);
            if let Some(c) = c {
                if c.can_use_command(@world, @player, command) {
                    let res: Result<(), Error> = c.execute_command(ref world, @player, command);
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
            }
            let c: Option<InventoryItem> = InventoryItemComponent::get_component(@world, item.inst, player.game_id);
            if let Some(c) = c {
                if c.can_use_command(@world, @player, command) {
                    let res: Result<(), Error> = c.execute_command(ref world, @player, command);
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
            }
            let c: Option<Container> = ContainerComponent::get_component(@world, item.inst, player.game_id);
            if let Some(c) = c {
                    if c.can_use_command(@world, @player, command) {
                    let res: Result<(), Error> = c.execute_command(ref world, @player, command);
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
            };
        };
    } else if directions.len() > 0 {
        let context: Array<Entity> = player.get_context(@world);
        for item in context {
            // @dev: not guaranteed there's a noun
            let exit: Option<Exit> = Component::get_component(@world, item.inst, player.game_id);
            if let Some(exit) = exit {
                if exit.can_use_command(@world, @player, command) {
                    let res: Result<(), Error> = exit.execute_command(ref world, @player, command);
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
            }
        };
    }

    //println!("executed: {:?}", executed);
    if let Some(executed) = executed {
        return if (executed) {
            Result::Ok(())
        } else {
            result
        };
    };

    // We haven't found any targets that have a verb mapped to the action
    // Are there any default actions we can do?
    // if command is just one token,
    let tokens = command.tokens.clone().span();
    if tokens.len() == 1 {
        let initialVerb: felt252 = verbs.at(0).text.to_felt252_word().unwrap();
        if initialVerb == 'look' {
            let res: Result<(), Error> = player.describe_room(ref world);
            if res.is_err() {
                return Result::Err(res.unwrap_err());
            };
            return Result::Ok(());
        }
        if initialVerb == 'inventory' {
            let personal_container: Option<Container> = player.get_personal_container(ref world);
            if personal_container.is_none() {
                return Result::Err(Error::NoPersonalContainer);
            }
            let container_component: Container = personal_container.unwrap();
            let noun: ByteArray = "Your";
            let done: bool = container_component.check_container(ref world, @player, @noun);
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
                    let res: Result<(), Error> = player.describe_room(ref world);
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
            // check if nouns or directions exist, if they do player recognize verb and target but cant execute command
            if nouns.len() > 0 {
                player.say(ref world, format!("I recognize the VERB(s) and the TARGET(s) in: \"{}\", but is not possible to execute your command", command.text));
            } else if directions.len() > 0 {
                player.say(ref world, format!("I recognize the VERB(s) and the Direction in: \"{}\", but is not possible to execute your command", command.text));
            } else {
                // the verb is recognized but the target/direction is not recognized
                player.say(ref world, format!("I recognize the VERB(s) in: \"{}\", but not the TARGET(s) or the Direction", command.text));
            }
            // return error
            return Result::Err(Error::ActionFailed);
        }
        // it tokens lengt is more then,
        // check if nouns or directions exist, if they do player recognize verb and target but cant execute command
        if nouns.len() > 0 {
            player.say(ref world, format!("I recognize the VERB(s) and the TARGET(s) in: \"{}\", but is not possible to execute your command", command.text));
        } else if directions.len() > 0 {
            player.say(ref world, format!("I recognize the VERB(s) and the Direction in: \"{}\", but is not possible to execute your command", command.text));
        } else {
            // the verb is recognized but the target/direction is not recognized
            player.say(ref world, format!("I recognize the VERB(s) in: \"{}\", but not the TARGET(s) or the Direction", command.text));
        }
        return Result::Err(Error::ActionFailed);
    }
    
    result
}

fn system_command(
    command: @Command, ref world: WorldStorage, ref player: Player,
) -> Result<(), Error> {
    let mut system_command: ByteArray = "";
    let tokens: Span<Token> = command.tokens.clone().span();
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
            let room: Option<Entity> = player.get_room_entity(@world);
            if room.is_none() {
                return Result::Err(Error::ActionFailed);
            }
            let reactable: Reactable = Component::get_component(@world, room.unwrap().inst, player.game_id).unwrap();
            player.log_sys(ref world, format!("+sys+{:?}", reactable));
            return Result::Ok(());
        }
        if (system_command == "g_init_dict") {
            world.lexer_dispatcher().initialize_dictionary(world);
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
            let room: Option<Entity> = player.get_room_entity(@world);
            player.log_sys(ref world, format!("+sys+{:?}", room));
            player.log_sys(ref world, format!("+sys+{:?}", player.entity(@world).get_parent(@world, player.game_id)));
            return Result::Ok(());
        }
        if (system_command == "g_look") {
            player.log_sys(ref world, "+sys+you see this:");
            let context: Array<Entity> = player.get_context(@world);
            let room: Option<Entity> = player.get_room_entity(@world);
            if room.is_none() {
                return Result::Err(Error::ActionFailed);
            }
            player.log_sys(ref world, format!("{}", room.unwrap().name));
            for item in context {
                let reactable: Option<Reactable> = Component::get_component(@world, item.inst, player.game_id);
                if reactable.is_some() {
                    let description: ByteArray = reactable.unwrap().get_random_description(command, world, player.game_id);
                    player.log_sys(ref world, format!("{}", description));
                }
            };
            return Result::Ok(());
        }
        if (system_command == "g_create_game") {
            let player_address: ContractAddress = get_caller_address();
            let game_id: u128 = world.game_token_dispatcher().create_game(player_address);
            player.log_sys(ref world, format!("+sys+Created game-{:?}", game_id));
            // force create new player
            let player: Option<Player> = PlayerImpl::get_player_for_account(ref world, player_address, game_id);
            if (player.is_none()) {
                return Result::Err(Error::NoPlayerComponent);
            }
            return Result::Ok(());
        }
        if (system_command == "g_create_trail") {
            let player_address: ContractAddress = get_caller_address();
            if (!world.is_player_editor(player_address)) {
                return Result::Err(Error::NotEditor);
            }
            let trail_id: u128 = world.trail_token_dispatcher().create_trail(player_address);
            TrailTrait::create_new_trail_entity(ref world, trail_id);
            player.log_sys(ref world, format!("+sys+Created trail-{:?}", trail_id));
            return Result::Ok(());
        }
        if (system_command == "g_load_game") {
            let player_address: ContractAddress = get_caller_address();
            let game_id: u256 = tokens.at(1).text.to_felt252_decimal().unwrap().into();
            // validate ownership
            if (!world.game_token_dispatcher().is_owner_of(player_address, game_id)) {
                player.log_sys(ref world, format!("+sys+Not your game!"));
                return Result::Err(Error::NotYourGame);
            }
            // switch game...
            PlayerGameTrait::switch_game_id(ref world, player_address, game_id.low);
            player.log_sys(ref world, format!("+sys+Loaded game-{:?}", game_id));
            return Result::Ok(());
        }
        if (system_command == "g_game_id") {
            player.log_sys(ref world, format!("+sys+game-{:?}", player.game_id));
            return Result::Ok(());
        }
        if (system_command == "g_game_data") {
            let token_info: GameTokenInfo = world.read_model(player.game_id);
            let trail_progress: TrailProgress = world.read_model((player.game_id, MAIN_TRAIL_ID),);
            player.log_sys(ref world, format!("+sys+game-{:?}", token_info.game_id));
            player.log_sys(ref world, format!("+sys+room: {}", token_info.room_name));
            player.log_sys(ref world, format!("+sys+act: {}", token_info.act_number));
            player.log_sys(ref world, format!("+sys+progress: {}%25", trail_progress.percentage));
            player.log_sys(ref world, format!("+sys+completed: {}", ByteArrayTraitExt::byte_array_from_bool(trail_progress.completed)));
            return Result::Ok(());
        }
        if (system_command == "g_player") {
            player.log_sys(ref world, format!("+sys+address: 0x{:x}", player.address));
            player.log_sys(ref world, format!("+sys+current_game_id: {}", player.game_id));
            player.log_sys(ref world, format!("+sys+is_dead: {}", ByteArrayTraitExt::byte_array_from_bool(player.is_dead)));
            player.log_sys(ref world, format!("+sys+is_admin: {}", ByteArrayTraitExt::byte_array_from_bool(world.is_player_admin(player.address))));
            player.log_sys(ref world, format!("+sys+is_editor: {}", ByteArrayTraitExt::byte_array_from_bool(world.is_player_editor(player.address))));
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
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        create_test_level(ref sys.world);
        let game_id: u128 = 0;
        let mut player: Player = PlayerImpl::caller_as_player(ref sys.world, helpers::PLAYER_1, game_id);
        player.move_to_room(ref sys.world, 2826);

        // Create a test command with g_command system token
        let mut command: Command = Command {
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
        let result: Result<(), Error> = handle_command(@command, ref sys.world, ref player);

        // Verify the command was handled successfully
        assert(result.is_ok(), 'Command not handled');
    }
}

