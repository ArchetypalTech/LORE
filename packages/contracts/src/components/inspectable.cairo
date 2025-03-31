use dojo::{world::{WorldStorage, IWorldDispatcherTrait}, model::ModelStorage};

use lore::lib::{random, a_lexer::Command};
use lore::lib::entity::{Entity, EntityImpl};

use super::{Component, player::Player};

#[derive(Clone, Drop, Serde, Introspect, Debug)]
pub enum InspectableActions {
    set_visible,
    read_description,
}

// Inspectable component
#[derive(Clone, Drop, Serde, Introspect, Debug)]
#[dojo::model]
pub struct Inspectable {
    #[key]
    pub inst: felt252,
    pub is_inspectable: bool,
    // properties
    pub is_visible: bool,
    pub description: Array<ByteArray>,
    // pub action_map: Array<(ByteArray, InspectableActions)>,
// pub temp: InspectableActions,
}

// #[derive(Clone, Drop, Serde, Introspect, Debug)]
// #[dojo::model]
// pub struct ActionMap {
//     #[key]
//     pub action: ByteArray,
//     #[key]
//     pub inst: felt252,
//     pub action_fn: felt252,
// }

#[generate_trait]
pub impl InspectableImpl of InspectableTrait {
    fn look_at(self: Inspectable, world: WorldStorage) -> ByteArray {
        self.get_random_description(world)
    }

    fn set_visible(self: Inspectable, mut world: WorldStorage, visible: bool) {
        let mut model: Inspectable = world.read_model(self);
        model.is_visible = visible;
        world.write_model(@model);
    }

    fn get_random_description(self: Inspectable, world: WorldStorage) -> ByteArray {
        let rng: u32 = random::random_u16(world.dispatcher.uuid().try_into().unwrap())
            .try_into()
            .unwrap();
        let description = self.description.at(rng % self.description.len()).clone();
        description
    }
}

pub impl InspectableComponent of Component<Inspectable> {
    fn entity(self: Inspectable, world: WorldStorage) -> Entity {
        EntityImpl::get_entity(world, self.inst).unwrap()
    }

    fn has_component(self: Inspectable, world: WorldStorage, inst: felt252) -> bool {
        let inspectable: Inspectable = world.read_model(inst);
        inspectable.is_inspectable
    }

    fn add_component(mut world: WorldStorage, inst: felt252) -> Inspectable {
        let mut inspectable: Inspectable = world.read_model(inst);
        inspectable.inst = inst;
        inspectable.is_inspectable = true;
        // inspectable.action_map = array![("look", InspectableActions::read_description)];
        world.write_model(@inspectable);
        inspectable
    }

    fn get_component(world: WorldStorage, inst: felt252) -> Option<Inspectable> {
        let inspectable: Inspectable = world.read_model(inst);
        if (!inspectable.has_component(world, inst)) {
            return Option::None;
        }
        let inspectable: Inspectable = world.read_model(inst);
        Option::Some(inspectable)
    }

    fn can_use_command(
        self: Inspectable, world: WorldStorage, player: Player, command: Command,
    ) -> bool {
        true
    }

    fn execute_command(self: Inspectable, world: WorldStorage, player: Player, command: Command) {
        println!("Inspectable execute_command");
    }
}

#[cfg(test)]
mod tests {
    use starknet::ContractAddress;
    use dojo::{world::WorldStorage, model::ModelStorage};
    use super::*;
    use lore::tests::helpers;

    fn Inspectable_create_prefab() -> (
        Inspectable, WorldStorage, ContractAddress, ContractAddress,
    ) {
        let (mut world, _, _, player_1, player_2) = helpers::setup_core();
        let prefab = Inspectable {
            inst: 42,
            is_inspectable: true,
            is_visible: true,
            description: array![
                "hello",
                "world",
                "how big is a rock",
                "what's up with the rock",
                "let's talk about the rock",
            ],
            // action_key: array![],
        // action_value: array![],
        // action_map: array![ // ("show", InspectableActions::set_visible),
        // ("look", InspectableActions::read_description),
        // ],
        // temp: InspectableActions::set_visible,
        };
        world.write_model(@prefab);
        (prefab, world, player_1, player_2)
    }

    #[test]
    fn Inspectable_test_create_inspectable() {
        let (prefab, world, _, _) = Inspectable_create_prefab();
        let read_inspectable: Inspectable = Component::get_component(world, prefab.inst).unwrap();
        println!("read_inspectable: {:?}", read_inspectable);
        assert(read_inspectable.is_inspectable, 'inspectable is inspectable');
        let mut res = array![];
        for _ in 0..10_u8 {
            res.append(read_inspectable.clone().get_random_description(world));
        };
        println!("inspectable: {:?}", res);
    }

    #[test]
    fn Inspectable_test_get_component() {
        let (prefab, world, _, _) = Inspectable_create_prefab();
        let i: Inspectable = Component::get_component(world, prefab.inst).unwrap();
        assert(i.is_inspectable, 'inspectable is inspectable');
    }
}
