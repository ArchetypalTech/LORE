use dojo::{world::WorldStorage, model::ModelStorage};

use lore::{
    components::{
        area::{AreaComponent}, exit::{ExitComponent}, inspectable::{InspectableComponent},
        inventoryItem::{InventoryItemComponent}, container::{ContainerComponent},
        player::{PlayerComponent, PlayerImpl, Player, PlayerTrait},
    },
    lib::{
        entity::{Entity, EntityImpl}, utils::ByteArrayTraitExt,
        variable_property::{VariablePropertyImp}, trigger::{Trigger, TriggerContext, TriggerImpl},
        condition::{Condition, ConditionImpl}, effect::{Effect, EffectImpl},
    },
    constants::{errors::Error},
};

#[derive(Clone, Drop, Serde, Debug, Introspect, PartialEq)]
#[dojo::model]
pub struct Action {
    /// Unique identifier attached to the entity
    #[key]
    pub inst: felt252,
    /// Unique identifier of the action
    #[key]
    pub key: felt252,
    /// Human-readable name for the editor
    pub name: ByteArray,
    /// Optional description
    pub description: ByteArray,
    /// For toggling the entire action
    pub is_enabled: bool,
    /// When this action can occur, the id's of the triggers. Key is (trigger.inst, trigger.key)
    pub trigger: Array<(felt252, felt252)>,
    /// What must be true, the id's of the conditions. Key is (condition.inst, condition.key)
    pub conditions: Array<(felt252, felt252)>,
    /// What happens when triggered, the id's of the effects. Key is (effect.inst, effect.key)
    pub effects: Array<(felt252, felt252)>,
    /// For searching/filtering
    pub tags: Array<ByteArray>,
    /// Whether the action has been executed
    pub executed: bool,
    /// In case action fails, need a response
    pub failing_response: Array<ByteArray>,
    /// In case action succeeds, need a response
    pub success_response: Array<ByteArray>,
}

// Implementation for processing actions
#[generate_trait]
pub impl ActionImpl of ActionTrait {
    fn register_action(mut world: WorldStorage, action: Action) -> Result<(), Error> {
        // 0. Check if action is already in the entity array
        let maybe_entity = EntityImpl::get_entity(@world, @action.inst);
        match maybe_entity {
            Option::Some(mut entity) => {
                // Check if action is already registered
                let mut found = false;
                for pos_action in entity.actions_keys.clone() {
                    if (action.key == pos_action) {
                        found = true;
                        break;
                    }
                };
                if found {
                    // If found just update the action
                    world.write_model(@action);
                    return Result::Ok(());
                }
            },
            Option::None => {},
        }
        // 1. Register action key in the entity
        let mut entity: Entity = EntityImpl::get_entity(@world, @action.inst).unwrap();
        entity.actions_keys.append(action.key);
        // 2. Update the entity
        world.write_model(@entity);
        // 3. Write the action
        world.write_model(@action);
        Result::Ok(())
    }

    fn unregister_action(mut world: WorldStorage, action: Action) -> Result<(), Error> {
        // 1. Remove the action
        world.erase_model(@action);
        Result::Ok(())
    }

