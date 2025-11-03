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
        arrays::{ArrayUtilsTrait},
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
    /// trails this Hub contains
    pub trails_inst: Array<felt252>,
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

    //
    // called when deleting a Hub
    fn remove_trails_from_hub(self: @Hub, ref world: WorldStorage) {
        for trails_inst in self.trails_inst {
            let mut trail: Trail = world.read_model(*trails_inst);
            if (trail.is_trail && trail.hub_inst == *self.inst) {
                trail.hub_inst = 0;
                world.write_model(@trail);
            }
        }
    }

    // used for tests only
    fn add_component(ref world: WorldStorage, inst: felt252) -> Hub {
        (Hub {
            inst,
            is_hub: true,
            is_enabled: true,
            trails_inst: array![],
        })
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
        // not allowed to create a Trails from designer
        // Trails are one-to-one with tokens, and created automatically when a token is minted
        assert(existing_trail.is_trail, 'TRAIL: Trail not found');
        // not allowed to change trail_id
        assert(existing_trail.trail_id == *new_trail.trail_id, 'TRAIL: Invalid trail id');
        // not allowed to change the hub_inst
        assert(new_trail.hub_inst.is_zero() || self.has_hub_component(*new_trail.hub_inst), 'TRAIL: Invalid hub');
    }

    // avoid deleting a top-level Trail entity
    // called from designer.delete_entity()
    // called from designer.delete_trail()
    fn assert_can_delete_trail(ref self: WorldStorage, inst: felt252) {
        assert(!self.has_trail_component(inst), 'TRAIL: Not allowed delete trail');
    }

    //
    // called when adding/editing a Trail
    fn append_to_hub(self: @Trail, ref world: WorldStorage) {
        //
        // remove from current Hub, if any
        let current_trail: Trail = world.read_model(*self.inst);
        current_trail.remove_from_hub(ref world);
        //
        // check is being added to a Hub
        if (self.hub_inst.is_non_zero()) {
            let mut hub: Hub = world.read_model(*self.hub_inst);
            assert(hub.is_hub, 'TRAIL: Invalid hub');
            assert(hub.is_enabled, 'TRAIL: Hub is disabled');
            hub.trails_inst.append(*self.inst);
            world.write_model(@hub);
        }
    }

    // called when deleting a Trail
    fn remove_from_hub(self: @Trail, ref world: WorldStorage) {
        // check if Trail exists
        if (*self.is_trail && self.hub_inst.is_non_zero()) {
            // check if it is inside a Hub
            let mut current_hub: Hub = world.read_model(*self.hub_inst);
            if (current_hub.is_hub && current_hub.trails_inst.contains(self.inst)) {
                // remove from current Hub
                current_hub.trails_inst = current_hub.trails_inst.remove(self.inst);
                world.write_model(@current_hub);
            }
        }
    }

    // used for tests only
    fn add_component(ref world: WorldStorage, inst: felt252, trail_id: u128) -> Trail {
        (Trail {
            inst,
            is_trail: true,
            trail_id,
            hub_inst: 0,
            is_published: false,
        })
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
        lib::{
            arrays::{ArrayTestUtilsTrait},
        }
    };

    // based on game_token_test::test_token_winner_becomes_editor()
    fn _create_trail(ref sys: helpers::HelperSystems, player_address: ContractAddress) -> (Entity, Trail) {
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
        helpers::set_caller(OWNER());
        (entity, trail)
    }

    #[test]
    fn test_create_trail_ok() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let (entity, trail) : (Entity, Trail) = _create_trail(ref sys, helpers::PLAYER_1);
        assert!(trail.is_trail, "is_trail");
        assert_eq!(entity.name, "Trail-1");
        assert_eq!(entity.trail_id, trail.trail_id);
        //
        // add some children
        let game_id: u128 = 0;
        let mut child1: Entity = EntityImpl::create_entity(ref sys.world, "child1");
        let mut child2: Entity = EntityImpl::create_entity(ref sys.world, "child2");
        child1.trail_id = trail.trail_id;
        child2.trail_id = trail.trail_id;
        sys.world.write_model(@child1);
        sys.world.write_model(@child2);
        child1.set_parent(ref sys.world, @entity, game_id);
        child2.set_parent(ref sys.world, @entity, game_id);
        // should be able to delete children
        sys.designer.delete_entity(array![child1.inst, child2.inst]);
    }

    #[test]
    #[should_panic(expected: ('TRAIL: Trail not found','ENTRYPOINT_FAILED'))]
    fn test_not_allowed_to_create_trails_directly() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let mut trail_1: Trail = TrailImpl::add_component(ref sys.world, 0x123, 1);
        sys.designer.create_trail(array![trail_1.clone()]);
    }

    #[test]
    #[should_panic(expected: ('TRAIL: Invalid trail id','ENTRYPOINT_FAILED'))]
    fn test_not_allowed_to_edit_trail_id() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let (_entity, mut trail) : (Entity, Trail) = _create_trail(ref sys, helpers::PLAYER_1);
        trail.trail_id = 2;
        sys.designer.create_trail(array![trail.clone()]);
    }

    #[test]
    #[should_panic(expected: ('TRAIL: Invalid hub','ENTRYPOINT_FAILED'))]
    fn test_not_allowed_to_use_invalid_hub() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let (_entity, mut trail) : (Entity, Trail) = _create_trail(ref sys, helpers::PLAYER_1);
        trail.hub_inst = 0x123;
        sys.designer.create_trail(array![trail.clone()]);
    }

    #[test]
    #[should_panic(expected: ('TRAIL: Not allowed delete trail','ENTRYPOINT_FAILED'))]
    fn test_not_allowed_to_delete_trail_entity() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let (_entity, mut trail) : (Entity, Trail) = _create_trail(ref sys, helpers::PLAYER_1);
        helpers::set_caller(OWNER());
        sys.designer.delete_entity(array![trail.inst]);
    }

    #[test]
    #[should_panic(expected: ('TRAIL: Not allowed delete trail','ENTRYPOINT_FAILED'))]
    fn test_not_allowed_to_delete_trail_component() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let (_entity, mut trail) : (Entity, Trail) = _create_trail(ref sys, helpers::PLAYER_1);
        helpers::set_caller(OWNER());
        sys.designer.delete_trail(array![trail.inst]);
    }

    //---------------------------------
    // Hubs + Trails
    //

    fn _mint_trail(ref sys: helpers::HelperSystems) -> (Entity, Trail) {
        // initialize player singleton
        PlayerImpl::caller_as_player(ref sys.world, OWNER(), 0);
        // mint from command
        let supply: u128 = sys.trail_token.total_supply().low;
        helpers::set_caller(OWNER());
        sys.prompt.prompt("g_create_trail", Option::None);
        // find entity
        let trail_id: u128 = supply + 1;
        let trail_info: TrailTokenInfo = sys.world.read_model(trail_id);
        assert_ne!(trail_info.trail_inst, 0, "_mint_trail()");
        let entity: Entity = sys.world.read_model(trail_info.trail_inst);
        let trail: Trail = sys.world.read_model(trail_info.trail_inst);
        assert_eq!(trail.trail_id, trail_id, "_mint_trail()");
        (entity, trail)
    }

    #[test]
    fn test_designer_create_hub_trails_ok() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        // create trails
        // Create Hubs
        let entity_hub_1: Entity = EntityImpl::create_entity(ref sys.world, "hub");
        let entity_hub_2: Entity = EntityImpl::create_entity(ref sys.world, "hub");
        let mut hub_1: Hub = HubImpl::add_component(ref sys.world, entity_hub_1.inst);
        let mut hub_2: Hub = HubImpl::add_component(ref sys.world, entity_hub_2.inst);
        // create with designer
        helpers::set_caller(OWNER());
        sys.designer.create_entity(array![entity_hub_1.clone(), entity_hub_2.clone()]);
        sys.designer.create_hub(array![hub_1.clone(), hub_2.clone()]);
        // mint Trails -- will create trails
        let (_entity_trail_1, mut trail_1): (Entity, Trail) = _mint_trail(ref sys);
        let (_entity_trail_2, mut trail_2): (Entity, Trail) = _mint_trail(ref sys);
        let (_entity_trail_3, mut trail_3): (Entity, Trail) = _mint_trail(ref sys);
        trail_1.hub_inst = hub_1.inst;
        trail_2.hub_inst = hub_1.inst;
        trail_3.hub_inst = 0;
        // edit Trails with designer >> assign to Hubs
        sys.designer.create_trail(array![trail_1.clone(), trail_2.clone(), trail_3.clone()]);
        //
        // check hub trails
        let hub_1: Hub = sys.world.read_model(hub_1.inst);
        ArrayTestUtilsTrait::assert_span_eq(hub_1.trails_inst.span(), array![trail_1.inst, trail_2.inst].span(), "hub_1.trails_inst 1");
        ArrayTestUtilsTrait::assert_span_eq(hub_2.trails_inst.span(), array![].span(), "hub_2.trails_inst 2");
        //
        // move trails...
        trail_1.hub_inst = 0; // remove...
        trail_2.hub_inst = hub_2.inst; // move...
        trail_3.hub_inst = hub_2.inst; // add...
        sys.designer.create_trail(array![trail_1.clone(), trail_2.clone(), trail_3.clone()]);
        let hub_1: Hub = sys.world.read_model(hub_1.inst);
        let hub_2: Hub = sys.world.read_model(hub_2.inst);
        ArrayTestUtilsTrait::assert_span_eq(hub_1.trails_inst.span(), array![].span(), "hub_1.trails_inst 2");
        ArrayTestUtilsTrait::assert_span_eq(hub_2.trails_inst.span(), array![trail_2.inst, trail_3.inst].span(), "hub_2.trails_inst 2");
        //
        // delete trail, remove from hub -- NOT ALLOWED!!
