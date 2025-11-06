use core::num::traits::Zero;
use starknet::{ContractAddress};
use dojo::{
    world::{WorldStorage}, //, IWorldDispatcherTrait},
    model::{ModelStorage, Model},
};
use lore::{
    models::{
        entity::{Entity, EntityImpl, ParentToChildren, ChildToParent},
        trail_token_info::{TrailTokenInfo},
        description_text::{DescriptionText},
        reactable::{Reactable},
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
        dns::{DnsTrait, ITrailTokenDispatcherTrait},
        variable_property_helper::{VariablePropertyHelper},
        utils::{ByteArrayTraitExt},
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

    fn get_trails_as_children(self: @Hub, world: @WorldStorage) -> Array<Entity> {
        let mut result: Array<Entity> = array![];
        self.append_trails_as_children(world, ref result);
        (result)
    }
    fn append_trails_as_children(self: @Hub, world: @WorldStorage, ref context: Array<Entity>) {
        let trails_insts: Span<felt252> = self.get_published_trails_insts(world);
        for i in 0..trails_insts.len() {
            let trail_entity: Entity = world.read_model(*trails_insts[i]);
            context.append(trail_entity);
        }
    }

    // fn get_trails_exits(self: @Hub, world: @WorldStorage) -> Span<Exit> {
    //     let mut result: Array<Exit> = array![];
    //     // get all published trails added to this Hub
    //     let trails_insts: Span<felt252> = self.get_published_trails_insts(world);
    //     // get children of each trail
    //     let trails_children: Array<Array<felt252>> = world.read_member_of_models(Model::<ParentToChildren>::ptrs_from_keys(trails_insts), selector!("children"));
    //     for i in 0..trails_children.len() {
    //         // Find spawn points in Areas
    //         let children_insts: Span<felt252> = trails_children[i].span();
    //         let is_spawn_points: Array<bool> = world.read_member_of_models(Model::<Area>::ptrs_from_keys(children_insts), selector!("is_spawn_point"));
    //         for j in 0..is_spawn_points.len() {
    //             // if is_spawn_point is true, the Area exists and it is a spawn point
    //             if (*is_spawn_points[j]) {
    //                 let exit: Exit = Exit {
    //                     inst: world.dispatcher.uuid().try_into().unwrap(), // ephemeral inst
    //                     is_exit: true,
    //                     is_enterable: true,
    //                     leads_to: *children_insts[j],
    //                     direction_type: Direction::North,
    //                     action_map: array![],
    //                 };
    //                 result.append(exit);
    //             }
    //         }
    //     }
    //     (result.span())
    // }

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
    #[inline(always)]
    fn is_trail(self: @Trail) -> bool {
        (*self.is_trail)
    }

    // this is a top-level Entity that has a Trail component
    fn has_trail_component(self: @WorldStorage, inst: felt252) -> bool {
        (inst != 0 && self.read_member(Model::<Trail>::ptr_from_keys(inst), selector!("is_trail")))
    }

    // this is an entity that was added to a Trail
    fn is_inside_trail(self: @WorldStorage, inst: felt252) -> bool {
        (self.get_entity_trail_id(inst).is_non_zero())
    }
    fn is_inside_trail_id(self: @WorldStorage, inst: felt252, trail_id: u128) -> bool {
        (self.get_entity_trail_id(inst) == trail_id)
    }
    fn get_entity_trail_id(self: @WorldStorage, inst: felt252) -> u128 {
        (self.read_member(Model::<Entity>::ptr_from_keys(inst), selector!("trail_id")))
    }
    fn get_entities_trail_ids(self: @WorldStorage, insts: Span<felt252>) -> Array<u128> {
        (self.read_member_of_models(Model::<Entity>::ptrs_from_keys(insts), selector!("trail_id")))
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

    fn can_edit_trail(self: @WorldStorage, inst: felt252, owned: ContractAddress) -> bool {
        if (EntityImpl::is_entity(self, inst)) {
            let trail_id: u128 = self.get_entity_trail_id(inst);
            if (trail_id.is_non_zero()) {
                // check trail ownership
                (self.trail_token_dispatcher().is_owner_of(owned, trail_id.into()))
            } else {
                // not in a trail
                (false)
            }
        } else {
            // new entity
            (true)
        }
    }

    // avoid deleting a top-level Trail entities and components
    // called from designer delete_*()
    fn assert_trail_delete_protection(self: @WorldStorage, inst: felt252) {
        assert(!self.has_trail_component(inst), 'TRAIL: Not allowed delete trail');
    }

    // called from designer.create_trail()
    fn assert_trail_edit_protection(self: @WorldStorage, new_trail: @Trail) {
        let existing_trail: Trail = self.read_model(*new_trail.inst);
        // not allowed to create a Trails from designer
        // Trails are one-to-one with tokens, and created automatically when a token is minted
        assert(existing_trail.is_trail, 'TRAIL: Not allowed to create');
        // not allowed to change trail_id
        assert(existing_trail.trail_id == *new_trail.trail_id, 'TRAIL: Invalid trail id');
        // not allowed to change the hub_inst
        assert(new_trail.hub_inst.is_zero() || self.has_hub_component(*new_trail.hub_inst), 'TRAIL: Invalid hub');
    }

    // called from designer.create_parent()
    fn assert_trail_parent_protection(self: @WorldStorage, new_parent: @ParentToChildren) {
        let parent_trail_id: u128 = self.get_entity_trail_id(*new_parent.inst);
        let trail_ids: Array<u128> = self.get_entities_trail_ids(new_parent.children.span());
        for trail_id in trail_ids {
            assert(trail_id == parent_trail_id, 'TRAIL: Invalid child trail_id');
        }
    }

    // called from designer.create_child()
    fn assert_trail_child_protection(self: @WorldStorage, new_child: @ChildToParent) {
        let child_trail_id: u128 = self.get_entity_trail_id(*new_child.inst);
        let parent_trail_id: u128 = self.get_entity_trail_id(*new_child.parent);
        assert(parent_trail_id == child_trail_id, 'TRAIL: Invalid parent trail_id');
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
pub mod tests {
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
            container::{Container, ContainerComponent},
            inventory_item::{InventoryItem, InventoryItemComponent},
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

    pub fn _mint_trail(ref sys: helpers::HelperSystems, recipient: ContractAddress) -> (Entity, Trail, Exit) {
        // initialize player singleton
        helpers::set_caller(OWNER());
        PlayerImpl::caller_as_player(ref sys.world, OWNER(), 0);
        // mint from command
        let supply: u128 = sys.trail_token.total_supply().low;
        helpers::set_caller(recipient);
        sys.prompt.prompt("g_create_trail", Option::None);
        // minted
        let trail_id: u128 = supply + 1;
        assert_eq!(sys.trail_token.total_supply().low, trail_id, "trail_token.total_supply()");
        assert_eq!(sys.trail_token.owner_of(trail_id.into()), recipient, "trail.owner_of(recipient)");
        // find entity
        let trail_info: TrailTokenInfo = sys.world.read_model(trail_id);
        assert_ne!(trail_info.trail_inst, 0, "_mint_trail()");
        let entity: Entity = sys.world.read_model(trail_info.trail_inst);
        let trail: Trail = sys.world.read_model(trail_info.trail_inst);
        let exit: Exit = sys.world.read_model(trail_info.trail_inst);
        assert_eq!(trail.trail_id, trail_id, "_mint_trail()");
        assert_eq!(entity.trail_id, trail_id, "_mint_trail()");
        (entity, trail, exit)
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
        let (_entity_trail_1, mut trail_1, _exit_1): (Entity, Trail, Exit) = _mint_trail(ref sys, OWNER());
        let (_entity_trail_2, mut trail_2, _exit_2): (Entity, Trail, Exit) = _mint_trail(ref sys, OWNER());
        let (_entity_trail_3, mut trail_3, _exit_3): (Entity, Trail, Exit) = _mint_trail(ref sys, OWNER());
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
        let (_entity_trail_1, mut trail_1, _exit_1): (Entity, Trail, Exit) = _mint_trail(ref sys, OWNER());
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
        let (_entity_trail_1, mut trail_1, _exit_1): (Entity, Trail, Exit) = _mint_trail(ref sys, OWNER());
        trail_1.hub_inst = 0x123;
        //
        // edit trail and panic...
        helpers::set_caller(OWNER());
        sys.designer.create_trail(array![trail_1.clone()]);
    }


    #[test]
    fn test_get_hub_trails_as_children_ok() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        // Create Hubs
        let game_id: u128 = 0;
        let entity_hub_1: Entity = EntityImpl::create_entity(ref sys.world, "hub");
        let mut hub_1: Hub = HubImpl::add_component(ref sys.world, entity_hub_1.inst);
        sys.designer.create_entity(array![entity_hub_1.clone()]);
        sys.designer.create_hub(array![hub_1.clone()]);
        // mint Trails
        let (entity_trail_1, mut trail_1, _exit_1): (Entity, Trail, Exit) = _mint_trail(ref sys, OWNER());
        let (entity_trail_2, mut trail_2, _exit_2): (Entity, Trail, Exit) = _mint_trail(ref sys, OWNER());
        let (entity_trail_3, mut trail_3, _exit_3): (Entity, Trail, Exit) = _mint_trail(ref sys, OWNER());
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
        // check hub trails as children
        let children: Span<Entity> = hub_1.get_trails_as_children(@sys.world).span();
        assert_eq!(children.len(), 2, "exits.len()");
        assert_eq!(*children[0].inst, entity_trail_1.inst, "children[0].inst");
        assert_eq!(*children[1].inst, entity_trail_2.inst, "children[1].inst");
        //
        // check hub trails -- NOT USED!
        // let exits: Span<Exit> = hub_1.get_trails_exits(@sys.world);
        // assert_eq!(exits.len(), 2, "exits.len()");
        // assert_eq!(*exits[0].leads_to, area_1_spawn.inst, "exits[0].leads_to");
        // assert_eq!(*exits[1].leads_to, area_2_spawn.inst, "exits[1].leads_to");
    }
    
    #[test]
    fn test_hub_look_around() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        // create some rooms
        let (room_1_entity, area_1): (Entity, Area) = helpers::create_area_entity(ref sys, "This is Room 1", "ROOM1", Option::None);
        let (room_2_entity, area_2): (Entity, Area) = helpers::create_area_entity(ref sys, "This is Room 2", "ROOM2", Option::None);
        // create exits
        let (_exit_1_entity, _exit_to_room_2): (Entity, Exit) = helpers::create_exit_in_area(ref sys, "Exit To Room 2", "to_room_2", @room_1_entity, area_2.inst);
        let (_exit_2_entity, _exit_to_room_1): (Entity, Exit) = helpers::create_exit_in_area(ref sys, "Exit To Room 1", "to_room_1", @room_2_entity, area_1.inst);
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
// helpers::print_game_story_last_command(@sys.world, game_id, "look around (in_room_1)");
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "to_room_2", "look 2");
        //
        // Create Hub inside ROOM 1
        helpers::set_caller(helpers::OWNER());
        let mut hub_1: Hub = HubImpl::add_component(ref sys.world, room_1_entity.inst);
        // sys.world.write_model(@hub_1);
        sys.designer.create_hub(array![hub_1.clone()]);
        // mint Trails
        let (entity_trail_1, mut trail_1, mut exit_1): (Entity, Trail, Exit) = _mint_trail(ref sys, OWNER());
        let (entity_trail_2, mut trail_2, mut exit_2): (Entity, Trail, Exit) = _mint_trail(ref sys, OWNER());
        // add trails to hub
        trail_1.hub_inst = hub_1.inst;
        trail_2.hub_inst = hub_1.inst;
        trail_1.is_published = true;
        trail_2.is_published = false;
        // sys.world.write_model(@trail_1);
        // sys.world.write_model(@trail_2);
        sys.designer.create_trail(array![trail_1.clone(), trail_2.clone()]);
        //
        // Create areas inside trails
        let (trail_1_area_entity, _trail_1_area): (Entity, Area) = helpers::create_area_entity(ref sys, "This is Trail 1", "TRAIL1", Option::Some(@entity_trail_1));
        let (trail_2_area_entity, _trail_2_area): (Entity, Area) = helpers::create_area_entity(ref sys, "This is Trail 2", "TRAIL2", Option::Some(@entity_trail_2));
        exit_1.leads_to = trail_1_area_entity.inst;
        exit_2.leads_to = trail_2_area_entity.inst;
        sys.world.write_model(@exit_1);
        sys.world.write_model(@exit_2);
        // create exits back to Hub
        let (_exit_1_entity, _exit_from_trail_1): (Entity, Exit) = helpers::create_exit_in_area(ref sys, "Exit From Trail 1", "trail_1_exit", @trail_1_area_entity, room_1_entity.inst);
        let (_exit_2_entity, _exit_from_trail_2): (Entity, Exit) = helpers::create_exit_in_area(ref sys, "Exit From Trail 2", "trail_2_exit", @trail_2_area_entity, room_1_entity.inst);
        //
        // list rooms (with trail)
        helpers::set_caller(helpers::PLAYER_1);
        sys.prompt.prompt("look around", Option::None); // will display the description
        sys.prompt.prompt("look around", Option::None); // willl display reactable.new_entry
// helpers::print_game_story_last_command(@sys.world, game_id, "look around (+trail_1)");
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "trail-1"); // last exit available
        //
        // enable Trail2 
        helpers::set_caller(helpers::OWNER());
        trail_2.is_published = true;
        sys.world.write_model(@trail_2);
        // list rooms (with trail)
        helpers::set_caller(helpers::PLAYER_1);
        sys.prompt.prompt("look around", Option::None); // will display the description
        sys.prompt.prompt("look around", Option::None); // willl display reactable.new_entry
// helpers::print_game_story_last_command(@sys.world, game_id, "look around (+trail_2)");
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "trail-2"); // last exit available

        //
        // move to trail 1...
        sys.prompt.prompt("use trail-1", Option::None);
// helpers::print_game_story_last_command(@sys.world, game_id, "use trail-1");
        // assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "trail-1", "use trail-1");
        sys.prompt.prompt("look around", Option::None); // willl display reactable.new_entry
// helpers::print_game_story_last_command(@sys.world, game_id, "look around (IN trail_1 AGAIN)");
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "trail_1_exit"); // last exit available

        //
        // move back to hub...
        sys.prompt.prompt("use trail_1_exit", Option::None);
