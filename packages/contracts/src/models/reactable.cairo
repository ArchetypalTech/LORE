use dojo::{world::{WorldStorage, IWorldDispatcherTrait}, model::{ModelStorage, Model}};
use lore::{
    models::{
        entity::{Entity, EntityImpl},
        components::{Instance, Component},
        game_instance::{GameModelImpl},
        player::{Player, PlayerImpl},
        index::{DescriptionText},
    },
    types::{
        command_type::{Command, Token},
        component_type::{ReactableActions, ActionMapReactable},
    },
    constants::errors::Error,
    lib::random,
};

#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct Reactable {
    #[key]
    pub inst: felt252,
    pub is_reactable: bool,
    /// Properties ///
    /// If the reactable is visible
    pub is_visible: bool,
    /// Array of descriptions for the reactable
    pub description: Array<u32>,
    /// Array of action maps for the reactable
    pub action_map: Array<ActionMapReactable>,
    /// For the first description, if we want to show a different one
    pub already_shown: bool,
    /// New first description
    pub new_entry: ByteArray,
}


//---------------------------------
// Model Trait
//
#[generate_trait]
pub impl ReactableImpl of ReactableTrait {
    fn get_random_description(
        self: @Reactable, command: @Command, world: WorldStorage,
    ) -> ByteArray {
        let (action, _token) = get_action_token(self, @world, command).unwrap();
        match action.action_fn {
            ReactableActions::ReadRandomDescription => {
                let (idx1, idx2): (u32, u32) = action.entrypoints.try_into().unwrap();
                if self.description.len() == 0 || idx1 > idx2 {
                    return "";
                }
                let range_len = idx2 - idx1 + 1;
                let rng: u32 = random::random_u16(world.dispatcher.uuid().try_into().unwrap())
                    .try_into()
                    .unwrap();

                let random_idx = idx1 + (rng % range_len);
                if random_idx >= self.description.len().try_into().unwrap() {
                    return ""; // avoid out-of-bounds access
                }
                let key: u32 = self.description.at(random_idx).clone();
                let descriptionText: DescriptionText = world.read_model((*self.inst, key));
                descriptionText.text
            },
            _ => "",
        }
    }

    fn get_first_description(self: @Reactable, world: WorldStorage) -> ByteArray {
        if self.description.len() == 0 {
            return "";
        }
        let key: u32 = self.description.at(0).clone();
        let descriptionText: DescriptionText = world.read_model((self.inst.clone(), key));
        descriptionText.text
    }

    fn get_specific_description(
        reactable: @Reactable, index: u32, world: WorldStorage,
    ) -> ByteArray {
        if reactable.description.len() == 0 {
            return "";
        }
        let key: u32 = reactable.description.at(index).clone();
        let descriptionText: DescriptionText = world.read_model((reactable.inst.clone(), key));
        descriptionText.text
    }
}


//---------------------------------
// Component
//
pub impl ReactableInstance of Instance<Reactable> {
    #[inline(always)]
    fn inst(self: @Reactable) -> felt252 {
        (*self.inst)
    }
    #[inline(always)]
    fn set_inst(ref self: Reactable, new_inst: felt252) {
        self.inst = new_inst;
    }
    #[inline(always)]
    fn is_component(self: @Reactable) -> bool {
        (*self.is_reactable)
    }
    fn has_component(self: @WorldStorage, inst: felt252) -> bool {
        (inst != 0 && self.read_member(Model::<Reactable>::ptr_from_keys(inst), selector!("is_reactable")))
    }
}

pub impl ReactableComponent of Component<Reactable> {
    type ComponentType = Reactable;

    fn entity(self: @Reactable, world: @WorldStorage) -> Entity {
        EntityImpl::get_entity(world, self.inst()).unwrap()
    }

    fn get_component(world: @WorldStorage, inst: felt252, game_id: u128) -> Option<Reactable> {
        let reactable: Reactable = world.read_game_model(inst, game_id);
        if (reactable.is_component()) {
            Option::Some(reactable)
        } else {
            Option::None
        }
    }

    fn store(self: @Reactable, ref world: WorldStorage, game_id: u128) {
        world.write_game_model(self, game_id);
    }

    fn can_use_command(
        self: @Reactable, world: @WorldStorage, player: @Player, command: @Command,
    ) -> bool {
        get_action_token(self, world, command).is_some()
    }

    fn execute_command(
        mut self: Reactable, ref world: WorldStorage, player: @Player, command: @Command,
    ) -> Result<(), Error> {
        // println!("Reactable execute_command");
        let (action, _token) = get_action_token(@self, @world, command).unwrap();
        match action.action_fn {
            ReactableActions::SetVisible => {
                self.is_visible = !self.is_visible;
                self.store(ref world, *command.game_id);
                return Result::Ok(());
            },
            ReactableActions::ReadRandomDescription => {
                player.say(ref world, *command.game_id, self.get_random_description(command, world));
                return Result::Ok(());
            },
            ReactableActions::ReadFirstDescription => {
                player.say(ref world, *command.game_id, self.get_first_description(world));
                return Result::Ok(());
            },
            ReactableActions::ReadSpecificDescription => {
                // Get idxs from the action map entrypoints
                let (idx1, _idx2): (u32, u32) = action.entrypoints.try_into().unwrap();
                // Say the description
                player.say(ref world, *command.game_id, ReactableImpl::get_specific_description(@self, idx1, world));
                return Result::Ok(());
            },
        }
        Result::Err(Error::ActionFailed)
    }

