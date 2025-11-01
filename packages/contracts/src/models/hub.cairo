use core::num::traits::Zero;
use dojo::{world::WorldStorage, model::{ModelStorage, Model}};
use lore::{
    models::{
        entity::{Entity, EntityImpl},
        trail_token_info::{TrailTokenInfo},
    },
    lib::{
        utils::ByteArrayTraitExt,
        variable_property_helper::{VariablePropertyHelper},
    },
};

#[derive(Clone, Drop, Serde, Debug, Introspect, PartialEq)]
#[dojo::model]
pub struct Hub {
    /// Unique identifier attached to the entity
    #[key]
    pub inst: felt252,
    pub is_hub: bool,
    /// Properties ///
    /// can receive trails
    pub is_enabled: bool,
}

#[derive(Clone, Drop, Serde, Debug, Introspect, PartialEq)]
#[dojo::model]
pub struct Trail {
    /// Unique identifier attached to the entity
    #[key]
    pub inst: felt252,
    pub is_trail: bool,
    /// Properties ///
    /// trail token_id, there must be only 1 Trail component per trail_id
    pub trail_id: u128,
    /// hub this Trail belongs to
    pub hub_inst: felt252,
    /// published status
    pub is_published: bool,
}


//---------------------------------
// Model Trait
//
#[generate_trait]
pub impl HubImpl of HubTrait {
    fn is_hub(self: @Hub) -> bool {
        (*self.is_hub)
    }

    fn has_hub_component(self: @WorldStorage, inst: felt252) -> bool {
        (inst != 0 && self.read_member(Model::<Hub>::ptr_from_keys(inst), selector!("is_hub")))
    }
}

#[generate_trait]
pub impl TrailImpl of TrailTrait {
    // this is a top-level Trail component
    fn is_trail(self: @Trail) -> bool {
        (*self.is_trail)
    }

    // this is a top-level Entity that has a Trail component
    fn has_trail_component(self: @WorldStorage, inst: felt252) -> bool {
        (inst != 0 && self.read_member(Model::<Trail>::ptr_from_keys(inst), selector!("is_trail")))
    }

    // this is an entity that was added to a Trail
    fn get_entity_trail_id(self: @WorldStorage, inst: felt252) -> u128 {
        (self.read_member(Model::<Entity>::ptr_from_keys(inst), selector!("trail_id")))
    }
    fn is_inside_trail_id(self: @WorldStorage, inst: felt252, trail_id: u128) -> bool {
        (self.get_entity_trail_id(inst) == trail_id)
    }
    fn is_inside_trail(self: @WorldStorage, inst: felt252) -> bool {
        (self.get_entity_trail_id(inst).is_non_zero())
    }

    // called when a new trial is minted
    fn create_new_trail_entity(ref self: WorldStorage, trail_id: u128) {
        // Create a new entity for the trail
        let trail_name: ByteArray = format!("Trail-{}", trail_id);
        let entity: Entity = EntityImpl::create_trail_entity(ref self, trail_name, trail_id);
        // Create the trail component
        let trail: Trail = Trail {
            inst: entity.inst,
            is_trail: true,
            trail_id,
            hub_inst: 0,
            is_published: false,
        };
        self.write_model(@trail);
        // update trail token
        self.write_member(Model::<TrailTokenInfo>::ptr_from_keys(trail_id), selector!("trail_inst"), trail.inst);
    }

    // called from designer.create_trail()
    fn assert_can_edit_trail(ref self: WorldStorage, new_trail: @Trail) {
        let existing_trail: Trail = self.read_model(*new_trail.inst);
        assert(existing_trail.is_trail, 'TRAIL: Trail not found');
        // avoid changinf a Trail's trail_id
        assert(existing_trail.trail_id == *new_trail.trail_id, 'TRAIL: Invalid trail id');
        // avoid changinf a Trail's trail_id
        assert(new_trail.hub_inst.is_zero() || self.has_hub_component(*new_trail.hub_inst), 'TRAIL: Invalid hub');
    }

    // avoid deleting a top-level trail entity
    // called from designer.delete_entity()
    // called from designer.delete_trail()
    fn assert_can_delete_trail(ref self: WorldStorage, inst: felt252) {
        assert(!self.is_inside_trail(inst), 'TRAIL: Not allowed delete trail');
    }
}




