// use core::num::traits::Zero;
use starknet::{ContractAddress};

use lore::{
    models::{
        actions_config::{ActionsConfigTrait},
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
    constants::errors::{Error},
};
use lore::tests::{helpers,
    helpers::{
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
    //
    // set actions price
    helpers::set_caller(OWNER());
    let action_cost_amount: u256 = (1 * CONST::ETH_TO_WEI);
    sys.actions.set_action_cost_amount(action_cost_amount);
    //
    // initialize a world
    let (_room_1_entity, area_1): (Entity, Area) = helpers::create_area_entity(ref sys, "This is Room 1", "ROOM1", Option::None);
    let (room_2_entity, _area_2): (Entity, Area) = helpers::create_area_entity(ref sys, "This is Room 2", "ROOM2", Option::None);
    let (_exit_2_entity, _exit_to_room_1): (Entity, Exit) = helpers::create_exit_in_area(ref sys, "Exit To Room 1", "to_room_1", @room_2_entity, area_1.inst);
    // initialize player
    let player: Player = PlayerImpl::caller_as_player(ref sys.world, OWNER(), 0);
    helpers::set_caller(helpers::OWNER());
    player.move_to_room(ref sys.world, room_2_entity.inst);
    //
    // player_1 say anything... (will create a game)
    let game_id_1: u128 = 1;
    helpers::set_caller(helpers::PLAYER_1);
    sys.prompt.prompt("", Option::None);
    // balance: 0
    sys.prompt.prompt("g_actions", Option::None);
    assert_eq!(helpers::game_story_last_line(@sys.world, game_id_1), "+sys+actions_balance: 0");
    //
    // try to spend actions...
    let error_message: ByteArray = Error::InsufficientActionsBalance.error_message(ref sys.world);
    assert_gt!(error_message.len(), 0, "Error message is empty");
    sys.prompt.prompt("look around", Option::None);
    assert_eq!(helpers::game_story_last_line(@sys.world, game_id_1), error_message);
    //
    // mint actions to player...
    helpers::set_caller(OWNER());
    sys.actions.mint_to(helpers::PLAYER_1, 100);
    // balance: 100
    helpers::set_caller(helpers::PLAYER_1);
    sys.prompt.prompt("g_actions", Option::None);
    assert_eq!(sys.actions.balance_of(helpers::PLAYER_1), 100 * CONST::ETH_TO_WEI);
    assert_eq!(helpers::game_story_last_line(@sys.world, game_id_1), "+sys+actions_balance: 100");
    //
    // try to spend actions...
    sys.prompt.prompt("look around", Option::None);
// helpers::print_game_story_last_line(@sys.world, game_id_1);
    assert_ne!(helpers::game_story_last_line(@sys.world, game_id_1), error_message);
    assert_eq!(helpers::game_story_last_line(@sys.world, game_id_1), "hello");
    assert_eq!(sys.actions.balance_of(helpers::PLAYER_1), 99 * CONST::ETH_TO_WEI);
    sys.prompt.prompt("g_actions", Option::None);
    assert_eq!(helpers::game_story_last_line(@sys.world, game_id_1), "+sys+actions_balance: 99");
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
    assert_eq!(sys.world.calculate_actions_cost(@command_null), 0, "initial cost");
    assert_eq!(sys.world.calculate_actions_cost(@command_sys), 0, "initial cost");
    assert_eq!(sys.world.calculate_actions_cost(@command_action), 0, "initial cost");
    // set price
    helpers::set_caller(OWNER());
    let amount: u256 = 100 * CONST::ETH_TO_WEI;
    sys.actions.set_action_cost_amount(amount);
    assert_eq!(sys.world.get_actions_config().action_cost_amount, amount);
    // validate action cost amount
    assert_eq!(sys.world.calculate_actions_cost(@command_null), 0, "updated cost");
    assert_eq!(sys.world.calculate_actions_cost(@command_sys), 0, "updated cost");
    assert_eq!(sys.world.calculate_actions_cost(@command_action), amount, "updated cost");
}

#[test]
#[should_panic(expected: ('ACTIONS: Invalid caller','ENTRYPOINT_FAILED'))]
fn test_set_action_cost_invalid_caller() {
    let mut sys: HelperSystems = helpers::setup_core();
    helpers::set_caller(OTHER());
    let amount: u256 = 100 * CONST::ETH_TO_WEI;
    sys.actions.set_action_cost_amount(amount);
}
