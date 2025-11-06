#[cfg(test)]
mod tests {
    // use starknet::ContractAddress;
    use dojo::{
        world::{WorldStorage},
        model::{ModelStorage},
    };
    use lore::{
        systems::{
            designer::{IDesignerDispatcherTrait},
            prompt::{IPromptDispatcherTrait},
        },
        models::{
            entity::{Entity, ParentToChildren, ChildToParent},
            area::{Area, AreaComponent},
            description_text::{DescriptionText},
            player::{PlayerImpl},
            hub::tests::{_mint_trail},
            hub::{Trail},
            exit::{Exit},
        },
        tests::{
            helpers,
            helpers::{OWNER, OTHER, RECIPIENT, ADMIN},
        },
        
        lib:: {
            access::{AccessTrait, ROLES},
        }
    };

    #[test]
    fn test_access_initialized() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        assert!(sys.world.is_player_admin(OWNER()));
        assert!(sys.world.is_player_editor(OWNER()));
        assert!(sys.world.is_player_admin(ADMIN()));
        assert!(sys.world.is_player_editor(ADMIN()));
        assert!(!sys.world.is_player_admin(OTHER()));
        assert!(!sys.world.is_player_editor(OTHER()));
        // also..
        assert!(sys.designer.is_admin(ADMIN()), "set_admin(OTHER)");
        assert!(sys.designer.is_editor(ADMIN()), "set_admin(OTHER)");
        assert!(sys.designer.has_role(ROLES::ADMIN, ADMIN()), "set_admin(OTHER)");
        assert!(sys.designer.has_role(ROLES::EDITOR, ADMIN()), "set_admin(OTHER)");
        // not for...
        assert!(!sys.world.is_player_admin(OTHER()));
        assert!(!sys.world.is_player_editor(OTHER()));
        assert!(!sys.designer.is_admin(OTHER()));
        assert!(!sys.designer.is_editor(OTHER()));
        assert!(!sys.designer.has_role(ROLES::ADMIN, OTHER()));
        assert!(!sys.designer.has_role(ROLES::EDITOR, OTHER()));
    }

    #[test]
    fn test_designer_permissions() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        //
        // deployer can design...
        helpers::set_caller(OWNER());
        sys.designer.create_entity(array![helpers::create_new_entity(1, "entity_1")]);
        let entity: Entity = sys.world.read_model(1);
        assert_eq!(entity.name, "entity_1");
        assert_eq!(entity.creator_address, OWNER());
        //
        // calldata admin can design...
        helpers::set_caller(ADMIN());
        sys.designer.create_entity(array![helpers::create_new_entity(2, "entity_2")]);
        let entity: Entity = sys.world.read_model(2);
        assert_eq!(entity.name, "entity_2");
        assert_eq!(entity.creator_address, ADMIN());
        //
        // another admin can design...
        sys.designer.set_admin(OTHER(), true);
        helpers::set_caller(OTHER());
        sys.designer.create_entity(array![helpers::create_new_entity(3, "entity_3")]);
        let entity: Entity = sys.world.read_model(3);
        assert_eq!(entity.name, "entity_3");
        assert_eq!(entity.creator_address, OTHER());
        //
        // another editor can design...
        sys.designer.set_editor(RECIPIENT(), true);
        assert!(sys.world.is_player_editor(RECIPIENT()), "editor RECIPIENT");
        helpers::set_caller(RECIPIENT());
        sys.designer.create_entity(array![helpers::create_new_entity(4, "entity_4")]);
        let entity: Entity = sys.world.read_model(4);
        assert_eq!(entity.name, "entity_4");
        assert_eq!(entity.creator_address, RECIPIENT());
    }

    #[test]
    #[should_panic(expected: ('DESIGNER: Not admin','ENTRYPOINT_FAILED'))]
    fn test_designer_not_editor() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        // this is not an editor or admin
        helpers::set_caller(OTHER());
        sys.designer.register_property_registry(array![true]);
    }

    fn _get_entity(world: @WorldStorage, inst: felt252) -> Entity {
        world.read_model(inst)
    }
    fn _get_area(world: @WorldStorage, inst: felt252) -> Area {
        world.read_model(inst)
    }
    fn _get_description_text(world: @WorldStorage, inst: felt252, key: felt252) -> DescriptionText {
        world.read_model((inst, key),)
    }

    #[test]
    fn test_create_delete_components() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        //
        // deployer can create...
        let mut entity_1: Entity = helpers::create_new_entity(1, "entity_1");
        let mut entity_2: Entity = helpers::create_new_entity(2, "entity_2");
        sys.designer.create_entity(array![entity_1.clone(), entity_2.clone()]);
        assert!(_get_entity(@sys.world, entity_1.inst).is_entity, "entity_1 created");
        assert!(_get_entity(@sys.world, entity_2.inst).is_entity, "entity_2 created");
        assert_eq!(_get_entity(@sys.world, entity_1.inst).creator_address, OWNER(), "entity_1 creator");
        assert_eq!(_get_entity(@sys.world, entity_2.inst).creator_address, OWNER(), "entity_2 creator");
        //
        // create components
        let mut area_1: Area = Area {
            inst: entity_1.inst,
            is_area: true,
            is_spawn_point: false,
            preserve_children: false,
            progress_percentage: 10,
        };
        let mut area_2: Area = Area {
            inst: entity_2.inst,
            is_area: true,
            is_spawn_point: false,
            preserve_children: false,
            progress_percentage: 20,
        };
        sys.designer.create_area(array![area_1.clone(), area_2.clone()]);
        assert!(_get_area(@sys.world, entity_1.inst).is_area, "area_1 created");
        assert!(_get_area(@sys.world, entity_1.inst).is_area, "area_2 created");
        assert_eq!(_get_area(@sys.world, entity_1.inst).progress_percentage, 10, "area_1 progress");
        assert_eq!(_get_area(@sys.world, entity_2.inst).progress_percentage, 20, "area_2 progress");
        //
        // create keyed components
        let mut desc_1_1: DescriptionText = DescriptionText{ inst: entity_1.inst, key: 1, text: "desc_1_1" };
        let mut desc_1_2: DescriptionText = DescriptionText{ inst: entity_1.inst, key: 2, text: "desc_1_2" };
        let mut desc_2_1: DescriptionText = DescriptionText{ inst: entity_2.inst, key: 1, text: "desc_2_1" };
        let mut desc_2_2: DescriptionText = DescriptionText{ inst: entity_2.inst, key: 2, text: "desc_2_2" };
        sys.designer.create_description_text(array![desc_1_1.clone(), desc_1_2.clone(), desc_2_1.clone(), desc_2_2.clone()]);
        assert_eq!(_get_description_text(@sys.world, entity_1.inst, 1).text, "desc_1_1", "text_1 created");
        assert_eq!(_get_description_text(@sys.world, entity_1.inst, 2).text, "desc_1_2", "text_2 created");
        assert_eq!(_get_description_text(@sys.world, entity_2.inst, 1).text, "desc_2_1", "text_3 created");
        assert_eq!(_get_description_text(@sys.world, entity_2.inst, 2).text, "desc_2_2", "text_4 created");
        //
        // deployer can edit...
        entity_1.name = "entity_1_edited";
        entity_2.name = "entity_2_edited";
        area_1.progress_percentage = 50;
        area_2.progress_percentage = 60;
        desc_1_1.text = "desc_1_1_edited";
        desc_1_2.text = "desc_1_2_edited";
        desc_2_1.text = "desc_2_1_edited";
        desc_2_2.text = "desc_2_2_edited";
        sys.designer.create_entity(array![entity_1.clone(), entity_2.clone()]);
        sys.designer.create_area(array![area_1.clone(), area_2.clone()]);
        sys.designer.create_description_text(array![desc_1_1.clone(), desc_1_2.clone(), desc_2_1.clone(), desc_2_2.clone()]);
        assert_eq!(_get_entity(@sys.world, entity_1.inst).name, "entity_1_edited", "entity_1 edited");
        assert_eq!(_get_entity(@sys.world, entity_2.inst).name, "entity_2_edited", "entity_2 edited");
        assert_eq!(_get_entity(@sys.world, entity_1.inst).creator_address, OWNER(), "entity_1 creator");
        assert_eq!(_get_entity(@sys.world, entity_2.inst).creator_address, OWNER(), "entity_2 creator");
        assert_eq!(_get_area(@sys.world, entity_1.inst).progress_percentage, 50, "area_1 edited");
        assert_eq!(_get_area(@sys.world, entity_2.inst).progress_percentage, 60, "area_2 edited");
        assert_eq!(_get_description_text(@sys.world, entity_1.inst, 1).text, "desc_1_1_edited", "text_1 edited");
        assert_eq!(_get_description_text(@sys.world, entity_1.inst, 2).text, "desc_1_2_edited", "text_2 edited");
        assert_eq!(_get_description_text(@sys.world, entity_2.inst, 1).text, "desc_2_1_edited", "text_3 edited");
        assert_eq!(_get_description_text(@sys.world, entity_2.inst, 2).text, "desc_2_2_edited", "text_4 edited");
        //
        // deployer can delete...
        sys.designer.delete_description_text(array![(entity_1.inst, 1), (entity_1.inst, 2), (entity_2.inst, 1), (entity_2.inst, 2)]);
        assert_eq!(_get_description_text(@sys.world, entity_1.inst, 1).text, "", "text_1 deleted");
        assert_eq!(_get_description_text(@sys.world, entity_1.inst, 2).text, "", "text_2 deleted");
        assert_eq!(_get_description_text(@sys.world, entity_2.inst, 1).text, "", "text_3 deleted");
        assert_eq!(_get_description_text(@sys.world, entity_2.inst, 2).text, "", "text_4 deleted");
        sys.designer.delete_area(array![entity_1.inst, entity_2.inst]);
        assert!(!_get_area(@sys.world, entity_1.inst).is_area, "area_1 deleted");
        assert!(!_get_area(@sys.world, entity_2.inst).is_area, "area_2 deleted");
        sys.designer.delete_entity(array![entity_1.inst, entity_2.inst]);
        assert!(!_get_entity(@sys.world, entity_1.inst).is_entity, "entity_1 deleted");
        assert!(!_get_entity(@sys.world, entity_2.inst).is_entity, "entity_2 deleted");
    }

    #[test]
    fn test_editor_create_delete_components() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        // mint a trail to an editor
        sys.designer.set_editor(OTHER(), true);
        helpers::set_caller(OTHER());
        let (_entity_trail_1, _trail_1, _exit_1): (Entity, Trail, Exit) = _mint_trail(ref sys, OTHER());
        let trail_id: u128 = _trail_1.trail_id;
        //
        // EDITOR can create in their trails...
        let mut entity_1: Entity = helpers::create_new_entity(100, "entity_1");
        let mut entity_2: Entity = helpers::create_new_entity(101, "entity_2");
        entity_1.trail_id = trail_id;
        entity_2.trail_id = trail_id;
        sys.designer.create_entity(array![entity_1.clone(), entity_2.clone()]);
        assert!(_get_entity(@sys.world, entity_1.inst).is_entity, "entity_1 created");
        assert!(_get_entity(@sys.world, entity_2.inst).is_entity, "entity_2 created");
        assert_eq!(_get_entity(@sys.world, entity_1.inst).creator_address, OTHER(), "entity_1 creator");
        assert_eq!(_get_entity(@sys.world, entity_2.inst).creator_address, OTHER(), "entity_2 creator");
        //
        // create components
        let mut area_1: Area = Area {
            inst: entity_1.inst,
            is_area: true,
            is_spawn_point: false,
            preserve_children: false,
            progress_percentage: 10,
        };
        let mut area_2: Area = Area {
            inst: entity_2.inst,
            is_area: true,
            is_spawn_point: false,
            preserve_children: false,
            progress_percentage: 20,
        };
        sys.designer.create_area(array![area_1.clone(), area_2.clone()]);
        assert!(_get_area(@sys.world, entity_1.inst).is_area, "area_1 created");
        assert!(_get_area(@sys.world, entity_1.inst).is_area, "area_2 created");
        assert_eq!(_get_area(@sys.world, entity_1.inst).progress_percentage, 10, "area_1 progress");
        assert_eq!(_get_area(@sys.world, entity_2.inst).progress_percentage, 20, "area_2 progress");
        //
        // create keyed components
        let mut desc_1_1: DescriptionText = DescriptionText{ inst: entity_1.inst, key: 1, text: "desc_1_1" };
        let mut desc_1_2: DescriptionText = DescriptionText{ inst: entity_1.inst, key: 2, text: "desc_1_2" };
        let mut desc_2_1: DescriptionText = DescriptionText{ inst: entity_2.inst, key: 1, text: "desc_2_1" };
        let mut desc_2_2: DescriptionText = DescriptionText{ inst: entity_2.inst, key: 2, text: "desc_2_2" };
        sys.designer.create_description_text(array![desc_1_1.clone(), desc_1_2.clone(), desc_2_1.clone(), desc_2_2.clone()]);
        assert_eq!(_get_description_text(@sys.world, entity_1.inst, 1).text, "desc_1_1", "text_1 created");
        assert_eq!(_get_description_text(@sys.world, entity_1.inst, 2).text, "desc_1_2", "text_2 created");
        assert_eq!(_get_description_text(@sys.world, entity_2.inst, 1).text, "desc_2_1", "text_3 created");
        assert_eq!(_get_description_text(@sys.world, entity_2.inst, 2).text, "desc_2_2", "text_4 created");
        //
        // EDITOR can edit...
        entity_1.name = "entity_1_edited";
        entity_2.name = "entity_2_edited";
        area_1.progress_percentage = 50;
        area_2.progress_percentage = 60;
        desc_1_1.text = "desc_1_1_edited";
        desc_1_2.text = "desc_1_2_edited";
        desc_2_1.text = "desc_2_1_edited";
        desc_2_2.text = "desc_2_2_edited";
        sys.designer.create_entity(array![entity_1.clone(), entity_2.clone()]);
        sys.designer.create_area(array![area_1.clone(), area_2.clone()]);
        sys.designer.create_description_text(array![desc_1_1.clone(), desc_1_2.clone(), desc_2_1.clone(), desc_2_2.clone()]);
        assert_eq!(_get_entity(@sys.world, entity_1.inst).name, "entity_1_edited", "entity_1 edited");
        assert_eq!(_get_entity(@sys.world, entity_2.inst).name, "entity_2_edited", "entity_2 edited");
        assert_eq!(_get_entity(@sys.world, entity_1.inst).creator_address, OTHER(), "entity_1 edited");
        assert_eq!(_get_entity(@sys.world, entity_2.inst).creator_address, OTHER(), "entity_2 edited");
        assert_eq!(_get_area(@sys.world, entity_1.inst).progress_percentage, 50, "area_1 edited");
        assert_eq!(_get_area(@sys.world, entity_2.inst).progress_percentage, 60, "area_2 edited");
        assert_eq!(_get_description_text(@sys.world, entity_1.inst, 1).text, "desc_1_1_edited", "text_1 edited");
        assert_eq!(_get_description_text(@sys.world, entity_1.inst, 2).text, "desc_1_2_edited", "text_2 edited");
        assert_eq!(_get_description_text(@sys.world, entity_2.inst, 1).text, "desc_2_1_edited", "text_3 edited");
        assert_eq!(_get_description_text(@sys.world, entity_2.inst, 2).text, "desc_2_2_edited", "text_4 edited");
        //
        // EDITOR can delete...
        sys.designer.delete_description_text(array![(entity_1.inst, 1), (entity_1.inst, 2), (entity_2.inst, 1), (entity_2.inst, 2)]);
        assert_eq!(_get_description_text(@sys.world, entity_1.inst, 1).text, "", "text_1 deleted");
        assert_eq!(_get_description_text(@sys.world, entity_1.inst, 2).text, "", "text_2 deleted");
        assert_eq!(_get_description_text(@sys.world, entity_2.inst, 1).text, "", "text_3 deleted");
        assert_eq!(_get_description_text(@sys.world, entity_2.inst, 2).text, "", "text_4 deleted");
        sys.designer.delete_area(array![entity_1.inst, entity_2.inst]);
        assert!(!_get_area(@sys.world, entity_1.inst).is_area, "area_1 deleted");
        assert!(!_get_area(@sys.world, entity_2.inst).is_area, "area_2 deleted");
        sys.designer.delete_entity(array![entity_1.inst, entity_2.inst]);
        assert!(!_get_entity(@sys.world, entity_1.inst).is_entity, "entity_1 deleted");
        assert!(!_get_entity(@sys.world, entity_2.inst).is_entity, "entity_2 deleted");
    }

    #[test]
    fn test_editor_create_delete_components_admin_too() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        // mint a trail to an editor
        sys.designer.set_editor(OTHER(), true);
        let (entity_trail_1, trail_1, _exit_1): (Entity, Trail, Exit) = _mint_trail(ref sys, OTHER());
        let trail_id: u128 = trail_1.trail_id;
        //
        // EDITOR can create in their trails...
        helpers::set_caller(OTHER());
        let mut entity_1: Entity = helpers::create_new_entity(100, "entity_1");
        entity_1.trail_id = trail_id;
        sys.designer.create_entity(array![entity_1.clone()]);
        assert!(_get_entity(@sys.world, entity_1.inst).is_entity, "entity_1 created");
        assert_eq!(_get_entity(@sys.world, entity_1.inst).creator_address, OTHER(), "entity_1 creator");
        //
        // make it child of trail
        let mut parent_1: ParentToChildren = ParentToChildren {
            inst: entity_trail_1.inst,
            is_parent: true,
            children: array![entity_1.inst],
        };
        let mut child_1: ChildToParent = ChildToParent {
            inst: entity_1.inst,
            parent: entity_trail_1.inst,
            is_child: true,
        };
        sys.designer.create_parent(array![parent_1.clone()]);
        sys.designer.create_child(array![child_1.clone()]);
        //
        // create components
        let mut area_1: Area = Area {
            inst: entity_1.inst,
            is_area: true,
            is_spawn_point: false,
            preserve_children: false,
            progress_percentage: 10,
        };
        sys.designer.create_area(array![area_1.clone()]);
        assert!(_get_area(@sys.world, entity_1.inst).is_area, "area_1 created");
        assert_eq!(_get_area(@sys.world, entity_1.inst).progress_percentage, 10, "area_1 progress");
        //
        // create keyed components
        let mut desc_1_1: DescriptionText = DescriptionText{ inst: entity_1.inst, key: 1, text: "desc_1_1" };
        let mut desc_1_2: DescriptionText = DescriptionText{ inst: entity_1.inst, key: 2, text: "desc_1_2" };
        sys.designer.create_description_text(array![desc_1_1.clone(), desc_1_2.clone()]);
        assert_eq!(_get_description_text(@sys.world, entity_1.inst, 1).text, "desc_1_1", "text_1 created");
        assert_eq!(_get_description_text(@sys.world, entity_1.inst, 2).text, "desc_1_2", "text_2 created");
        //
        // ADMIN can edit...
        helpers::set_caller(ADMIN());
        entity_1.name = "entity_1_edited";
        area_1.progress_percentage = 50;
        desc_1_1.text = "desc_1_1_edited";
        desc_1_2.text = "desc_1_2_edited";
        sys.designer.create_entity(array![entity_1.clone()]);
        sys.designer.create_area(array![area_1.clone()]);
        sys.designer.create_description_text(array![desc_1_1.clone(), desc_1_2.clone()]);
        assert_eq!(_get_entity(@sys.world, entity_1.inst).creator_address, OTHER(), "entity_1 edited");
        assert_eq!(_get_entity(@sys.world, entity_1.inst).name, "entity_1_edited", "entity_1 edited");
        assert_eq!(_get_area(@sys.world, entity_1.inst).progress_percentage, 50, "area_1 edited");
        assert_eq!(_get_description_text(@sys.world, entity_1.inst, 1).text, "desc_1_1_edited", "text_1 edited");
        assert_eq!(_get_description_text(@sys.world, entity_1.inst, 2).text, "desc_1_2_edited", "text_2 edited");
        //
        // ADMIN can delete...
        sys.designer.delete_description_text(array![(entity_1.inst, 1), (entity_1.inst, 2)]);
        assert_eq!(_get_description_text(@sys.world, entity_1.inst, 1).text, "", "text_1 deleted");
        assert_eq!(_get_description_text(@sys.world, entity_1.inst, 2).text, "", "text_2 deleted");
        sys.designer.delete_area(array![entity_1.inst]);
        assert!(!_get_area(@sys.world, entity_1.inst).is_area, "area_1 deleted");
        sys.designer.delete_entity(array![entity_1.inst]);
        assert!(!_get_entity(@sys.world, entity_1.inst).is_entity, "entity_1 deleted");
    }

    #[test]
    #[should_panic(expected: ('DESIGNER: Not your entity','ENTRYPOINT_FAILED'))]
    fn test_editor_create_invalid_trail() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        // mint a trail
        sys.designer.set_editor(OTHER(), true);
        let (_entity_trail_1, _trail_1, _exit_1): (Entity, Trail, Exit) = _mint_trail(ref sys, OTHER());
        //
        // EDITOR can create in their trails...
        helpers::set_caller(OTHER());
        let mut entity_1: Entity = helpers::create_new_entity(1, "entity_1");
        entity_1.trail_id = 123;
        sys.designer.create_entity(array![entity_1.clone()]);
    }



    //--------------------------------
    // Admin functions
    //

    #[test]
    fn test_set_admin_editor() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        // OWNER set admin to OTHER
        helpers::set_caller(OWNER());
        sys.designer.set_admin(OTHER(), true);
        assert!(sys.world.is_player_admin(OTHER()), "set_admin(OTHER)");
        assert!(sys.world.is_player_editor(OTHER()), "set_admin(OTHER)");
        assert!(sys.designer.is_admin(OTHER()), "set_admin(OTHER)");
        assert!(sys.designer.is_editor(OTHER()), "set_admin(OTHER)");
        assert!(sys.designer.has_role(ROLES::ADMIN, OTHER()), "set_admin(OTHER)");
        assert!(sys.designer.has_role(ROLES::EDITOR, OTHER()), "set_admin(OTHER)");
        // OTHER set admin to RECIPIENT
        helpers::set_caller(OTHER());
        sys.designer.set_admin(RECIPIENT(), true);
        assert!(sys.world.is_player_admin(RECIPIENT()), "set_admin(RECIPIENT)");
        assert!(sys.world.is_player_editor(RECIPIENT()), "editor RECIPIENT 1");
        // OTHER set editor to RECIPIENT
        helpers::set_caller(OTHER());
        sys.designer.set_editor(RECIPIENT(), true);
        assert!(sys.world.is_player_admin(RECIPIENT()), "admin RECIPIENT 2");
        assert!(sys.world.is_player_editor(RECIPIENT()), "editor RECIPIENT 2");
        // OTHER set editor to RECIPIENT
        helpers::set_caller(OTHER());
        sys.designer.set_admin(RECIPIENT(), false);
        assert!(!sys.world.is_player_admin(RECIPIENT()), "admin RECIPIENT 3");
        assert!(sys.world.is_player_editor(RECIPIENT()), "editor RECIPIENT 3");
        // OTHER set editor to RECIPIENT
        helpers::set_caller(OTHER());
        sys.designer.set_editor(RECIPIENT(), false);
        assert!(!sys.world.is_player_admin(RECIPIENT()), "admin RECIPIENT 4");
        assert!(!sys.world.is_player_editor(RECIPIENT()), "editor RECIPIENT 4");
    }

    #[test]
    fn test_prompt_game_zero_new_admin() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        // initialize player singleton
        PlayerImpl::caller_as_player(ref sys.world, OWNER(), 0);
        //
        // create new editor
        helpers::set_caller(OWNER());
        sys.designer.set_admin(OTHER(), true);
        //
        // player_1 say something...
        helpers::set_caller(OTHER());
        sys.prompt.prompt("hello", Option::Some(0));
    }

    #[test]
    #[should_panic(expected: ('DESIGNER: Not admin','ENTRYPOINT_FAILED'))]
    fn test_other_set_admin_not_admin() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        helpers::set_caller(OTHER());
        sys.designer.set_admin(OTHER(), true);
    }
    #[test]
    #[should_panic(expected: ('DESIGNER: Not admin','ENTRYPOINT_FAILED'))]
    fn test_editor_set_admin_not_admin() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        sys.designer.set_editor(OTHER(), true);
        helpers::set_caller(OTHER());
        sys.designer.set_admin(OTHER(), true);
    }

    #[test]
    #[should_panic(expected: ('DESIGNER: Not admin','ENTRYPOINT_FAILED'))]
    fn test_other_set_editor_not_admin() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        helpers::set_caller(OTHER());
        sys.designer.set_editor(OTHER(), true);
    }
    #[test]
    #[should_panic(expected: ('DESIGNER: Not admin','ENTRYPOINT_FAILED'))]
    fn test_set_editor_not_admin() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        sys.designer.set_editor(OTHER(), true);
        helpers::set_caller(OTHER());
        sys.designer.set_editor(OTHER(), true);
    }


    //--------------------------------
    // Other/Editors > core > panic
    //

    #[test]
    #[should_panic(expected: ('DESIGNER: Not editor','ENTRYPOINT_FAILED'))]
    fn test_other_not_allowed_to_edit_core_entity() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        //
        // create...
        helpers::set_caller(OWNER());
        let mut entity_1: Entity = helpers::create_new_entity(1, "entity_1");
        sys.designer.create_entity(array![entity_1.clone()]);
        //
        // fail...
        helpers::set_caller(OTHER());
        sys.designer.create_entity(array![entity_1.clone()]);
    }
    #[test]
    #[should_panic(expected: ('DESIGNER: Not your entity','ENTRYPOINT_FAILED'))]
    fn test_editor_not_allowed_to_edit_core_entity() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        //
        // create...
        helpers::set_caller(OWNER());
        let mut entity_1: Entity = helpers::create_new_entity(1, "entity_1");
        sys.designer.create_entity(array![entity_1.clone()]);
        //
        // fail...
        sys.designer.set_editor(OTHER(), true);
        helpers::set_caller(OTHER());
        sys.designer.create_entity(array![entity_1.clone()]);
    }

    #[test]
    #[should_panic(expected: ('DESIGNER: Not editor','ENTRYPOINT_FAILED'))]
    fn test_other_not_allowed_to_edit_core_component() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        //
        // create...
        helpers::set_caller(OWNER());
        let mut entity_1: Entity = helpers::create_new_entity(1, "entity_1");
        sys.designer.create_entity(array![entity_1.clone()]);
        let mut area_1: Area = Area {
            inst: entity_1.inst,
            is_area: true,
            is_spawn_point: false,
            preserve_children: false,
            progress_percentage: 10,
        };
        sys.designer.create_area(array![area_1.clone()]);
        //
        // fail...
        helpers::set_caller(OTHER());
        sys.designer.create_area(array![area_1.clone()]);
    }
    #[test]
    #[should_panic(expected: ('DESIGNER: Not your entity','ENTRYPOINT_FAILED'))]
    fn test_editor_not_allowed_to_edit_core_component() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        //
        // create...
        helpers::set_caller(OWNER());
        let mut entity_1: Entity = helpers::create_new_entity(1, "entity_1");
        sys.designer.create_entity(array![entity_1.clone()]);
        let mut area_1: Area = Area {
            inst: entity_1.inst,
            is_area: true,
            is_spawn_point: false,
            preserve_children: false,
            progress_percentage: 10,
        };
        sys.designer.create_area(array![area_1.clone()]);
        //
        // fail...
        sys.designer.set_editor(OTHER(), true);
        helpers::set_caller(OTHER());
        sys.designer.create_area(array![area_1.clone()]);
    }

    #[test]
    #[should_panic(expected: ('DESIGNER: Not editor','ENTRYPOINT_FAILED'))]
    fn test_other_not_allowed_to_edit_core_keyed() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        //
        // create...
        helpers::set_caller(OWNER());
        let mut entity_1: Entity = helpers::create_new_entity(1, "entity_1");
        sys.designer.create_entity(array![entity_1.clone()]);
        let mut desc_1_1: DescriptionText = DescriptionText{ inst: entity_1.inst, key: 1, text: "desc_1_1" };
        sys.designer.create_description_text(array![desc_1_1.clone()]);
        //
        // fail...
        helpers::set_caller(OTHER());
        sys.designer.create_description_text(array![desc_1_1.clone()]);
    }
    #[test]
    #[should_panic(expected: ('DESIGNER: Not your entity','ENTRYPOINT_FAILED'))]
    fn test_editor_not_allowed_to_edit_core_keyed() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        //
        // create...
        helpers::set_caller(OWNER());
        let mut entity_1: Entity = helpers::create_new_entity(1, "entity_1");
        sys.designer.create_entity(array![entity_1.clone()]);
        let mut desc_1_1: DescriptionText = DescriptionText{ inst: entity_1.inst, key: 1, text: "desc_1_1" };
        sys.designer.create_description_text(array![desc_1_1.clone()]);
        //
        // fail...
        sys.designer.set_editor(OTHER(), true);
        helpers::set_caller(OTHER());
        sys.designer.create_description_text(array![desc_1_1.clone()]);
    }

    #[test]
    #[should_panic(expected: ('DESIGNER: Not editor','ENTRYPOINT_FAILED'))]
    fn test_other_not_allowed_to_delete_core_entity() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        //
        // create...
        helpers::set_caller(OWNER());
        let mut entity_1: Entity = helpers::create_new_entity(1, "entity_1");
        sys.designer.create_entity(array![entity_1.clone()]);
        //
        // fail...
        helpers::set_caller(OTHER());
        sys.designer.delete_entity(array![entity_1.inst]);
    }
    #[test]
    #[should_panic(expected: ('DESIGNER: Not your entity','ENTRYPOINT_FAILED'))]
    fn test_editor_not_allowed_to_delete_core_entity() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        //
        // create...
        helpers::set_caller(OWNER());
        let mut entity_1: Entity = helpers::create_new_entity(1, "entity_1");
        sys.designer.create_entity(array![entity_1.clone()]);
        //
        // fail...
        sys.designer.set_editor(OTHER(), true);
        helpers::set_caller(OTHER());
        sys.designer.delete_entity(array![entity_1.inst]);
    }

    #[test]
    #[should_panic(expected: ('DESIGNER: Not editor','ENTRYPOINT_FAILED'))]
    fn test_other_not_allowed_to_delete_core_component() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        //
        // create...
        helpers::set_caller(OWNER());
        let mut entity_1: Entity = helpers::create_new_entity(1, "entity_1");
        sys.designer.create_entity(array![entity_1.clone()]);
        let mut area_1: Area = Area {
            inst: entity_1.inst,
            is_area: true,
            is_spawn_point: false,
            preserve_children: false,
            progress_percentage: 10,
        };
        sys.designer.create_area(array![area_1.clone()]);
        //
        // fail...
        helpers::set_caller(OTHER());
        sys.designer.delete_area(array![area_1.inst]);
    }
    #[test]
    #[should_panic(expected: ('DESIGNER: Not your entity','ENTRYPOINT_FAILED'))]
    fn test_editor_not_allowed_to_delete_core_component() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        //
        // create...
        helpers::set_caller(OWNER());
        let mut entity_1: Entity = helpers::create_new_entity(1, "entity_1");
        sys.designer.create_entity(array![entity_1.clone()]);
        let mut area_1: Area = Area {
            inst: entity_1.inst,
            is_area: true,
            is_spawn_point: false,
            preserve_children: false,
            progress_percentage: 10,
        };
        sys.designer.create_area(array![area_1.clone()]);
        //
        // fail...
        sys.designer.set_editor(OTHER(), true);
        helpers::set_caller(OTHER());
        sys.designer.delete_area(array![area_1.inst]);
    }

    #[test]
    #[should_panic(expected: ('DESIGNER: Not editor','ENTRYPOINT_FAILED'))]
    fn test_other_not_allowed_to_delete_core_keyed() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        //
        // create...
        helpers::set_caller(OWNER());
        let mut entity_1: Entity = helpers::create_new_entity(1, "entity_1");
        sys.designer.create_entity(array![entity_1.clone()]);
        let mut desc_1_1: DescriptionText = DescriptionText{ inst: entity_1.inst, key: 1, text: "desc_1_1" };
        sys.designer.create_description_text(array![desc_1_1.clone()]);
        //
        // fail...
        helpers::set_caller(OTHER());
        sys.designer.delete_description_text(array![(desc_1_1.inst, 1)]);
    }
    #[test]
    #[should_panic(expected: ('DESIGNER: Not your entity','ENTRYPOINT_FAILED'))]
    fn test_editor_not_allowed_to_delete_core_keyed() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        //
        // create...
        helpers::set_caller(OWNER());
        let mut entity_1: Entity = helpers::create_new_entity(1, "entity_1");
        sys.designer.create_entity(array![entity_1.clone()]);
        let mut desc_1_1: DescriptionText = DescriptionText{ inst: entity_1.inst, key: 1, text: "desc_1_1" };
        sys.designer.create_description_text(array![desc_1_1.clone()]);
        //
        // fail...
        sys.designer.set_editor(OTHER(), true);
        helpers::set_caller(OTHER());
        sys.designer.delete_description_text(array![(desc_1_1.inst, 1)]);
    }

}
