use dojo::{world::WorldStorage, model::ModelStorage, model::Model};
use lore::{
    models::{
        entity::{Entity, EntityImpl},
        components::{Instance, Component},
        game_instance::{GameModelImpl},
        player::{Player, PlayerImpl},
        action::{Action, ActionImpl},
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
pub impl InventoryItemInstance of Instance<InventoryItem> {
    #[inline(always)]
    fn inst(self: @InventoryItem) -> felt252 {
        (*self.inst)
    }

    #[inline(always)]
    fn set_inst(ref self: InventoryItem, new_inst: felt252) {
        self.inst = new_inst;
    }

    #[inline(always)]
    fn is_component(self: @InventoryItem) -> bool {
        (*self.is_inventory_item)
    }

    fn has_component(self: @WorldStorage, inst: felt252) -> bool {
        (inst != 0 && self.read_member(Model::<InventoryItem>::ptr_from_keys(inst), selector!("is_inventory_item")))
    }
}

pub impl InventoryItemComponent of Component<InventoryItem> {
    type ComponentType = InventoryItem;

    fn entity(self: @InventoryItem, world: @WorldStorage) -> Entity {
        EntityImpl::get_entity(world, self.inst()).unwrap()
    }

    fn get_component(world: @WorldStorage, inst: felt252, game_id: u128) -> Option<InventoryItem> {
        let inventory_item: InventoryItem = world.read_game_model(inst, game_id);
        if (inventory_item.is_component()) {
            Option::Some(inventory_item)
        } else {
            Option::None
        }
    }

    fn store(self: @InventoryItem, ref world: WorldStorage, game_id: u128) {
        world.write_game_model(self, game_id);
    }

    fn can_use_command(
        self: @InventoryItem, world: @WorldStorage, player: @Player, command: @Command,
    ) -> bool {
        get_action_token(self, world, command).is_some()
    }

    fn execute_command(
        mut self: InventoryItem, ref world: WorldStorage, player: @Player, command: @Command,
    ) -> Result<(), Error> {
        // println!("InventoryItem execute_command");
        let (action, _token) = get_action_token(@self, @world, command).unwrap();
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

                let target_entity = EntityImpl::get_entity(@world, *nouns[1].target);
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
                        action, world, @context, *command.game_id,
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
                let personal_container = player.get_personal_container(@world, *command.game_id);
                if personal_container.is_none() {
                    return Result::Err(Error::NoPersonalContainer);
                }
                let container_component: Container = personal_container.unwrap();
                return container_component.put_item_in(ref world, ref self, *command.game_id);
            },
            InventoryItemActions::DropItem => {
                // This is for taking an item from the player's personal inventory
                // Ex:: "drop the sword"
                let personal_container = player.get_personal_container(@world, *command.game_id);
                if personal_container.is_none() {
                    return Result::Err(Error::NoPersonalContainer);
                }
                let container_component: Container = personal_container.unwrap();
                return container_component.put_item_out(ref world, ref self, player, *command.game_id);
            },
            InventoryItemActions::PutItem => {
                // This is for a specific container
                // Ex: "put the sword in the bag"
                // Get the player's container
                let player_container = get_player_container(@world, player, nouns.clone(), *command.game_id);
                if player_container.is_none() {
                    // if it is not in the player, it means it is in an entity container
                    // that is on the room Ex: "put the sword in the box"
                    let entity_container = get_entity_container(@world, player, nouns, *command.game_id);
                    if entity_container.is_none() {
                        return Result::Err(Error::NoContainer);
                    }
                    let container_component: Container = entity_container.unwrap();
                    return container_component.put_item_in(ref world, ref self, *command.game_id);
                }
                let container_component: Container = player_container.unwrap();
                return container_component.put_item_in(ref world, ref self, *command.game_id);
            },
            InventoryItemActions::TakeOutItem => {
                // This is for taking an item from a specific container
                // Ex: "take out the sword from the bag"
                // Get the player's container
                let player_container = get_player_container(@world, player, nouns.clone(), *command.game_id);
                if player_container.is_none() {
                    // if it is not in the player, it means it is in an entity container
                    // that is on the room Ex: "take out the sword from the box"
                    let entity_container = get_entity_container(@world, player, nouns, *command.game_id);
                    if entity_container.is_none() {
                        return Result::Err(Error::NoContainer);
                    }
                    let container_component: Container = entity_container.unwrap();
                    return container_component.put_item_out(ref world, ref self, player, *command.game_id);
                }
                return Result::Ok(());
            },
        }
        Result::Err(Error::ActionFailed)
    }

    // used for tests only
    fn add_component(ref world: WorldStorage, inst: felt252, game_id: u128) -> InventoryItem {
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
        inventory_item.can_be_picked_up = true;
        inventory_item.can_go_in_container = true;
        inventory_item.store(ref world, game_id);
        // Return the component
        inventory_item
    }
}

// @dev: wip how to access tokens
fn get_action_token(
    self: @InventoryItem, world: @WorldStorage, command: @Command,
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
    world: @WorldStorage, player: @Player, nouns: Array<Token>, game_id: u128,
) -> Option<Container> {
    let player_entity: Entity = EntityImpl::get_entity(world, *player.inst).unwrap();
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
    player_container = ContainerComponent::get_component(world, container.unwrap().inst, game_id);
    return player_container;
}

// @dev: wip get entity's container
// This can be the an entity container attached to the room
// Ex: a chest in the room
fn get_entity_container(
    world: @WorldStorage, player: @Player, nouns: Array<Token>, game_id: u128,
) -> Option<Container> {
    // get room
    let room = player.get_room(world);
    if room.is_none() {
        return Option::None;
    }
    let room_entity: Entity = EntityImpl::get_entity(world, room.unwrap().inst).unwrap();
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
    room_container = ContainerComponent::get_component(world, container.unwrap().inst, game_id);
    return room_container;
}
