// use dojo::{world::WorldStorage, model::{ModelStorage}};
use starknet::ContractAddress;

#[derive(Clone, Drop, Serde, Introspect, Debug)]
#[dojo::model]
pub struct MessagingConfig {
    #[key]
    pub key: felt252,
    //-----------------------------------
    pub messaging_contract: ContractAddress,
    pub appchain_contract: ContractAddress,
}
