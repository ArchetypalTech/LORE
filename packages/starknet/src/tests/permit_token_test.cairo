// use core::num::traits::Zero;
use starknet::{ContractAddress};
use dojo::model::{ModelStorage, ModelStorageTest};
use bundle::models::index::{Bundle};
use lore_sn::tests::erc20_mock::{ITestERC20Dispatcher, ITestERC20DispatcherTrait};

use lore_sn::models::{
    permit_token_info::{PermitTokenInfo},
};
use lore_sn::appchain::{
    appchain::APPCHAIN::PERMIT_TYPES,
};
use lore_sn::lib::{
    constants::{permit_metadata, CONST},
};
use lore_sn::tests::{helpers,
    helpers::{
        IPermitTokenDispatcherTrait,
        ISetupDispatcherTrait,
        HelperSystems,
        OWNER, OTHER,
    },
};

const AMOUNT: u128 = 1000 * CONST::ETH_TO_WEI.low;

const BUNDLE_ID: u32 = 1;
const BUNDLE_ID_RESERVED: u32 = 2;
const BUNDLE_ID_INVALID: u32 = 11;

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

#[test]
fn test_permit_metadata() {
    let mut sys: helpers::HelperSystems = helpers::setup_core();
    let metadata: ByteArray = sys.setup.get_metadata(BUNDLE_ID);
    println!("PERMIT METADATA: [{}]", metadata);
    assert_gt!(metadata.len(), 100, "metadata.len()");
}

#[test]
fn test_permit_metadata_reserved() {
    let mut sys: helpers::HelperSystems = helpers::setup_core();
    let metadata: ByteArray = sys.setup.get_metadata(BUNDLE_ID_RESERVED);
    println!("RESERVED PERMIT METADATA: [{}]", metadata);
    assert_lt!(metadata.len(), 20, "metadata.len()");
}

#[test]
#[should_panic(expected: ('Bundle: not found','ENTRYPOINT_FAILED'))]
fn test_permit_metadata_invalid_bundle() {
    let mut sys: helpers::HelperSystems = helpers::setup_core();
    let _metadata: ByteArray = sys.setup.get_metadata(BUNDLE_ID_INVALID);
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
    sys.permit.purchased_bundle(OTHER(), PERMIT_TYPES::PERMIT_BUNDLE, 1, false);
    assert_eq!(sys.permit.balance_of(OTHER()), 1, "balance_of");
}

#[test]
#[should_panic(expected: ('PERMIT: Invalid permit','ENTRYPOINT_FAILED'))]
fn test_purchase_invalid_permit_type() {
    let mut sys: helpers::HelperSystems = helpers::setup_core();
    helpers::impersonate(sys.setup.contract_address);
    sys.permit.purchased_bundle(OTHER(), 'INVALID', 1, false);
}

#[test]
#[should_panic(expected: ('PERMIT: Invalid caller','ENTRYPOINT_FAILED'))]
fn test_purchase_not_world_contract() {
    let mut sys: helpers::HelperSystems = helpers::setup_core();
    helpers::impersonate(OTHER());
    sys.permit.purchased_bundle(OTHER(), PERMIT_TYPES::PERMIT_BUNDLE, 1, false);
}

//
// issue
//

#[test]
fn test_issue_ok() {
    let mut sys: helpers::HelperSystems = helpers::setup_core();

    // deploy a mock payment token, minting the supply to the payer (OWNER)
    let supply: u256 = 1_000_000_000;
    let payment_token: ContractAddress = helpers::deploy_mock_erc20(OWNER(), supply);

    // point the bundle at the mock token so issue() can charge it
    let mut bundle: Bundle = sys.world.read_model(BUNDLE_ID);
    bundle.payment_token = payment_token;
    sys.world.write_model_test(@bundle);

    // OWNER approves the setup contract (the transfer_from caller) to spend the price
    helpers::impersonate(OWNER());
    ITestERC20Dispatcher { contract_address: payment_token }.approve(sys.setup.contract_address, supply);

    sys.setup.issue(OTHER(), BUNDLE_ID, 1, Option::None, Option::None, Option::None, 0, Option::None, Option::None);
    assert_eq!(sys.permit.balance_of(OTHER()), 1, "balance_of");
    assert_eq!(bundle.price, ITestERC20Dispatcher { contract_address: payment_token }.balance_of(bundle.payment_receiver), "payment_received");
}

#[test]
#[should_panic(expected: ('PERMIT: Invalid permit','ENTRYPOINT_FAILED','ENTRYPOINT_FAILED'))]
fn test_issue_reserved_bundle() {
    let mut sys: helpers::HelperSystems = helpers::setup_core();
    helpers::impersonate(OWNER());
    sys.setup.issue(OTHER(), BUNDLE_ID_RESERVED, 1, Option::None, Option::None, Option::None, 0, Option::None, Option::None);
}

#[test]
#[should_panic(expected: ('Bundle: not found','ENTRYPOINT_FAILED'))]
fn test_issue_invalid_bundle() {
    let mut sys: helpers::HelperSystems = helpers::setup_core();
    helpers::impersonate(OWNER());
    sys.setup.issue(OTHER(), BUNDLE_ID_INVALID, 1, Option::None, Option::None, Option::None, 0, Option::None, Option::None);
}

//
// use_permit
//

#[test]
fn test_used_permit_ok() {
    let mut sys: helpers::HelperSystems = helpers::setup_core();
    helpers::impersonate(sys.setup.contract_address);
    let token_ids: Span<u128> = sys.permit.purchased_bundle(OTHER(), PERMIT_TYPES::PERMIT_BUNDLE, 2, false);
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
    let token_ids: Span<u128> = sys.permit.purchased_bundle(OTHER(), PERMIT_TYPES::PERMIT_BUNDLE, 1, false);
    helpers::impersonate(OTHER());
    sys.permit.use_permits(token_ids);
    sys.permit.use_permits(token_ids);
}

#[test]
#[should_panic(expected: ('PERMIT: Invalid caller','ENTRYPOINT_FAILED'))]
fn test_used_permit_not_owner() {
    let mut sys: helpers::HelperSystems = helpers::setup_core();
    helpers::impersonate(sys.setup.contract_address);
    let token_ids: Span<u128> = sys.permit.purchased_bundle(OTHER(), PERMIT_TYPES::PERMIT_BUNDLE, 1, false);
    helpers::impersonate(OWNER());
    sys.permit.use_permits(token_ids);
}

#[test]
#[should_panic(expected: ('PERMIT: Already used','ENTRYPOINT_FAILED'))]
fn test_used_permit_auto_used() {
    let mut sys: helpers::HelperSystems = helpers::setup_core();
    helpers::impersonate(sys.setup.contract_address);
    let token_ids: Span<u128> = sys.permit.purchased_bundle(OTHER(), PERMIT_TYPES::PERMIT_BUNDLE, 1, true);
    helpers::impersonate(OTHER());
    sys.permit.use_permits(token_ids);
}
