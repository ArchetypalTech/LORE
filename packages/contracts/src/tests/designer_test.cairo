#[cfg(test)]
mod tests {
    // use starknet::ContractAddress;
    use dojo::{
        // world::{WorldStorage},
        model::{ModelStorage},
    };
    use lore::{
        systems::{
            designer::{IDesignerDispatcherTrait},
            game_token::{IGameTokenDispatcherTrait},
        },
        models::{
            entity::{Entity},
        },
        tests::{
            helpers,
            helpers::{OWNER, OTHER, RECIPIENT, ADMIN},
        },
    };

    fn _new_entity(inst: felt252, name: ByteArray) -> Entity {
        (Entity {
            inst,
            is_entity: true,
            name,
            alt_names: array![],
            actions_keys: array![],
        })
    }

    #[test]
    fn test_designer_ok() {
        let (world, designer, _, token, _, _) = helpers::setup_core();
        //
        // deployer can design...
        helpers::set_caller(OWNER());
        designer.register_property_registry(array![true]);
        designer.create_entity(array![_new_entity(1, "entity_1")]);
        let entity: Entity = world.read_model(1);
        assert_eq!(entity.name, "entity_1");
        //
        // calldata admin can design...
        helpers::set_caller(ADMIN());
        designer.create_entity(array![_new_entity(2, "entity_2")]);
        let entity: Entity = world.read_model(2);
        assert_eq!(entity.name, "entity_2");
        //
        // another admin can design...
        token.set_admin(OTHER(), true);
        helpers::set_caller(OTHER());
        designer.create_entity(array![_new_entity(3, "entity_3")]);
        let entity: Entity = world.read_model(3);
        assert_eq!(entity.name, "entity_3");
        //
        // another editor can design...
        token.set_editor(RECIPIENT(), true);
        helpers::set_caller(RECIPIENT());
        designer.create_entity(array![_new_entity(4, "entity_4")]);
        let entity: Entity = world.read_model(4);
        assert_eq!(entity.name, "entity_4");
    }

    #[test]
    #[should_panic(expected: ('DESIGNER: Not editor','ENTRYPOINT_FAILED'))]
    fn test_designer_not_editor() {
        let (_, designer, _, _, _, _) = helpers::setup_core();
        // this is not an editor or admin
        helpers::set_caller(OTHER());
        designer.register_property_registry(array![true]);
    }
}
