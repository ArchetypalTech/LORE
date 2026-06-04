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
        HelperSystems,
        OWNER, OTHER,
    },
};
use lore_sn::models::constants::{CONST};

const AMOUNT: u128 = 1000 * CONST::ETH_TO_WEI.low;

const TOKEN_ID_1_1: u256 = 1;
const TOKEN_ID_1_2: u256 = 2;
const TOKEN_ID_2_1: u256 = 3;
const TOKEN_ID_2_2: u256 = 4;
const TOKEN_ID_3_1: u256 = 5;
const TOKEN_ID_3_2: u256 = 6;

fn _mint_token(ref sys: HelperSystems, recipient: ContractAddress) {
    helpers::impersonate(helpers::cartridge_contract());
    sys.permit.purchased_starter_pack(recipient);
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
    _mint_token(ref sys, OWNER());
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

    _mint_token(ref sys, OWNER());
    assert_eq!(sys.permit.total_supply(), 1, "token_1");
    assert_eq!(sys.permit.owner_of(1), OWNER(), "token_1");
    assert_eq!(sys.permit.balance_of(OWNER()), 1, "token_1");
    let token_info_1: PermitTokenInfo = sys.world.read_model(1);
    assert_eq!(token_info_1.is_used, true, "token_1");

    _mint_token(ref sys, OTHER());
    assert_eq!(sys.permit.total_supply(), 2, "token_2");
    assert_eq!(sys.permit.owner_of(2), OTHER(), "token_2");
    assert_eq!(sys.permit.balance_of(OTHER()), 1, "token_2");
    let token_info_2: PermitTokenInfo = sys.world.read_model(2);
    assert_eq!(token_info_2.is_used, true, "token_2");

    _mint_token(ref sys, OWNER());
    assert_eq!(sys.permit.total_supply(), 3, "token_3");
    assert_eq!(sys.permit.owner_of(3), OWNER(), "token_3");
    assert_eq!(sys.permit.balance_of(OWNER()), 2, "token_3");
    let token_info_3: PermitTokenInfo = sys.world.read_model(3);
    assert_eq!(token_info_3.is_used, true, "token_3");
}


#[test]
#[should_panic(expected: ('PERMIT: Invalid caller','ENTRYPOINT_FAILED'))]
fn test_purchase_not_cartridge_contract() {
    let mut sys: helpers::HelperSystems = helpers::setup_core();
    helpers::impersonate(OWNER());
    sys.permit.purchased_starter_pack(OTHER());
}
