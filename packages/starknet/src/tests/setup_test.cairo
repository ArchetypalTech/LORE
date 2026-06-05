use starknet::{ContractAddress};

use lore_sn::models::{
    permit_config::{PermitConfigTrait},
};
use lore_sn::tests::{helpers,
    helpers::{
        ISetupDispatcherTrait,
        HelperSystems,
        OWNER, OTHER,
    },
};

//-----------------------------------
// admin functions
//

#[test]
fn test_set_messaging_contract() {
    let mut sys: HelperSystems = helpers::setup_core();
    let address: ContractAddress = 0x1234.try_into().unwrap();
    helpers::impersonate(OWNER());
    sys.setup.set_messaging_contract(address);
    assert_eq!(sys.world.get_permit_config().messaging_contract, address);
}

#[test]
fn test_set_appchain_contract() {
    let mut sys: HelperSystems = helpers::setup_core();
    let address: ContractAddress = 0x1234.try_into().unwrap();
    helpers::impersonate(OWNER());
    sys.setup.set_appchain_contract(address);
    assert_eq!(sys.world.get_permit_config().appchain_contract, address);
}

#[test]
#[should_panic(expected: ('SETUP: Invalid caller','ENTRYPOINT_FAILED'))]
fn test_set_messaging_contract_not_owner() {
    let mut sys: HelperSystems = helpers::setup_core();
    let address: ContractAddress = 0x1234.try_into().unwrap();
    helpers::impersonate(OTHER());
    sys.setup.set_messaging_contract(address);
}

#[test]
#[should_panic(expected: ('SETUP: Invalid caller','ENTRYPOINT_FAILED'))]
fn test_set_appchain_contract_not_owner() {
    let mut sys: HelperSystems = helpers::setup_core();
    let address: ContractAddress = 0x1234.try_into().unwrap();
    helpers::impersonate(OTHER());
    sys.setup.set_appchain_contract(address);
}
