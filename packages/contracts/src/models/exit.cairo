use dojo::{world::WorldStorage, model::ModelStorage};
use lore::{
    models::{
        entity::{Entity, EntityImpl},
        components::{Component},
        player::{Player, PlayerImpl},
        action::{Action, ActionImpl},
    },
    types::{
        component_type::{ExitActions, ActionMapExit},
        command_type::{Command, Token},
        action_type::TriggerContext,
        direction_type::{Direction, IntoDirectionByteArray},
    },
    lib::{a_lexer::CommandImpl, utils::ByteArrayTraitExt},
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
    fn is_exit(self: Exit) -> bool {
        self.is_exit
    }

    fn can_player_enter(self: Exit) -> bool {
        self.is_enterable
    }
}


//---------------------------------
// Component
//
pub impl ExitComponent of Component<Exit> {
    type ComponentType = Exit;

    fn inst(self: @Exit) -> @felt252 {
        self.inst
    }

    fn entity(self: @Exit, world: @WorldStorage) -> Entity {
        EntityImpl::get_entity(world, self.inst).unwrap()
    }

    fn has_component(self: @Exit, world: WorldStorage, inst: felt252) -> bool {
        let exit: Exit = world.read_model(inst);
        exit.is_exit
    }

    fn add_component(mut world: WorldStorage, inst: felt252) -> Exit {
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
        exit.store(world);
        // Return the component
        exit
    }

    fn get_component(world: WorldStorage, inst: felt252) -> Option<Exit> {
        let exit: Exit = world.read_model(inst);
        if (!exit.has_component(world, inst)) {
            return Option::None;
        }
        let exit: Exit = world.read_model(inst);
        Option::Some(exit)
    }

    fn can_use_command(
        self: @Exit, world: WorldStorage, player: @Player, command: @Command,
    ) -> bool {
        get_action_token(self, world, command).is_some()
    }

    fn execute_command(
        mut self: Exit, mut world: WorldStorage, player: @Player, command: @Command,
    ) -> Result<(), Error> {
        // println!("Exit execute_command");
        let (action, _token) = get_action_token(@self, world, command).unwrap();
        let direction_tokens = command.get_directions();

        let mut destination_inst: felt252 = 0;
        match action.action_fn {
            ExitActions::UseExit => {
                if *player.use_debug {
                    player.say(world, format!("You go to {:?}", self));
                }

                let mut matchesName = false;
                let nouns = command.get_nouns();
                let names = self.entity(@world).get_names();
                for noun in nouns {
                    for name in names.clone() {
                        if noun.text == name {
                            matchesName = true;
                            break;
                        }
                    }
                };

                let mut matchesDirection = false;
                if (direction_tokens.len() > 0
                    && matches_direction(@self, world, player, @direction_tokens).is_some()) {
                    matchesDirection = true;
                }

                // we need to either match by name or by direction
                if (!(matchesName || matchesDirection)) {
                    if !matchesDirection {
                        return Result::Err(Error::DirectionNotMatch);
                    }
                    if !matchesName {
                        return Result::Err(Error::NameNotMatch);
                    }
                }
                // if the exit is not enterable, we can't go there
                if (!self.clone().can_player_enter()) {
                    return Result::Err(Error::Unenterable);
                }
                // Move player to room
                destination_inst = self.leads_to;
                player.clone().move_to_room(world, destination_inst);

                // Do action
                // Check if the entity of the exit has an action
                let pos_entity = EntityImpl::get_entity(@world, @self.inst);
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

                        let (_trig_res, _cond_res, _eff_res) = ActionImpl::process_action(
                            action, world, @context,
                        );
                    };
                }
                // Describe room
                let _ = player.describe_room(world);
                return Result::Ok(());
            },
        }
        Result::Err(Error::ActionFailed)
    }

    fn store(self: @Exit, mut world: WorldStorage) {
        world.write_model(self);
    }
}


fn matches_direction(
    self: @Exit, world: WorldStorage, player: @Player, directions_token: @Array<Token>,
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
    self: @Exit, world: WorldStorage, command: @Command,
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
