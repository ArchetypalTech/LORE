// use core::num::traits::Zero;
use starknet::{ContractAddress};
use dojo::{
    // world::{WorldStorage},
    model::{ModelStorage},
};

use lore::{
    models::{
        actions_config::{ActionsConfig, ActionsConfigTrait},
        player_account::{PlayerBalances},
        player::{Player, PlayerImpl},
        entity::{Entity},
        area::{Area},
        exit::{Exit},
    },
    types::{
        command_type::{Command, CommandType},
    },
    lib::{
        dns::{
            DnsTrait,
            IActionsTokenDispatcherTrait,
            IPromptDispatcherTrait,
            ILexerDispatcherTrait,
        },
        errors_texts_output::{ErrorOutputterTrait},
    },
    constants::{
        errors::{Error},
        constants::{TIMESTAMP},
    },
};
use lore::tests::{helpers,
    helpers::{
        HelperSystems,
        OWNER, OTHER, RECIPIENT, PLAYER_1,
    }
};
use lore::constants::constants::{CONST};

const AMOUNT: u128 = 1000 * CONST::ETH_TO_WEI.low;

const CLAIM_INTERVAL: u64 = TIMESTAMP::ONE_HOUR;

const TOKEN_ID_1_1: u256 = 1;
const TOKEN_ID_1_2: u256 = 2;
const TOKEN_ID_2_1: u256 = 3;
const TOKEN_ID_2_2: u256 = 4;
const TOKEN_ID_3_1: u256 = 5;
const TOKEN_ID_3_2: u256 = 6;

#[starknet::interface]
trait IMessaging<TState> {
    fn used_permit(ref self: TState, from_address: felt252, payload: Array<felt252>);
}

fn _messaging_dispatcher(sys: @HelperSystems) -> IMessagingDispatcher {
    IMessagingDispatcher {
        contract_address: *sys.actions.contract_address,
    }
}


//
// initialize
//

#[test]
fn test_initializer() {
    let mut sys: HelperSystems = helpers::setup_core();
println!("sys.actions.symbol(): {}", sys.actions.symbol());
println!("sys.actions.name(): {}", sys.actions.name());
    assert_eq!(sys.actions.symbol(), "ORUG_ACTIONS", "Symbol is wrong");
}

//-----------------------------------
// minting
//

#[test]
fn test_mint_to() {
    let mut sys: HelperSystems = helpers::setup_core();
    helpers::set_caller(OWNER());
    sys.actions.mint_to(RECIPIENT(), 100);
    assert_eq!(sys.actions.balance_of(RECIPIENT()), 100 * CONST::ETH_TO_WEI);
    sys.actions.mint_to(RECIPIENT(), 50);
    assert_eq!(sys.actions.balance_of(RECIPIENT()), 150 * CONST::ETH_TO_WEI);
    sys.actions.mint_to(OTHER(), 20);
    assert_eq!(sys.actions.balance_of(OTHER()), 20 * CONST::ETH_TO_WEI);
}

#[test]
#[should_panic(expected: ('ACTIONS: Invalid caller','ENTRYPOINT_FAILED'))]
fn test_mint_to_invalid_caller() {
    let mut sys: HelperSystems = helpers::setup_core();
    helpers::set_caller(OTHER());
    sys.actions.mint_to(RECIPIENT(), 100);
}


//-----------------------------------
// transfers
//

#[test]
fn test_transfer_from_prompt_contract() {
    let mut sys: HelperSystems = helpers::setup_core();
    helpers::set_caller(OWNER());
    sys.actions.mint_to(RECIPIENT(), 100);
    assert_eq!(sys.actions.balance_of(RECIPIENT()), 100 * CONST::ETH_TO_WEI);
    // mock prompt contract
    helpers::set_caller(sys.prompt.contract_address);
    sys.actions.transfer_from(RECIPIENT(), OTHER(), 80 * CONST::ETH_TO_WEI);
    assert_eq!(sys.actions.balance_of(RECIPIENT()), 20 * CONST::ETH_TO_WEI);
    assert_eq!(sys.actions.balance_of(OTHER()), 80 * CONST::ETH_TO_WEI);
}

#[test]
#[should_panic(expected: ('ACTIONS: Not permitted','ENTRYPOINT_FAILED'))]
fn test_transfer_not_permitted() {
    let mut sys: HelperSystems = helpers::setup_core();
    helpers::set_caller(OWNER());
    sys.actions.mint_to(RECIPIENT(), 100);
    // try to transfer...
    helpers::set_caller(RECIPIENT());
    sys.actions.transfer(OTHER(), 100 * CONST::ETH_TO_WEI);
}


