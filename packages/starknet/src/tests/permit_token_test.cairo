// use core::num::traits::Zero;
use starknet::{ContractAddress};
use dojo::model::{ModelStorage};

use lore_sn::models::{
    permit_token_info::{PermitTokenInfo},
    permit_metadata::{permit_metadata}
};
use lore_sn::tests::{helpers,
    helpers::{
        IPermitTokenDispatcherTrait,
        ISetupDispatcherTrait,
        HelperSystems,
        OWNER, OTHER,
    },
};
use lore_sn::models::constants::{CONST};

const AMOUNT: u128 = 1000 * CONST::ETH_TO_WEI.low;

const BUNDLE_ID: u32 = 0;

const TOKEN_ID_1_1: u256 = 1;
const TOKEN_ID_1_2: u256 = 2;
const TOKEN_ID_2_1: u256 = 3;
const TOKEN_ID_2_2: u256 = 4;
const TOKEN_ID_3_1: u256 = 5;
const TOKEN_ID_3_2: u256 = 6;

fn _mint_token(ref sys: HelperSystems, recipient: ContractAddress, quantity: u32) {
    helpers::impersonate(OWNER());
    sys.permit.airdrop_bundle(recipient, quantity, true);
}

//
// initialize
//

#[test]
fn test_token_initialized() {
    let mut sys: HelperSystems = helpers::setup_core();
    println!("PERMIT TOKEN NAME: [{}]", sys.permit.name());
    println!("PERMIT TOKEN SYMBOL: [{}]", sys.permit.symbol());
    assert_ne!(sys.permit.name(), "", "empty name");
    assert_ne!(sys.permit.symbol(), "", "empty symbol");
    assert_eq!(sys.permit.name(), permit_metadata::TOKEN_NAME(), "wrong name");
    assert_eq!(sys.permit.symbol(), permit_metadata::TOKEN_SYMBOL(), "wrong symbol");
}

#[test]
fn test_token_token_uri() {
    let mut sys: helpers::HelperSystems = helpers::setup_core();
    _mint_token(ref sys, OWNER(), 1);
    let uri: ByteArray = sys.permit.token_uri(1);
    assert_gt!(uri.len(), 1000, "token_uri.len()");
    println!("PERMIT TOKEN URI: [{}]", uri);
}



//-----------------------------------
// minting
//

#[test]
fn test_token_mint() {
    let mut sys: helpers::HelperSystems = helpers::setup_core();

    _mint_token(ref sys, OWNER(), 1);
    assert_eq!(sys.permit.total_supply(), 1, "supply_1");
    assert_eq!(sys.permit.owner_of(1), OWNER(), "owner_of_token_1");
    assert_eq!(sys.permit.balance_of(OWNER()), 1, "balance_of_owner_1");
    let token_info_1: PermitTokenInfo = sys.world.read_model(1);
    assert_eq!(token_info_1.is_used, true, "is_used_token_1");

    _mint_token(ref sys, OTHER(), 2);
    assert_eq!(sys.permit.total_supply(), 3, "supply_3");
    assert_eq!(sys.permit.owner_of(2), OTHER(), "owner_of_token_2");
    assert_eq!(sys.permit.owner_of(3), OTHER(), "owner_of_token_3");
    assert_eq!(sys.permit.balance_of(OTHER()), 2, "balance_of_owner_2");
    let token_info_2: PermitTokenInfo = sys.world.read_model(2);
    let token_info_3: PermitTokenInfo = sys.world.read_model(3);
    assert_eq!(token_info_2.is_used, true, "is_used_token_2");
    assert_eq!(token_info_3.is_used, true, "is_used_token_3");

    _mint_token(ref sys, OWNER(), 2);
    assert_eq!(sys.permit.total_supply(), 5, "supply_5");
    assert_eq!(sys.permit.owner_of(4), OWNER(), "owner_of_token_4");
    assert_eq!(sys.permit.owner_of(5), OWNER(), "owner_of_token_5");
    assert_eq!(sys.permit.balance_of(OWNER()), 3, "balance_of_owner_3");
    let token_info_4: PermitTokenInfo = sys.world.read_model(4);
    let token_info_5: PermitTokenInfo = sys.world.read_model(5);
    assert_eq!(token_info_4.is_used, true, "is_used_token_4");
    assert_eq!(token_info_5.is_used, true, "is_used_token_5");
}

//
// airdrops
//

