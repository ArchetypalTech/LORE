use dojo::{world::WorldStorage, model::ModelStorage};
use lore::constants::constants::Direction;
use lore::components::{Component, player::Player};
use lore::lib::a_lexer::{Command};
use lore::lib::entity::{Entity, EntityImpl};

#[derive(Clone, Drop, Serde, Introspect, Debug)]
#[dojo::model]
pub struct Area {
    #[key]
    pub inst: felt252,
    pub is_area: bool,
    //properties
    pub direction: Direction,
}

pub impl InspectableComponent of Component<Area> {
    fn entity(self: Area, world: WorldStorage) -> Entity {
        EntityImpl::get_entity(world, self.inst).unwrap()
    }

    fn has_component(self: Area, world: WorldStorage, inst: felt252) -> bool {
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

    fn can_use_command(self: Area, world: WorldStorage, player: Player, command: Command) -> bool {
        true
    }

    fn execute_command(self: Area, world: WorldStorage, player: Player, command: Command) {
        println!("Area execute_command");
    }
}
