use dojo::{world::WorldStorage, model::{ModelStorage, Model}};
use lore::{
    models::{
        entity::{Entity, EntityImpl},
        components::{Component},
        game_instance::{Instance, GameModelImpl},
        player::{Player, PlayerImpl},
        action::{Action, ActionImpl},
        area::AreaComponent,
        container::{Container, ContainerImpl, ContainerComponent},
    },
    types::{
        command_type::{Command, CommandImpl, Token},
        component_type::{InventoryItemActions, ActionMapInventoryItem},
        action_type::TriggerContext,
    },
    constants::errors::Error,
    lib::{
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
    fn is_inventory_item(self: @InventoryItem) -> bool {
        (*self.is_inventory_item)
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
    fn is_partially_mapped() -> bool {
        (true)
    }
    fn partially_map_from(ref self: InventoryItem, game_model: @InventoryItem) {
        // map properties declared in VariablePropertyHelperTrait::register_properties()
        self.owner_id = *game_model.owner_id;
        self.can_be_picked_up = *game_model.can_be_picked_up;
        self.can_go_in_container = *game_model.can_go_in_container;
        self.quantity = *game_model.quantity;
        self.already_used = *game_model.already_used;
        self.multiple_use = *game_model.multiple_use;
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
        let nouns: Span<Token> = command.get_nouns();
        match action.action_fn {
            InventoryItemActions::UseItem => {
                if *player.use_debug {
                    player.log_debug(ref world, format!("You are trying to use: {}", nouns[0].text));
                }
                let mut resultUse: Result<(), Error> = Result::Ok(());
                // HERE SHOULD GO THE LOGIC FOR HANDLING THE COMMAND
                // LIKE USE ITEM
                // Ex: "use the key on the door"
                // V: Use, N0: key, N1: door (target)
                // Get target entity to get the actions and execute it
                // OUTDATED
                // if *player.use_debug {
                //     player.log_debug(ref world, format!("Your target is: {}", nouns[1].text));
                // }

                // Execute action on the target entity
                // Ex: "use the work permit on the oily rag"
                // N0: work, N1: permit, N2: oily , N3: rag
                // 1. N0 is Self. Get entity so that we can get the alt names
                let executor: Entity = EntityImpl::get_entity(@world, self.inst).unwrap();
                // println!("InventoryItem execute_command: executor: {:?}", executor);
                // println!("N0: {}. Executor: {:?}", nouns[0].text, executor);
                // 1.5 if nouns lenght is equal to 1 then return message
                if nouns.len() == 1 {
                    player.say(ref world, format!("Please provide a target for the action called by {}.", nouns[0].text));
                    return Result::Ok(());
                }
                //let mut target_entity_opt: Option<Entity> = Option::None;
                // 2. Check if noun[1] is in the alt names
                let mut found_in_alt_names: bool = false;
                for alt_name in executor.alt_names {
                    if nouns[1].text == @alt_name {
                        found_in_alt_names = true;
                        break;
                    }
                };

                let target_entity: Entity = if found_in_alt_names {
                    // noun1 is an alias for self → target is noun2 or noun3
                    // if nouns lenght is equal to 2 then return message as there is no target
                    if nouns.len() == 2 {
                        player.say(ref world, format!("Please provide a target for the action called by {} {}.", nouns[0].text, nouns[1].text));
                        return Result::Ok(());
                    }
                    // if n2 or n3 are empty then, return message
                    match EntityImpl::get_entity(@world, *nouns[2].target) {
                        Option::Some(e) => e, // If noun2 is found, target is noun2
                        Option::None => {
                            // If noun2 is not found, then noun3 is the target
                            match EntityImpl::get_entity(@world, *nouns[3].target) {
                                Option::Some(e) => e,
                                Option::None => {
                                    // If noun3 is not found, then player.say and return
                                    player.say(ref world, format!(
                                        "I cannot find the target: {} {}.",
                                        nouns[2].text, nouns[3].text
                                    ));
                                    return Result::Ok(());
                                }
                            }
                        }
                    }
                } else {
                    // noun1 is not an alias for self → target is noun1
                    match EntityImpl::get_entity(@world, *nouns[1].target) {
                        Option::Some(e) => e,
                        Option::None => {
                            player.say(ref world, format!(
                                "I cannot find the target: {}. It's not possible to execute that action.",
                                nouns[1].text
                            ));
                            return Result::Ok(());
                        }
                    }
                };
                
                // Get the target actions
                let target_actions: Array<felt252> = target_entity.actions_keys;
                if target_actions.is_empty() {
                    // 6.1 No actions found, just return
                    player.say(ref world, format!("There is no action to perform on {}.", target_entity.name));
                    return Result::Ok(());
                }
                // Get the actions
                let mut actions: Array<Action> = ArrayTrait::new();
                // For each action, execute it
                for key in target_actions {
                    let mut action: Action = world.read_model((target_entity.inst, key));
                    actions.append(action);
                };
                if actions.is_empty() {
                    // No actions found, just return
                    player.say(ref world, format!("There is no action to perform on {}.", target_entity.name));
                    return Result::Ok(());
                }
                // Execute actions
                for action in actions {
                    // context is not being used inside evaluations or processing.
                    let context: TriggerContext = TriggerContext {
                        doer: *player.inst,
                        target1: target_entity.inst,
                        target2: 0,
                        inventory_object: self.inst,
                    };

                    if *player.use_debug {
                        player
                            .log_debug(
                                ref world,
                                format!(
                                    "Using {} trigger's something at {}",
                                    nouns[0].text,
                                    nouns[1].text,
                                ),
                            );
                        player
                            .log_debug(
                                ref world,
                                format!(
                                    "Using: {:?} trigger's the action: {:?} at: {:?} as the target",
                                    nouns[0].text,
                                    action,
                                    nouns[1].text,
                                ),
                            );
                    }
                    let (trig_res, cond_res, eff_res) = action.process_action(
                        ref world, player, @context,
                    );
                    if *player.use_debug {
                        player.log_debug(ref world, format!("Trigger result: {:?}", trig_res));
                        player.log_debug(ref world, format!("Condition result: {:?}", cond_res));
                        player.log_debug(ref world, format!("Effect result: {:?}", eff_res));
                    }
                    // If all are ok, set used to true
                    if trig_res.is_ok() && cond_res && eff_res.is_ok() {
                        // Read the changed model again to change the already_used property
                        let mut inventory_item: InventoryItem = world.read_game_model(self.inst, *player.game_id);
                        inventory_item.already_used = true;
                        inventory_item.store(ref world, *player.game_id);
                        resultUse = Result::Ok(());
                        break;
                    }
                };
                return resultUse;
            },
            InventoryItemActions::PickupItem => {
                // This is for the player's personal inventory container
                // Ex: "pickup the sword"
                let personal_container: Option<Container> = player.get_personal_container(ref world);
                if personal_container.is_none() {
                    return Result::Err(Error::NoPersonalContainer);
                }
                let container_component: Container = personal_container.unwrap();
                let res: Result<(), Error> = container_component.put_item_in(ref world, ref self, *player.game_id);
                if res.is_err() {
                    player.say(ref world, format!("You cannot pick the {}", nouns[0].text));
                } else {
                    player.say(ref world, format!("You picked up the {}", nouns[0].text));
                }
                return res;
            },
            InventoryItemActions::DropItem => {
                // This is for taking an item from the player's personal inventory
                // Ex:: "drop the sword"
                let personal_container: Option<Container> = player.get_personal_container(ref world);
                if personal_container.is_none() {
                    return Result::Err(Error::NoPersonalContainer);
                }
                let container_component: Container = personal_container.unwrap();
                let res: Result<(), Error> = container_component.put_item_out(ref world, ref self, player);
                if res.is_err() {
                    player.say(ref world, format!("You cannot drop the {}", nouns[0].text));
                } else {
                    player.say(ref world, format!("You dropped the {}", nouns[0].text));
                }
                return res;
            },
            InventoryItemActions::PutItem => {
                // This is for a specific container
                // Ex: "put the sword in the bag"
                // Get the player's container
                let player_container: Option<Container> = get_player_container(@world, player, nouns);
                if player_container.is_none() {
                    // if it is not in the player, it means it is in an entity container
                    // that is on the room Ex: "put the sword in the box"
                    let entity_container: Option<Container> = get_entity_container(@world, player, nouns);
                    if entity_container.is_none() {
                        return Result::Err(Error::NoContainer);
                    }
                    let container_component: Container = entity_container.unwrap();
                    let res: Result<(), Error> = container_component.put_item_in(ref world, ref self, *player.game_id);
                    if res.is_err() {
                        player.say(ref world, format!("You cannot put {} inside {}", nouns[0].text, nouns[1].text));
                    } else {
                        player.say(ref world, format!("You put the {} inside {}", nouns[0].text, nouns[1].text));
                    }
                    return res;
                }
                let container_component: Container = player_container.unwrap();
                let res: Result<(), Error> = container_component.put_item_in(ref world, ref self, *player.game_id);
                if res.is_err() {
                    player.say(ref world, format!("You cannot put {} inside {}", nouns[0].text, nouns[1].text));
                } else {
                    player.say(ref world, format!("You put the {} inside {}", nouns[0].text, nouns[1].text));
                }
                return res;
            },
            InventoryItemActions::TakeOutItem => {
                // This is for taking an item from a specific container
                // Ex: "take out the sword from the bag"
                // Get the player's container
                let player_container: Option<Container> = get_player_container(@world, player, nouns);
                if player_container.is_none() {
                    // if it is not in the player, it means it is in an entity container
                    // that is on the room Ex: "take out the sword from the box"
                    let entity_container: Option<Container> = get_entity_container(@world, player, nouns);
                    if entity_container.is_none() {
                        return Result::Err(Error::NoContainer);
                    }
                    let container_component: Container = entity_container.unwrap();
                    let res: Result<(), Error> = container_component.put_item_out(ref world, ref self, player);
                    if res.is_err() {
                        player.say(ref world, format!("You cannot take {} from {} and place in the floor", nouns[0].text, nouns[1].text));
                    } else {
                        player.say(ref world, format!("You took {} from {} and placed in the floor", nouns[0].text, nouns[1].text));
                    }
                    return res;
                }
                let container_component: Container = player_container.unwrap();
                let res: Result<(), Error> = container_component.put_item_out(ref world, ref self, player);
                if res.is_err() {
                    player.say(ref world, format!("You cannot take {} from {} and place in the floor", nouns[0].text, nouns[1].text));
                } else {
                    player.say(ref world, format!("You took {} from {} and placed in the floor", nouns[0].text, nouns[1].text));
                }
                return res;
            },
        }
        // Result::Err(Error::ActionFailed) // Unreachable code
    }

    // used for tests only
    fn add_component(ref world: WorldStorage, inst: felt252) -> InventoryItem {
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
        inventory_item.store(ref world, 0);
        // Return the component
        (inventory_item)
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
    (action_token)
}

// @dev: wip get player's container
// This can be the an entity container attached to the player
// Ex: a bag in the player's personalinventory
fn get_player_container(
    world: @WorldStorage, player: @Player, nouns: Span<Token>,
) -> Option<Container> {
    let player_entity: Entity = player.entity(world);
    let player_children: Span<Entity> = player_entity.get_children(world, *player.game_id);
    let mut container: Option<@Entity> = Option::None;
    // match the noun wth the child name or alt_name
    for child in player_children {
        let text: @ByteArray = nouns.at(1).text;
        if (child.name == text || child.name_is(text)) {
            container = Option::Some(child);
            break;
        }
    };
    (match container {
        Option::Some(container) => {
            // get container component
            let player_container: Option<Container> = ContainerComponent::get_component(world, *container.inst, *player.game_id);
            (player_container)
        },
        Option::None => {
            return Option::None;
        },
    })
}

// @dev: wip get entity's container
// This can be the an entity container attached to the room
// Ex: a chest in the room
fn get_entity_container(
    world: @WorldStorage, player: @Player, nouns: Span<Token>,
) -> Option<Container> {
    // get room
    let room: Option<Entity> = player.get_room_entity(world);
    if room.is_none() {
        return Option::None;
    }
    let room_entity: Entity = EntityImpl::get_entity(world, room.unwrap().inst).unwrap();
    let room_children: Span<Entity> = room_entity.get_children(world, *player.game_id);
    let mut container: Option<@Entity> = Option::None;
    // match the noun wth the child name or alt_name
    for child in room_children {
        let text: @ByteArray = nouns.at(1).text;
        if (child.name == text || child.name_is(text)) {
            container = Option::Some(child);
            break;
        }
    };
    (match container {
        Option::Some(container) => {
            // get container component
            let room_container: Option<Container> = ContainerComponent::get_component(world, *container.inst, *player.game_id);
            (room_container)
        },
        Option::None => {
            return Option::None;
        },
    })
}