    fn process_action(
        mut action: Action, mut world: WorldStorage, context: @TriggerContext,
    ) -> (Result<(), Error>, bool, Result<(), Error>) {
        let player_inst: felt252 = *context.doer;
        let player: Player = world.read_model(player_inst);
        if action.executed {
            // Action has already been executed, don't do anything
            // return condition as false.
            if player.use_debug {
                player.say(world, format!("Action has already been executed"));
            }
            return (Result::Ok(()), false, Result::Ok(()));
        }
        // Trigger
        let mut result_t: Result<(), Error> = Result::Ok(());
        //Conditions. We want to have the bool value as true in case there is no condition
        let mut result: bool = true;
        //Effects
        let mut result_e: Result<(), Error> = Result::Ok(());

        // First check if the trigger/s are valid
        for trigger_key in action.trigger.clone() {
            let trigger: Trigger = world.read_model(trigger_key);
            let result_opt = TriggerImpl::evaluate_trigger(world, trigger.clone());
            if player.use_debug {
                player
                    .say(world, format!("Result for trigger: {:?}, is: {:?}", trigger, result_opt));
            }
            if result_opt.is_err() {
                result_t = result_opt;
                break;
            }
        };

        // Then evaluate all conditions
        for condition_key in action.conditions.clone() {
            let condition: Condition = world.read_model(condition_key);
            result = condition.evaluate_condition(@world, context.clone());
            if player.use_debug {
                player
                    .say(world, format!("Result for condition: {:?}, is: {:?}", condition, result));
            }
            if !result {
                break; // If a single condition fails, break out of the loop
            }
        };

        // Finally execute all effects if conditions are met
        if result {
            for effect_key in action.effects.clone() {
                let effect: Effect = world.read_model(effect_key);
                let result_pos = effect.apply_effect(world, *context);
                if player.use_debug {
                    player
                        .say(
                            world, format!("Result for effect: {:?}, is: {:?}", effect, result_pos),
                        );
                }
                if result_pos.is_err() {
                    result_e = result_pos;
                }
            };
        } else {
            result_e = Result::Err(Error::ConditionFailed);
            // result_e = Result::Ok(()); // -> THIS IS FOR TESTING ONLY
        // println!("result_effect: {:?}, but effect is not applied as condition failed",
        // result_e);
        }
        // If all conditions are met, mark action as executed
        if (result_t.is_ok() && result && result_e.is_ok()) {
            action.executed = true;
            world.write_model(@action);
            for response in action.success_response.clone() {
                player.say(world, response);
            }
        } else {
            for response in action.failing_response.clone() {
                player.say(world, response);
            }
        }
        (result_t, result, result_e)
    }

    fn enable_action(mut self: Action, mut world: WorldStorage) {
        self.is_enabled = true;
        world.write_model(@self);
    }