//         sys.designer.delete_trail(array![trail_2.inst]);
//         let hub_1: Hub = sys.world.read_model(hub_1.inst);
//         let hub_2: Hub = sys.world.read_model(hub_2.inst);
//         ArrayTestUtilsTrait::assert_span_eq(hub_1.trails_inst.span(), array![].span(), "hub_1.trails_inst 3");
//         ArrayTestUtilsTrait::assert_span_eq(hub_2.trails_inst.span(), array![trail_3.inst].span(), "hub_2.trails_inst 3");
        //
        // delete Hub, remove trails from hub
        sys.designer.delete_hub(array![hub_2.inst]);
        let hub_1: Hub = sys.world.read_model(hub_1.inst);
        let hub_2: Hub = sys.world.read_model(hub_2.inst);
        let trail_1: Trail = sys.world.read_model(trail_1.inst);
        let trail_2: Trail = sys.world.read_model(trail_2.inst);
        let trail_3: Trail = sys.world.read_model(trail_3.inst);
        ArrayTestUtilsTrait::assert_span_eq(hub_1.trails_inst.span(), array![].span(), "hub_1.trails_inst 4");
        ArrayTestUtilsTrait::assert_span_eq(hub_2.trails_inst.span(), array![].span(), "hub_2.trails_inst 4");
        assert!(trail_1.hub_inst.is_zero(), "trail_1.hub_inst 4");
        assert!(trail_2.hub_inst.is_zero(), "trail_2.hub_inst 4");
        assert!(trail_3.hub_inst.is_zero(), "trail_3.hub_inst 4");
    }

    #[test]
    #[should_panic(expected: ('TRAIL: Hub is disabled','ENTRYPOINT_FAILED'))]
    fn test_designer_create_trail_to_disabled_hub() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        // create trails
        let (_entity_trail_1, mut trail_1): (Entity, Trail) = _mint_trail(ref sys);
        // Create Hubs
        let entity_hub_1: Entity = EntityImpl::create_entity(ref sys.world, "hub");
        let mut hub_1: Hub = HubImpl::add_component(ref sys.world, entity_hub_1.inst);
        hub_1.is_enabled = false;
        trail_1.hub_inst = hub_1.inst;
        //
        // create with designer
        helpers::set_caller(OWNER());
        sys.designer.create_entity(array![entity_hub_1.clone()]);
        sys.designer.create_hub(array![hub_1.clone()]);
        // edit trail and panic...
        sys.designer.create_trail(array![trail_1.clone()]);
    }


    #[test]
    #[should_panic(expected: ('TRAIL: Invalid hub','ENTRYPOINT_FAILED'))]
    fn test_designer_create_trail_to_invalid_hub() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        // create trails
        let (_entity_trail_1, mut trail_1): (Entity, Trail) = _mint_trail(ref sys);
        trail_1.hub_inst = 0x123;
        //
        // edit trail and panic...
        helpers::set_caller(OWNER());
        sys.designer.create_trail(array![trail_1.clone()]);
    }

}