//-----------------------------------
// spend
//

fn _setup_level(ref sys: HelperSystems) -> u128 {
    helpers::set_caller(OWNER());
    // setup actions price
    let action_cost_amount: u128 = (1 * CONST::ETH_TO_WEI.low);
    sys.actions.set_action_cost_amount(action_cost_amount);
    // initialize a world
    let (_room_1_entity, area_1): (Entity, Area) = helpers::create_area_entity(ref sys, "This is Room 1", "ROOM1", Option::None);
    let (room_2_entity, _area_2): (Entity, Area) = helpers::create_area_entity(ref sys, "This is Room 2", "ROOM2", Option::None);
    let (_exit_2_entity, _exit_to_room_1): (Entity, Exit) = helpers::create_exit_in_area(ref sys, "Exit To Room 1", "to_room_1", @room_2_entity, area_1.inst);
    // initialize player
    let player: Player = PlayerImpl::caller_as_player(ref sys.world, OWNER(), 0);
    player.move_to_room(ref sys.world, room_2_entity.inst);
    //
    // player_1 say anything... (will create a game)
    let game_id: u128 = 1;
    helpers::set_caller(PLAYER_1);
    sys.prompt.prompt("", Option::None);
    (game_id)
}

fn _assert_error_no_balance(ref sys: HelperSystems, game_id: u128) {
    let error_message: ByteArray = Error::InsufficientActionsBalance.error_message(ref sys.world);
    assert_gt!(error_message.len(), 0, "Error message is empty");
    assert_eq!(helpers::game_story_last_line(@sys.world, game_id), error_message);
}

fn _assert_balances(sys: @HelperSystems, player_address: ContractAddress, free_actions_count: u32, paid_actions_count: u32, prefix: ByteArray) {
    let balances: PlayerBalances = (*sys.world).read_model(player_address);
    assert_eq!(balances.free_actions_balance, free_actions_count.into() * CONST::ETH_TO_WEI.low, "[{}] free_actions_balance", prefix);
    assert_eq!(balances.paid_actions_balance, paid_actions_count.into() * CONST::ETH_TO_WEI.low, "[{}] paid_actions_balance", prefix);
    assert_eq!(sys.actions.balance_of(player_address).low, (free_actions_count + paid_actions_count).into() * CONST::ETH_TO_WEI.low, "[{}] balance_of", prefix);
}

#[test]
fn test_spend_actions_ok() {
    let mut sys: helpers::HelperSystems = helpers::setup_core();
    let game_id: u128 = _setup_level(ref sys);
    //
    // balance: 5 (initial free actions)
    assert_eq!(sys.actions.total_supply(), 0);
    sys.prompt.prompt("g_actions", Option::None);
    assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "+sys+actions balance: 5");
    assert_eq!(sys.actions.total_supply(), 5 * CONST::ETH_TO_WEI);
    // spend it all...
    sys.prompt.prompt("look around", Option::None);
    sys.prompt.prompt("look around", Option::None);
    sys.prompt.prompt("look around", Option::None);
    sys.prompt.prompt("look around", Option::None);
    sys.prompt.prompt("look around", Option::None);
    // balance: 0
    sys.prompt.prompt("g_actions", Option::None);
    assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "+sys+actions balance: 0");
    assert_eq!(sys.actions.total_supply(), 0);
    //
    // try to spend actions...
    sys.prompt.prompt("look around", Option::None);
    _assert_error_no_balance(ref sys, game_id);
    //
    // mint actions to player...
    helpers::set_caller(OWNER());
    sys.actions.mint_to(PLAYER_1, 100);
    // balance: 100
    helpers::set_caller(PLAYER_1);
    sys.prompt.prompt("g_actions", Option::None);
    assert_eq!(sys.actions.balance_of(PLAYER_1), 100 * CONST::ETH_TO_WEI);
    assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "+sys+actions balance: 100");
    assert_eq!(sys.actions.total_supply(), 100 * CONST::ETH_TO_WEI);
    //
    // try to spend actions...
    sys.prompt.prompt("look around", Option::None);
// helpers::print_game_story_last_line(@sys.world, game_id);
    assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "to_room_1");
    assert_eq!(sys.actions.balance_of(PLAYER_1), 99 * CONST::ETH_TO_WEI);
    sys.prompt.prompt("g_actions", Option::None);
    assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "+sys+actions balance: 99");
    assert_eq!(sys.actions.total_supply(), 99 * CONST::ETH_TO_WEI);
}


//-----------------------------------
// free actions
//