    fn disable_action(mut self: Action, mut world: WorldStorage) {
        self.is_enabled = false;
        world.write_model(@self);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use dojo::{model::ModelStorage, world::WorldStorage};
    use lore::tests::helpers;
    use lore::{
        lib::{
            entity::{Entity, EntityImpl},
            trigger::{Trigger, TriggerType, TriggerImpl, TriggerParameter, TriggerContext},
            condition::{Condition, Operator}, effect::{Effect, EffectImpl},
            actions::{Action, ActionImpl}, variable_property::VariablePropertyImp,
            utils::ByteArrayTraitExt,
        },
        components::{
            area::{Area, AreaComponent}, exit::{Exit, ExitComponent, ExitActions, ActionMapExit},
            inspectable::{
                Inspectable, InspectableComponent, InspectableActions, ActionMapInspectable,
            },
            inventoryItem::{
                InventoryItem, InventoryItemComponent, InventoryItemActions, ActionMapInventoryItem,
            },
            container::{Container, ContainerComponent},
            player::{PlayerComponent, caller_as_player, PlayerImpl}, Components, Component,
        },
    };
    use lore::constants::constants::Direction;

    fn create_rooms(mut world: WorldStorage) -> (Entity, Entity) {
        // create room entity 1
        let mut room_entity_1 = EntityImpl::create_entity(world);
        world.write_model(@room_entity_1);
        // create room entity 2
        let mut room_entity_2 = EntityImpl::create_entity(world);
        world.write_model(@room_entity_2);

        // ROOM 1 //
        // add area component to room entity 1
        let mut area_component: Area = Component::add_component(world, room_entity_1.inst);
        area_component.is_area = true;
        area_component.store(world);
        // add exit component to room entity
        let mut exit_component_1: Exit = Component::add_component(world, room_entity_1.inst);
        exit_component_1.is_enterable = true;
        exit_component_1.leads_to = room_entity_2.inst;
        exit_component_1.direction_type = Direction::North;
        exit_component_1.store(world);

        // ROOM 2 //
        // add area component to room entity 2
        let mut area_component_2: Area = Component::add_component(world, room_entity_2.inst);
        area_component_2.is_area = true;
        area_component_2.store(world);

        // return room entities
        (room_entity_1, room_entity_2)
    }

    fn create_door(mut world: WorldStorage, leads_to: felt252, direction: Direction) -> Entity {
        // create door entity
        let mut door = EntityImpl::create_entity(world);
        door.name = "door";
        world.write_model(@door);
        // add inspectable component to door
        let mut inspectable: Inspectable = Component::add_component(world, door.inst);
        inspectable.is_inspectable = true;
        inspectable.is_visible = true;
        inspectable.description = array!["A door"];
        inspectable
            .action_map =
                array![
                    ActionMapInspectable {
                        action: "show",
                        inst: 0,
                        action_fn: InspectableActions::SetVisible,
                        entrypoint: 0,
                    },
                    ActionMapInspectable {
                        action: "look",
                        inst: 0,
                        action_fn: InspectableActions::ReadRandomDescription,
                        entrypoint: 1,
                    },
                ];
        inspectable.store(world);
        // add exit component to door
        let mut exit_component: Exit = Component::add_component(world, door.inst);
        exit_component.is_exit = true;
        exit_component.is_enterable = false;
        exit_component.leads_to = leads_to;
        exit_component.direction_type = direction;
        exit_component
            .action_map =
                array![
                    ActionMapExit { action: "go", inst: 0, action_fn: ExitActions::UseExit },
                    ActionMapExit { action: "enter", inst: 0, action_fn: ExitActions::UseExit },
                    ActionMapExit { action: "use", inst: 0, action_fn: ExitActions::UseExit },
                ];
        exit_component.store(world);

        // return door entity
        door
    }

    fn create_item(mut world: WorldStorage, owner_id: felt252) -> Entity {
        // create item entity
        let mut item = EntityImpl::create_entity(world);
        item.name = "ball";
        item.alt_names = array!["ball"];
        world.write_model(@item);
        // add inspectable component to item
        let mut inspectable: Inspectable = Component::add_component(world, item.inst);
        inspectable.is_inspectable = true;
        inspectable.is_visible = true;
        inspectable.description = array!["A ball"];
        inspectable
            .action_map =
                array![
                    ActionMapInspectable {
                        action: "show",
                        inst: 0,
                        action_fn: InspectableActions::SetVisible,
                        entrypoint: 0,
                    },
                    ActionMapInspectable {
                        action: "look",
                        inst: 0,
                        action_fn: InspectableActions::ReadRandomDescription,
                        entrypoint: 1,
                    },
                ];
        inspectable.store(world);
        // add inventory item component to item
        let mut inventory_item: InventoryItem = Component::add_component(world, item.inst);
        inventory_item.owner_id = owner_id;
        inventory_item.is_inventory_item = true;
        inventory_item.can_be_picked_up = true;
        inventory_item.can_go_in_container = true;
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
        inventory_item.multiple_use = true;
        inventory_item.store(world);

        // return item entity
        item
    }

    fn create_test_trigger(
        inst: felt252, key: felt252, nameT: ByteArray, trigger_type: TriggerType,
    ) -> Trigger {
        Trigger {
            inst,
            key,
            name: nameT,
            trigger_type,
            parameters: array![TriggerParameter { name: "area", value: inst }],
            is_enabled: true,
            is_once: false,
            was_triggered: false,
        }
    }

    fn create_test_condition(
        inst: felt252,
        key: felt252,
        target: felt252,
        component: Components,
        property: ByteArray,
        operator: Operator,
        value: Array<felt252>,
    ) -> Condition {
        Condition { inst, key, target, component, property, operator, value }
    }

    fn create_test_effect(
        inst: felt252,
        key: felt252,
        target: felt252,
        component: Components,
        property: ByteArray,
        value: Array<ByteArray>,
    ) -> Effect {
        Effect { inst, key, target, component, property, value }
    }

    fn create_test_action(
        inst: felt252,
        key: felt252,
        name: ByteArray,
        description: ByteArray,
        is_enabled: bool,
        trigger: Array<(felt252, felt252)>,
        conditions: Array<(felt252, felt252)>,
        effects: Array<(felt252, felt252)>,
        tags: Array<ByteArray>,
        executed: bool,
        failing_response: Array<ByteArray>,
        success_response: Array<ByteArray>,
    ) -> Action {
        Action {
            inst,
            key,
            name,
            description,
            is_enabled,
            trigger,
            conditions,
            effects,
            tags,
            executed,
            failing_response,
            success_response,
        }
    }

    fn create_test_trigger_context(
        doer: felt252, target1: felt252, target2: felt252, inventory_object: felt252,
    ) -> TriggerContext {
        TriggerContext { doer, target1, target2, inventory_object }
    }

    fn register_variable_properties(ref world: WorldStorage) {
        VariablePropertyImp::register_component_properties(ref world, Components::Area);
        VariablePropertyImp::register_component_properties(ref world, Components::Exit);
        VariablePropertyImp::register_component_properties(ref world, Components::Inspectable);
        VariablePropertyImp::register_component_properties(ref world, Components::InventoryItem);
        VariablePropertyImp::register_component_properties(ref world, Components::Container);
        VariablePropertyImp::register_component_properties(ref world, Components::Player);
        VariablePropertyImp::register_component_properties(ref world, Components::Area);
        VariablePropertyImp::register_component_properties(ref world, Components::Container);
        VariablePropertyImp::register_component_properties(ref world, Components::Inspectable);
    }

    #[test]
    // Trigger: player1 enters room 2
    // Condition: player1 has item
    // Effect: door description and exit.is_enterable changes
    // However player1 does not have item
    // Result: door description and exit.is_enterable should not be updated
    fn test_enter_room_without_item() {
        let (mut world, _, _, player_1, _) = helpers::setup_core();

        // create rooms
        let (room_1, room_2) = create_rooms(world);

        // create door entity in room 2 that leads to room 1 via south
        let mut door = create_door(world, room_1.inst, Direction::South);
        door.set_parent(world, @room_2);

        // create item that is in room 1
        let mut item = create_item(world, room_1.inst);
        item.set_parent(world, @room_1);

        // create player
        let mut player1 = caller_as_player(world, player_1);
        world.write_model(@player1);

        // Register variable properties
        register_variable_properties(ref world);

        // TRIGGER that jumps when an action is executed
        let t_key: felt252 = 1;
        // create trigger for when entering room 2
        let mut trigger = create_test_trigger(
            room_2.inst, t_key, "TestTrigger", TriggerType::PlayerEntersArea,
        );
        let _result = TriggerImpl::register_trigger(world, trigger.clone());

        // CONDITION that checks if player has item
        let property: ByteArray = "owner_id";
        let c_key: felt252 = 1;
        let mut array: Array<felt252> = ArrayTrait::new();
        array.append(player1.inst);
        // create condition for when player has item
        let mut condition = create_test_condition(
            room_2.inst,
            c_key,
            item.inst,
            Components::InventoryItem,
            property,
            Operator::Equals,
            array,
        );
        world.write_model(@condition);

        // EFFECT TO APPLY WHEN PLAYER1 HAS ITEM
        // New Description door -> Inspectable
        // 1. New description as bytearray
        let new_txt1: ByteArray = "A door that is open";
        let new_txt2: ByteArray = "Looks that it leads somewhere";
        // 2. Create array of the new description
        let new_description: Array<ByteArray> = array![new_txt1, new_txt2];

        // New is_enterable -> Exit
        // 1. New value as bytearray
        let enterable: ByteArray = "true";
        // 2. Create array of the new value
        let new_enterable: Array<ByteArray> = array![enterable];

        // Properties as bytearray
        let property: ByteArray = "description";
        let property2: ByteArray = "is_enterable";

        let e_key: felt252 = 1;
        let e_key2: felt252 = 2;

        // Create effects
        let mut effect = create_test_effect(
            door.inst, e_key, door.inst, Components::Inspectable, property, new_description.clone(),
        );
        let mut effect2 = create_test_effect(
            door.inst, e_key2, door.inst, Components::Exit, property2, new_enterable,
        );
        world.write_model(@effect);
        world.write_model(@effect2);

        // TODO: create action
        let a_key: felt252 = 90527;
        let act_name: ByteArray = "TestAction";
        let act_desc: ByteArray = "TestActionDesc";
        let mut triggers: Array<(felt252, felt252)> = ArrayTrait::new();
        let mut conditions: Array<(felt252, felt252)> = ArrayTrait::new();
        let mut effects: Array<(felt252, felt252)> = ArrayTrait::new();
        triggers.append((trigger.inst, trigger.key));
        conditions.append((condition.inst, condition.key));
        effects.append((effect.inst, effect.key));
        effects.append((effect2.inst, effect2.key));
        let tags: Array<ByteArray> = array!["TestAction"];
        let mut failing_response: Array<ByteArray> = array![
            "Testing failure response", "Testing failure response 2",
        ];
        let mut success_response: Array<ByteArray> = array![
            "Testing success response", "Testing success response 2",
        ];
        let mut action = create_test_action(
            room_2.inst,
            a_key,
            act_name,
            act_desc,
            true,
            triggers,
            conditions,
            effects,
            tags,
            false,
            failing_response,
            success_response,
        );
        // Register the action
        let _res = ActionImpl::register_action(world, action.clone());

        // create trigger context
        let mut context: TriggerContext = create_test_trigger_context(
            player1.inst, door.inst, 0, item.inst,
        );

        // EXECUTE ACTION
        // 1. move player to room 2
        player1.move_to_room(world, room_2.inst);
        // 2. Execute action
        let (trig_res, cond_res, eff_res) = ActionImpl::process_action(action, world, @context);
        // // The one below are for testing individually
        //let trig_res = TriggerImpl::evaluate_trigger(world, @trigger);
        //let cond_res = condition.evaluate_condition(@world, context);
        //let eff_res1 = effect.apply_effect(world, context);
        //let eff_res2 = effect2.apply_effect(world, context);

        // ASSERT //
        // 1. Trigger should jump
        assert(trig_res.is_ok(), 'Trigger should jump');
        // 2. Condition should fail as player does not have item
        assert((cond_res == false), 'Condition should fail');
        // 3. Effects should fail as condition is not met
        assert(eff_res.is_err(), 'Effects should fail');
        //assert(eff_res1.is_err(), 'Effects should fail');
        //assert(eff_res2.is_err(), 'Effects2 shoul fail');

        // 3. Effects should not be update
        let upd_door: Inspectable = world.read_model(door.inst);
        let upd_door_exit: Exit = world.read_model(door.inst);
        let new_text1 = new_description.at(0);
        let _new_text2 = new_description.at(1);
        assert_ne!(
            upd_door.description[0].clone(),
            new_text1.clone(),
            "Description1 should not be updated",
        );
        // This one fails as there is no index 1 in the array
        //assert_ne!(upd_door.description[1].clone(), new_text2, "Description2 should not be
        //updated");
        assert(upd_door_exit.is_enterable == false, 'Exit should not be updated');
    }

    #[test]
    // Trigger: player1 enters room 2
    // Condition: player1 has item
    // Effect: door description and exit.is_enterable changes
    fn test_enter_room_with_item() {
        let (mut world, _, _, player_1, _) = helpers::setup_core();

        // create rooms
        let (room_1, room_2) = create_rooms(world);

        // create door entity in room 2 that leads to room 1 via south
        let mut door = create_door(world, room_1.inst, Direction::South);
        door.set_parent(world, @room_2);
        let _old_inspectable: Inspectable = world.read_model(door.inst);
        let _old_exit: Exit = world.read_model(door.inst);

        // create item that is in room 1
        let mut item = create_item(world, room_1.inst);
        item.set_parent(world, @room_1);

        // create player
        let mut player1 = caller_as_player(world, player_1);
        world.write_model(@player1);
        let player_entity: Entity = EntityImpl::get_entity(@world, @player1.inst).unwrap();
        let mut player_container: Container = Component::add_component(world, player_entity.inst);
        player_container.is_container = true;
        player_container.can_be_opened = true;
        player_container.can_receive_items = true;
        player_container.is_open = true;
        player_container.num_slots = 2;
        player_container.store(world);

        // Register variable properties
        register_variable_properties(ref world);

        // TRIGGER that jumps when an action is executed
        // create trigger for when entering room 2
        let t_key: felt252 = 1;
        let mut trigger = create_test_trigger(
            room_2.inst, t_key, "TestTrigger", TriggerType::PlayerEntersArea,
        );
        let _result = TriggerImpl::register_trigger(world, trigger.clone());

        // CONDITION that checks if player has item
        let property: ByteArray = "owner_id";
        let c_key: felt252 = 1;
        let mut array: Array<felt252> = ArrayTrait::new();
        array.append(player1.inst);
        // create condition for when player has item
        let mut condition = create_test_condition(
            room_2.inst,
            c_key,
            item.inst,
            Components::InventoryItem,
            property,
            Operator::Equals,
            array,
        );
        world.write_model(@condition);

        // EFFECT TO APPLY WHEN PLAYER1 HAS ITEM
        // New Description door -> Inspectable
        // 1. New description as bytearray
        let new_txt1: ByteArray = "A door that is open";
        let new_txt2: ByteArray = "Looks that it leads somewhere";
        // 2. Create array of the new description
        let new_description: Array<ByteArray> = array![new_txt1, new_txt2];

        // New is_enterable -> Exit
        // 1. New value as ByteArray
        let enterable: ByteArray = "true";
        // 2. Create array of the new value
        let new_enterable: Array<ByteArray> = array![enterable];

        // Properties as bytearray
        let property: ByteArray = "description";
        let property2: ByteArray = "is_enterable";

        let e_key: felt252 = 1;
        let e_key2: felt252 = 2;

        // Create effects
        let mut effect = create_test_effect(
            door.inst, e_key, door.inst, Components::Inspectable, property, new_description.clone(),
        );
        let mut effect2 = create_test_effect(
            door.inst, e_key2, door.inst, Components::Exit, property2, new_enterable.clone(),
        );
        world.write_model(@effect);
        world.write_model(@effect2);

        // TODO: create action
        let a_key: felt252 = 90527;
        let act_name: ByteArray = "TestAction";
        let act_desc: ByteArray = "TestActionDesc";
        let mut triggers: Array<(felt252, felt252)> = ArrayTrait::new();
        let mut conditions: Array<(felt252, felt252)> = ArrayTrait::new();
        let mut effects: Array<(felt252, felt252)> = ArrayTrait::new();
        triggers.append((trigger.inst, trigger.key));
        conditions.append((condition.inst, condition.key));
        effects.append((effect.inst, effect.key));
        effects.append((effect2.inst, effect2.key));
        let tags: Array<ByteArray> = array!["TestAction"];
        let mut failing_response: Array<ByteArray> = array![
            "Testing failure response", "Testing failure response 2",
        ];
        let mut success_response: Array<ByteArray> = array![
            "Testing success response", "Testing success response 2",
        ];
        let mut action = create_test_action(
            room_1.inst,
            a_key,
            act_name,
            act_desc,
            true,
            triggers,
            conditions,
            effects,
            tags,
            false,
            failing_response,
            success_response,
        );
        // Register the action
        let _result = ActionImpl::register_action(world, action.clone());

        // create trigger context
        let mut context: TriggerContext = create_test_trigger_context(
            player1.inst, door.inst, 0, item.inst,
        );

        // EXECUTE ACTION
        // 1. move player to room 1
        player1.location = room_1.inst;
        player1.store(world);
        player1.move_to_room(world, room_1.inst);
        let player_entity: Entity = EntityImpl::get_entity(@world, @player1.inst).unwrap();

        // 2. Pickup item
        item.set_parent(world, @player_entity);
        let player_container: Container = world.read_model(player1.inst);
        let mut itemInv: InventoryItem = world.read_model(item.inst);
        itemInv.owner_id = player_container.inst;
        itemInv.store(world);
        // 3. Check if item is owned by player1
        assert(itemInv.owner_id == player_container.inst, 'Item should be owned by player1');
        // 4. Move player to room 2
        player1.move_to_room(world, room_2.inst);
        // 5. Execute action
        let (trig_res, cond_res, eff_res) = ActionImpl::process_action(action, world, @context);
        // // The one below are for testing individually
        //let trig_res = TriggerImpl::evaluate_trigger(world, @trigger);
        //let cond_res = condition.evaluate_condition(@world, context);
        //let eff_res1 = effect.apply_effect(world, context);
        //let eff_res2 = effect2.apply_effect(world, context);

        // ASSERT //
        // 1. Trigger should jump
        assert(trig_res.is_ok(), 'Trigger should jump');
        // 2. Condition should fail as player does not have item
        assert((cond_res == true), 'Condition should be true');
        // 3. Effects should fail as condition is not met
        assert(eff_res.is_ok(), 'Effects should pass');
        //assert(eff_res1.is_err(), 'Effects should fail');
        //assert(eff_res2.is_err(), 'Effects2 shoul fail');

        // 3. Effects should be update
        let upd_door: Inspectable = world.read_model(door.inst);
        let upd_door_exit: Exit = world.read_model(door.inst);
        let new_text1 = new_description.at(0);
        let new_text2 = new_description.at(1);
        assert_eq!(
            upd_door.description[0].clone(), new_text1.clone(), "Description1 should be updated",
        );
        assert_eq!(
            upd_door.description[1].clone(), new_text2.clone(), "Description2 should be updated",
        );
        assert(upd_door_exit.is_enterable == true, 'Exit should be updated');
        // println!("Old description: {:?}", old_inspectable.description);
    // println!("New description: {:?}", array![new_text1, new_text2]);
    // println!("Old is_enterable: {:?}", old_exit.is_enterable);
    // println!("New is_enterable: {:?}", new_enterable);
    }
}
