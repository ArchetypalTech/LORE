use core::num::traits::Zero;
use dojo::{
    world::{WorldStorage, IWorldDispatcherTrait},
    model::{ModelStorage, Model},
};
use lore::{
    models::{
        entity::{Entity, EntityImpl, ParentToChildren},
        trail_token_info::{TrailTokenInfo},
        description_text::{DescriptionText},
        reactable::{Reactable},
        area::{Area},
        exit::{Exit},
    },
    types::{
        direction_type::{Direction},
        component_type::{
            ActionMapReactable, ReactableActions,
            ActionMapExit, ExitActions,
        },
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
    pub trails_insts: Array<felt252>,
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

    fn get_hub_component(self: @WorldStorage, inst: felt252) -> Option<Hub> {
        if (self.has_hub_component(inst)) {
            let hub: Hub = self.read_model(inst);
            Option::Some(hub)
        } else {
            Option::None
        }
    }

    fn get_published_trails_insts(self: @Hub, world: @WorldStorage) -> Span<felt252> {
        let mut result: Array<felt252> = array![];
        let is_published: Array<bool> = world.read_member_of_models(Model::<Trail>::ptrs_from_keys(self.trails_insts.span()), selector!("is_published"));
        for i in 0..is_published.len() {
            if (*is_published[i]) {
                //
                // TODO: apply Trail moderation here (exclude flagged trails)
                //
                result.append(*self.trails_insts[i]);
            }
        }
        (result.span())
    }

    // fn get_trails_as_children(self: @Hub, world: @WorldStorage, ref context: Array<Entity>) -> Array<Entity> {
    //     let mut result: Array<Entity> = array![];
    //     self.append_trails_as_children(world, ref result);
    //     (result)
    // }
    fn append_trails_as_children(self: @Hub, world: @WorldStorage, ref context: Array<Entity>) {
        let trails_insts: Span<felt252> = self.get_published_trails_insts(world);
        for i in 0..trails_insts.len() {
            let trail_entity: Entity = world.read_model(*trails_insts[i]);
            context.append(trail_entity);
        }
    }

    fn get_trails_exits(self: @Hub, world: @WorldStorage) -> Span<Exit> {
        let mut result: Array<Exit> = array![];
        // get all published trails added to this Hub
        let trails_insts: Span<felt252> = self.get_published_trails_insts(world);
        // get children of each trail
        let trails_children: Array<Array<felt252>> = world.read_member_of_models(Model::<ParentToChildren>::ptrs_from_keys(trails_insts), selector!("children"));
        for i in 0..trails_children.len() {
            // Find spawn points in Areas
            let children_insts: Span<felt252> = trails_children[i].span();
            let is_spawn_points: Array<bool> = world.read_member_of_models(Model::<Area>::ptrs_from_keys(children_insts), selector!("is_spawn_point"));
            for j in 0..is_spawn_points.len() {
                // if is_spawn_point is true, the Area exists and it is a spawn point
                if (*is_spawn_points[j]) {
                    let exit: Exit = Exit {
                        inst: world.dispatcher.uuid().try_into().unwrap(), // ephemeral inst
                        is_exit: true,
                        is_enterable: true,
                        leads_to: *children_insts[j],
                        direction_type: Direction::North,
                        action_map: array![],
                    };
                    result.append(exit);
                }
            }
        }
        (result.span())
    }

    //
    // called when deleting a Hub
    fn remove_trails_from_hub(self: @Hub, ref world: WorldStorage) {
        for trails_insts in self.trails_insts {
            let mut trail: Trail = world.read_model(*trails_insts);
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
            trails_insts: array![],
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

    //
    // called when a new trial is minted
    // from trail_token only!!!
    fn create_new_trail_entity(ref self: WorldStorage, trail_id: u128) {
        // Create a new entity for the trail
        let trail_name: ByteArray = format!("Trail-{}", trail_id);
        let trail_name_alt: ByteArray = format!("trail-{}", trail_id);
        let mut entity: Entity = EntityImpl::create_trail_entity(ref self, trail_name.clone(), trail_id);
        entity.alt_names = array![trail_name_alt.clone()];
        // Create the trail components
        let trail: Trail = Trail {
            inst: entity.inst,
            is_trail: true,
            trail_id,
            hub_inst: 0,
            is_published: false,
        };
        let exit: Exit = Exit {
            inst: entity.inst,
            is_exit: true,
            is_enterable: true,
            leads_to: 0,
            direction_type: Direction::Down,
            action_map: array![
                ActionMapExit { action: "go", inst: 0, action_fn: ExitActions::UseExit },
                ActionMapExit { action: "enter", inst: 0, action_fn: ExitActions::UseExit },
                ActionMapExit { action: "use", inst: 0, action_fn: ExitActions::UseExit },
            ],
        };
        let descr_0: DescriptionText = DescriptionText {
            inst: entity.inst,
            key: 0,
            text: "A player generated Trail. Enter at your own risk!",
        };
        let reactable: Reactable = Reactable {
            inst: entity.inst,
            is_reactable: true,
            is_visible: true,
            description: array![0],
            action_map: array![
                ActionMapReactable {
                    action: "show",
                    inst: 0,
                    action_fn: ReactableActions::ReadSpecificDescription,
                    entrypoints: (0, 0),
                },
                ActionMapReactable {
                    action: "look",
                    inst: 0,
                    action_fn: ReactableActions::ReadSpecificDescription,
                    entrypoints: (0, 0),
                },
                ActionMapReactable {
                    action: "read",
                    inst: 0,
                    action_fn: ReactableActions::ReadSpecificDescription,
                    entrypoints: (0, 0),
                },
            ],
            already_shown: false,
            new_entry: trail_name_alt,
        };
        // write models
        self.write_model(@entity);
        self.write_model(@trail);
        self.write_model(@exit);
        self.write_model(@descr_0);
        self.write_model(@reactable);
        // update trail token
        self.write_member(Model::<TrailTokenInfo>::ptr_from_keys(trail_id), selector!("trail_inst"), trail.inst);
    }

    // avoid deleting a top-level Trail entities and components
    // called from designer delete_*()
    fn assert_trail_delete_protection(ref self: WorldStorage, inst: felt252) {
        assert(!self.has_trail_component(inst), 'TRAIL: Not allowed delete trail');
    }

    // called from designer.create_trail()
    fn assert_trail_edit_protection(ref self: WorldStorage, new_trail: @Trail) {
        let existing_trail: Trail = self.read_model(*new_trail.inst);
        // not allowed to create a Trails from designer
        // Trails are one-to-one with tokens, and created automatically when a token is minted
        assert(existing_trail.is_trail, 'TRAIL: Not allowed to create');
        // not allowed to change trail_id
        assert(existing_trail.trail_id == *new_trail.trail_id, 'TRAIL: Invalid trail id');
        // not allowed to change the hub_inst
        assert(new_trail.hub_inst.is_zero() || self.has_hub_component(*new_trail.hub_inst), 'TRAIL: Invalid hub');
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
            hub.trails_insts.append(*self.inst);
            world.write_model(@hub);
        }
    }

    // called when deleting a Trail
    fn remove_from_hub(self: @Trail, ref world: WorldStorage) {
        // check if Trail exists
        if (*self.is_trail && self.hub_inst.is_non_zero()) {
            // check if it is inside a Hub
            let mut current_hub: Hub = world.read_model(*self.hub_inst);
            if (current_hub.is_hub && current_hub.trails_insts.contains(self.inst)) {
                // remove from current Hub
                current_hub.trails_insts = current_hub.trails_insts.remove(self.inst);
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
            area::{AreaComponent, Area},
            exit::{Exit, ExitComponent, ExitInstance},
            reactable::{ReactableInstance},
            reactable::tests::{Reactable_create_prefab},

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
// helpers::print_game_story_last_line(@sys.world, game_id);
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
        assert!(ExitInstance::has_component(@sys.world, entity.inst));
        assert!(ReactableInstance::has_component(@sys.world, entity.inst));
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
    #[should_panic(expected: ('TRAIL: Not allowed to create','ENTRYPOINT_FAILED'))]
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
        let (entity, _trail) : (Entity, Trail) = _create_trail(ref sys, helpers::PLAYER_1);
        helpers::set_caller(OWNER());
        sys.designer.delete_entity(array![entity.inst]);
    }

    #[test]
    #[should_panic(expected: ('TRAIL: Not allowed delete trail','ENTRYPOINT_FAILED'))]
    fn test_not_allowed_to_delete_trail_component() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let (entity, _trail) : (Entity, Trail) = _create_trail(ref sys, helpers::PLAYER_1);
        helpers::set_caller(OWNER());
        sys.designer.delete_trail(array![entity.inst]);
    }

    #[test]
    #[should_panic(expected: ('TRAIL: Not allowed delete trail','ENTRYPOINT_FAILED'))]
    fn test_not_allowed_to_delete_exit_component() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let (entity, _trail) : (Entity, Trail) = _create_trail(ref sys, helpers::PLAYER_1);
        helpers::set_caller(OWNER());
        sys.designer.delete_exit(array![entity.inst]);
    }

    #[test]
    #[should_panic(expected: ('TRAIL: Not allowed delete trail','ENTRYPOINT_FAILED'))]
    fn test_not_allowed_to_delete_reactable_component() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let (entity, _trail) : (Entity, Trail) = _create_trail(ref sys, helpers::PLAYER_1);
        helpers::set_caller(OWNER());
        sys.designer.delete_reactable(array![entity.inst]);
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
        let mut hub_1: Hub = sys.world.read_model(hub_1.inst);
        ArrayTestUtilsTrait::assert_span_eq(hub_1.trails_insts.span(), array![trail_1.inst, trail_2.inst].span(), "hub_1.trails_insts 1");
        ArrayTestUtilsTrait::assert_span_eq(hub_2.trails_insts.span(), array![].span(), "hub_2.trails_insts 2");
        //
        // try to edit trails -- NOW ALLOWED!
        hub_1.trails_insts = array![trail_3.inst];
        sys.designer.create_hub(array![hub_1.clone()]);
        let mut hub_1: Hub = sys.world.read_model(hub_1.inst);
        ArrayTestUtilsTrait::assert_span_eq(hub_1.trails_insts.span(), array![trail_1.inst, trail_2.inst].span(), "hub_1.trails_insts STILL");
        //
        // move trails...
        trail_1.hub_inst = 0; // remove...
        trail_2.hub_inst = hub_2.inst; // move...
        trail_3.hub_inst = hub_2.inst; // add...
        sys.designer.create_trail(array![trail_1.clone(), trail_2.clone(), trail_3.clone()]);
        let hub_1: Hub = sys.world.read_model(hub_1.inst);
        let hub_2: Hub = sys.world.read_model(hub_2.inst);
        ArrayTestUtilsTrait::assert_span_eq(hub_1.trails_insts.span(), array![].span(), "hub_1.trails_insts 2");
        ArrayTestUtilsTrait::assert_span_eq(hub_2.trails_insts.span(), array![trail_2.inst, trail_3.inst].span(), "hub_2.trails_insts 2");
        //
        // delete trail, remove from hub -- NOT ALLOWED!!
//         sys.designer.delete_trail(array![trail_2.inst]);
//         let hub_1: Hub = sys.world.read_model(hub_1.inst);
//         let hub_2: Hub = sys.world.read_model(hub_2.inst);
//         ArrayTestUtilsTrait::assert_span_eq(hub_1.trails_insts.span(), array![].span(), "hub_1.trails_insts 3");
//         ArrayTestUtilsTrait::assert_span_eq(hub_2.trails_insts.span(), array![trail_3.inst].span(), "hub_2.trails_insts 3");
        //
        // delete Hub, remove trails from hub
        sys.designer.delete_hub(array![hub_2.inst]);
        let hub_1: Hub = sys.world.read_model(hub_1.inst);
        let hub_2: Hub = sys.world.read_model(hub_2.inst);
        let trail_1: Trail = sys.world.read_model(trail_1.inst);
        let trail_2: Trail = sys.world.read_model(trail_2.inst);
        let trail_3: Trail = sys.world.read_model(trail_3.inst);
        ArrayTestUtilsTrait::assert_span_eq(hub_1.trails_insts.span(), array![].span(), "hub_1.trails_insts 4");
        ArrayTestUtilsTrait::assert_span_eq(hub_2.trails_insts.span(), array![].span(), "hub_2.trails_insts 4");
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


    #[test]
    fn test_get_hub_trails_exits_ok() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        // Create Hubs
        let game_id: u128 = 0;
        let entity_hub_1: Entity = EntityImpl::create_entity(ref sys.world, "hub");
        let mut hub_1: Hub = HubImpl::add_component(ref sys.world, entity_hub_1.inst);
        sys.designer.create_entity(array![entity_hub_1.clone()]);
        sys.designer.create_hub(array![hub_1.clone()]);
        // mint Trails
        let (entity_trail_1, mut trail_1): (Entity, Trail) = _mint_trail(ref sys);
        let (entity_trail_2, mut trail_2): (Entity, Trail) = _mint_trail(ref sys);
        let (entity_trail_3, mut trail_3): (Entity, Trail) = _mint_trail(ref sys);
        // add trails to hub
        trail_1.hub_inst = hub_1.inst;
        trail_2.hub_inst = hub_1.inst;
        trail_3.hub_inst = hub_1.inst;
        trail_1.is_published = true;
        trail_2.is_published = true;
        trail_3.is_published = false;
        sys.designer.create_trail(array![trail_1.clone(), trail_2.clone(), trail_3.clone()]);
        // validate...
        let hub_1: Hub = sys.world.read_model(hub_1.inst);
        ArrayTestUtilsTrait::assert_span_eq(hub_1.trails_insts.span(), array![trail_1.inst, trail_2.inst, trail_3.inst].span(), "hub_1.trails_insts");
        // create Areas inside trails
        let mut entity_area_1_spawn: Entity = EntityImpl::create_entity(ref sys.world, "entity_area_1_spawn");
        let mut entity_area_1_other: Entity = EntityImpl::create_entity(ref sys.world, "entity_area_1_other");
        let mut entity_area_2_spawn: Entity = EntityImpl::create_entity(ref sys.world, "entity_area_2_spawn");
        let mut entity_area_2_other: Entity = EntityImpl::create_entity(ref sys.world, "entity_area_2_other");
        let mut entity_area_3_spawn: Entity = EntityImpl::create_entity(ref sys.world, "entity_area_3_spawn");
        let mut entity_area_3_other: Entity = EntityImpl::create_entity(ref sys.world, "entity_area_3_other");
        let mut area_1_spawn: Area = AreaComponent::add_component(ref sys.world, entity_area_1_spawn.inst);
        let mut area_1_other: Area = AreaComponent::add_component(ref sys.world, entity_area_1_other.inst);
        let mut area_2_spawn: Area = AreaComponent::add_component(ref sys.world, entity_area_2_spawn.inst);
        let mut area_2_other: Area = AreaComponent::add_component(ref sys.world, entity_area_2_other.inst);
        let mut area_3_spawn: Area = AreaComponent::add_component(ref sys.world, entity_area_3_spawn.inst);
        let mut area_3_other: Area = AreaComponent::add_component(ref sys.world, entity_area_3_other.inst);
        area_1_spawn.is_spawn_point = true;
        area_1_other.is_spawn_point = false;
        area_2_spawn.is_spawn_point = true;
        area_2_other.is_spawn_point = false;
        area_3_spawn.is_spawn_point = true;
        area_3_other.is_spawn_point = false;
        entity_area_1_spawn.trail_id = trail_1.trail_id;
        entity_area_1_other.trail_id = trail_1.trail_id;
        entity_area_2_spawn.trail_id = trail_2.trail_id;
        entity_area_2_other.trail_id = trail_2.trail_id;
        entity_area_3_spawn.trail_id = trail_3.trail_id;
        entity_area_3_other.trail_id = trail_3.trail_id;
        sys.designer.create_entity(array![
            entity_area_1_spawn.clone(), entity_area_1_other.clone(),
            entity_area_2_spawn.clone(), entity_area_2_other.clone(),
            entity_area_3_spawn.clone(), entity_area_3_other.clone(),
        ]);
        sys.designer.create_area(array![
            area_1_spawn.clone(), area_1_other.clone(),
            area_2_spawn.clone(), area_2_other.clone(),
            area_3_spawn.clone(), area_3_other.clone(),
        ]);
        entity_area_1_spawn.set_parent(ref sys.world, @entity_trail_1, game_id);
        entity_area_1_other.set_parent(ref sys.world, @entity_trail_1, game_id);
        entity_area_2_spawn.set_parent(ref sys.world, @entity_trail_2, game_id);
        entity_area_2_other.set_parent(ref sys.world, @entity_trail_2, game_id);
        entity_area_3_spawn.set_parent(ref sys.world, @entity_trail_3, game_id);
        entity_area_3_other.set_parent(ref sys.world, @entity_trail_3, game_id);
        //
        // check hub trails
        let exits: Span<Exit> = hub_1.get_trails_exits(@sys.world);
        assert_eq!(exits.len(), 2, "exits.len()");
        assert_eq!(*exits[0].leads_to, area_1_spawn.inst, "exits[0].leads_to");
        assert_eq!(*exits[1].leads_to, area_2_spawn.inst, "exits[1].leads_to");
    }

    #[test]
    fn test_hub_look_around() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        // create some rooms
        let room_1_entity: Entity = EntityImpl::create_entity(ref sys.world, "You are in Room 1");
        let room_2_entity: Entity = EntityImpl::create_entity(ref sys.world, "You are in Room 2");
        let _: Reactable = Reactable_create_prefab(ref sys.world, room_1_entity.inst, "ROOM1");
        let _: Reactable = Reactable_create_prefab(ref sys.world, room_2_entity.inst, "ROOM2");
        let _area_1: Area = AreaComponent::add_component(ref sys.world, room_1_entity.inst);
        let _area_2: Area = AreaComponent::add_component(ref sys.world, room_2_entity.inst);
        // create exits
        let mut exit_1_entity: Entity = EntityImpl::create_entity(ref sys.world, "Exit To Room 2");
        let mut exit_2_entity: Entity = EntityImpl::create_entity(ref sys.world, "Exit To Room 1");
        exit_1_entity.alt_names = array!["to_room_2"];
        exit_2_entity.alt_names = array!["to_room_1"];
        sys.world.write_model(@exit_1_entity);
        sys.world.write_model(@exit_2_entity);
        let _: Reactable = Reactable_create_prefab(ref sys.world, exit_1_entity.inst, "to_room_2");
        let _: Reactable = Reactable_create_prefab(ref sys.world, exit_2_entity.inst, "to_room_1");
        let mut exit_to_room_2: Exit = ExitComponent::add_component(ref sys.world, exit_1_entity.inst);
        let mut exit_to_room_1: Exit = ExitComponent::add_component(ref sys.world, exit_2_entity.inst);
        exit_to_room_2.leads_to = room_2_entity.inst;
        exit_to_room_2.is_enterable = true;
        exit_to_room_2.direction_type = Direction::North;
        exit_to_room_1.leads_to = room_1_entity.inst;
        exit_to_room_1.is_enterable = true;
        exit_to_room_1.direction_type = Direction::South;
        sys.world.write_model(@exit_to_room_2);
        sys.world.write_model(@exit_to_room_1);
        // add exits to rooms
        exit_1_entity.set_parent(ref sys.world, @room_1_entity, 0);
        exit_2_entity.set_parent(ref sys.world, @room_2_entity, 0);
        //
        // create player
        let game_id: u128 = 1;
        let player: Player = PlayerImpl::caller_as_player(ref sys.world, helpers::PLAYER_1, 0);
        helpers::set_caller(helpers::PLAYER_1);
        sys.prompt.prompt("", Option::None); // creates game token
// helpers::print_game_story_last_command(@sys.world, game_id, "init");
        // place in Room 2
        helpers::set_caller(helpers::OWNER());
        player.move_to_room(ref sys.world, room_2_entity.inst);
        //
        // move to room 2
        helpers::set_caller(helpers::PLAYER_1);
        sys.prompt.prompt("use to_room_1", Option::None);
// helpers::print_game_story_last_command(@sys.world, game_id, "use to_room_1");
        sys.prompt.prompt("look around", Option::None);
helpers::print_game_story_last_command(@sys.world, game_id, "look around (in_room_1)");
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "to_room_2", "look 2");
        //
        // Create Hub inside ROOM 1
        helpers::set_caller(helpers::OWNER());
        let mut hub_1: Hub = HubImpl::add_component(ref sys.world, room_1_entity.inst);
        sys.designer.create_hub(array![hub_1.clone()]);
        // mint Trails
        let (_entity_trail_1, mut trail_1): (Entity, Trail) = _mint_trail(ref sys);
        let (_entity_trail_2, mut trail_2): (Entity, Trail) = _mint_trail(ref sys);
        let (_entity_trail_3, mut trail_3): (Entity, Trail) = _mint_trail(ref sys);
        // add trails to hub
        trail_1.hub_inst = hub_1.inst;
        trail_2.hub_inst = hub_1.inst;
        trail_3.hub_inst = hub_1.inst;
        trail_1.is_published = true;
        trail_2.is_published = false;
        trail_3.is_published = false;
        sys.designer.create_trail(array![trail_1.clone(), trail_2.clone(), trail_3.clone()]);
        //
        // list rooms (with trail)
        helpers::set_caller(helpers::PLAYER_1);
println!("___________________________look at trail-1...");
        sys.prompt.prompt("look around", Option::None); // will display the description
helpers::print_game_story_last_command(@sys.world, game_id, "look around (+trail_1)");
        sys.prompt.prompt("look around", Option::None); // willl display reactable.new_entry
helpers::print_game_story_last_command(@sys.world, game_id, "look around (+trail_1 AGAIN)");
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "trail-1");
        //
        // enable Trail2 
        helpers::set_caller(helpers::OWNER());
        trail_2.is_published = true;
        sys.designer.create_trail(array![trail_2.clone()]);
        // list rooms (with trail)
        helpers::set_caller(helpers::PLAYER_1);
        sys.prompt.prompt("look around", Option::None); // will display the description
