//
// L3 initial config
// (can be changed later by admin)
//
pub mod CONFIG {
    pub const ACTION_COST_AMOUNT: u128 = 1 * lore::constants::constants::CONST::ETH_TO_WEI.low;
    pub const INITIAL_FREE_ACTIONS_COUNT: u32 = 5;
    pub const MAX_FREE_ACTIONS_COUNT: u32 = 5;
    pub const FREE_ACTION_CLAIM_INTERVAL: u64 = lore::constants::constants::TIMESTAMP::ONE_HOUR;
}