#[test]
fn test_claim_free_actions_ok() {
    let mut sys: helpers::HelperSystems = helpers::setup_core();
    let _game_id: u128 = _setup_level(ref sys);
    //
    // balance: 5 (initial free actions)
    _assert_balances(@sys, PLAYER_1, 0, 0, "start");
    sys.prompt.prompt("g_actions", Option::None);
    _assert_balances(@sys, PLAYER_1, 5, 0, "start");
    // spend it all...
    sys.prompt.prompt("look around", Option::None);
    _assert_balances(@sys, PLAYER_1, 4, 0, "start");
    sys.prompt.prompt("look around", Option::None);
    _assert_balances(@sys, PLAYER_1, 3, 0, "start");
    sys.prompt.prompt("look around", Option::None);
    _assert_balances(@sys, PLAYER_1, 2, 0, "start");
    sys.prompt.prompt("look around", Option::None);
    _assert_balances(@sys, PLAYER_1, 1, 0, "start");
    sys.prompt.prompt("look around", Option::None);
    _assert_balances(@sys, PLAYER_1, 0, 0, "start");
    // still cant claim because no purchase or subscription
    assert_eq!(sys.actions.get_free_actions_count(), 0, "spent initial");
    helpers::elapse_block_timestamp(CLAIM_INTERVAL);
    assert_eq!(sys.actions.get_free_actions_count(), 0, "after 1 hour");
    //
    // mint actions to player...
    helpers::set_caller(OWNER());
    sys.actions.mint_to(PLAYER_1, 10);
    _assert_balances(@sys, PLAYER_1, 0, 10, "after airdrop");
    // now can claim...
    helpers::set_caller(PLAYER_1);
    assert_eq!(sys.actions.get_free_actions_count(), 1, "after airdrop");
    helpers::elapse_block_timestamp(CLAIM_INTERVAL * 2);
    assert_eq!(sys.actions.get_free_actions_count(), 3, "after 3 hours");
    //
    // claim...
    sys.actions.claim_free_actions();
    _assert_balances(@sys, PLAYER_1, 3, 10, "after airdrop");
    assert_eq!(sys.actions.get_free_actions_count(), 0, "after claim");
}

#[test]
fn test_claim_free_actions_max() {
    let mut sys: helpers::HelperSystems = helpers::setup_core();
    let _game_id: u128 = _setup_level(ref sys);
    //
    // balance: 5 (initial free actions)
    // spend it all...
    sys.prompt.prompt("look around", Option::None);
    sys.prompt.prompt("look around", Option::None);
    sys.prompt.prompt("look around", Option::None);
    sys.prompt.prompt("look around", Option::None);
    sys.prompt.prompt("look around", Option::None);
    // spent all free actions
    _assert_balances(@sys, PLAYER_1, 0, 0, "spent initial");
    // mint actions to player...
    helpers::set_caller(OWNER());
    sys.actions.mint_to(PLAYER_1, 10);
    _assert_balances(@sys, PLAYER_1, 0, 10, "1 - airdrop");
    // now can claim...
    helpers::set_caller(PLAYER_1);
    assert_eq!(sys.actions.get_free_actions_count(), 0, "1 - zero");
    helpers::elapse_block_timestamp(CLAIM_INTERVAL * 10);
    assert_eq!(sys.actions.get_free_actions_count(), 5, "1 - can claim 5");
    // claim...
    sys.actions.claim_free_actions();
    _assert_balances(@sys, PLAYER_1, 5, 10, "2 - balances");
    assert_eq!(sys.actions.get_free_actions_count(), 0, "2 - zero");
    // claim again, no changes
    helpers::elapse_block_timestamp(CLAIM_INTERVAL * 10);
    assert_eq!(sys.actions.get_free_actions_count(), 0, "2 - still zero");
    sys.actions.claim_free_actions();
    _assert_balances(@sys, PLAYER_1, 5, 10, "3 - balances");
    assert_eq!(sys.actions.get_free_actions_count(), 0, "3 - zero");
    // spend 2, claim 2...
    sys.prompt.prompt("look around", Option::None); // will up 1 automatically
    sys.prompt.prompt("look around", Option::None);
    sys.prompt.prompt("look around", Option::None);
    _assert_balances(@sys, PLAYER_1, 3, 10, "4 - balances");
    assert_eq!(sys.actions.get_free_actions_count(), 0, "4 - 0");
    helpers::elapse_block_timestamp(CLAIM_INTERVAL * 10);
    assert_eq!(sys.actions.get_free_actions_count(), 2, "4 - 2");
    sys.actions.claim_free_actions();
    _assert_balances(@sys, PLAYER_1, 5, 10, "5 - balances");
    assert_eq!(sys.actions.get_free_actions_count(), 0, "5 - zero");
}