#[test]
fn test_airdrop_ok() {
    let mut sys: helpers::HelperSystems = helpers::setup_core();
    helpers::impersonate(OWNER());
    sys.permit.airdrop_bundle(OTHER(), 1, false);
    assert_eq!(sys.permit.balance_of(OTHER()), 1, "balance_of");
}

#[test]
#[should_panic(expected: ('PERMIT: Invalid caller','ENTRYPOINT_FAILED'))]
fn test_airdrop_other() {
    let mut sys: helpers::HelperSystems = helpers::setup_core();
    helpers::impersonate(OTHER());
    sys.permit.airdrop_bundle(OTHER(), 1, false);
}

//
// purchases
//

#[test]
fn test_purchase_from_world_contract_ok() {
    let mut sys: helpers::HelperSystems = helpers::setup_core();
    helpers::impersonate(sys.setup.contract_address);
    sys.permit.purchased_bundle(OTHER(), 1, false);
    assert_eq!(sys.permit.balance_of(OTHER()), 1, "balance_of");
}

#[test]
#[should_panic(expected: ('PERMIT: Invalid caller','ENTRYPOINT_FAILED'))]
fn test_purchase_not_world_contract() {
    let mut sys: helpers::HelperSystems = helpers::setup_core();
    helpers::impersonate(OTHER());
    sys.permit.purchased_bundle(OTHER(), 1, false);
}

//
// issue
//

#[test]
fn test_issue_ok() {
    let mut sys: helpers::HelperSystems = helpers::setup_core();
    helpers::impersonate(OWNER());
    sys.setup.issue(OTHER(), BUNDLE_ID, 1, Option::None, Option::None, Option::None, 0, Option::None, Option::None);
    assert_eq!(sys.permit.balance_of(OTHER()), 1, "balance_of");
}

#[test]
#[should_panic(expected: ('Bundle: not found','ENTRYPOINT_FAILED'))]
fn test_issue_invalid_bundle() {
    let mut sys: helpers::HelperSystems = helpers::setup_core();
    helpers::impersonate(OWNER());
    sys.setup.issue(OTHER(), BUNDLE_ID+1, 1, Option::None, Option::None, Option::None, 0, Option::None, Option::None);
}

//
// use_permit
//

#[test]
fn test_used_permit_ok() {
    let mut sys: helpers::HelperSystems = helpers::setup_core();
    helpers::impersonate(sys.setup.contract_address);
    let token_ids: Span<u128> = sys.permit.purchased_bundle(OTHER(), 2, false);
    helpers::impersonate(OTHER());
    sys.permit.use_permits(token_ids);
    let token_info_0: PermitTokenInfo = sys.world.read_model(*token_ids[0]);
    let token_info_1: PermitTokenInfo = sys.world.read_model(*token_ids[1]);
    assert_eq!(token_info_0.is_used, true, "token_used_0");
    assert_eq!(token_info_1.is_used, true, "token_used_1");
}

#[test]
#[should_panic(expected: ('PERMIT: Already used','ENTRYPOINT_FAILED'))]
fn test_used_permit_twice() {
    let mut sys: helpers::HelperSystems = helpers::setup_core();
    helpers::impersonate(sys.setup.contract_address);
    let token_ids: Span<u128> = sys.permit.purchased_bundle(OTHER(), 1, false);
    helpers::impersonate(OTHER());
    sys.permit.use_permits(token_ids);
    sys.permit.use_permits(token_ids);
}

#[test]
#[should_panic(expected: ('PERMIT: Invalid caller','ENTRYPOINT_FAILED'))]
fn test_used_permit_not_owner() {
    let mut sys: helpers::HelperSystems = helpers::setup_core();
    helpers::impersonate(sys.setup.contract_address);
    let token_ids: Span<u128> = sys.permit.purchased_bundle(OTHER(), 1, false);
    helpers::impersonate(OWNER());
    sys.permit.use_permits(token_ids);
}

#[test]
#[should_panic(expected: ('PERMIT: Already used','ENTRYPOINT_FAILED'))]
fn test_used_permit_auto_used() {
    let mut sys: helpers::HelperSystems = helpers::setup_core();
    helpers::impersonate(sys.setup.contract_address);
    let token_ids: Span<u128> = sys.permit.purchased_bundle(OTHER(), 1, true);
    helpers::impersonate(OTHER());
    sys.permit.use_permits(token_ids);
}
