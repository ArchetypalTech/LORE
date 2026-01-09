
//
// L2/L3 constants
// must always be in sync
//

pub mod PERMIT_TYPES {
    // product ids
    pub const STARTER_PACK: felt252 = 'STARTER_PACK';
    pub const CREATOR_REWARD: felt252 = 'CREATOR_REWARD';
    // actions included
    pub const STARTER_PACK_ACTIONS_COUNT: u32 = 20;
    pub const CREATOR_REWARD_ACTIONS_COUNT: u32 = 20;
}

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