helpers::print_game_story_last_command(@sys.world, game_id, "look around (+trail_2)");
        sys.prompt.prompt("look around", Option::None); // willl display reactable.new_entry
helpers::print_game_story_last_command(@sys.world, game_id, "look around (+trail_2 AGAIN)");
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "trail-2");


//         //
//         // rooom 1
//         helpers::set_caller(helpers::PLAYER_1);
//         sys.prompt.prompt("g_game_id", Option::None);
//         assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "+sys+game-1", "g_game_id");
//         sys.prompt.prompt("use to_room_2", Option::None);
//         sys.prompt.prompt("look around", Option::None);
// // println!("++ room 1: {}: {}", _story_len(@sys.world, game_id), helpers::game_story_last_line(@sys.world, game_id));
//         assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "to_room_1", "look 2");
//         sys.prompt.prompt("use to_room_1", Option::None);
//         sys.prompt.prompt("look around", Option::None);
// // println!("++ room 2: {}: {}", _story_len(@sys.world, game_id), helpers::game_story_last_line(@sys.world, game_id));
//         assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "to_room_2", "look 1");
//         //
//         // add new entity to room 2
//         assert_eq!(room_2_entity.get_children_count(@sys.world, 0), 1, "after add");
//         helpers::set_caller(helpers::OWNER());
//         let mut new_entity: Entity = EntityImpl::create_entity(ref sys.world, "New Entity");
//         let _: Reactable = Reactable_create_prefab(ref sys.world, new_entity.inst, "new_entity");
//         new_entity.set_parent(ref sys.world, @room_2_entity, 0);
//         helpers::set_caller(helpers::PLAYER_1);
//         // one more children
//         assert_eq!(room_2_entity.get_children_count(@sys.world, 0), 2, "after add");
//         assert_eq!(room_2_entity.get_children_count(@sys.world, game_id), 1, "after add");
//         //
//         // enter room 2, look around... new entity not present
//         sys.prompt.prompt("use to_room_2", Option::None);
//         assert_eq!(room_2_entity.get_children_count(@sys.world, game_id), 1+1, "use after add");
//         sys.prompt.prompt("look around", Option::None);
//         assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "to_room_1", "use after add");
//         sys.prompt.prompt("use to_room_1", Option::None);
//         //
//         // enable preserve_children
//         helpers::set_caller(helpers::OWNER());
//         area_2.preserve_children = true;
//         sys.world.write_model(@area_2);
//         helpers::set_caller(helpers::PLAYER_1);
//         //
//         // enter room 2, look around... new entity not present
//         sys.prompt.prompt("use to_room_2", Option::None);
//         assert_eq!(room_2_entity.get_children_count(@sys.world, game_id), 2+1, "after preserve");
//         let token_info: GameTokenInfo = sys.world.read_model(game_id);
//         assert_eq!(token_info.room_name, room_2_entity.name.clone(), "after to_room_2");
//         sys.prompt.prompt("look around", Option::None);
//         assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "new_entity", "after preserve");
//         sys.prompt.prompt("use to_room_1", Option::None);
//         let token_info: GameTokenInfo = sys.world.read_model(game_id);
//         assert_eq!(token_info.room_name, room_1_entity.name.clone(), "after to_room_1");
    }
}