    // used for tests only
    fn add_component(ref world: WorldStorage, inst: felt252) -> Reactable {
        let mut reactable: Reactable = world.read_model(inst);
        reactable.inst = inst;
        reactable.is_reactable = true;
        reactable.is_visible = true;
        reactable
            .action_map =
                array![
                    ActionMapReactable {
                        action: "look",
                        inst: 0,
                        action_fn: ReactableActions::ReadRandomDescription,
                        entrypoints: (0, 2),
                    },
                    ActionMapReactable {
                        action: "stare",
                        inst: 0,
                        action_fn: ReactableActions::ReadFirstDescription,
                        entrypoints: (1, 1),
                    },
                    ActionMapReactable {
                        action: "read",
                        inst: 0,
                        action_fn: ReactableActions::ReadSpecificDescription,
                        entrypoints: (2, 2),
                    },
                ];
        reactable.already_shown = false;
        reactable.new_entry = "";
        reactable.store(ref world, 0);
        // Return the component
        reactable
    }
}

// @dev: wip how to access tokens
pub fn get_action_token(
    self: @Reactable, world: @WorldStorage, command: @Command,
) -> Option<(ActionMapReactable, Token)> {
    let mut action_token: Option<(ActionMapReactable, Token)> = Option::None;
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
pub mod tests {
    use starknet::ContractAddress;
    use dojo::{world::WorldStorage, model::ModelStorage};
    use super::*;
    use lore::tests::helpers;
    use lore::{
        models::{
            index::{DescriptionText},
            reactable::{Reactable, ReactableImpl},
        },
        types::{command_type::{Command, Token, TokenType}},
    };

    pub fn Reactable_create_prefab(ref world: WorldStorage, inst: felt252) -> Reactable {
        let descr1 = DescriptionText { inst, key: 0, text: "hello" };
        let descr2 = DescriptionText { inst, key: 1, text: "world" };
        let descr3 = DescriptionText { inst, key: 2, text: "how big is a rock" };
        let descr4 = DescriptionText { inst, key: 3, text: "what's up with the rock" };
        let descr5 = DescriptionText { inst, key: 4, text: "let's talk about the rock" };
        let descr6 = DescriptionText { inst, key: 5, text: "the rock is from the moon" };
        world.write_model(@descr1);
        world.write_model(@descr2);
        world.write_model(@descr3);
        world.write_model(@descr4);
        world.write_model(@descr5);
        world.write_model(@descr6);
        let prefab = Reactable {
            inst,
            is_reactable: true,
            is_visible: true,
            description: array![0, 1, 2, 3, 4, 5],
            action_map: array![
                ActionMapReactable {
                    action: "show",
                    inst: 0,
                    action_fn: ReactableActions::SetVisible,
                    entrypoints: (0, 0),
                },
                ActionMapReactable {
                    action: "look",
                    inst: 0,
                    action_fn: ReactableActions::ReadRandomDescription,
                    entrypoints: (3, 5),
                },
                ActionMapReactable {
                    action: "read",
                    inst: 0,
                    action_fn: ReactableActions::ReadSpecificDescription,
                    entrypoints: (5, 5),
                },
            ],
            already_shown: false,
            new_entry: "",
        };
        world.write_model(@prefab);
        (prefab)
    }
    
    fn Reactable_create_prefab_world() -> (Reactable, WorldStorage, ContractAddress, ContractAddress) {
        let (mut world, _, _, player_1, player_2) = helpers::setup_core();
        let prefab = Reactable_create_prefab(ref world, 42);
        (prefab, world, player_1, player_2)
    }

    #[test]
    fn Reactable_test_create_reactable() {
        // Create a test command with g_command system token
        let mut command = Command {
            command_id: 1,
            text: "look tower",
            words: array!["look", "tower"],
            token_count: 2,
            action_type: 0,
            tokens: array![
                Token {
                    position: 0,
                    text: "look",
                    token_type: TokenType::Verb,
                    token_value: 2,
                    target: 0,
                },
                Token {
                    position: 1,
                    text: "tower",
                    token_type: TokenType::Unknown,
                    token_value: 0,
                    target: 0,
                },
            ],
            game_id: 0,
        };
        let (prefab, world, _, _) = Reactable_create_prefab_world();
        let read_reactable: Reactable = Component::get_component(@world, prefab.inst, 0).unwrap();
        // println!("read_reactable: {:?}", read_reactable);
        assert(read_reactable.is_reactable, 'reactable is reactable');
        let mut res = array![];
        for _ in 0..10_u8 {
            res.append(read_reactable.clone().get_random_description(@command, world));
        };
        // println!("reactable: {:?}", res);
    }

    #[test]
    fn Reactable_test_get_component() {
        let (prefab, world, _, _) = Reactable_create_prefab_world();
        let i: Reactable = Component::get_component(@world, prefab.inst, 0).unwrap();
        assert(i.is_reactable, 'reactable is reactable');
    }

    #[test]
    fn Reactable_test_read_specific_description() {
        let (prefab, world, _, _) = Reactable_create_prefab_world();
        let i: Reactable = Component::get_component(@world, prefab.inst, 0).unwrap();
        let idx: u32 = 5;
        let res = ReactableImpl::get_specific_description(@i, idx, world);
        assert(res == "the rock is from the moon", 'description should be the moon');
    }
}