#[test]
fn test_claim_spend_order() {
    let mut sys: helpers::HelperSystems = helpers::setup_core();
    let game_id: u128 = _setup_level(ref sys);
    //
    // balance: 5 (initial free actions)
    // spend it all...
    helpers::set_caller(PLAYER_1);
    sys.prompt.prompt("look around", Option::None);
    _assert_balances(@sys, PLAYER_1, 4, 0, "spent 1");
    // mint actions to player...
    helpers::set_caller(OWNER());
    sys.actions.mint_to(PLAYER_1, 5);
    _assert_balances(@sys, PLAYER_1, 4, 5, "after airdrop");
    // spend free...
    helpers::set_caller(PLAYER_1);
    sys.prompt.prompt("look around", Option::None);
    _assert_balances(@sys, PLAYER_1, 3, 5, "spent 2");
    sys.prompt.prompt("look around", Option::None);
    _assert_balances(@sys, PLAYER_1, 2, 5, "spent 3");
    sys.prompt.prompt("look around", Option::None);
    _assert_balances(@sys, PLAYER_1, 1, 5, "spent 4");
    sys.prompt.prompt("look around", Option::None);
    _assert_balances(@sys, PLAYER_1, 0, 5, "spent 5");
    // spend paid...
    sys.prompt.prompt("look around", Option::None);
    _assert_balances(@sys, PLAYER_1, 0, 4, "spent 6");
    sys.prompt.prompt("look around", Option::None);
    _assert_balances(@sys, PLAYER_1, 0, 3, "spent 7");
    // claim some more...
    helpers::set_caller(PLAYER_1);
    helpers::elapse_block_timestamp(CLAIM_INTERVAL * 2);
    assert_eq!(sys.actions.get_free_actions_count(), 2, "claiming");
    sys.actions.claim_free_actions();
    _assert_balances(@sys, PLAYER_1, 2, 3, "after airdrop");
    // spend it all...
    sys.prompt.prompt("look around", Option::None);
    _assert_balances(@sys, PLAYER_1, 1, 3, "spent 8");
    sys.prompt.prompt("look around", Option::None);
    _assert_balances(@sys, PLAYER_1, 0, 3, "spent 9");
    sys.prompt.prompt("look around", Option::None);
    _assert_balances(@sys, PLAYER_1, 0, 2, "spent 10");
    sys.prompt.prompt("look around", Option::None);
    _assert_balances(@sys, PLAYER_1, 0, 1, "spent 11");
    sys.prompt.prompt("look around", Option::None);
    _assert_balances(@sys, PLAYER_1, 0, 0, "spent 12");
    // no more!
    sys.prompt.prompt("look around", Option::None);
    _assert_error_no_balance(ref sys, game_id);
}


//-----------------------------------
// messaging
//

#[test]
fn test_set_sn_contract() {
    let mut sys: HelperSystems = helpers::setup_core();
    let msg1_contract: ContractAddress = 0x1234.try_into().unwrap();
    // again...
    helpers::set_caller(OWNER());
    sys.actions.set_sn_contract(msg1_contract);
    assert_eq!(sys.world.get_actions_config().sn_contract, msg1_contract);
    // again...
    let msg2_contract: ContractAddress = 0x5678.try_into().unwrap();
    sys.actions.set_sn_contract(msg2_contract);
    assert_eq!(sys.world.get_actions_config().sn_contract, msg2_contract);
}

#[test]
#[should_panic(expected: ('ENTRYPOINT_NOT_FOUND','ENTRYPOINT_FAILED'))]
fn test_messaging_not_found() {
    let mut sys: HelperSystems = helpers::setup_core();
    let msg1_contract: ContractAddress = 0x1234.try_into().unwrap();
    helpers::set_caller(OWNER());
    sys.actions.set_sn_contract(msg1_contract);
    // message...
    helpers::set_caller(msg1_contract);
    let messaging_dispatcher: IMessagingDispatcher = _messaging_dispatcher(@sys);
    messaging_dispatcher.used_permit(msg1_contract.into(), array![
        RECIPIENT().into(),
        100.into(),
    ]);
    // assert_eq!(sys.actions.balance_of(RECIPIENT()), 100 * CONST::ETH_TO_WEI);
}

#[test]
#[should_panic(expected: ('ACTIONS: Invalid SN contract','ENTRYPOINT_FAILED'))]
fn test_set_sn_contract_invalid_sn_contract() {
    let mut sys: HelperSystems = helpers::setup_core();
    helpers::set_caller(OWNER());
    sys.actions.set_sn_contract(0x0.try_into().unwrap());
}


