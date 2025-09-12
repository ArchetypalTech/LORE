use dojo::{world::WorldStorage, model::{ModelStorage}};
use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct ContractConfig {
    #[key]
    pub contract_address: ContractAddress,
    /// Properties ///
    pub admin_address: ContractAddress,
}

#[derive(Copy, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct GameTokenInfo {
    #[key]
    pub game_id: u128,
    /// Properties ///
    pub minter_address: ContractAddress,
    pub seed: felt252,
    pub act_number: u8,
    pub room_inst: felt252,
    pub progress: u8, // 0-100
    pub completed: bool,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event(historical:false)]
pub struct GameCreatedEvent {
    #[key]
    pub contract_address: ContractAddress,
    #[key]
    pub game_id: u128,
    /// Properties ///
    pub recipient: ContractAddress,
}

#[derive(Copy, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct PlayerAccount {
    #[key]
    pub address: ContractAddress,
    /// Properties ///
    pub current_game_id: u128,
}


//---------------------------------
// Model Traits
//
// use lib::dns::{DnsTrait};

#[generate_trait]
pub impl ContractConfigImpl of ContractConfigTrait {
    fn is_admin(world: @WorldStorage, contract_address: ContractAddress, address: ContractAddress) -> bool {
        let config: ContractConfig = world.read_model(contract_address);
        (config.admin_address == address)
    }
    fn set_admin(ref world: WorldStorage, contract_address: ContractAddress, address: ContractAddress) {
        let mut config: ContractConfig = world.read_model(contract_address);
        config.admin_address = address;
        world.write_model(@config);
    }
}

#[generate_trait]
pub impl PlayerAccountImpl of PlayerAccountTrait {
    fn current_game_id(world: @WorldStorage, address: ContractAddress) -> u128 {
        let account: PlayerAccount = world.read_model(address);
        (account.current_game_id)
    }
    fn switch_game_id(ref world: WorldStorage, address: ContractAddress, game_id: u128) {
        let mut account: PlayerAccount = world.read_model(address);
        if (account.current_game_id != game_id && game_id != 0) {
            account.current_game_id = game_id;
            world.write_model(@account);
        }
    }
}