// helpers::print_game_story_last_command(@sys.world, game_id, "use trail_1_exit");
        // assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "trail-1", "use trail-1");
        sys.prompt.prompt("look around", Option::None); // willl display reactable.new_entry
// helpers::print_game_story_last_command(@sys.world, game_id, "look around (trail_1_exit)");
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "trail-2"); // last exit available

        //
        // create a player's cont   ainer
        helpers::set_caller(helpers::OWNER());
        let player_entity: Entity = sys.world.read_model(player.inst);
        let _player_container: Container = ContainerComponent::add_component(ref sys.world, player_entity.inst);
        // list empty inventory
        helpers::set_caller(helpers::PLAYER_1);
        sys.prompt.prompt("inventory", Option::None);
// helpers::print_game_story_last_command(@sys.world, game_id, "inventory (EMPTY)");
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "It is empty.");
        //
        // Add something to the player's container
        helpers::set_caller(helpers::OWNER());
        let mut item1_entity: Entity = EntityImpl::create_entity(ref sys.world, "item-1");
        let mut _item1: InventoryItem = InventoryItemComponent::add_component(ref sys.world, item1_entity.inst);
        assert!(!item1_entity.has_parent(@sys.world, game_id), "!item1.has_parent");
        item1_entity.set_parent(ref sys.world, @player_entity, game_id);
        sys.world.write_model(@item1_entity);
        // list invetory
        helpers::set_caller(helpers::PLAYER_1);
        sys.prompt.prompt("inventory", Option::None);
