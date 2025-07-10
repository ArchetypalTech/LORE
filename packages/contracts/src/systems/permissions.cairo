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
    use lore::store::{Store, StoreTrait};
    use lore::constants::world::{DEFAULT_NS};

    #[abi(embed_v0)]
    impl LoreSettingsImpl of ILoreSettings<ContractState> {
        fn add_settings(ref self: ContractState, token_gate_config: TokenGateConfig, name: felt252) -> u32 {
            let mut world: WorldStorage = self.world(@DEFAULT_NS());
            let mut store = StoreTrait::new(world);
            // Use a constant for the counter id
            let counter_id: felt252 = 1;
            let mut counter: SettingsCounter = store.settings_counter(counter_id);
            // If first time, initialize
            if counter.count == 0 {
                counter = SettingsCounterImpl::new();
            }
            // Increment counter for new settings_id
            SettingsCounterImpl::increment(ref counter);
            let settings_id = SettingsCounterImpl::get_count(@counter);
            store.set_settings_countes(@counter);
            // Store GameSettings
            let game_settings = GameSettings { settings_id, token_gate: token_gate_config };
            store.set_game_settings(@game_settings);
            
            let name: felt252 = name;
            let created_by = get_caller_address();
            let created_at = starknet::get_block_timestamp(),
            let metadata = SettingsMetadata { settings_id, name, created_by, created_at };
            store.set_settings_metadata(@metadata);
            settings_id
        }

        fn flip_gate(ref self: ContractState, settings_id: u32) {
            let mut world: WorldStorage = self.world(@DEFAULT_NS());
            let mut store = StoreTrait::new(world);
            let mut game_settings: GameSettings = store.game_settings(settings_id);
            // Only creator can flip
            let metadata: SettingsMetadata = store.settings_metadata(settings_id);
            assert(get_caller_address() == metadata.created_by, 'Only creator can flip gate');
            // Flip the gate
            TokenGateConfigImpl::flip_enabled(ref game_settings.token_gate);
            store.set_game_settings(@game_settings);
        }

        fn set_erc721_address(ref self: ContractState, new_address: ContractAddress) {
            // This function needs a settings_id to know which settings to update
            // For demo, assume settings_id = 1
            let settings_id: u32 = 1; // Replace with argument if needed
            let mut world: WorldStorage = self.world(@DEFAULT_NS());
            let mut store = StoreTrait::new(world);
            let mut game_settings: GameSettings = store.game_settings(settings_id);
            let metadata: SettingsMetadata = store.settings_metadata(settings_id);
            assert(get_caller_address() == metadata.created_by, 'Only creator can set address');
            TokenGateConfigImpl::set_gate_address(ref game_settings.token_gate, new_address);
            store.set_game_settings(@game_settings);
        }
    }
}
