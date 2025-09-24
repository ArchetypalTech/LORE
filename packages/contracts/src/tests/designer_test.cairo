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
            game_token::{IGameTokenDispatcherTrait},
        },
        models::{
            entity::{Entity},
            admin::{AccountPermissionsTrait},
            area::{Area, AreaComponent},
            index::{DescriptionText},
        },
        tests::{
            helpers,
            helpers::{OWNER, OTHER, RECIPIENT, ADMIN},
        },
    };

    #[test]
    fn test_designer_permissions() {
        let (world, designer, _, token, _, _) = helpers::setup_core();
        //
        // deployer can design...
        helpers::set_caller(OWNER());
        designer.register_property_registry(array![true]);
        designer.create_entity(array![helpers::create_new_entity(1, "entity_1")]);
        let entity: Entity = world.read_model(1);
        assert_eq!(entity.name, "entity_1");
        assert_eq!(entity.creator_address, OWNER());
        //
        // calldata admin can design...
        helpers::set_caller(ADMIN());
        designer.create_entity(array![helpers::create_new_entity(2, "entity_2")]);
        let entity: Entity = world.read_model(2);
        assert_eq!(entity.name, "entity_2");
        assert_eq!(entity.creator_address, ADMIN());
        //
        // another admin can design...
        token.set_admin(OTHER(), true);
        helpers::set_caller(OTHER());
        designer.create_entity(array![helpers::create_new_entity(3, "entity_3")]);
        let entity: Entity = world.read_model(3);
        assert_eq!(entity.name, "entity_3");
        assert_eq!(entity.creator_address, OTHER());
        //
        // another editor can design...
        token.set_editor(RECIPIENT(), true);
        assert!(AccountPermissionsTrait::is_editor(@world, RECIPIENT()), "editor RECIPIENT");
        helpers::set_caller(RECIPIENT());
        designer.create_entity(array![helpers::create_new_entity(4, "entity_4")]);
        let entity: Entity = world.read_model(4);
        assert_eq!(entity.name, "entity_4");
        assert_eq!(entity.creator_address, RECIPIENT());
    }

    #[test]
    #[should_panic(expected: ('DESIGNER: Not editor','ENTRYPOINT_FAILED'))]
    fn test_designer_not_editor() {
        let (_, designer, _, _, _, _) = helpers::setup_core();
        // this is not an editor or admin
        helpers::set_caller(OTHER());
        designer.register_property_registry(array![true]);
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
        let (mut world, designer, _, _, _, _) = helpers::setup_core();
        designer.register_property_registry(array![true]);
        //
        // deployer can create...
        let mut entity_1 = helpers::create_new_entity(1, "entity_1");
        let mut entity_2 = helpers::create_new_entity(2, "entity_2");
        designer.create_entity(array![entity_1.clone(), entity_2.clone()]);
        assert!(_get_entity(@world, entity_1.inst).is_entity, "entity_1 created");
        assert!(_get_entity(@world, entity_2.inst).is_entity, "entity_2 created");
        assert_eq!(_get_entity(@world, entity_1.inst).creator_address, OWNER(), "entity_1 creator");
        assert_eq!(_get_entity(@world, entity_2.inst).creator_address, OWNER(), "entity_2 creator");
        //
        // create components
        let mut area_1: Area = Area {
            inst: entity_1.inst,
            is_area: true,
            is_spawn_point: false,
            progress_percentage: 10,
        };
        let mut area_2: Area = Area {
            inst: entity_2.inst,
            is_area: true,
            is_spawn_point: false,
            progress_percentage: 20,
        };
        designer.create_area(array![area_1.clone(), area_2.clone()]);
        assert!(_get_area(@world, entity_1.inst).is_area, "area_1 created");
        assert!(_get_area(@world, entity_1.inst).is_area, "area_2 created");
        assert_eq!(_get_area(@world, entity_1.inst).progress_percentage, 10, "area_1 progress");
        assert_eq!(_get_area(@world, entity_2.inst).progress_percentage, 20, "area_2 progress");
        //
        // create keyed components
        let mut desc_1_1: DescriptionText = DescriptionText{ inst: entity_1.inst, key: 1, text: "desc_1_1" };
        let mut desc_1_2: DescriptionText = DescriptionText{ inst: entity_1.inst, key: 2, text: "desc_1_2" };
        let mut desc_2_1: DescriptionText = DescriptionText{ inst: entity_2.inst, key: 1, text: "desc_2_1" };
        let mut desc_2_2: DescriptionText = DescriptionText{ inst: entity_2.inst, key: 2, text: "desc_2_2" };
        designer.create_description_text(array![desc_1_1.clone(), desc_1_2.clone(), desc_2_1.clone(), desc_2_2.clone()]);
        assert_eq!(_get_description_text(@world, entity_1.inst, 1).text, "desc_1_1", "text_1 created");
        assert_eq!(_get_description_text(@world, entity_1.inst, 2).text, "desc_1_2", "text_2 created");
        assert_eq!(_get_description_text(@world, entity_2.inst, 1).text, "desc_2_1", "text_3 created");
        assert_eq!(_get_description_text(@world, entity_2.inst, 2).text, "desc_2_2", "text_4 created");
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
        designer.create_entity(array![entity_1.clone(), entity_2.clone()]);
        designer.create_area(array![area_1.clone(), area_2.clone()]);
        designer.create_description_text(array![desc_1_1.clone(), desc_1_2.clone(), desc_2_1.clone(), desc_2_2.clone()]);
        assert_eq!(_get_entity(@world, entity_1.inst).name, "entity_1_edited", "entity_1 edited");
        assert_eq!(_get_entity(@world, entity_2.inst).name, "entity_2_edited", "entity_2 edited");
        assert_eq!(_get_entity(@world, entity_1.inst).creator_address, OWNER(), "entity_1 creator");
        assert_eq!(_get_entity(@world, entity_2.inst).creator_address, OWNER(), "entity_2 creator");
        assert_eq!(_get_area(@world, entity_1.inst).progress_percentage, 50, "area_1 edited");
        assert_eq!(_get_area(@world, entity_2.inst).progress_percentage, 60, "area_2 edited");
        assert_eq!(_get_description_text(@world, entity_1.inst, 1).text, "desc_1_1_edited", "text_1 edited");
        assert_eq!(_get_description_text(@world, entity_1.inst, 2).text, "desc_1_2_edited", "text_2 edited");
        assert_eq!(_get_description_text(@world, entity_2.inst, 1).text, "desc_2_1_edited", "text_3 edited");
        assert_eq!(_get_description_text(@world, entity_2.inst, 2).text, "desc_2_2_edited", "text_4 edited");
        //
        // deployer can delete...
        designer.delete_description_text(array![(entity_1.inst, 1), (entity_1.inst, 2), (entity_2.inst, 1), (entity_2.inst, 2)]);
        assert_eq!(_get_description_text(@world, entity_1.inst, 1).text, "", "text_1 deleted");
        assert_eq!(_get_description_text(@world, entity_1.inst, 2).text, "", "text_2 deleted");
        assert_eq!(_get_description_text(@world, entity_2.inst, 1).text, "", "text_3 deleted");
        assert_eq!(_get_description_text(@world, entity_2.inst, 2).text, "", "text_4 deleted");
        designer.delete_area(array![entity_1.inst, entity_2.inst]);
        assert!(!_get_area(@world, entity_1.inst).is_area, "area_1 deleted");
        assert!(!_get_area(@world, entity_2.inst).is_area, "area_2 deleted");
        designer.delete_entity(array![entity_1.inst, entity_2.inst]);
        assert!(!_get_entity(@world, entity_1.inst).is_entity, "entity_1 deleted");
        assert!(!_get_entity(@world, entity_2.inst).is_entity, "entity_2 deleted");
    }

    #[test]
    fn test_editor_create_delete_components() {
        let (mut world, designer, _, token, _, _) = helpers::setup_core();
        designer.register_property_registry(array![true]);
        token.set_editor(OTHER(), true);
        //
        // EDITOR can create...
        helpers::set_caller(OTHER());
        let mut entity_1 = helpers::create_new_entity(1, "entity_1");
        let mut entity_2 = helpers::create_new_entity(2, "entity_2");
        designer.create_entity(array![entity_1.clone(), entity_2.clone()]);
        assert!(_get_entity(@world, entity_1.inst).is_entity, "entity_1 created");
        assert!(_get_entity(@world, entity_2.inst).is_entity, "entity_2 created");
        assert_eq!(_get_entity(@world, entity_1.inst).creator_address, OTHER(), "entity_1 creator");
        assert_eq!(_get_entity(@world, entity_2.inst).creator_address, OTHER(), "entity_2 creator");
        //
        // create components
        let mut area_1: Area = Area {
            inst: entity_1.inst,
            is_area: true,
            is_spawn_point: false,
            progress_percentage: 10,
        };
        let mut area_2: Area = Area {
            inst: entity_2.inst,
            is_area: true,
            is_spawn_point: false,
            progress_percentage: 20,
        };
        designer.create_area(array![area_1.clone(), area_2.clone()]);
        assert!(_get_area(@world, entity_1.inst).is_area, "area_1 created");
        assert!(_get_area(@world, entity_1.inst).is_area, "area_2 created");
        assert_eq!(_get_area(@world, entity_1.inst).progress_percentage, 10, "area_1 progress");
        assert_eq!(_get_area(@world, entity_2.inst).progress_percentage, 20, "area_2 progress");
        //
        // create keyed components
        let mut desc_1_1: DescriptionText = DescriptionText{ inst: entity_1.inst, key: 1, text: "desc_1_1" };
        let mut desc_1_2: DescriptionText = DescriptionText{ inst: entity_1.inst, key: 2, text: "desc_1_2" };
        let mut desc_2_1: DescriptionText = DescriptionText{ inst: entity_2.inst, key: 1, text: "desc_2_1" };
        let mut desc_2_2: DescriptionText = DescriptionText{ inst: entity_2.inst, key: 2, text: "desc_2_2" };
        designer.create_description_text(array![desc_1_1.clone(), desc_1_2.clone(), desc_2_1.clone(), desc_2_2.clone()]);
        assert_eq!(_get_description_text(@world, entity_1.inst, 1).text, "desc_1_1", "text_1 created");
        assert_eq!(_get_description_text(@world, entity_1.inst, 2).text, "desc_1_2", "text_2 created");
        assert_eq!(_get_description_text(@world, entity_2.inst, 1).text, "desc_2_1", "text_3 created");
        assert_eq!(_get_description_text(@world, entity_2.inst, 2).text, "desc_2_2", "text_4 created");
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
        designer.create_entity(array![entity_1.clone(), entity_2.clone()]);
        designer.create_area(array![area_1.clone(), area_2.clone()]);
        designer.create_description_text(array![desc_1_1.clone(), desc_1_2.clone(), desc_2_1.clone(), desc_2_2.clone()]);
        assert_eq!(_get_entity(@world, entity_1.inst).name, "entity_1_edited", "entity_1 edited");
        assert_eq!(_get_entity(@world, entity_2.inst).name, "entity_2_edited", "entity_2 edited");
        assert_eq!(_get_entity(@world, entity_1.inst).creator_address, OTHER(), "entity_1 edited");
        assert_eq!(_get_entity(@world, entity_2.inst).creator_address, OTHER(), "entity_2 edited");
        assert_eq!(_get_area(@world, entity_1.inst).progress_percentage, 50, "area_1 edited");
        assert_eq!(_get_area(@world, entity_2.inst).progress_percentage, 60, "area_2 edited");
        assert_eq!(_get_description_text(@world, entity_1.inst, 1).text, "desc_1_1_edited", "text_1 edited");
        assert_eq!(_get_description_text(@world, entity_1.inst, 2).text, "desc_1_2_edited", "text_2 edited");
        assert_eq!(_get_description_text(@world, entity_2.inst, 1).text, "desc_2_1_edited", "text_3 edited");
        assert_eq!(_get_description_text(@world, entity_2.inst, 2).text, "desc_2_2_edited", "text_4 edited");
        //
        // EDITOR can delete...
        designer.delete_description_text(array![(entity_1.inst, 1), (entity_1.inst, 2), (entity_2.inst, 1), (entity_2.inst, 2)]);
        assert_eq!(_get_description_text(@world, entity_1.inst, 1).text, "", "text_1 deleted");
        assert_eq!(_get_description_text(@world, entity_1.inst, 2).text, "", "text_2 deleted");
        assert_eq!(_get_description_text(@world, entity_2.inst, 1).text, "", "text_3 deleted");
        assert_eq!(_get_description_text(@world, entity_2.inst, 2).text, "", "text_4 deleted");
        designer.delete_area(array![entity_1.inst, entity_2.inst]);
        assert!(!_get_area(@world, entity_1.inst).is_area, "area_1 deleted");
        assert!(!_get_area(@world, entity_2.inst).is_area, "area_2 deleted");
        designer.delete_entity(array![entity_1.inst, entity_2.inst]);
        assert!(!_get_entity(@world, entity_1.inst).is_entity, "entity_1 deleted");
        assert!(!_get_entity(@world, entity_2.inst).is_entity, "entity_2 deleted");
    }

    #[test]
    fn test_editor_create_delete_components_admin_too() {
        let (mut world, designer, _, token, _, _) = helpers::setup_core();
        designer.register_property_registry(array![true]);
        token.set_editor(OTHER(), true);
        //
        // EDITOR can create...
        helpers::set_caller(OTHER());
        let mut entity_1 = helpers::create_new_entity(1, "entity_1");
        designer.create_entity(array![entity_1.clone()]);
        assert!(_get_entity(@world, entity_1.inst).is_entity, "entity_1 created");
        assert_eq!(_get_entity(@world, entity_1.inst).creator_address, OTHER(), "entity_1 creator");
        //
        // create components
        let mut area_1: Area = Area {
            inst: entity_1.inst,
            is_area: true,
            is_spawn_point: false,
            progress_percentage: 10,
        };
        designer.create_area(array![area_1.clone()]);
        assert!(_get_area(@world, entity_1.inst).is_area, "area_1 created");
        assert_eq!(_get_area(@world, entity_1.inst).progress_percentage, 10, "area_1 progress");
        //
        // create keyed components
        let mut desc_1_1: DescriptionText = DescriptionText{ inst: entity_1.inst, key: 1, text: "desc_1_1" };
        let mut desc_1_2: DescriptionText = DescriptionText{ inst: entity_1.inst, key: 2, text: "desc_1_2" };
        designer.create_description_text(array![desc_1_1.clone(), desc_1_2.clone()]);
        assert_eq!(_get_description_text(@world, entity_1.inst, 1).text, "desc_1_1", "text_1 created");
        assert_eq!(_get_description_text(@world, entity_1.inst, 2).text, "desc_1_2", "text_2 created");
        //
        // ADMIN can edit...
        helpers::set_caller(ADMIN());
        entity_1.name = "entity_1_edited";
        area_1.progress_percentage = 50;
        desc_1_1.text = "desc_1_1_edited";
        desc_1_2.text = "desc_1_2_edited";
        designer.create_entity(array![entity_1.clone()]);
        designer.create_area(array![area_1.clone()]);
        designer.create_description_text(array![desc_1_1.clone(), desc_1_2.clone()]);
        assert_eq!(_get_entity(@world, entity_1.inst).creator_address, OTHER(), "entity_1 edited");
        assert_eq!(_get_entity(@world, entity_1.inst).name, "entity_1_edited", "entity_1 edited");
        assert_eq!(_get_area(@world, entity_1.inst).progress_percentage, 50, "area_1 edited");
        assert_eq!(_get_description_text(@world, entity_1.inst, 1).text, "desc_1_1_edited", "text_1 edited");
        assert_eq!(_get_description_text(@world, entity_1.inst, 2).text, "desc_1_2_edited", "text_2 edited");
        //
        // ADMIN can delete...
        designer.delete_description_text(array![(entity_1.inst, 1), (entity_1.inst, 2)]);
        assert_eq!(_get_description_text(@world, entity_1.inst, 1).text, "", "text_1 deleted");
        assert_eq!(_get_description_text(@world, entity_1.inst, 2).text, "", "text_2 deleted");
        designer.delete_area(array![entity_1.inst]);
        assert!(!_get_area(@world, entity_1.inst).is_area, "area_1 deleted");
        designer.delete_entity(array![entity_1.inst]);
        assert!(!_get_entity(@world, entity_1.inst).is_entity, "entity_1 deleted");
    }

    //--------------------------------
    // Other > core > panic
    //

    #[test]
    #[should_panic(expected: ('DESIGNER: Not your entity','ENTRYPOINT_FAILED'))]
    fn test_other_not_allowed_to_edit_core_entity() {
        let (mut _world, designer, _, _, _, _) = helpers::setup_core();
        designer.register_property_registry(array![true]);
        //
        // create...
        helpers::set_caller(OWNER());
        let mut entity_1 = helpers::create_new_entity(1, "entity_1");
        designer.create_entity(array![entity_1.clone()]);
        //
        // EDITOR fail...
        helpers::set_caller(OTHER());
        designer.create_entity(array![entity_1.clone()]);
    }

    #[test]
    #[should_panic(expected: ('DESIGNER: Not your entity','ENTRYPOINT_FAILED'))]
    fn test_other_not_allowed_to_edit_core_component() {
        let (mut _world, designer, _, _, _, _) = helpers::setup_core();
        designer.register_property_registry(array![true]);
        //
        // create...
        helpers::set_caller(OWNER());
        let mut entity_1 = helpers::create_new_entity(1, "entity_1");
        designer.create_entity(array![entity_1.clone()]);
        let mut area_1: Area = Area {
            inst: entity_1.inst,
            is_area: true,
            is_spawn_point: false,
            progress_percentage: 10,
        };
        designer.create_area(array![area_1.clone()]);
        //
        // EDITOR fail...
        helpers::set_caller(OTHER());
        designer.create_area(array![area_1.clone()]);
    }

    #[test]
    #[should_panic(expected: ('DESIGNER: Not your entity','ENTRYPOINT_FAILED'))]
    fn test_other_not_allowed_to_edit_core_keyed() {
        let (mut _world, designer, _, _, _, _) = helpers::setup_core();
        designer.register_property_registry(array![true]);
        //
        // create...
        helpers::set_caller(OWNER());
        let mut entity_1 = helpers::create_new_entity(1, "entity_1");
        designer.create_entity(array![entity_1.clone()]);
        let mut desc_1_1: DescriptionText = DescriptionText{ inst: entity_1.inst, key: 1, text: "desc_1_1" };
        designer.create_description_text(array![desc_1_1.clone()]);
        //
        // EDITOR fail...
        helpers::set_caller(OTHER());
        designer.create_description_text(array![desc_1_1.clone()]);
    }

    #[test]
    #[should_panic(expected: ('DESIGNER: Not your entity','ENTRYPOINT_FAILED'))]
    fn test_other_not_allowed_to_delete_core_entity() {
        let (mut _world, designer, _, _, _, _) = helpers::setup_core();
        designer.register_property_registry(array![true]);
        //
        // create...
        helpers::set_caller(OWNER());
        let mut entity_1 = helpers::create_new_entity(1, "entity_1");
        designer.create_entity(array![entity_1.clone()]);
        //
        // EDITOR fail...
        helpers::set_caller(OTHER());
        designer.delete_entity(array![entity_1.inst]);
    }

    #[test]
    #[should_panic(expected: ('DESIGNER: Not your entity','ENTRYPOINT_FAILED'))]
    fn test_other_not_allowed_to_delete_core_component() {
        let (mut _world, designer, _, _, _, _) = helpers::setup_core();
        designer.register_property_registry(array![true]);
        //
        // create...
        helpers::set_caller(OWNER());
        let mut entity_1 = helpers::create_new_entity(1, "entity_1");
        designer.create_entity(array![entity_1.clone()]);
        let mut area_1: Area = Area {
            inst: entity_1.inst,
            is_area: true,
            is_spawn_point: false,
            progress_percentage: 10,
        };
        designer.create_area(array![area_1.clone()]);
        //
        // EDITOR fail...
        helpers::set_caller(OTHER());
        designer.delete_area(array![area_1.inst]);
    }

    #[test]
    #[should_panic(expected: ('DESIGNER: Not your entity','ENTRYPOINT_FAILED'))]
    fn test_other_not_allowed_to_delete_core_keyed() {
        let (mut _world, designer, _, _, _, _) = helpers::setup_core();
        designer.register_property_registry(array![true]);
        //
        // create...
        helpers::set_caller(OWNER());
        let mut entity_1 = helpers::create_new_entity(1, "entity_1");
        designer.create_entity(array![entity_1.clone()]);
        let mut desc_1_1: DescriptionText = DescriptionText{ inst: entity_1.inst, key: 1, text: "desc_1_1" };
        designer.create_description_text(array![desc_1_1.clone()]);
        //
        // EDITOR fail...
        helpers::set_caller(OTHER());
        designer.delete_description_text(array![(desc_1_1.inst, 1)]);
    }


    //--------------------------------
    // Editor > core > panic
    //

    #[test]
    #[should_panic(expected: ('DESIGNER: Not your entity','ENTRYPOINT_FAILED'))]
    fn test_editor_not_allowed_to_edit_core_entity() {
        let (mut _world, designer, _, token, _, _) = helpers::setup_core();
        designer.register_property_registry(array![true]);
        token.set_editor(OTHER(), true);
        //
        // create...
        helpers::set_caller(OWNER());
        let mut entity_1 = helpers::create_new_entity(1, "entity_1");
        designer.create_entity(array![entity_1.clone()]);
        //
        // EDITOR fail...
        helpers::set_caller(OTHER());
        designer.create_entity(array![entity_1.clone()]);
    }

    #[test]
    #[should_panic(expected: ('DESIGNER: Not your entity','ENTRYPOINT_FAILED'))]
    fn test_editor_not_allowed_to_edit_core_component() {
        let (mut _world, designer, _, token, _, _) = helpers::setup_core();
        designer.register_property_registry(array![true]);
        token.set_editor(OTHER(), true);
        //
        // create...
        helpers::set_caller(OWNER());
        let mut entity_1 = helpers::create_new_entity(1, "entity_1");
        designer.create_entity(array![entity_1.clone()]);
        let mut area_1: Area = Area {
            inst: entity_1.inst,
            is_area: true,
            is_spawn_point: false,
            progress_percentage: 10,
        };
        designer.create_area(array![area_1.clone()]);
        //
        // EDITOR fail...
        helpers::set_caller(OTHER());
        designer.create_area(array![area_1.clone()]);
    }

    #[test]
    #[should_panic(expected: ('DESIGNER: Not your entity','ENTRYPOINT_FAILED'))]
    fn test_editor_not_allowed_to_edit_core_keyed() {
        let (mut _world, designer, _, token, _, _) = helpers::setup_core();
        designer.register_property_registry(array![true]);
        token.set_editor(OTHER(), true);
        //
        // create...
        helpers::set_caller(OWNER());
        let mut entity_1 = helpers::create_new_entity(1, "entity_1");
        designer.create_entity(array![entity_1.clone()]);
        let mut desc_1_1: DescriptionText = DescriptionText{ inst: entity_1.inst, key: 1, text: "desc_1_1" };
        designer.create_description_text(array![desc_1_1.clone()]);
        //
        // EDITOR fail...
        helpers::set_caller(OTHER());
        designer.create_description_text(array![desc_1_1.clone()]);
    }

    #[test]
    #[should_panic(expected: ('DESIGNER: Not your entity','ENTRYPOINT_FAILED'))]
    fn test_editor_not_allowed_to_delete_core_entity() {
        let (mut _world, designer, _, token, _, _) = helpers::setup_core();
        designer.register_property_registry(array![true]);
        token.set_editor(OTHER(), true);
        //
        // create...
        helpers::set_caller(OWNER());
        let mut entity_1 = helpers::create_new_entity(1, "entity_1");
        designer.create_entity(array![entity_1.clone()]);
        //
        // EDITOR fail...
        helpers::set_caller(OTHER());
        designer.delete_entity(array![entity_1.inst]);
    }

    #[test]
    #[should_panic(expected: ('DESIGNER: Not your entity','ENTRYPOINT_FAILED'))]
    fn test_editor_not_allowed_to_delete_core_component() {
        let (mut _world, designer, _, token, _, _) = helpers::setup_core();
        designer.register_property_registry(array![true]);
        token.set_editor(OTHER(), true);
        //
        // create...
        helpers::set_caller(OWNER());
        let mut entity_1 = helpers::create_new_entity(1, "entity_1");
        designer.create_entity(array![entity_1.clone()]);
        let mut area_1: Area = Area {
            inst: entity_1.inst,
            is_area: true,
            is_spawn_point: false,
            progress_percentage: 10,
        };
        designer.create_area(array![area_1.clone()]);
        //
        // EDITOR fail...
        helpers::set_caller(OTHER());
        designer.delete_area(array![area_1.inst]);
    }

    #[test]
    #[should_panic(expected: ('DESIGNER: Not your entity','ENTRYPOINT_FAILED'))]
    fn test_editor_not_allowed_to_delete_core_keyed() {
        let (mut _world, designer, _, token, _, _) = helpers::setup_core();
        designer.register_property_registry(array![true]);
        token.set_editor(OTHER(), true);
        //
        // create...
        helpers::set_caller(OWNER());
        let mut entity_1 = helpers::create_new_entity(1, "entity_1");
        designer.create_entity(array![entity_1.clone()]);
        let mut desc_1_1: DescriptionText = DescriptionText{ inst: entity_1.inst, key: 1, text: "desc_1_1" };
        designer.create_description_text(array![desc_1_1.clone()]);
        //
        // EDITOR fail...
        helpers::set_caller(OTHER());
        designer.delete_description_text(array![(desc_1_1.inst, 1)]);
    }
}
