use super::super::lib::entity::EntityTrait;
use dojo::{world::{WorldStorage}, model::ModelStorage};
use lore::{
    constants::errors::Error,
    lib::{
        entity::{Entity, EntityImpl}, a_lexer::{Command, Token, CommandImpl},
        utils::ByteArrayTraitExt,
    },
    components::{area::{AreaComponent}, container::{Container, ContainerComponent, ContainerImpl}},
};
use super::{Component, player::{Player, PlayerImpl, PlayerTrait}};


#[derive(Clone, Drop, Serde)]
#[dojo::model]
pub struct InventoryItem {
    #[key]
    pub inst: felt252,
    pub is_inventory_item: bool,
    // properties
    pub owner_id: felt252,
    pub can_be_picked_up: bool,
    pub can_go_in_container: bool,
    pub action_map: Array<ActionMapInventoryItem>,
}

#[derive(Clone, Drop, Serde, Introspect, Debug)]
pub struct ActionMapInventoryItem {
    pub action: ByteArray,
    pub inst: felt252,
    pub action_fn: InventoryItemActions,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum InventoryItemActions {
    UseItem,
    PickupItem,
    DropItem,
    PutItem,
    TakeOutItem,
}

#[generate_trait]
pub impl InventoryItemImpl of InventoryItemTrait {
    fn is_inventory_item(self: InventoryItem) -> bool {
        self.is_inventory_item
    }

    fn set_can_be_picked_up(ref self: InventoryItem, can_be_picked_up: bool) {
        self.can_be_picked_up = can_be_picked_up;
    }

    fn set_can_go_in_container(ref self: InventoryItem, can_go_in_container: bool) {
        self.can_go_in_container = can_go_in_container;
    }
}

pub impl InventoryItemComponent of Component<InventoryItem> {
    type ComponentType = InventoryItem;

    fn inst(self: @InventoryItem) -> @felt252 {
        self.inst
    }

    fn entity(self: @InventoryItem, world: @WorldStorage) -> Entity {
        EntityImpl::get_entity(world, self.inst).unwrap()
    }

    fn has_component(self: @InventoryItem, world: WorldStorage, inst: felt252) -> bool {
        let inventory_item: InventoryItem = world.read_model(inst);
        inventory_item.is_inventory_item
    }

    fn add_component(mut world: WorldStorage, inst: felt252) -> InventoryItem {
        let mut inventory_item: InventoryItem = world.read_model(inst);
        inventory_item.inst = inst;
        inventory_item.is_inventory_item = true;
        inventory_item
            .action_map =
                array![
                    ActionMapInventoryItem {
                        action: "pickup", inst: 0, action_fn: InventoryItemActions::PickupItem,
                    },
                    ActionMapInventoryItem {
                        action: "drop", inst: 0, action_fn: InventoryItemActions::DropItem,
                    },
                    ActionMapInventoryItem {
                        action: "put", inst: 0, action_fn: InventoryItemActions::PutItem,
                    },
                    ActionMapInventoryItem {
                        action: "take", inst: 0, action_fn: InventoryItemActions::TakeOutItem,
                    },
                    ActionMapInventoryItem {
                        action: "use", inst: 0, action_fn: InventoryItemActions::UseItem,
                    },
                ];
        inventory_item.store(world);
        inventory_item
    }

    fn get_component(world: WorldStorage, inst: felt252) -> Option<InventoryItem> {
        let inventory_item: InventoryItem = world.read_model(inst);
        if (!inventory_item.has_component(world, inst)) {
            return Option::None;
        }
        let inventory_item: InventoryItem = world.read_model(inst);
        Option::Some(inventory_item)
    }

    fn can_use_command(
        self: @InventoryItem, world: WorldStorage, player: @Player, command: @Command,
    ) -> bool {
        get_action_token(self, world, command).is_some()
    }

