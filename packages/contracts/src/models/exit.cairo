use dojo::{world::WorldStorage, model::{ModelStorage, Model}};
use lore::{
    models::{
        entity::{Entity, EntityImpl},
        components::{Instance, Component},
        game_instance::{GameModelImpl},
        player::{Player, PlayerImpl},
        action::{Action, ActionImpl},
    },
    types::{
        component_type::{ExitActions, ActionMapExit},
        command_type::{Command, Token},
        action_type::TriggerContext,
        direction_type::{Direction, IntoDirectionByteArray},
    },
    lib::{
        a_lexer::CommandImpl,
        utils::ByteArrayTraitExt,
    },
    constants::{
        constants,
        errors::Error,
    },
};

#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct Exit {
    #[key]
    pub inst: felt252,
    pub is_exit: bool,
    /// Properties ///
    /// If the exit is enterable
    pub is_enterable: bool,
    /// The leads to entity
    pub leads_to: felt252,
    /// The direction type
    pub direction_type: Direction,
    /// Array of action maps for the exit
    pub action_map: Array<ActionMapExit>,
}


//---------------------------------
// Model Trait
//
#[generate_trait]
pub impl ExitImpl of ExitTrait {
    fn is_exit(self: @Exit) -> bool {
        (*self.is_exit)
    }

    fn can_player_enter(self: @Exit) -> bool {
        (*self.is_enterable)
    }
}


//---------------------------------
// Component
//
pub impl ExitInstance of Instance<Exit> {
    #[inline(always)]
    fn inst(self: @Exit) -> felt252 {
        (*self.inst)
    }
    #[inline(always)]
    fn set_inst(ref self: Exit, new_inst: felt252) {
        self.inst = new_inst;
    }
    #[inline(always)]
    fn is_component(self: @Exit) -> bool {
        (*self.is_exit)
    }
    fn has_component(self: @WorldStorage, inst: felt252) -> bool {
        (inst != 0 && self.read_member(Model::<Exit>::ptr_from_keys(inst), selector!("is_exit")))
    }
}

pub impl ExitComponent of Component<Exit> {
    type ComponentType = Exit;

    fn entity(self: @Exit, world: @WorldStorage) -> Entity {
        EntityImpl::get_entity(world, self.inst()).unwrap()
    }

    fn get_component(world: @WorldStorage, inst: felt252, game_id: u128) -> Option<Exit> {
        let exit: Exit = world.read_game_model(inst, game_id);
        if (exit.is_component()) {
            Option::Some(exit)
        } else {
            Option::None
        }
    }

    fn store(self: @Exit, ref world: WorldStorage, game_id: u128) {
        world.write_game_model(self, game_id);
    }

    fn can_use_command(
        self: @Exit, world: @WorldStorage, player: @Player, command: @Command,
    ) -> bool {
        get_action_token(self, world, command).is_some()
    }

    fn execute_command(
        mut self: Exit, ref world: WorldStorage, player: @Player, command: @Command,
    ) -> Result<(), Error> {
        // println!("Exit execute_command");
        let (action, _token) = get_action_token(@self, @world, command).unwrap();
        let direction_tokens = command.get_directions();

        match action.action_fn {
            ExitActions::UseExit => {
                if *player.use_debug {
                    player.log_debug(ref world, format!("You go to {:?}", self));
                }

                let mut matchesName = false;
                let nouns = command.get_nouns();
                let names = self.entity(@world).get_names();
                for noun in nouns {
                    for name in names {
                        if noun.text == name {
                            matchesName = true;
                            break;
                        }
                    }
                };

                let mut matchesDirection = false;
                if (direction_tokens.len() > 0
                    && matches_direction(@self, world, player, direction_tokens).is_some()) {
                    matchesDirection = true;
                }

                // we need to either match by name or by direction
                if !matchesDirection {
                    return Result::Err(Error::DirectionNotMatch);
                }
                if !matchesName {
                    return Result::Err(Error::NameNotMatch);
                }
                // if the exit is not enterable, we can't go there
                if (!self.can_player_enter()) {
                    return Result::Err(Error::Unenterable);
                }

                // Move player to room
                player.clone().move_to_room(ref world, self.leads_to);

                // Do action
                // Check if the entity of the exit has an action
                let pos_entity = EntityImpl::get_entity(@world, self.inst);
                if pos_entity.is_none() {
                    return Result::Err(Error::NoTargetEntity);
                }
                let pos_entity = pos_entity.unwrap();
                let pos_actions = pos_entity.actions_keys;
                if pos_actions.len() > 0 {
                    let mut actions: Array<Action> = ArrayTrait::new();
                    // For each action, execute it
                    for key in pos_actions {
                        let mut action: Action = world.read_model((pos_entity.inst, key));
                        actions.append(action);
                    };
                    if actions.len() == 0 {
                        // No actions found, just return
                        return Result::Ok(());
                    }
                    // execute actions
                    for action in actions {
                        // context is not being used inside evaluations or processing.
                        let context = TriggerContext {
                            doer: *player.inst,
                            target1: self.leads_to, // would be the room that the player moved to
                            target2: 0,
                            inventory_object: self.inst,
                        };

                        let (_trig_res, _cond_res, _eff_res) = action.process_action(
                            ref world, player, @context,
                        );
                    };
                }
                // Describe room
                let _ = player.describe_room(ref world);
                return Result::Ok(());
            },
        }
        // Result::Err(Error::ActionFailed) // Unreachable code
    }

    // used for tests only
    fn add_component(ref world: WorldStorage, inst: felt252) -> Exit {
        let mut exit: Exit = world.read_model(inst);
        exit.inst = inst;
        exit.is_exit = true;
        exit
            .action_map =
                array![
                    ActionMapExit { action: "go", inst: 0, action_fn: ExitActions::UseExit },
                    ActionMapExit { action: "enter", inst: 0, action_fn: ExitActions::UseExit },
                    ActionMapExit { action: "use", inst: 0, action_fn: ExitActions::UseExit },
                ];
        exit.store(ref world, 0);
        // Return the component
        exit
    }
}


fn matches_direction(
    self: @Exit, world: WorldStorage, player: @Player, directions_token: Span<Token>,
) -> Option<felt252> {
    if (directions_token.len() == 0) {
        return Option::None;
    }
    let exit_dir = ByteArrayTraitExt::byte_array_from_direction(*self.direction_type);
    let dir_text = constants::direction_one_letter(directions_token[0].text);
    // println!("area_dir: {:?}", directions_token[0]);
    if (exit_dir == dir_text) {
        return Option::Some(*self.leads_to);
    }
    Option::None
}

// @dev: wip how to access tokens
fn get_action_token(
    self: @Exit, world: @WorldStorage, command: @Command,
) -> Option<(ActionMapExit, Token)> {
    let mut action_token: Option<(ActionMapExit, Token)> = Option::None;
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
