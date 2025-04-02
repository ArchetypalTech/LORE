use dojo::{world::WorldStorage, model::ModelStorage};
use lore::{constants::{errors::Error, constants::Direction}};
use lore::components::{Component, player::Player};
use lore::lib::{entity::{Entity, EntityImpl}, a_lexer::{Command}};

#[derive(Clone, Drop, Serde, Introspect, Debug)]
#[dojo::model]
pub struct Area {
    #[key]
    pub inst: felt252,
    pub is_area: bool,
    //properties
    pub direction: Direction,
}

pub impl AreaComponent of Component<Area> {
    type ComponentType = Area;

    fn inst(self: @Area) -> @felt252 {
        self.inst
    }

    fn has_component(self: @Area, world: WorldStorage, inst: felt252) -> bool {
        let area: Area = world.read_model(inst);
        area.is_area
    }

    fn add_component(mut world: WorldStorage, inst: felt252) -> Area {
        let mut area: Area = world.read_model(inst);
        area.inst = inst;
        area.is_area = true;
        // area.action_map = array![("look", InspectableActions::read_description)];
        world.write_model(@area);
        area
    }

    fn get_component(world: WorldStorage, inst: felt252) -> Option<Area> {
        let area: Area = world.read_model(inst);
        if (!area.has_component(world, inst)) {
            return Option::None;
        }
        let area: Area = world.read_model(inst);
        Option::Some(area)
    }

    fn can_use_command(
        self: @Area, world: WorldStorage, player: @Player, command: @Command,
    ) -> bool {
        true
    }

    fn execute_command(
        self: Area, world: WorldStorage, player: @Player, command: @Command,
    ) -> Result<(), Error> {
        println!("Area execute_command");
        Result::Err(Error::Unimplemented)
    }

    fn store(self: @Area, mut world: WorldStorage) {
        world.write_model(self);
    }
}
