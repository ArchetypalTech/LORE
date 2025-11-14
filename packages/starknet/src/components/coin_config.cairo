use starknet::{ContractAddress};

#[derive(Copy, Drop, Serde, Introspect, Debug)]
#[dojo::model]
pub struct CoinConfig {
    #[key]
    pub coin_address: ContractAddress,
    //------
    pub minter_address: ContractAddress,
    pub faucet_amount: u128, // zero if faucet is closed
}
