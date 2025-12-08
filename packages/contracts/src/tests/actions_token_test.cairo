// use core::num::traits::Zero;
use starknet::{ContractAddress};

use lore::models::{
    actions_config::{ActionsConfigTrait},
    player::{PlayerImpl},
};
use lore::tests::{helpers,
    helpers::{
        IActionsTokenDispatcherTrait,
        IPromptDispatcherTrait,
        HelperSystems,
        OWNER, OTHER, RECIPIENT,
    }
};
use lore::constants::constants::{CONST};

const AMOUNT: u128 = 1000 * CONST::ETH_TO_WEI.low;

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

#[test]
fn test_spend_actions_ok() {
    let mut sys: helpers::HelperSystems = helpers::setup_core();
    // initialize player singleton
    PlayerImpl::caller_as_player(ref sys.world, OWNER(), 0);
    // player_1 say anything... (will create a game)
    let game_id_1: u128 = 1;
    helpers::set_caller(helpers::PLAYER_1);
    sys.prompt.prompt("", Option::None);
    // balance: 0
    sys.prompt.prompt("g_actions", Option::None);
    assert_eq!(helpers::game_story_last_line(@sys.world, game_id_1), "+sys+actions_balance: 0");
    // mint...
    helpers::set_caller(OWNER());
    sys.actions.mint_to(helpers::PLAYER_1, 100);
    // balance: 100
    helpers::set_caller(helpers::PLAYER_1);
    sys.prompt.prompt("g_actions", Option::None);
    assert_eq!(helpers::game_story_last_line(@sys.world, game_id_1), "+sys+actions_balance: 100");
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
#[should_panic(expected: ('ACTIONS: Invalid caller','ENTRYPOINT_FAILED'))]
fn test_set_sn_contract_invalid_caller() {
    let mut sys: HelperSystems = helpers::setup_core();
    helpers::set_caller(OTHER());
    sys.actions.set_sn_contract(RECIPIENT());
}

