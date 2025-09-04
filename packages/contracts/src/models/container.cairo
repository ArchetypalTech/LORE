use dojo::{world::{WorldStorage}, model::ModelStorage};
use lore::{
    models::{
        entity::{Entity, EntityImpl},
        player::{Player},
        components::{Component},
    },
    new_components::{
        player_trait::PlayerImpl,
        container_trait::ContainerImpl,
    },
    types::{command_type::{Command, Token},
    component_type::{ContainerActions, ActionMapContainer}},
    lib::{a_lexer::CommandImpl},
    constants::errors::Error,
};

#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct Container {
    #[key]
    pub inst: felt252,
    pub is_container: bool,
    /// Properties ///
    /// If the container can be opened
    pub can_be_opened: bool,
    /// If the container can receive items
    pub can_receive_items: bool,
    /// If the container is open
    pub is_open: bool,
    /// Total number of slots of the container
    pub num_slots: u32,
    // pub accept_tags: Array<Tag>,
    pub action_map: Array<ActionMapContainer>,
}

pub impl ContainerComponent of Component<Container> {
    type ComponentType = Container;

    fn inst(self: @Container) -> @felt252 {
        self.inst
    }

    fn entity(self: @Container, world: @WorldStorage) -> Entity {
        EntityImpl::get_entity(world, self.inst).unwrap()
    }

    fn has_component(self: @Container, world: WorldStorage, inst: felt252) -> bool {
        let container: Container = world.read_model(inst);
        container.is_container
    }

    fn add_component(mut world: WorldStorage, inst: felt252) -> Container {
        let mut container: Container = world.read_model(inst);
        container.inst = inst;
        container.is_container = true;
        container.can_be_opened = true;
        container.can_receive_items = true;
        container.is_open = true;
        container.num_slots = 0;
        container
            .action_map =
                array![
                    ActionMapContainer {
                        action: "open", inst: 0, action_fn: ContainerActions::Open,
                    },
                    ActionMapContainer {
                        action: "close", inst: 0, action_fn: ContainerActions::Close,
                    },
                    ActionMapContainer {
                        action: "check", inst: 0, action_fn: ContainerActions::Check,
                    },
                ];
        container.store(world);
        // Return the component
        container
    }

    fn get_component(world: WorldStorage, inst: felt252) -> Option<Container> {
        let container: Container = world.read_model(inst);
        if (!container.has_component(world, inst)) {
            return Option::None;
        }
        Option::Some(container)
    }

    fn can_use_command(
        self: @Container, world: WorldStorage, player: @Player, command: @Command,
    ) -> bool {
        get_action_token(self, world, command).is_some()
    }

    fn execute_command(
        mut self: Container, mut world: WorldStorage, player: @Player, command: @Command,
    ) -> Result<(), Error> {
        // println!("Container execute_command");
        let (action, _token) = get_action_token(@self, world, command).unwrap();
        let nouns = command.get_nouns();
        match action.action_fn {
            ContainerActions::Open => {
                if (self.is_open) {
                    player
                        .say(
                            world,
                            format!("The {} is already open.", self.clone().entity(@world).name),
                        );
                } else {
                    player.say(world, format!("You open {}", self.clone().entity(@world).name));
                    self.set_open(world, true);
                }
                return Result::Ok(());
            },
            ContainerActions::Close => {
                if (!self.is_open) {
                    player
                        .say(
                            world,
                            format!("The {} is already closed.", self.clone().entity(@world).name),
                        );
                } else {
                    player.say(world, format!("You close {}", self.clone().entity(@world).name));
                    self.set_open(world, false);
                }
                return Result::Ok(());
            },
            ContainerActions::Check => {
                // Check container status
                let doneChecking = self.check_container(@world, player, nouns[0].text);
                if (doneChecking) {
                    return Result::Ok(());
                }
            },
        }
        Result::Err(Error::ActionFailed)
    }

    fn store(self: @Container, mut world: WorldStorage) {
        world.write_model(self);
    }
}

// @dev: wip how to access tokens
fn get_action_token(
    self: @Container, world: WorldStorage, command: @Command,
) -> Option<(ActionMapContainer, Token)> {
    let mut action_token: Option<(ActionMapContainer, Token)> = Option::None;
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
