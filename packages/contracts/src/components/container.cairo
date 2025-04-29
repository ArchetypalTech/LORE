use dojo::{world::WorldStorage, model::ModelStorage};
use lore::{
    constants::errors::Error, components::{inventoryItem::InventoryItem},
    lib::{entity::{Entity, EntityImpl}, a_lexer::{Command, Token, CommandImpl}},
};
use super::{Component, player::{Player, PlayerImpl, PlayerTrait}};

#[derive(Clone, Drop, Serde, Introspect)]
#[dojo::model]
pub struct Container {
    #[key]
    pub inst: felt252,
    pub is_container: bool,
    // properties
    pub can_be_opened: bool,
    pub can_receive_items: bool,
    pub is_open: bool,
    pub num_slots: u32,
    // item_ids: Array<felt252>,
    // pub accept_tags: Array<Tag>,
    pub action_map: Array<ActionMapContainer>,
}

#[derive(Clone, Drop, Serde, Introspect, Debug)]
pub struct ActionMapContainer {
    pub action: ByteArray,
    pub inst: felt252,
    pub action_fn: ContainerActions,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum ContainerActions {
    Open,
    Close,
    Check,
}

#[generate_trait]
pub impl ContainerImpl of ContainerTrait {
    fn is_container(self: Container) -> bool {
        self.is_container
    }

    fn get_item_ids(self: Container, world: @WorldStorage) -> Array<felt252> {
        let mut item_ids: Array<felt252> = ArrayTrait::new();
        let items = self.entity(world).get_children(world);
        for item in items {
            item_ids.append(item.inst);
        };
        item_ids
    }

    fn set_open(self: Container, mut world: WorldStorage, opened: bool) {
        let mut model: Container = world.read_model(self);
        model.is_open = opened;
        world.write_model(@model);
    }

    fn set_can_be_opened(self: Container, mut world: WorldStorage, can_be_opened: bool) {
        let mut model: Container = world.read_model(self);
        model.can_be_opened = can_be_opened;
        world.write_model(@model);
    }

    fn set_can_receive_items(self: Container, mut world: WorldStorage, can_receive_items: bool) {
        let mut model: Container = world.read_model(self);
        model.can_receive_items = can_receive_items;
        world.write_model(@model);
    }

    fn is_full(self: Container, world: @WorldStorage) -> bool {
        let itemAmount: u32 = self.clone().get_item_ids(world).len().try_into().unwrap();
        return itemAmount >= self.num_slots;
    }

    fn is_empty(self: Container, world: @WorldStorage) -> bool {
        return self.clone().get_item_ids(world).len() == 0;
    }

    fn can_put_item(self: Container, world: WorldStorage, item: InventoryItem) -> bool {
        let mut can_put_item = false;
        // chekc if container is open
        if (!self.is_open) {
            return can_put_item;
        }
        // check if container is full
        if (self.clone().is_full(@world)) {
            return can_put_item;
        }
        // check if container can receive items
        if (!self.can_receive_items) {
            return can_put_item;
        }
        // check if item can go into the container
        if (!item.can_go_in_container) {
            return can_put_item;
        }
        // check if item is already in the container
        if (self.contains(item.inst, @world)) {
            return can_put_item;
        }
        // if checks pass, container can receive item
        can_put_item = true;
        can_put_item
    }

    fn put_item(self: Container, mut world: WorldStorage, item: InventoryItem) {
        // get container
        let mut container: Container = world.read_model(self.inst);

        // get item entity
        let item_entity: Entity = world.read_model(item.inst);

        // check if item can be put in container
        if (!container.clone().can_put_item(world, item.clone())) {
            return;
        }
        // set parent to be the container's entity
        item_entity.set_parent(world, @container.entity(@world));
        // update container
        world.write_model(@container);
    }


    fn take_item(self: Container, world: WorldStorage, item: InventoryItem) {
        assert(true == false, 'take_item not yet implemented');
    }

    fn contains(self: Container, itemID: felt252, world: @WorldStorage) -> bool {
        let mut already_inside = false;
        // check if item is already in container
        for item_id in self.clone().get_item_ids(world) {
            if (item_id == itemID) {
                already_inside;
                break;
            }
        };
        already_inside
    }

    fn check_container(
        self: Container, world: @WorldStorage, player: @Player, object: @ByteArray,
    ) -> bool {
        // check if container is open
        if (!self.is_open) {
            player.say(*world, format!("The {} is closed", object));
            return true;
        } else {
            player.say(*world, format!("The {} is open.", object));
        }
        // check if container is full
        if (self.clone().is_full(world)) {
            player.say(*world, ("It is full."));
        } else {
            player.say(*world, ("It is not full."));
        }
        // check if container can receive items
        if (!self.can_receive_items) {
            player.say(*world, ("It cannot receive items"));
        } else {
            player.say(*world, ("It can receive items"));
        }
        // check if container is empty
        if (self.clone().is_empty(world)) {
            player.say(*world, ("It is empty."));
        } else {
            // Say what it contains
            player.say(*world, format!("It contains:"));
            let items_id = self.get_item_ids(world);
            for item_id in items_id {
                let item = EntityImpl::get_entity(world, @item_id).unwrap();
                player.say(*world, format!("{}", item.name));
            };
        }

        return true;
    }
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
        println!("Container execute_command");
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