#[test]
fn test_set_action_cost() {
    let mut sys: HelperSystems = helpers::setup_core();
    // validate initial costs (zero)
    let player: Player = PlayerImpl::caller_as_player(ref sys.world, OWNER(), 0);
    let command_null: Command = sys.world.lexer_dispatcher().parse(sys.world, "", player).unwrap();
    let command_sys: Command = sys.world.lexer_dispatcher().parse(sys.world, "g_actions", player).unwrap();
    let command_action: Command = sys.world.lexer_dispatcher().parse(sys.world, "look around", player).unwrap();
    assert_eq!(command_null.command_type, CommandType::Unknown);
    assert_eq!(command_sys.command_type, CommandType::System);
    assert_eq!(command_action.command_type, CommandType::Action);
    assert_eq!(sys.world.calculate_actions_cost(command_null.command_type), 0, "initial cost");
    assert_eq!(sys.world.calculate_actions_cost(command_sys.command_type), 0, "initial cost");
    assert_eq!(sys.world.calculate_actions_cost(command_action.command_type), 0, "initial cost");
    // set price
    helpers::set_caller(OWNER());
    let amount: u128 = 100 * CONST::ETH_TO_WEI.low;
    sys.actions.set_action_cost_amount(amount);
    assert_eq!(sys.world.get_actions_config().action_cost_amount, amount);
    // validate action cost amount
    assert_eq!(sys.world.calculate_actions_cost(command_null.command_type), 0, "updated cost");
    assert_eq!(sys.world.calculate_actions_cost(command_sys.command_type), 0, "updated cost");
    assert_eq!(sys.world.calculate_actions_cost(command_action.command_type), amount, "updated cost");
}

#[test]
fn test_admin_setters() {
    let mut sys: HelperSystems = helpers::setup_core();
    let config: ActionsConfig = sys.world.get_actions_config();
    helpers::set_caller(OWNER());
    sys.actions.set_initial_free_actions_count(123);
    sys.actions.set_max_free_actions_count(123);
    sys.actions.set_free_action_claim_interval(123);
    sys.actions.set_trail_reward_actions_count(123);
    let new_config: ActionsConfig = sys.world.get_actions_config();
    assert_ne!(new_config.initial_free_actions_count, config.initial_free_actions_count);
    assert_ne!(new_config.max_free_actions_count, config.max_free_actions_count);
    assert_ne!(new_config.free_action_claim_interval, config.free_action_claim_interval);
    assert_ne!(new_config.trail_reward_actions_count, config.trail_reward_actions_count);
}

#[test]
#[should_panic(expected: ('ACTIONS: Invalid caller','ENTRYPOINT_FAILED'))]
fn test_set_sn_contract_invalid_caller() {
    let mut sys: HelperSystems = helpers::setup_core();
    helpers::set_caller(OTHER());
    sys.actions.set_sn_contract(RECIPIENT());
}
#[test]
#[should_panic(expected: ('ACTIONS: Invalid caller','ENTRYPOINT_FAILED'))]
fn test_set_action_cost_invalid_caller() {
    let mut sys: HelperSystems = helpers::setup_core();
    helpers::set_caller(OTHER());
    let amount: u128 = 100 * CONST::ETH_TO_WEI.low;
    sys.actions.set_action_cost_amount(amount);
}
#[test]
#[should_panic(expected: ('ACTIONS: Invalid caller','ENTRYPOINT_FAILED'))]
fn test_set_initial_free_actions_count_invalid_caller() {
    let mut sys: HelperSystems = helpers::setup_core();
    helpers::set_caller(OTHER());
    sys.actions.set_initial_free_actions_count(123);
}
#[test]
#[should_panic(expected: ('ACTIONS: Invalid caller','ENTRYPOINT_FAILED'))]
fn test_set_max_free_actions_count_invalid_caller() {
    let mut sys: HelperSystems = helpers::setup_core();
    helpers::set_caller(OTHER());
    sys.actions.set_max_free_actions_count(123);
}
#[test]
#[should_panic(expected: ('ACTIONS: Invalid caller','ENTRYPOINT_FAILED'))]
fn test_set_free_action_claim_interval_invalid_caller() {
    let mut sys: HelperSystems = helpers::setup_core();
    helpers::set_caller(OTHER());
    sys.actions.set_free_action_claim_interval(123);
}
#[test]
#[should_panic(expected: ('ACTIONS: Invalid caller','ENTRYPOINT_FAILED'))]
fn test_set_trail_reward_actions_count_invalid_caller() {
    let mut sys: HelperSystems = helpers::setup_core();
    helpers::set_caller(OTHER());
    sys.actions.set_trail_reward_actions_count(123);
}
