use dojo::{world::{WorldStorage}, model::ModelStorage};
use lore::{
    models::{
        entity::{Entity, EntityImpl},
        player::{Player, PlayerImpl},
        action::{Action, ActionImpl},
        components::{Component},
        area::AreaComponent,
        container::{Container, ContainerImpl, ContainerComponent},
    },
    types::{
        command_type::{Command, Token},
        component_type::{InventoryItemActions, ActionMapInventoryItem},
        action_type::TriggerContext,
    },
    constants::errors::Error,
    lib::{
        a_lexer::CommandImpl,
        utils::ByteArrayTraitExt,
    },
};

#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct InventoryItem {
    #[key]
    pub inst: felt252,
    pub is_inventory_item: bool,
    /// Properties ///
    /// The owner of the inventory item
    pub owner_id: felt252,
    /// If the inventory item can be picked up
    pub can_be_picked_up: bool,
    /// If the inventory item can go in a container
    pub can_go_in_container: bool,
    /// The quantity of the inventory item
    pub quantity: u32,
    /// Array of action maps for the inventory item
    pub action_map: Array<ActionMapInventoryItem>,
    /// If the inventory item has already been used
    pub already_used: bool,
    /// If the inventory item can be used multiple times
    pub multiple_use: bool,
}


//---------------------------------
// Model Trait
//
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


//---------------------------------
// Component
//
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
        inventory_item.already_used = false;
        inventory_item.store(world);
        // Return the component
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
        // println!("InventoryItem execute_command");
        let (action, _token) = get_action_token(@self, world, command).unwrap();
        let nouns = command.get_nouns();
        match action.action_fn {
            InventoryItemActions::UseItem => {
                if *player.use_debug {
                    player.say(world, format!("You are trying to use: {}", nouns[0].text));
                }
                let mut resultUse: Result<(), Error> = Result::Ok(());
                // HERE SHOULD GO THE LOGIC FOR HANDLING THE COMMAND
                // LIKE USE ITEM
                // Ex: "use the key on the door"
                // V: Use, N1: key, N2: door (target)
                // Get target entity to get the actions and execute it
                if *player.use_debug {
                    player.say(world, format!("Your target is: {}", nouns[1].text));
                }

                let target_entity = EntityImpl::get_entity(@world, nouns[1].target);
                if target_entity.is_none() {
                    return Result::Err(Error::NoTargetEntity);
                }
                let target_entity = target_entity.unwrap();
                let target_actions = target_entity.actions_keys;
                if target_actions.len() == 0 {
                    // No actions found, just return
                    return Result::Ok(());
                }
                let mut actions: Array<Action> = ArrayTrait::new();
                // For each action, execute it
                for key in target_actions {
                    let mut action: Action = world.read_model((target_entity.inst, key));
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
                        target1: target_entity.inst,
                        target2: 0,
                        inventory_object: self.inst,
                    };

                    if *player.use_debug {
                        player
                            .say(
                                world,
                                format!(
                                    "Using {} trigger's something at {}",
                                    nouns[0].text,
                                    nouns[1].text,
                                ),
                            );
                        player
                            .say(
                                world,
                                format!(
                                    "Using: {:?} trigger's the action: {:?} at: {:?} as the target",
                                    nouns[0].text,
                                    action,
                                    nouns[1].text,
                                ),
                            );
                    }
                    let (trig_res, cond_res, eff_res) = ActionImpl::process_action(
                        action, world, @context,
                    );
                    if *player.use_debug {
                        player.say(world, format!("Trigger result: {:?}", trig_res));
                        player.say(world, format!("Condition result: {:?}", cond_res));
                        player.say(world, format!("Effect result: {:?}", eff_res));
                    }
                    // If all are ok, set used to true
                    if trig_res.is_ok() && cond_res && eff_res.is_ok() {
                        let mut updated_invItem: InventoryItem = world.read_model(self.inst);
                        updated_invItem.already_used = true;
                        world.write_model(@updated_invItem);
                        resultUse = Result::Ok(());
                        break;
                    }
                };
                return resultUse;
            },
            InventoryItemActions::PickupItem => {
                // This is for the player's personal inventory container
                // Ex: "pickup the sword"
                let personal_container = player.get_personal_container(@world);
                if personal_container.is_none() {
                    return Result::Err(Error::NoPersonalContainer);
                }
                let container_component: Container = personal_container.unwrap();
                let res = container_component.put_item_in(world, self.clone());
                if res.is_err() {
                    return Result::Err(res.unwrap_err());
                }

                return Result::Ok(());
            },
            InventoryItemActions::DropItem => {
                // This is for taking an item from the player's personal inventory
                // Ex:: "drop the sword"
                let personal_container = player.get_personal_container(@world);
                if personal_container.is_none() {
                    return Result::Err(Error::NoPersonalContainer);
                }
                let container_component: Container = personal_container.unwrap();
                let res = container_component.put_item_out(world, self.clone(), player);
                if res.is_err() {
                    return Result::Err(res.unwrap_err());
                }
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
                        return Result::Err(Error::NoContainer);
                    }
                    let container_component: Container = entity_container.unwrap();
                    let res = container_component.put_item_in(world, self.clone());
                    if res.is_err() {
                        return Result::Err(res.unwrap_err());
                    }
                    return Result::Ok(());
                }
                let container_component: Container = player_container.unwrap();
                let res = container_component.put_item_in(world, self.clone());
                if res.is_err() {
                    return Result::Err(res.unwrap_err());
                }
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
                        return Result::Err(Error::NoContainer);
                    }
                    let container_component: Container = entity_container.unwrap();
                    let res = container_component.put_item_out(world, self.clone(), player);
                    if res.is_err() {
                        return Result::Err(res.unwrap_err());
                    }
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
