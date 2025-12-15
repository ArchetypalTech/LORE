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
}

const ACTIONS_KEY: felt252 = 1;


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
    constants::constants::{TIMESTAMP},
    constants::appchain::{PERMIT_TYPES},
};

#[generate_trait]
pub impl ActionsConfigImpl of ActionsConfigTrait {
    fn initialize_actions_config(ref self: WorldStorage,
        sn_contract: ContractAddress,
        action_cost_amount: u128,
    ) {
        let actions_config: ActionsConfig = ActionsConfig {
            key: ACTIONS_KEY,
            sn_contract,
            action_cost_amount,
            initial_free_actions_count: 5,
            max_free_actions_count: 5,
            free_action_claim_interval: TIMESTAMP::ONE_HOUR,
            trail_reward_actions_count: PERMIT_TYPES::TRAIL_REWARD_ACTIONS_COUNT,
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
}