    fn execute_command(
        mut self: InventoryItem, mut world: WorldStorage, player: @Player, command: @Command,
    ) -> Result<(), Error> {
        println!("InventoryItem execute_command");
        let (action, _token) = get_action_token(@self, world, command).unwrap();
        let nouns = command.get_nouns();
        match action.action_fn {
            InventoryItemActions::UseItem => {
                player.say(world, format!("You are trying to use: {}", nouns[0].text));
                // HERE SHOULD GO THE LOGIC FOR HANDLING THE COMMAND
                // LIKE USE ITEM
                return Result::Ok(());
            },
            InventoryItemActions::PickupItem => {
                // This is for the player's personal inventory container
                // Ex: "pickup the sword"
                let personal_container = player.get_personal_container(@world);
                if personal_container.is_none() {
                    return Result::Err(Error::ActionFailed);
                }
                let container_component: Container = personal_container.unwrap();
                container_component.put_item_in(world, self.clone());

                return Result::Ok(());
            },
            InventoryItemActions::DropItem => {
                // This is for taking an item from the player's personal inventory
                // Ex:: "drop the sword"
                let personal_container = player.get_personal_container(@world);
                if personal_container.is_none() {
                    return Result::Err(Error::ActionFailed);
                }
                let container_component: Container = personal_container.unwrap();
                container_component.put_item_out(world, self.clone(), player);
                return Result::Ok(());
            },
            InventoryItemActions::PutItem => {
                // This is for a specific container
                // Ex: "put the sword in the bag"
                // Get the player's container
                let player_container = get_player_container(@world, player, nouns.clone());
                if player_container.is_none() {
                    // if it is not in the player, it means it is in an entity container
                    // that is on the room Ex: "put the sword in the box"
                    let entity_container = get_entity_container(@world, player, nouns);
                    if entity_container.is_none() {
                        return Result::Err(Error::ActionFailed);
                    }
                    let container_component: Container = entity_container.unwrap();
                    container_component.put_item_in(world, self.clone());
                    return Result::Ok(());
                }
                let container_component: Container = player_container.unwrap();
                container_component.put_item_in(world, self.clone());
                return Result::Ok(());
            },
            InventoryItemActions::TakeOutItem => {
                // This is for taking an item from a specific container
                // Ex: "take out the sword from the bag"
                // Get the player's container
                let player_container = get_player_container(@world, player, nouns.clone());
                if player_container.is_none() {
                    // if it is not in the player, it means it is in an entity container
                    // that is on the room Ex: "take out the sword from the box"
                    let entity_container = get_entity_container(@world, player, nouns);
                    if entity_container.is_none() {
                        return Result::Err(Error::ActionFailed);
                    }
                    let container_component: Container = entity_container.unwrap();
                    container_component.put_item_out(world, self.clone(), player);
                    return Result::Ok(());
                }
                return Result::Ok(());
            },
        }
        Result::Err(Error::ActionFailed)
    }

    fn store(self: @InventoryItem, mut world: WorldStorage) {
        world.write_model(self);
    }
}

// @dev: wip how to access tokens
fn get_action_token(
    self: @InventoryItem, world: WorldStorage, command: @Command,
) -> Option<(ActionMapInventoryItem, Token)> {
    let mut action_token: Option<(ActionMapInventoryItem, Token)> = Option::None;
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

// @dev: wip get player's container
// This can be the an entity container attached to the player
// Ex: a bag in the player's personalinventory
fn get_player_container(
    world: @WorldStorage, player: @Player, nouns: Array<Token>,
) -> Option<Container> {
    let player_entity: Entity = EntityImpl::get_entity(world, player.inst).unwrap();
    let player_children = player_entity.get_children(world);
    let mut container: Option<Entity> = Option::None;
    let mut player_container: Option<Container> = Option::None;
    // match the noun wth the child name or alt_name
    for child in player_children {
        if (@child.name == nouns[1].text || child.clone().name_is(nouns[1].text.clone())) {
            container = Option::Some(child);
            break;
        }
    };
    if container.is_none() {
        return Option::None;
    }
    // get container component
    player_container = ContainerComponent::get_component(*world, container.unwrap().inst);
    return player_container;
}

// @dev: wip get entity's container
// This can be the an entity container attached to the room
// Ex: a chest in the room
fn get_entity_container(
    world: @WorldStorage, player: @Player, nouns: Array<Token>,
) -> Option<Container> {
    // get room
    let room = player.get_room(world);
    if room.is_none() {
        return Option::None;
    }
    let room_entity: Entity = EntityImpl::get_entity(world, @room.unwrap().inst).unwrap();
    let room_children = room_entity.get_children(world);
    let mut container: Option<Entity> = Option::None;
    let mut room_container: Option<Container> = Option::None;
    // match the noun wth the child name or alt_name
    for child in room_children {
        if (@child.name == nouns[1].text || child.clone().name_is(nouns[1].text.clone())) {
            container = Option::Some(child);
            break;
        }
    };
    if container.is_none() {
        return Option::None;
    }
    // get container component
    room_container = ContainerComponent::get_component(*world, container.unwrap().inst);
    return room_container;
}
