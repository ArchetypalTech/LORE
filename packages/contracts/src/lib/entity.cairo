use dojo::{world::WorldStorage, model::ModelStorage};

#[derive(Clone, Drop, Serde, Introspect, Debug)]
#[dojo::model]
pub struct Entity {
    #[key]
    pub inst: felt252,
    pub is_entity: bool,
    //properties
    pub name: ByteArray,
    pub alt_names: Array<ByteArray>,
}

#[generate_trait]
pub impl EntityImpl of EntityTrait {
    fn get_names(self: Entity) -> Array<ByteArray> {
        let mut names = self.alt_names.clone();
        names.append(self.name);
        names
    }

    fn has_name(self: Entity, name: ByteArray) -> bool {
        if (self.name == name) {
            return true;
        }
        let mut has_name = false;
        for alt_name in self.alt_names {
            if (alt_name == name) {
                has_name = true;
                break;
            }
        };
        has_name
    }

    fn does_entity_exist(world: WorldStorage, inst: felt252) -> bool {
        let mut entity: Entity = world.read_model(inst);
        entity.is_entity
    }

    fn create_entity(mut world: WorldStorage, entity: Entity) -> Entity {
        world.write_model(@entity);
        entity
    }
}

