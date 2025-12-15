use dojo::{
    world::WorldStorage,
    model::{ModelStorage},
};
use starknet::ContractAddress;

// The main game trail, used to track progress
pub const MAIN_TRAIL_ID: u128 = 0;

#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct TrailTokenInfo {
    #[key]
    pub trail_id: u128,
    /// Properties ///
    pub minter_address: ContractAddress,
    pub seed: felt252,
    /// trail entity
    pub trail_inst: felt252,
}

#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct TrailProgress {
    #[key]
    pub game_id: u128,
    #[key]
    pub trail_id: u128,
    /// Properties ///
    pub percentage: u8, // 0-100
    pub completed: bool,
}


//---------------------------------
// events
//
#[derive(Copy, Drop, Serde)]
#[dojo::event(historical:false)]
pub struct TrailCreatedEvent {
    #[key]
    pub trail_id: u128,
    /// Properties ///
    pub recipient: ContractAddress,
}



//---------------------------------
// Model Traits
//
use core::num::traits::Zero;
use lore::models::{
    entity::{Entity},
};

#[generate_trait]
pub impl TrailTokenInfoImpl of TrailTokenInfoTrait {
    #[inline(always)]
    fn exists(self: @TrailTokenInfo) -> bool {
        (self.seed.is_non_zero())
    }
    //
    // Trail name
    //
    fn get_trail_name(self: @WorldStorage, trail_id: u128) -> ByteArray {
        let trail: TrailTokenInfo = self.read_model(trail_id);
        let entity: Entity = self.read_model(trail.trail_inst);
        (entity.name)
    }
}

#[generate_trait]
pub impl TrailProgressImpl of TrailProgressTrait {
    fn set_trail_progress(ref self: WorldStorage, game_id: u128, trail_id: u128, mut percentage: u8) {
        let mut trail_progress: TrailProgress = self.read_model((game_id, trail_id),);
        // clamp to not exceed 100
        percentage = core::cmp::min(percentage, 100);
        // write only if percentage has changed
        if (percentage > trail_progress.percentage) {
            trail_progress.percentage = percentage;
            if (percentage == 100) {
                trail_progress.completed = true;
            }
            self.write_model(@trail_progress);
        }
    }
    fn current_trail_progress(self: @WorldStorage, game_id: u128, trail_id: u128) -> u8 {
        let trail_progress: TrailProgress = self.read_model((game_id, trail_id),);
        (trail_progress.percentage)
    }
    fn has_finished_trail(self: @WorldStorage, game_id: u128, trail_id: u128) -> bool {
        let trail_progress: TrailProgress = self.read_model((game_id, trail_id),);
        (trail_progress.completed)
    }
}




#[cfg(test)]
mod tests {
    use super::*;
    // use dojo::{model::ModelStorage};
    use lore::{
        tests::helpers,
    };

    #[test]
    fn test_trail_progress() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        // main game trail
        let game_id: u128 = 1;
        let trail_id: u128 = MAIN_TRAIL_ID;
        sys.world.set_trail_progress(game_id, trail_id, 10);
        assert_eq!(sys.world.current_trail_progress(game_id, trail_id), 10, "trail_0_10%");
        assert!(!sys.world.has_finished_trail(game_id, trail_id), "trail_0_10%");
        sys.world.set_trail_progress(game_id, trail_id, 50);
        assert_eq!(sys.world.current_trail_progress(game_id, trail_id), 50, "trail_0_50%");
        assert!(!sys.world.has_finished_trail(game_id, trail_id), "trail_0_50%");
        sys.world.set_trail_progress(game_id, trail_id, 40);
        assert_eq!(sys.world.current_trail_progress(game_id, trail_id), 50, "trail_0_50%_still");
        assert!(!sys.world.has_finished_trail(game_id, trail_id), "trail_0_50%_still");
        sys.world.set_trail_progress(game_id, trail_id, 100);
        assert_eq!(sys.world.current_trail_progress(game_id, trail_id), 100, "trail_0_100%");
        assert!(sys.world.has_finished_trail(game_id, trail_id), "trail_0_100%");
        // value stored just to be sure
        let trail_progress: TrailProgress = sys.world.read_model((game_id, trail_id),);
        assert_eq!(trail_progress.percentage, 100, "trail_0_100%");
        assert_eq!(trail_progress.completed, true, "trail_0_100%");
        // another trail...
        let trail_id: u128 = 1;
        sys.world.set_trail_progress(game_id, trail_id, 20);
        assert_eq!(sys.world.current_trail_progress(game_id, trail_id), 20, "trail_1_20%");
        assert!(!sys.world.has_finished_trail(game_id, trail_id), "trail_1_20%");
        // main trail still ok
        assert_eq!(sys.world.current_trail_progress(game_id, MAIN_TRAIL_ID), 100, "trail_0_100%_still");
        assert!(sys.world.has_finished_trail(game_id, MAIN_TRAIL_ID), "trail_0_100%_still");
        // another trail, above 100
        let trail_id: u128 = 2;
        sys.world.set_trail_progress(game_id, trail_id, 255);
        assert_eq!(sys.world.current_trail_progress(game_id, trail_id), 100, "trail_2_100%");
        assert!(sys.world.has_finished_trail(game_id, trail_id), "trail_2_100%");
    }
}
