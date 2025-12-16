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
    /// grants editor access by reaching an Area containing this Hub
    pub grants_editor_access: bool,
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
            grants_editor_access: true,
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
    // fn is_inside_trail(self: @WorldStorage, inst: felt252) -> bool {
    //     (self.get_entity_trail_id(inst).is_non_zero())
    // }
    // fn is_inside_trail_id(self: @WorldStorage, inst: felt252, trail_id: u128) -> bool {
    //     (self.get_entity_trail_id(inst) == trail_id)
    // }
    fn get_entity_trail_id(self: @WorldStorage, inst: felt252) -> u128 {
        (self.read_member(Model::<Entity>::ptr_from_keys(inst), selector!("trail_id")))
    }
    fn get_entities_trail_ids(self: @WorldStorage, insts: Span<felt252>) -> Array<u128> {
        (self.read_member_of_models(Model::<Entity>::ptrs_from_keys(insts), selector!("trail_id")))
    }

    // returns the corresponding trail_inst (top-level) from any Entity
    // can be zero if not in a specific trail
    fn get_entity_trail_inst(self: @WorldStorage, inst: felt252) -> felt252 {
        let trail_id: u128 = self.get_entity_trail_id(inst);
        if (trail_id.is_non_zero()) {
            let trail_info: TrailTokenInfo = self.read_model(trail_id);
            (trail_info.trail_inst)
        } else {
            (0)
        }
    }

    fn get_trail_entity(self: @WorldStorage, inst: felt252) -> Option<Entity> {
        let trail_inst: felt252 = self.get_entity_trail_inst(inst);
        if (trail_inst.is_non_zero()) {
            let trail_entity: Entity = self.read_model(trail_inst);
            (Option::Some(trail_entity))
        } else {
            return Option::None;
        }
    }
    fn get_trail_hub_entity(self: @WorldStorage, inst: felt252) -> Option<Entity> {
        let trail_inst: felt252 = self.get_entity_trail_inst(inst);
        if (trail_inst.is_non_zero()) {
            let hub_inst: felt252 = self.read_member(Model::<Trail>::ptr_from_keys(trail_inst), selector!("hub_inst"));
            let hub_entity: Entity = self.read_model(hub_inst);
            if (hub_entity.is_entity) {
                (Option::Some(hub_entity))
            } else {
                (Option::None)
            }
        } else {
            return Option::None;
        }
    }

    fn are_in_the_same_trail(self: @WorldStorage, inst_1: felt252, inst_2: felt252) -> bool {
        let trail_ids: Array<u128> = self.get_entities_trail_ids(array![inst_1, inst_2].span());
        (trail_ids[0] == trail_ids[1])
    }

    //
    // called when a new trail is minted
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
                (self.is_owner_of_trail(trail_id, owned))
            } else {
                // not in a trail
                (false)
            }
        } else {
            // new entity
            (true)
        }
    }

    fn is_owner_of_trail(self: @WorldStorage, trail_id: u128, owned: ContractAddress) -> bool {
        (self.trail_token_dispatcher().is_owner_of(owned, trail_id.into()))
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
