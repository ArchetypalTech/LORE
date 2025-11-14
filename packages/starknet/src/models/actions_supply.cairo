// use dojo::{world::WorldStorage, model::{ModelStorage}};
use starknet::ContractAddress;

#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct ActionsSupply {
    #[key]
    pub contract_address: ContractAddress,
    //-----------------------------------
    pub amount_minted: u256,
    pub amount_locked: u256,
    pub amount_burned: u256,
}