#[cfg(test)]
mod tests {
    use starknet::ContractAddress;
    use dojo::{
        // world::{WorldStorage},
        model::{ModelStorage},
    };
    use super::*;
    use lore::{
        systems::{
            designer::{IDesignerDispatcherTrait},
            prompt::{IPromptDispatcherTrait},
            game_token::{IGameTokenDispatcherTrait},
            trail_token::{ITrailTokenDispatcherTrait},
        },
        models::{
            entity::{Entity},
            player::{Player, PlayerImpl},
            game_token_info::{PlayerGameImpl},
            trail_token_info::{TrailTokenInfo},
        },
        tests::{
            helpers,
            helpers::{OWNER},
        },
    };

    // based on game_token_test::test_token_winner_becomes_editor()
    fn _create_trail(ref sys: helpers::HelperSystems, player_address: ContractAddress) -> (Player, Entity, Trail) {
        // initialize player singleton
        PlayerImpl::caller_as_player(ref sys.world, OWNER(), 0);
        // mint a game
        helpers::set_caller(player_address);
        sys.prompt.prompt("", Option::None);
        let game_id: u128 = PlayerGameImpl::current_game_id(@sys.world, player_address);
        assert_gt!(sys.game_token.total_supply(), 0);
        assert_eq!(sys.game_token.owner_of(game_id.into()), player_address);
        // get player
        let player: Player = PlayerImpl::get_player(@sys.world, game_id).unwrap();
        assert!(player.is_player, "player created");
        // set as editor
        helpers::set_caller(OWNER());
        sys.designer.set_editor(player_address, true);
        // create trail
        helpers::set_caller(player_address);
        sys.prompt.prompt("g_create_trail", Option::None);
// helpers::print_player_story_last_line(@sys.world, game_id);
        let trail_id: u128 = game_id; // we're creating one trail per game
// println!("trail_id: {}", trail_id);
        assert_gt!(sys.trail_token.total_supply(), 0);
        assert_eq!(sys.trail_token.owner_of(trail_id.into()), player_address);
        let trail_info: TrailTokenInfo = sys.world.read_model(trail_id);
        assert_ne!(trail_info.seed, 0, "seed");
        assert_ne!(trail_info.trail_inst, 0, "trail_inst");
        let entity: Entity = sys.world.read_model(trail_info.trail_inst);
        let trail: Trail = sys.world.read_model(trail_info.trail_inst);
        (player, entity, trail)
    }

    #[test]
    fn test_create_trail_ok() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let (_player, entity, trail) : (Player, Entity, Trail) = _create_trail(ref sys, helpers::PLAYER_1);
        assert!(trail.is_trail, "is_trail");
        assert_eq!(entity.name, "Trail-1");
        assert_eq!(entity.trail_id, trail.trail_id);
    }

    #[test]
    #[should_panic(expected: ('TRAIL: Trail not found','ENTRYPOINT_FAILED'))]
    fn test_not_allowed_to_create_trails_directly() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let mut trail_1: Trail = Trail {
            trail_id: 1,
            hub_inst: 0,
            is_published: false,
            inst: 0x123,
            is_trail: true,
        };
        sys.designer.create_trail(array![trail_1.clone()]);
    }

    #[test]
    #[should_panic(expected: ('TRAIL: Invalid trail id','ENTRYPOINT_FAILED'))]
    fn test_not_allowed_to_edit_trail_id() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let (_player, _entity, mut trail) : (Player, Entity, Trail) = _create_trail(ref sys, helpers::PLAYER_1);
        trail.trail_id = 2;
        sys.designer.create_trail(array![trail.clone()]);
    }

    #[test]
    #[should_panic(expected: ('TRAIL: Invalid hub','ENTRYPOINT_FAILED'))]
    fn test_not_allowed_to_use_invalid_hub() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let (_player, _entity, mut trail) : (Player, Entity, Trail) = _create_trail(ref sys, helpers::PLAYER_1);
        trail.hub_inst = 0x123;
        sys.designer.create_trail(array![trail.clone()]);
    }

    #[test]
    #[should_panic(expected: ('TRAIL: Not allowed delete trail','ENTRYPOINT_FAILED'))]
    fn test_not_allowed_to_delete_trail_entity() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let (_player, _entity, mut trail) : (Player, Entity, Trail) = _create_trail(ref sys, helpers::PLAYER_1);
        helpers::set_caller(OWNER());
        sys.designer.delete_entity(array![trail.inst]);
    }

    #[test]
    #[should_panic(expected: ('TRAIL: Not allowed delete trail','ENTRYPOINT_FAILED'))]
    fn test_not_allowed_to_delete_trail_component() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let (_player, _entity, mut trail) : (Player, Entity, Trail) = _create_trail(ref sys, helpers::PLAYER_1);
        helpers::set_caller(OWNER());
        sys.designer.delete_trail(array![trail.inst]);
    }
}

