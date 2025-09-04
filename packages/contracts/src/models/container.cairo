use dojo::{world::WorldStorage, model::ModelStorage, model::Model};
use lore::{
    models::{
        entity::{Entity, EntityImpl},
        components::{Component},
        player::{Player, PlayerImpl},
        inventory_item::{InventoryItem, InventoryItemImpl},
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


//---------------------------------
// Model Trait
//
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
        world
            .write_member(
                Model::<Container>::ptr_from_keys(self.inst), selector!("is_open"), opened,
            );
        // world.write_model(@model);
    }

    fn set_can_be_opened(self: Container, mut world: WorldStorage, can_be_opened: bool) {
        world
            .write_member(
                Model::<Container>::ptr_from_keys(self.inst),
                selector!("can_be_opened"),
                can_be_opened,
            );
        // world.write_model(@model);
    }

    fn set_can_receive_items(self: Container, mut world: WorldStorage, can_receive_items: bool) {
        world
            .write_member(
                Model::<Container>::ptr_from_keys(self.inst),
                selector!("can_receive_items"),
                can_receive_items,
            );
        // world.write_model(@model);
    }

    fn is_full(self: @Container, world: @WorldStorage) -> bool {
        let itemAmount: u32 = self.clone().get_item_ids(world).len().try_into().unwrap();
        return itemAmount >= *self.num_slots;
    }

    fn is_empty(self: Container, world: @WorldStorage) -> bool {
        return self.clone().get_item_ids(world).len() == 0;
    }

    fn can_put_item(
        self: @Container, world: @WorldStorage, item: @InventoryItem,
    ) -> (bool, Result<(), Error>) {
        let mut can_put_item = false;
        // check if container is open
        if (!*self.is_open) {
            return (can_put_item, Result::Err(Error::NotOpen));
        }
        // check if container is full
        if (self.clone().is_full(world)) {
            return (can_put_item, Result::Err(Error::ContainerFull));
        }
        // check if container can receive items
        if (!*self.can_receive_items) {
            return (can_put_item, Result::Err(Error::CantStore));
        }
        // check if item can be picked up
        if (!*item.can_be_picked_up) {
            return (can_put_item, Result::Err(Error::CantBePicked));
        }
        // check if item can go into the container
        if (!*item.can_go_in_container) {
            return (can_put_item, Result::Err(Error::CantBeStored));
        }
        // check if item is already in the container
        if (self.contains(*item.inst, world)) {
            return (can_put_item, Result::Err(Error::AlreadyStored));
        }
        // if checks pass, container can receive item
        can_put_item = true;
        (can_put_item, Result::Ok(()))
    }

    fn put_item_in(
        self: Container, mut world: WorldStorage, mut item: InventoryItem,
    ) -> Result<(), Error> {
        // get container
        let mut container: Container = world.read_model(self.inst);

        // get item entity
        let item_entity: Entity = world.read_model(item.inst);

        // check if item can be put in container
        let (result_b, result_c) = container.clone().can_put_item(@world, @item.clone());
        if (!result_b) {
            return Result::Err(result_c.unwrap_err());
        }
        // set parent to be the container's entity
        item_entity.set_parent(ref world, @container.entity(@world));
        item.owner_id = container.inst;
        // update container
        world.write_model(@container);
        // update item
        world
            .write_member(
                Model::<InventoryItem>::ptr_from_keys(item.inst),
                selector!("owner_id"),
                item.owner_id,
            );
        //world.write_model(@item);
        return Result::Ok(());
    }


    fn put_item_out(
        self: Container, mut world: WorldStorage, mut item: InventoryItem, player: @Player,
    ) -> Result<(), Error> {
        // get container
        let mut container: Container = world.read_model(self.inst);
        // get item entity
        let item_entity: Entity = world.read_model(item.inst);
        // get room
        let room: Entity = player.get_room(@world).unwrap();

        // check if the item is in the container
        if (!container.clone().contains(item_entity.inst, @world)) {
            return Result::Err(Error::NotStored);
        }
        // remove item from container:
        // set parent to be the room's entity
        item_entity.set_parent(ref world, @room);
        item.owner_id = room.inst;
        //item_entity.remove_from_parent(ref world, @container);
        // update container
        world.write_model(@container);
        // update item
        world
            .write_member(
                Model::<InventoryItem>::ptr_from_keys(item.inst),
                selector!("owner_id"),
                item.owner_id,
            );
        //world.write_model(@item);
        return Result::Ok(());
    }

    fn contains(self: @Container, itemID: felt252, world: @WorldStorage) -> bool {
        let mut already_inside = false;
        // check if item is already in container
        for item_id in self.clone().get_item_ids(world) {
            if (item_id == itemID) {
                already_inside = true;
                break;
            }
        };
        already_inside
    }

    fn check_container(
        self: Container, world: @WorldStorage, player: @Player, object: @ByteArray,
    ) -> bool {
        // check if container is open
        // we also check if the container is the player's personal inventory
        if (!self.is_open) {
            if (self.inst == *player.inst) {
                player.say(*world, format!("{} personal inventory is close", object));
                return true;
            } else {
                player.say(*world, format!("The {} is closed", object));
                return true;
            }
        } else {
            if (self.inst == *player.inst) {
                player.say(*world, format!("{} personal inventory is open", object));
            } else {
                player.say(*world, format!("{} is open", object));
            }
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
                let item = EntityImpl::get_entity(world, item_id).unwrap();
                player.say(*world, format!("{}", item.name));
            };
        }

        return true;
    }
}


//---------------------------------
// Component
//
pub impl ContainerComponent of Component<Container> {
    type ComponentType = Container;

    fn entity(self: @Container, world: @WorldStorage) -> Entity {
        EntityImpl::get_entity(world, Self::inst(self)).unwrap()
    }

    fn inst(self: @Container) -> felt252 {
        *self.inst
    }

    fn has_component(world: @WorldStorage, inst: felt252) -> bool {
        Self::get_component(world, inst).is_some()
    }

    fn get_component(world: @WorldStorage, inst: felt252) -> Option<Container> {
        let container: Container = world.read_model(inst);
        if (container.is_container) {
            Option::Some(container)
        } else {
            Option::None
        }
    }

    fn can_use_command(
        self: @Container, world: @WorldStorage, player: @Player, command: @Command,
    ) -> bool {
        get_action_token(self, world, command).is_some()
    }

    fn execute_command(
        mut self: Container, ref world: WorldStorage, player: @Player, command: @Command,
    ) -> Result<(), Error> {
        // println!("Container execute_command");
        let (action, _token) = get_action_token(@self, @world, command).unwrap();
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

    fn store(self: @Container, ref world: WorldStorage) {
        world.write_model(self);
    }

    // used for tests only
    fn add_component(ref world: WorldStorage, inst: felt252) -> Container {
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
        container.store(ref world);
        // Return the component
        container
    }
}

// @dev: wip how to access tokens
fn get_action_token(
    self: @Container, world: @WorldStorage, command: @Command,
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
