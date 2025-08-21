use dojo::{world::{WorldStorage, IWorldDispatcherTrait}, model::ModelStorage};

use lore::{
    constants::errors::Error,
    lib::{entity::{Entity, EntityImpl}, random, a_lexer::{Command, Token}},
};

use super::{Component, player::{Player, PlayerImpl}};

#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum InspectableActions {
    SetVisible,
    ReadRandomDescription,
    ReadFirstDescription,
    ReadSpecificDescription,
}

#[derive(Clone, Drop, Serde, Debug)]
#[dojo::model]
pub struct Inspectable {
    #[key]
    pub inst: felt252,
    pub is_inspectable: bool,
    /// Properties
    pub is_visible: bool,
    pub description: Array<ByteArray>,
    pub action_map: Array<ActionMapInspectable>,
    /// For the first description, if we want to show a different one
    pub already_shown: bool,
    pub new_entry: ByteArray,
}

#[derive(Clone, Drop, Serde, Introspect, Debug)]
pub struct ActionMapInspectable {
    pub action: ByteArray,
    pub inst: felt252,
    pub action_fn: InspectableActions,
    pub entrypoint: u32,
}

#[generate_trait]
pub impl InspectableImpl of InspectableTrait {
    fn look_at(self: @Inspectable, world: WorldStorage) -> ByteArray {
        self.get_random_description(world)
    }

    fn get_random_description(self: @Inspectable, world: WorldStorage) -> ByteArray {
        if self.description.len() == 0 {
            return "";
        }
        let rng: u32 = random::random_u16(world.dispatcher.uuid().try_into().unwrap())
            .try_into()
            .unwrap();
        let description = self.description.at(rng % self.description.len()).clone();
        description
    }

    fn get_first_description(self: @Inspectable, world: WorldStorage) -> ByteArray {
        if self.description.len() == 0 {
            return "";
        }
        let description = self.description.at(0).clone();
        description
    }

    fn get_specific_description(inspectabe: @Inspectable, index: u32) -> ByteArray {
        if inspectabe.description.len() == 0 {
            return "";
        }
        let description = inspectabe.description.at(index).clone();
        description
    }
}

pub impl InspectableComponent of Component<Inspectable> {
    type ComponentType = Inspectable;

    fn inst(self: @Inspectable) -> @felt252 {
        self.inst
    }

    fn entity(self: @Inspectable, world: @WorldStorage) -> Entity {
        EntityImpl::get_entity(world, self.inst).unwrap()
    }

    fn has_component(self: @Inspectable, world: WorldStorage, inst: felt252) -> bool {
        let inspectable: Inspectable = world.read_model(inst);
        inspectable.is_inspectable
    }

    fn add_component(mut world: WorldStorage, inst: felt252) -> Inspectable {
        let mut inspectable: Inspectable = world.read_model(inst);
        inspectable.inst = inst;
        inspectable.is_inspectable = true;
        inspectable.is_visible = true;
        inspectable
            .action_map =
                array![
                    ActionMapInspectable {
                        action: "look",
                        inst: 0,
                        action_fn: InspectableActions::ReadRandomDescription,
                        entrypoint: 0,
                    },
                    ActionMapInspectable {
                        action: "stare",
                        inst: 0,
                        action_fn: InspectableActions::ReadFirstDescription,
                        entrypoint: 1,
                    },
                    ActionMapInspectable {
                        action: "read",
                        inst: 0,
                        action_fn: InspectableActions::ReadSpecificDescription,
                        entrypoint: 2,
                    },
                ];
        inspectable.already_shown = false;
        inspectable.new_entry = "";
        inspectable.store(world);
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
        self: @Inspectable, world: WorldStorage, player: @Player, command: @Command,
    ) -> bool {
        get_action_token(self, world, command).is_some()
    }

    fn execute_command(
        mut self: Inspectable, mut world: WorldStorage, player: @Player, command: @Command,
    ) -> Result<(), Error> {
        // println!("Inspectable execute_command");
        let (action, _token) = get_action_token(@self, world, command).unwrap();
        match action.action_fn {
            InspectableActions::SetVisible => {
                self.is_visible = !self.is_visible;
                world.write_model(@self);
                return Result::Ok(());
            },
            InspectableActions::ReadRandomDescription => {
                player.say(world, self.get_random_description(world));
                return Result::Ok(());
            },
            InspectableActions::ReadFirstDescription => {
                player.say(world, self.get_first_description(world));
                return Result::Ok(());
            },
            InspectableActions::ReadSpecificDescription => {
                // Get idx from the action map entrypoint
                let idx: u32 = action.entrypoint.try_into().unwrap();
                // Say the description
                player.say(world, InspectableImpl::get_specific_description(@self, idx));
                return Result::Ok(());
            },
        }
        Result::Err(Error::ActionFailed)
    }

    fn store(self: @Inspectable, mut world: WorldStorage) {
        world.write_model(self);
    }
}

// @dev: wip how to access tokens
fn get_action_token(
    self: @Inspectable, world: WorldStorage, command: @Command,
) -> Option<(ActionMapInspectable, Token)> {
    let mut action_token: Option<(ActionMapInspectable, Token)> = Option::None;
    for token in command.tokens.clone() {
        for action in self.action_map.clone() {
            if (token.text == action.action) {
                action_token = Option::Some((action, token));
                break;
            }
        }
    };
    action_token
}


#[cfg(test)]
mod tests {
    use starknet::ContractAddress;
    use dojo::{world::WorldStorage, model::ModelStorage};
    use super::*;
    use lore::tests::helpers;
    use lore::components::inspectable::InspectableImpl;

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
                "the rock is from the moon",
            ],
            action_map: array![
                ActionMapInspectable {
                    action: "show",
                    inst: 0,
                    action_fn: InspectableActions::SetVisible,
                    entrypoint: 0,
                },
                ActionMapInspectable {
                    action: "look",
                    inst: 0,
                    action_fn: InspectableActions::ReadRandomDescription,
                    entrypoint: 1,
                },
                ActionMapInspectable {
                    action: "read",
                    inst: 0,
                    action_fn: InspectableActions::ReadSpecificDescription,
                    entrypoint: 5,
                },
            ],
            already_shown: false,
            new_entry: "",
        };
        world.write_model(@prefab);
        (prefab, world, player_1, player_2)
    }

    #[test]
    fn Inspectable_test_create_inspectable() {
        let (prefab, world, _, _) = Inspectable_create_prefab();
        let read_inspectable: Inspectable = Component::get_component(world, prefab.inst).unwrap();
        // println!("read_inspectable: {:?}", read_inspectable);
        assert(read_inspectable.is_inspectable, 'inspectable is inspectable');
        let mut res = array![];
        for _ in 0..10_u8 {
            res.append(read_inspectable.clone().get_random_description(world));
        };
        // println!("inspectable: {:?}", res);
    }

    #[test]
    fn Inspectable_test_get_component() {
        let (prefab, world, _, _) = Inspectable_create_prefab();
        let i: Inspectable = Component::get_component(world, prefab.inst).unwrap();
        assert(i.is_inspectable, 'inspectable is inspectable');
    }

    #[test]
    fn Inspectable_test_read_specific_description() {
        let (prefab, world, _, _) = Inspectable_create_prefab();
        let i: Inspectable = Component::get_component(world, prefab.inst).unwrap();
        let idx: u32 = 5;
        let res = InspectableImpl::get_specific_description(@i, idx);
        assert(res == "the rock is from the moon", 'description should be the moon');
    }
}
