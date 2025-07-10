//! Store struct and component management methods.

// Dojo imports
use dojo::world::WorldStorage;
use dojo::model::ModelStorage;

// Models imports
use lore::models::settings::{SettingsMetadata, GameSettings, SettingsCounter};

// Structs
#[derive(Copy, Drop)]
pub struct Store {
    world: WorldStorage,
}

// Implementations
#[generate_trait]
pub impl StoreImpl of StoreTrait {
    #[inline]
    fn new(world: WorldStorage) -> Store {
        Store { world: world }
    }

    #[inline]
    fn settings_counter(self: Store, id: felt252) -> SettingsCounter {
        self.world.read_model(id)
    }

    #[inline]
    fn set_settings_countes(ref self: Store, settings_counter: @SettingsCounter) {
        self.world.write_model(settings_counter);
    }

    #[inline]
    fn settings_metadata(self: Store, settings_id: u32) -> SettingsMetadata {
        self.world.read_model(settings_id)
    }

    #[inline]
    fn set_settings_metadata(ref self: Store, settings_metadata: @SettingsMetadata) {
        self.world.write_model(settings_metadata);
    }

    #[inline]
    fn game_settings(self: Store, settings_id: u32) -> GameSettings {
        self.world.read_model(settings_id)
    }

    #[inline]
    fn set_game_settings(ref self: Store, game_settings: @GameSettings) {
        self.world.write_model(game_settings);
    }
}
