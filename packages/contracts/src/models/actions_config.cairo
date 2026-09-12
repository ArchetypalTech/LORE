use starknet::{ContractAddress};

#[derive(Copy, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct ActionsConfig {
    #[key]
    pub key: felt252,
    //------
    pub sn_contract: ContractAddress,
    pub action_cost_amount: u128,
    pub initial_free_actions_count: u32,    // amount of actions give to any player on first play
    pub max_free_actions_count: u32,        // max number of free actions a player can have
    pub free_action_claim_interval: u64,    // every x seconds, players can claim 1 free action
    pub trail_reward_actions_count: u32,    // how many actions to claim one trail reward on L2?
    // Feature-gate for the owner/creator/collaborator revenue split (Phase 3 of
    // docs/Monetization/revenue-distribution-implementation-plan.md). Defaults to false —
    // while disabled, prompt.cairo passes an empty targets array to charge_player_actions
    // regardless of what the command resolved, preserving today's 100%-to-trail-owner
    // behavior exactly. Toggle at runtime (admin-only) via scripts/set_revenue_split_enabled.sh.
    pub revenue_split_enabled: bool,
}

const ACTIONS_KEY: felt252 = 1;

#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct ActionsReward {
    #[key]
    pub player_address: ContractAddress,
    /// Properties ///
    pub collected_actions_amount: u128,     // amout of actions collected from user content
    pub claimed_actions_amount: u128,       // amout of actions rewarded on L2
}


//---------------------------------
// Model Traits
//
use dojo::{
    world::WorldStorage,
    model::{ModelStorage, Model},
    // event::EventStorage,
};
use lore::{
    types::command_type::{CommandType},
    constants::{
        appchain::{APPCHAIN},
        config::{CONFIG},
    },
    systems::actions_token::actions_token::{Errors as ActionsErrors},
};

#[generate_trait]
pub impl ActionsConfigImpl of ActionsConfigTrait {
    fn initialize_actions_config(ref self: WorldStorage,
        sn_contract: ContractAddress,
    ) {
        let actions_config: ActionsConfig = ActionsConfig {
            key: ACTIONS_KEY,
            sn_contract,
            action_cost_amount: CONFIG::ACTION_COST_AMOUNT,
            initial_free_actions_count: CONFIG::INITIAL_FREE_ACTIONS_COUNT,
            max_free_actions_count: CONFIG::MAX_FREE_ACTIONS_COUNT,
            trail_reward_actions_count: APPCHAIN::CREATOR_REWARD_ACTIONS_COUNT,
            free_action_claim_interval: CONFIG::FREE_ACTION_CLAIM_INTERVAL,
            revenue_split_enabled: false,
        };
        self.write_model(@actions_config);
    }
    fn get_actions_config(self: @WorldStorage) -> ActionsConfig {
        (self.read_model(ACTIONS_KEY))
    }
    fn get_actions_cost(self: @WorldStorage) -> u128 {
        (self.read_member(Model::<ActionsConfig>::ptr_from_keys(ACTIONS_KEY), selector!("action_cost_amount")))
    }
    fn calculate_actions_cost(self: @WorldStorage, command_type: CommandType) -> u128 {
        if command_type == CommandType::Action {
            (self.get_actions_cost())
        } else {
            (0) // free command
        }
    }
    //
    // admin setters
    //
    fn set_sn_contract(ref self: WorldStorage, sn_contract: ContractAddress) {
        self.write_member(Model::<ActionsConfig>::ptr_from_keys(ACTIONS_KEY), selector!("sn_contract"), sn_contract);
    }
    fn set_action_cost_amount(ref self: WorldStorage, action_cost_amount: u128) {
        self.write_member(Model::<ActionsConfig>::ptr_from_keys(ACTIONS_KEY), selector!("action_cost_amount"), action_cost_amount);
    }
    fn set_initial_free_actions_count(ref self: WorldStorage, initial_free_actions_count: u32) {
        self.write_member(Model::<ActionsConfig>::ptr_from_keys(ACTIONS_KEY), selector!("initial_free_actions_count"), initial_free_actions_count);
    }
    fn set_max_free_actions_count(ref self: WorldStorage, max_free_actions_count: u32) {
        self.write_member(Model::<ActionsConfig>::ptr_from_keys(ACTIONS_KEY), selector!("max_free_actions_count"), max_free_actions_count);
    }
    fn set_free_action_claim_interval(ref self: WorldStorage, free_action_claim_interval: u64) {
        self.write_member(Model::<ActionsConfig>::ptr_from_keys(ACTIONS_KEY), selector!("free_action_claim_interval"), free_action_claim_interval);
    }
    fn set_trail_reward_actions_count(ref self: WorldStorage, trail_reward_actions_count: u32) {
        self.write_member(Model::<ActionsConfig>::ptr_from_keys(ACTIONS_KEY), selector!("trail_reward_actions_count"), trail_reward_actions_count);
    }
    fn set_revenue_split_enabled(ref self: WorldStorage, revenue_split_enabled: bool) {
        self.write_member(Model::<ActionsConfig>::ptr_from_keys(ACTIONS_KEY), selector!("revenue_split_enabled"), revenue_split_enabled);
    }
}


#[generate_trait]
pub impl ActionsRewardImpl of ActionsRewardTrait {
    //
    // return the amount of actions available for rewards
    //
    #[inline(always)]
    fn claimable_actions_amount(self: @ActionsReward) -> u128 {
        (*self.collected_actions_amount - *self.claimed_actions_amount)
    }
    fn get_claimable_actions_amount(self: @WorldStorage, player_address: ContractAddress) -> u128 {
        let trail: ActionsReward = self.read_model(player_address);
        (trail.claimable_actions_amount())
    }
    //
    // add actions a player has collected from user content
    //
    fn set_actions_collected_on_content(ref self: WorldStorage, player_address: ContractAddress, actions_amount: u128) {
        let mut trail: ActionsReward = self.read_model(player_address);
        // store collected actions
        trail.collected_actions_amount += actions_amount;
        self.write_model(@trail);
    }
    //
    // player used actions to claim rewards
    //
    fn set_actions_claimed_as_rewards(ref self: WorldStorage, player_address: ContractAddress, actions_amount: u128) {
        let mut trail: ActionsReward = self.read_model(player_address);
        // validate claiming amount
        assert(actions_amount <= trail.claimable_actions_amount(), ActionsErrors::INSUFFICIENT_ACTIONS);
        // store claimed actions
        trail.claimed_actions_amount += actions_amount;
        self.write_model(@trail);
    }
}
