use starknet::{ContractAddress};

#[derive(Copy, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct ActionsConfig {
    #[key]
    pub key: felt252,
    //------
    pub sn_contract: ContractAddress,
}


//---------------------------------
// Model Traits
//
use dojo::{
    world::WorldStorage,
    model::ModelStorage,
    // event::EventStorage,
};

#[generate_trait]
pub impl ActionsConfigImpl of ActionsConfigTrait {
    fn initialize_actions_config(ref self: WorldStorage, sn_contract: ContractAddress) {
        let actions_config: ActionsConfig = ActionsConfig {
            key: 1,
            sn_contract,
        };
        self.write_model(@actions_config);
    }
    fn get_actions_config(self: @WorldStorage) -> ActionsConfig {
        (self.read_model(1))
    }
}
