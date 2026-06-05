// use dojo::{world::WorldStorage, model::{ModelStorage}};
use starknet::ContractAddress;

#[derive(Clone, Drop, Serde, Introspect, Debug)]
#[dojo::model]
pub struct PermitConfig {
    #[key]
    pub key: felt252,
    //-----------------------------------
    pub messaging_contract: ContractAddress,
    pub appchain_contract: ContractAddress,
}

const PERMIT_KEY: felt252 = 1;


//---------------------------------
// Model Traits
//
use dojo::{
    world::WorldStorage,
    model::{ModelStorage, Model},
    // event::EventStorage,
};    

#[generate_trait]
pub impl PermitConfigImpl of PermitConfigTrait {
    fn initialize_permit_config(ref self: WorldStorage,
        messaging_contract: ContractAddress,
        appchain_contract: ContractAddress,
    ) {
        let permit_config: PermitConfig = PermitConfig {
            key: PERMIT_KEY,
            messaging_contract,
            appchain_contract,
        };
        self.write_model(@permit_config);
    }
    fn get_permit_config(self: @WorldStorage) -> PermitConfig {
        (self.read_model(PERMIT_KEY))
    }
    //
    // admin setters
    //
    fn set_messaging_contract(ref self: WorldStorage, messaging_contract: ContractAddress) {
        self.write_member(Model::<PermitConfig>::ptr_from_keys(PERMIT_KEY), selector!("messaging_contract"), messaging_contract);
    }
    fn set_appchain_contract(ref self: WorldStorage, appchain_contract: ContractAddress) {
        self.write_member(Model::<PermitConfig>::ptr_from_keys(PERMIT_KEY), selector!("appchain_contract"), appchain_contract);
    }
}
