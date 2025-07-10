use starknet::{ContractAddress, get_caller_address};
use lore::models::token_gating::TokenGateConfig;
pub use lore::models::index::{SettingsMetadata, GameSettings, SettingsCounter};

#[generate_trait]
pub impl SettingsCounterImpl of SettingsCounterTrait {
    #[inline]
    fn new() -> SettingsCounter {
        SettingsCounter { id: 1, count: 0 }
    }

    #[inline]
    fn increment(ref self: SettingsCounter) {
        self.count += 1;
    }

    #[inline]
    fn get_count(self: @SettingsCounter) -> u32 {
        *self.count
    }
}

#[generate_trait]
pub impl GameSettingsImpl of GameSettingsTrait {
    #[inline]
    fn new(settings_id: u32, token_gate: TokenGateConfig) -> GameSettings {
        GameSettings { settings_id: settings_id, token_gate: token_gate }
    }
}

#[generate_trait]
pub impl SettingsMetadataImpl of SettingsMetadataTrait {
    #[inline]
    fn new(
        settings_id: u32, name: felt252, created_by: ContractAddress, created_at: u64,
    ) -> SettingsMetadata {
        SettingsMetadata {
            settings_id: settings_id, name: name, created_by: created_by, created_at: created_at,
        }
    }
}
