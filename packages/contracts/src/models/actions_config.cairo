use starknet::{ContractAddress};

#[derive(Copy, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct ActionsConfig {
    #[key]
    pub key: felt252,
    //------
    pub sn_contract: ContractAddress,
    pub action_cost_amount: u256,
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
    types::command_type::{Command, CommandType},
};

#[generate_trait]
pub impl ActionsConfigImpl of ActionsConfigTrait {
    fn initialize_actions_config(ref self: WorldStorage,
        sn_contract: ContractAddress,
        action_cost_amount: u256,
    ) {
        let actions_config: ActionsConfig = ActionsConfig {
            key: ACTIONS_KEY,
            sn_contract,
            action_cost_amount,
        };
        self.write_model(@actions_config);
    }
    fn get_actions_config(self: @WorldStorage) -> ActionsConfig {
        (self.read_model(ACTIONS_KEY))
    }
    fn get_actions_cost(self: @WorldStorage) -> u256 {
        (self.read_member(Model::<ActionsConfig>::ptr_from_keys(ACTIONS_KEY), selector!("action_cost_amount")))
    }
    fn calculate_actions_cost(self: @WorldStorage, command: @Command) -> u256 {
        if *command.command_type == CommandType::Action {
            (self.get_actions_cost())
        } else {
            (0) // free command
        }
    }
}