// helpers::print_game_story_last_command(@sys.world, game_id, "inventory (hub)");
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "item-1"); // last item available

        //
        // move to trail 2...
        helpers::set_caller(helpers::PLAYER_1);
        sys.prompt.prompt("use trail-2", Option::None);
// helpers::print_game_story_last_command(@sys.world, game_id, "use trail-21");
        // assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "trail-1", "use trail-1");
        sys.prompt.prompt("look around", Option::None);
// helpers::print_game_story_last_command(@sys.world, game_id, "look around (IN trail_2 AGAIN)");
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "trail_2_exit"); // last exit available

        //
        // DROP something from the player's inventory
        sys.prompt.prompt("drop item-1", Option::None);
// helpers::print_game_story_last_command(@sys.world, game_id, "drop item-1");
        sys.prompt.prompt("inventory", Option::None);
// helpers::print_game_story_last_command(@sys.world, game_id, "inventory (dropped item-1)");
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "It is empty.");
        sys.prompt.prompt("look around", Option::None);
// helpers::print_game_story_last_command(@sys.world, game_id, "look around (dropped item-1)");

        //
        // exit trail 2...
        // TODO: implement [exit trail] command
//         sys.prompt.prompt("exit trail", Option::None);
// // helpers::print_game_story_last_command(@sys.world, game_id, "exit trail_2");
//         // assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "trail-1", "use trail-1");
//         sys.prompt.prompt("look around", Option::None); // willl display reactable.new_entry
// helpers::print_game_story_last_command(@sys.world, game_id, "look around (exit trail_2 AGAIN)");
//         assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "to_room_2"); // last exit available

    }
}
