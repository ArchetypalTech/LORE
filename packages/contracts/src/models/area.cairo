use dojo::{world::WorldStorage, model::ModelStorage};
use lore::{
    models::{
        entity::{Entity, EntityImpl},
        components::{Component},
        player::{Player},
    },
    types::{command_type::Command},
    constants::errors::Error,
};

#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct Area {
    #[key]
    pub inst: felt252,
    pub is_area: bool,
    /// Properties ///
    /// If the area is a spawn point for players
    pub is_spawn_point: bool,
}


//---------------------------------
// Component
//
pub impl AreaComponent of Component<Area> {
    type ComponentType = Area;

    fn entity(self: @Area, world: @WorldStorage) -> Entity {
        EntityImpl::get_entity(world, Self::inst(self)).unwrap()
    }

    fn inst(self: @Area) -> felt252 {
        *self.inst
    }

    fn has_component(world: @WorldStorage, inst: felt252) -> bool {
        Self::get_component(world, inst).is_some()
    }

    fn get_component(world: @WorldStorage, inst: felt252) -> Option<Area> {
        let area: Area = world.read_model(inst);
        if (area.is_area) {
            Option::Some(area)
        } else {
            Option::None
        }
    }

    fn can_use_command(
        self: @Area, world: @WorldStorage, player: @Player, command: @Command,
    ) -> bool {
        true
    }

    fn execute_command(
        self: Area, ref world: WorldStorage, player: @Player, command: @Command,
    ) -> Result<(), Error> {
        // println!("Area execute_command");
        Result::Err(Error::Unimplemented)
    }

    fn store(self: @Area, ref world: WorldStorage) {
        world.write_model(self);
    }

    // used for tests only
    fn add_component(ref world: WorldStorage, inst: felt252) -> Area {
        let mut area: Area = world.read_model(inst);
        area.inst = inst;
        area.is_area = true;
        world.write_model(@area);
        // Return the component
        area
    }
}
