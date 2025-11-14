// use dojo::{world::WorldStorage, model::{ModelStorage}};
use starknet::ContractAddress;

#[derive(Clone, Drop, Serde, Introspect, Debug)]
#[dojo::model]
pub struct MessagingConfig {
    #[key]
    pub contract_address: ContractAddress,
    //-----------------------------------
    pub messaging_contract: ContractAddress,
    pub appchain_contract: ContractAddress,
}
