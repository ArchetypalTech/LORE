use starknet::{ContractAddress, get_caller_address};
use lore::models::token_gating::TokenGateConfig;

// ERC721 interface (minimal)
#[starknet::interface]
pub trait IERC721<T> {
    fn balance_of(self: @T, owner: ContractAddress) -> u256;
}

#[starknet::interface]
pub trait ILoreSettings<T> {
    fn add_settings(ref self: T, token_gate_config: TokenGateConfig) -> u32;
    fn flip_gate(ref self: T, settings_id: u32);
    fn set_erc721_address(ref self: T, new_address: ContractAddress);
}

#[dojo::contract]
pub mod permissions {
    use super::{ILoreSettings, IERC721};
    use starknet::{ContractAddress, get_caller_address};
    use dojo::model::ModelStorage;
    use dojo::world::{WorldStorage};
    use lore::models::settings::{
        SettingsCounter, SettingsCounterImpl, SettingsCounterTrait, GameSettings, GameSettingsImpl,
        GameSettingsTrait, SettingsMetadata, SettingsMetadataImpl, SettingsMetadataTrait,
    };
    use lore::models::token_gating::{TokenGateConfig, TokenGateConfigImpl, TokenGateConfigTrait};
    use lore::store::Store;
    use lore::constants::world::{DEFAULT_NS};

    #[abi(embed_v0)]
    impl LoreSettingsImpl of ILoreSettings<ContractState> {
        fn add_settings(ref self: ContractState, token_gate_config: TokenGateConfig) -> u32 {
            let mut world: WorldStorage = self.world(@DEFAULT_NS());
            let mut store = Store::new(world);
            0
        }
        fn flip_gate(ref self: ContractState, settings_id: u32) {}
        fn set_erc721_address(ref self: ContractState, new_address: ContractAddress) {}
    }
}
