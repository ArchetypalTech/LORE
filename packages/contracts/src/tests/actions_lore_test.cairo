// use core::num::traits::Zero;
use starknet::{ContractAddress};

use lore::models::{
    actions_config::{ActionsConfigTrait},
};
use lore::tests::{helpers,
    helpers::{
        IActionsLoreDispatcherTrait,
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
    fn purchased_starter_pack(ref self: TState, from_address: felt252, payload: Array<felt252>);
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
// messaging
//

#[test]
fn test_set_messaging_contract() {
    let mut sys: HelperSystems = helpers::setup_core();
    let msg1_contract: ContractAddress = 0x1234.try_into().unwrap();
    // again...
    helpers::set_caller(OWNER());
    sys.actions.set_messaging_contract(msg1_contract);
    assert_eq!(sys.world.get_actions_config().messaging_contract, msg1_contract);
    // again...
    let msg2_contract: ContractAddress = 0x5678.try_into().unwrap();
    sys.actions.set_messaging_contract(msg2_contract);
    assert_eq!(sys.world.get_actions_config().messaging_contract, msg2_contract);
}

#[test]
#[should_panic(expected: ('ENTRYPOINT_NOT_FOUND','ENTRYPOINT_FAILED'))]
fn test_messaging_not_found() {
    let mut sys: HelperSystems = helpers::setup_core();
    let msg1_contract: ContractAddress = 0x1234.try_into().unwrap();
    helpers::set_caller(OWNER());
    sys.actions.set_messaging_contract(msg1_contract);
    // message...
    helpers::set_caller(msg1_contract);
    let messaging_dispatcher: IMessagingDispatcher = _messaging_dispatcher(@sys);
    messaging_dispatcher.purchased_starter_pack(msg1_contract.into(), array![
        RECIPIENT().into(),
        100.into(),
    ]);
    // assert_eq!(sys.actions.balance_of(RECIPIENT()), 100 * CONST::ETH_TO_WEI);
}

#[test]
#[should_panic(expected: ('ACTIONS: Invalid messaging','ENTRYPOINT_FAILED'))]
fn test_set_messaging_contract_invalid_messaging_contract() {
    let mut sys: HelperSystems = helpers::setup_core();
    helpers::set_caller(OWNER());
    sys.actions.set_messaging_contract(0x0.try_into().unwrap());
}


#[test]
#[should_panic(expected: ('ACTIONS: Invalid caller','ENTRYPOINT_FAILED'))]
fn test_set_messaging_contract_invalid_caller() {
    let mut sys: HelperSystems = helpers::setup_core();
    helpers::set_caller(OTHER());
    sys.actions.set_messaging_contract(RECIPIENT());
}

