// use core::num::traits::Zero;
// use starknet::{ContractAddress};

use lore::models::{
    // config::{CoinConfig}
};
use lore::tests::{helpers,
    helpers::{
        IActionsLoreDispatcherTrait,
        HelperSystems,
        // OWNER,
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

fn setup(_fee_amount: u128) -> HelperSystems {
    let mut sys: HelperSystems = helpers::setup_core();
    (sys)
}

//
// initialize
//

#[test]
fn test_initializer() {
    let mut sys: HelperSystems = setup(0);
println!("sys.actions.symbol(): {}", sys.actions.symbol());
    assert_eq!(sys.actions.symbol(), "ACTIONS", "Symbol is wrong");
}

