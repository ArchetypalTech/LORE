use starknet::{ContractAddress};

#[derive(Copy, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct ActionsConfig {
    #[key]
    pub key: felt252,
    //------
    pub sn_contract: ContractAddress,
    pub action_cost_amount: u128,
    pub free_action_claim_interval: u64,
    pub max_free_actions_count: u32,
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
            free_action_claim_interval: TIMESTAMP::ONE_HOUR,
            max_free_actions_count: 5,
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
}
