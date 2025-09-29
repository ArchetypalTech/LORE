use dojo::{world::WorldStorage, model::{ModelStorage, Model}};
use lore::{
    models::{
        entity::{Entity, EntityImpl},
        player::{Player, PlayerImpl},
        effect::{Effect, EffectImpl},
        condition::{Condition, ConditionImpl},
        trigger::{Trigger, TriggerImpl},
    },
    types::action_type::{TriggerContext},
    lib::{
        utils::ByteArrayTraitExt,
        variable_property_helper::{VariablePropertyHelper},
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
    /// Properties ///
    /// Name of the action
    pub name: ByteArray,
    /// Optional description
    pub description: ByteArray,
    /// For toggling the entire action
    pub is_enabled: bool,
    /// Executor, to know if the action is called by the correct entity
    pub executor: felt252,
    /// When this action can occur, the id's of the triggers. Key is (trigger.inst, trigger.key)
    pub trigger: Array<(felt252, felt252)>,
    /// What must be true, the id's of the conditions. Key is (condition.inst, condition.key)
    pub conditions: Array<(felt252, felt252)>,
    /// What happens when triggered, the id's of the effects. Key is (effect.inst, effect.key)
    pub effects: Array<(felt252, felt252)>,
    /// For searching/filtering
    pub tags: Array<ByteArray>,
    /// In case action fails, need a response
    pub failing_response: Array<ByteArray>,
    /// In case action succeeds, need a response
    pub success_response: Array<ByteArray>,
}

// Action execution status per game instance
#[derive(Copy, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct ActionExecuted {
    /// The game instance
    #[key]
    pub game_id: u128,
    /// Action identifier
    #[key]
    pub inst: felt252,
    /// Unique identifier of the action
    #[key]
    pub key: felt252,
    /// Properties ///
    pub is_executed: bool,
}


//---------------------------------
// Model Trait
//
#[generate_trait]
pub impl ActionImpl of ActionTrait {
    fn register_action(ref world: WorldStorage, action: @Action) -> Result<(), Error> {
        // 0. Check if action is already in the entity array
        let maybe_entity = EntityImpl::get_entity(@world, *action.inst);
        match maybe_entity {
            Option::Some(mut entity) => {
                // Check if action is already registered
                let mut found = false;
                for pos_action in entity.actions_keys.clone() {
                    if (*action.key == pos_action) {
                        found = true;
                        break;
                    }
                };
                if found {
                    // If found just update the action
                    world.write_model(action);
                    return Result::Ok(());
                }
            },
            Option::None => {},
        }
        // 1. Register action key in the entity
        let mut entity: Entity = EntityImpl::get_entity(@world, *action.inst).unwrap();
        entity.actions_keys.append(*action.key);
        // 2. Update the entity
        world
            .write_member(
                Model::<Entity>::ptr_from_keys(entity.inst),
                selector!("actions_keys"),
                entity.actions_keys,
            );
        // world.write_model(@entity);
        // 3. Write the action
        world.write_model(action);
        Result::Ok(())
    }

    fn unregister_action(ref world: WorldStorage, action: @Action) -> Result<(), Error> {
        // 1. Remove the action
        world.erase_model(action);
        Result::Ok(())
    }

    fn process_action(
        mut self: Action, ref world: WorldStorage, player: @Player, context: @TriggerContext,
    ) -> (Result<(), Error>, bool, Result<(), Error>) {
        if self.is_executed(@world, *player.game_id) {
            // Action has already been executed, don't do anything
            // return a player.say
            player.say(ref world, format!("It seems that your memory is not working well as you have already done this. However, here is the result again:"));
            // return all success responses
            for response in self.success_response.clone() {
                player.say(ref world, response);
            }
            // return condition as false.
            if *player.use_debug {
                player.log_debug(ref world, format!("Action has already been executed"));
            }
            return (Result::Ok(()), false, Result::Ok(()));
        }
        // Check if the action is called by the correct entity
        if self.executor != *context.inventory_object {
            if *player.use_debug {
                player.log_debug(ref world, format!("Action is not called by the correct entity"));
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
        for trigger_key in self.trigger.clone() {
            let trigger: @Trigger = @world.read_model(trigger_key);
            let result_opt = trigger.evaluate_trigger(ref world, *player.game_id);
            if *player.use_debug {
                player
                    .log_debug(ref world, format!("Result for trigger: {:?}, is: {:?}", trigger, result_opt));
            }
            if result_opt.is_err() {
                result_t = result_opt;
                break;
            }
        };

        // Then evaluate all conditions
        for condition_key in self.conditions.clone() {
            let condition: Condition = world.read_model(condition_key);
            result = condition.evaluate_condition(@world, context, *player.game_id);
            if *player.use_debug {
                player
                    .log_debug(ref world, format!("Result for condition: {:?}, is: {:?}", condition, result));
            }
            if !result {
                break; // If a single condition fails, break out of the loop
            }
        };

        // Finally execute all effects if triggers and conditions are met
        if result_t.is_ok() && result {
            for effect_key in self.effects.clone() {
                let effect: Effect = world.read_model(effect_key);
                let result_pos = effect.apply_effect(ref world, context, *player.game_id);
                if *player.use_debug {
                    player
                        .log_debug(
                            ref world, format!("Result for effect: {:?}, is: {:?}", effect, result_pos),
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
            // Set action as executed
            self.set_executed(ref world, *player.game_id, true);
            // Set triggers as executed
            for trigger_key in self.trigger.clone() {
                let trigger: @Trigger = @world.read_model(trigger_key);
                trigger.set_executed(ref world, *player.game_id, true);
            }
            for response in self.success_response.clone() {
                player.say(ref world, response);
            }
        } else {
            for response in self.failing_response.clone() {
                player.say(ref world, response);
            }
        }
        (result_t, result, result_e)
    }

    fn is_executed(self: @Action, world: @WorldStorage, game_id: u128) -> bool {
        (world.read_member(Model::<ActionExecuted>::ptr_from_keys((game_id, *self.inst, *self.key),), selector!("is_executed")))
    }

    fn set_executed(self: @Action, ref world: WorldStorage, game_id: u128, is_executed: bool) {
        world.write_model(@ActionExecuted {
            game_id,
            inst: *self.inst,
            key: *self.key,
            is_executed,
        });
    }

    // fn enable_action(mut self: Action, mut world: WorldStorage) {
    //     self.is_enabled = true;
    //     world
    //         .write_member(
    //             Model::<Action>::ptr_from_keys((self.inst, self.key)),
    //             selector!("is_enabled"),
    //             self.is_enabled,
    //         );
    //     // world.write_model(@self);
    // }

    // fn disable_action(mut self: Action, mut world: WorldStorage) {
    //     self.is_enabled = false;
    //     world
    //         .write_member(
    //             Model::<Action>::ptr_from_keys((self.inst, self.key)),
    //             selector!("is_enabled"),
    //             self.is_enabled,
    //         );
    //     // world.write_model(@self);
    // }
}

#[cfg(test)]
mod tests {
    use super::*;
    use dojo::{model::ModelStorage, world::WorldStorage};
    use lore::tests::helpers;
    use lore::{
        models::{
            entity::{Entity, EntityImpl},
            description_text::{DescriptionText},
            action::{Action, ActionImpl},
            area::{Area},
            exit::{Exit},
            inventory_item::{InventoryItem},
            container::{Container},
            player::{PlayerImpl},
            components::{Component},
            reactable::{Reactable},
            trigger::{Trigger, TriggerImpl},
            condition::{Condition},
            effect::{Effect, EffectImpl},
            game_instance::{GameModelImpl, GameModelKeyImpl},
        },
        types::{
            component_type::{
                ComponentType, ExitActions, ActionMapExit, ReactableActions, ActionMapReactable,
                InventoryItemActions, ActionMapInventoryItem,
            },
            action_type::{TriggerType, TriggerContext, Operator, EffectType},
            direction_type::Direction,
        },
        lib::{
            variable_property_helper::{VariablePropertyHelper},
            utils::ByteArrayTraitExt,
        },
    };

    fn create_rooms(ref world: WorldStorage) -> (Entity, Entity) {
        // create room entity 1
        let mut room_entity_1 = EntityImpl::create_entity(ref world, "room_entity_1");
        world.write_model(@room_entity_1);
        // create room entity 2
        let mut room_entity_2 = EntityImpl::create_entity(ref world, "room_entity_2");
        world.write_model(@room_entity_2);

        // ROOM 1 //
        // add area component to room entity 1
        let mut area_component: Area = Component::add_component(ref world, room_entity_1.inst);
        area_component.is_area = true;
        area_component.store(ref world, 0);
        // add exit component to room entity
        let mut exit_component_1: Exit = Component::add_component(ref world, room_entity_1.inst);
        exit_component_1.is_enterable = true;
        exit_component_1.leads_to = room_entity_2.inst;
        exit_component_1.direction_type = Direction::North;
        exit_component_1.store(ref world, 0);

        // ROOM 2 //
        // add area component to room entity 2
        let mut area_component_2: Area = Component::add_component(ref world, room_entity_2.inst);
        area_component_2.is_area = true;
        area_component_2.store(ref world, 0);

        // return room entities
        (room_entity_1, room_entity_2)
    }

    fn create_door(ref world: WorldStorage, leads_to: felt252, direction: Direction) -> Entity {
        // create door entity
        let mut door = EntityImpl::create_entity(ref world, "door");
        world.write_model(@door);
        // add reactable component to door
        let mut reactable: Reactable = Component::add_component(ref world, door.inst);
        let desc1: DescriptionText = DescriptionText { inst: door.inst, key: 0, text: "A door" };
        world.write_model(@desc1);
        reactable.is_reactable = true;
        reactable.is_visible = true;
        reactable.description = array![0];
        reactable
            .action_map =
                array![
                    ActionMapReactable {
                        action: "show",
                        inst: 0,
                        action_fn: ReactableActions::SetVisible,
                        entrypoints: (0, 0),
                    },
                    ActionMapReactable {
                        action: "look",
                        inst: 0,
                        action_fn: ReactableActions::ReadRandomDescription,
                        entrypoints: (1, 1),
                    },
                ];
        reactable.store(ref world, 0);
        // add exit component to door
        let mut exit_component: Exit = Component::add_component(ref world, door.inst);
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
        exit_component.store(ref world, 0);

        // return door entity
        door
    }

    fn create_item(ref world: WorldStorage, owner_id: felt252) -> Entity {
        // create item entity
        let mut item = EntityImpl::create_entity(ref world, "ball");
        item.alt_names = array!["ball"];
        world.write_model(@item);
        // add reactable component to item
        let mut reactable: Reactable = Component::add_component(ref world, item.inst);
        let desc1: DescriptionText = DescriptionText { inst: item.inst, key: 0, text: "A ball" };
        world.write_model(@desc1);
        reactable.is_reactable = true;
        reactable.is_visible = true;
        reactable.description = array![0];
        reactable
            .action_map =
                array![
                    ActionMapReactable {
                        action: "show",
                        inst: 0,
                        action_fn: ReactableActions::SetVisible,
                        entrypoints: (0, 0),
                    },
                    ActionMapReactable {
                        action: "look",
                        inst: 0,
                        action_fn: ReactableActions::ReadRandomDescription,
                        entrypoints: (1, 1),
                    },
                ];
        reactable.store(ref world, 0);
        // add inventory item component to item
        let mut inventory_item: InventoryItem = Component::add_component(ref world, item.inst);
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
        inventory_item.store(ref world, 0);

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
            is_enabled: true,
            is_once: false,
        }
    }

    fn create_test_condition(
        inst: felt252,
        key: felt252,
        name: ByteArray,
        target: felt252,
        component: ComponentType,
        property: ByteArray,
        operator: Operator,
        value: Array<felt252>,
    ) -> Condition {
        Condition { inst, key, name, target, component, property, operator, value }
    }

    fn create_test_effect(
        inst: felt252,
        key: felt252,
        name: ByteArray,
        target: felt252,
        effect_type: EffectType,
        component: ComponentType,
        property: ByteArray,
        value: Array<(ByteArray, u32)>,
        n_value: u32,
        hex_value: felt252,
    ) -> Effect {
        Effect {
            inst, key, name, target, effect_type, component, property, value, n_value, hex_value,
        }
    }

    fn create_test_action(
        inst: felt252,
        key: felt252,
        name: ByteArray,
        description: ByteArray,
        is_enabled: bool,
        executor: felt252,
        trigger: Array<(felt252, felt252)>,
        conditions: Array<(felt252, felt252)>,
        effects: Array<(felt252, felt252)>,
        tags: Array<ByteArray>,
        failing_response: Array<ByteArray>,
        success_response: Array<ByteArray>,
    ) -> Action {
        Action {
            inst,
            key,
            name,
            description,
            is_enabled,
            executor,
            trigger,
            conditions,
            effects,
            tags,
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
        VariablePropertyHelper::register_component_properties(ref world, ComponentType::Area);
        VariablePropertyHelper::register_component_properties(ref world, ComponentType::Exit);
        VariablePropertyHelper::register_component_properties(ref world, ComponentType::Reactable);
        VariablePropertyHelper::register_component_properties(ref world, ComponentType::InventoryItem);
        VariablePropertyHelper::register_component_properties(ref world, ComponentType::Container);
        VariablePropertyHelper::register_component_properties(ref world, ComponentType::Player);
        VariablePropertyHelper::register_component_properties(ref world, ComponentType::Area);
        VariablePropertyHelper::register_component_properties(ref world, ComponentType::Container);
        VariablePropertyHelper::register_component_properties(ref world, ComponentType::Reactable);
    }

    #[test]
    // Trigger: player1 enters room 2
    // Condition: player1 has item
    // Effect: door description and exit.is_enterable changes
    // However player1 does not have item
    // Result: door description and exit.is_enterable should not be updated
    fn test_enter_room_without_item() {
        let (mut world, _, _, _, player_1, _) = helpers::setup_core();

        // create rooms
        let (room_1, room_2) = create_rooms(ref world);

        // create door entity in room 2 that leads to room 1 via south
        let mut door = create_door(ref world, room_1.inst, Direction::South);
        door.set_parent(ref world, @room_2, 0);
        let old_insp_door: Reactable = world.read_model(door.inst);
        let old_key: u32 = *old_insp_door.description.at(0);
        let _old_txt: DescriptionText = world.read_model((door.inst, old_key));

        // create item that is in room 1
        let mut item = create_item(ref world, room_1.inst);
        item.set_parent(ref world, @room_1, 0);

        // create player
        let game_id: u128 = 123;
        let mut player1 = PlayerImpl::caller_as_player(ref world, player_1, game_id);
        world.write_model(@player1);

        // Register variable properties
        register_variable_properties(ref world);

        // TRIGGER that jumps when an action is executed
        let t_key: felt252 = 1;
        // create trigger for when entering room 2
        let mut trigger = @create_test_trigger(
            room_2.inst, t_key, "TestTrigger", TriggerType::OnEnter,
        );
        let _result = TriggerImpl::register_trigger(ref world, trigger);

        // CONDITION that checks if player has item
        let property: ByteArray = "owner_id";
        let c_key: felt252 = 1;
        let c_name1: ByteArray = "Condition name1";
        let mut array: Array<felt252> = ArrayTrait::new();
        array.append(player1.inst);
        // create condition for when player has item
        let mut condition = create_test_condition(
            room_2.inst,
            c_key,
            c_name1,
            item.inst,
            ComponentType::InventoryItem,
            property,
            Operator::Equals,
            array,
        );
        world.write_model(@condition);

        // EFFECT TO APPLY WHEN PLAYER1 HAS ITEM
        // New Description door -> Reactable
        // 1. New description as bytearray
        let new_txt1: ByteArray = "A door that is open";
        let idx1: u32 = 0;
        let new_txt2: ByteArray = "Looks that it leads nowhere";
        let idx2: u32 = 1;
        // 2. Create array of the new description
        let new_description: Array<(ByteArray, u32)> = array![
            (new_txt1.clone(), idx1), (new_txt2.clone(), idx2),
        ];

        // New is_enterable -> Exit
        // 1. New value as bytearray
        let enterable: ByteArray = "true";
        // 2. Create array of the new value
        let new_enterable: Array<(ByteArray, u32)> = array![(enterable, 0)];

        // Properties as bytearray
        let property: ByteArray = "description";
        let property2: ByteArray = "is_enterable";

        let e_key: felt252 = 1;
        let e_key2: felt252 = 2;

        let name: ByteArray = "Effect name";
        let name2: ByteArray = "Effect name2";
        let hex_value: felt252 = 0;

        // Create effects
        let mut effect = create_test_effect(
            door.inst,
            e_key,
            name,
            door.inst,
            EffectType::ModifyProperty,
            ComponentType::Reactable,
            property,
            new_description.clone(),
            0,
            hex_value,
        );
        let mut effect2 = create_test_effect(
            door.inst,
            e_key2,
            name2,
            door.inst,
            EffectType::ModifyProperty,
            ComponentType::Exit,
            property2,
            new_enterable,
            0,
            hex_value,
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
        triggers.append((*trigger.inst, *trigger.key));
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

        let mut action = @create_test_action(
            room_2.inst,
            a_key,
            act_name,
            act_desc,
            true,
            item.inst,
            triggers,
            conditions,
            effects,
            tags,
            failing_response,
            success_response,
        );
        // Register the action
        let _res = ActionImpl::register_action(ref world, action);
        assert(!action.is_executed(@world, game_id), 'action not executed yet');

        // create trigger context
        let mut context: TriggerContext = create_test_trigger_context(
            player1.inst, door.inst, 0, item.inst,
        );

        // EXECUTE ACTION
        // 1. move player to room 2
        player1.move_to_room(ref world, room_2.inst);
        // 2. Execute action
        let (trig_res, cond_res, eff_res) = action.clone().process_action(ref world, @player1, @context);
        // // The one below are for testing individually
        //let trig_res = trigger.evaluate_trigger(ref world, game_id);
        //let cond_res = condition.evaluate_condition(@world, context);
        //let eff_res1 = effect.apply_effect(ref world, context, game_id);
        //let eff_res2 = effect2.apply_effect(ref world, context, game_id);

        // ASSERT //
        // 1. Trigger should jump
        assert(trig_res.is_ok(), 'Trigger should jump');
        // 2. Condition should fail as player does not have item
        assert((cond_res == false), 'Condition should fail');
        // 3. Effects should fail as condition is not met
        assert(eff_res.is_err(), 'Effects should fail');
        //assert(eff_res1.is_err(), 'Effects should fail');
        //assert(eff_res2.is_err(), 'Effects2 shoul fail');
        // 4. failed, not executed
        assert(!action.is_executed(@world, game_id), 'action executed');

        // 3. Effects should not be update
        let upd_door: Reactable = world.read_game_model(door.inst, game_id);
        let upd_door_exit: Exit = world.read_game_model(door.inst, game_id);
        let key1: u32 = *upd_door.description.at(0);
        // let key2: u32 = *new_description.at(1);
        let new_text1: DescriptionText = world.read_model((upd_door.inst, key1));
        let new_game_text1: DescriptionText = world.read_game_model_key(upd_door.inst, key1, game_id);
        // let _new_text2: DescriptionText = world.read_model((upd_door.inst, key2));
        assert_ne!(new_txt1.clone(), new_text1.text.clone(), "Description1 should not be updated");
        assert_ne!(new_txt1.clone(), new_game_text1.text.clone(), "Description1 should not be updated");
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
        let (mut world, _, _, _, player_1, _) = helpers::setup_core();

        // create rooms
        let (room_1, room_2) = create_rooms(ref world);

        // create door entity in room 2 that leads to room 1 via south
        let mut door = create_door(ref world, room_1.inst, Direction::South);
        door.set_parent(ref world, @room_2, 0);
        let _old_reactable: Reactable = world.read_model(door.inst);
        let _old_exit: Exit = world.read_model(door.inst);

        // create item that is in room 1
        let mut item = create_item(ref world, room_1.inst);
        item.set_parent(ref world, @room_1, 0);

        // create player
        let game_id: u128 = 456;
        let mut player1 = PlayerImpl::caller_as_player(ref world, player_1, game_id);
        world.write_model(@player1);
        let player_entity: Entity = EntityImpl::get_entity(@world, player1.inst).unwrap();
        let mut player_container: Container = Component::add_component(ref world, player_entity.inst);
        player_container.is_container = true;
        player_container.can_be_opened = true;
        player_container.can_receive_items = true;
        player_container.is_open = true;
        player_container.num_slots = 2;
        player_container.store(ref world, 0);

        // Register variable properties
        register_variable_properties(ref world);

        // TRIGGER that jumps when an action is executed
        // create trigger for when entering room 2
        let t_key: felt252 = 1;
        let mut trigger = @create_test_trigger(
            room_2.inst, t_key, "TestTrigger", TriggerType::OnEnter,
        );
        let _result = TriggerImpl::register_trigger(ref world, trigger);

        // CONDITION that checks if player has item
        let property: ByteArray = "owner_id";
        let c_key: felt252 = 1;
        let c_name1: ByteArray = "Condition name1";
        let mut array: Array<felt252> = ArrayTrait::new();
        array.append(player1.inst);
        // create condition for when player has item
        let mut condition = create_test_condition(
            room_2.inst,
            c_key,
            c_name1,
            item.inst,
            ComponentType::InventoryItem,
            property,
            Operator::Equals,
            array,
        );
        world.write_model(@condition);

        // EFFECT TO APPLY WHEN PLAYER1 HAS ITEM
        // New Description door -> Reactable
        // 1. New description as bytearray
        let new_txt1: ByteArray = "A door that is open";
        let idx1: u32 = 0;
        let new_txt2: ByteArray = "Looks that it leads nowhere";
        let idx2: u32 = 1;
        // 2. Create array of the new description
        let new_description: Array<(ByteArray, u32)> = array![
            (new_txt1.clone(), idx1), (new_txt2.clone(), idx2),
        ];

        // New is_enterable -> Exit
        // 1. New value as ByteArray
        let enterable: ByteArray = "true";
        // 2. Create array of the new value
        let new_enterable: Array<(ByteArray, u32)> = array![(enterable, 0)];

        // Properties as bytearray
        let property: ByteArray = "description";
        let property2: ByteArray = "is_enterable";

        let e_key: felt252 = 1;
        let e_key2: felt252 = 2;
        let name: ByteArray = "Effect name";
        let name2: ByteArray = "Effect name2";
        let hex_value: felt252 = 0;

        // Create effects
        let mut effect = create_test_effect(
            door.inst,
            e_key,
            name,
            door.inst,
            EffectType::ModifyProperty,
            ComponentType::Reactable,
            property,
            new_description.clone(),
            0,
            hex_value,
        );
        let mut effect2 = create_test_effect(
            door.inst,
            e_key2,
            name2,
            door.inst,
            EffectType::ModifyProperty,
            ComponentType::Exit,
            property2,
            new_enterable.clone(),
            0,
            hex_value,
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
        triggers.append((*trigger.inst, *trigger.key));
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
        let mut action = @create_test_action(
            room_1.inst,
            a_key,
            act_name,
            act_desc,
            true,
            item.inst,
            triggers,
            conditions,
            effects,
            tags,
            failing_response,
            success_response,
        );
        // Register the action
        let _result = ActionImpl::register_action(ref world, action);

        // create trigger context
        let mut context: TriggerContext = create_test_trigger_context(
            player1.inst, door.inst, 0, item.inst,
        );

        // EXECUTE ACTION
        // 1. move player to room 1
        player1.location = room_1.inst;
        player1.store(ref world, game_id);
        player1.move_to_room(ref world, room_1.inst);
        let player_entity: Entity = EntityImpl::get_entity(@world, player1.inst).unwrap();
        assert(!action.is_executed(@world, game_id), 'action not executed yet');

        // 2. Pickup item
        item.set_parent(ref world, @player_entity, 0);
        let player_container: Container = world.read_model(player1.inst);
        let mut itemInv: InventoryItem = world.read_model(item.inst);
        itemInv.owner_id = player_container.inst;
        itemInv.store(ref world, game_id);
        // 3. Check if item is owned by player1
        assert(itemInv.owner_id == player_container.inst, 'Item should be owned by player1');
        // 4. Move player to room 2
        player1.move_to_room(ref world, room_2.inst);
        // 5. Execute action
        let (trig_res, cond_res, eff_res) = action.clone().process_action(ref world, @player1, @context);
        // // The one below are for testing individually
        //let trig_res = trigger.evaluate_trigger(ref world, game_id);
        //let cond_res = condition.evaluate_condition(@world, context);
        //let eff_res1 = effect.apply_effect(ref world, context, game_id);
        //let eff_res2 = effect2.apply_effect(ref world, context, game_id);

        // ASSERT //
        // 1. Trigger should jump
        assert(trig_res.is_ok(), 'Trigger should jump');
        // 2. Condition should fail as player does not have item
        assert((cond_res == true), 'Condition should be true');
        // 3. Effects should fail as condition is not met
        assert(eff_res.is_ok(), 'Effects should pass');
        //assert(eff_res1.is_err(), 'Effects should fail');
        //assert(eff_res2.is_err(), 'Effects2 shoul fail');
        // 4. success, executed
        assert(action.is_executed(@world, game_id), 'action executed');

        // 3. Effects should be update
        let upd_door: Reactable = world.read_game_model(door.inst, game_id);
        let upd_door_exit: Exit = world.read_game_model(door.inst, game_id);
        let key1: u32 = *upd_door.description.at(0);
        let key2: u32 = *upd_door.description.at(1);
        // read_model() will return the original text
        let original_text1: DescriptionText = world.read_model((upd_door.inst, key1));
        // let original_text2: DescriptionText = world.read_model((upd_door.inst, key2));
        // read_game_model_key() will return the updated text
        let new_text1: DescriptionText = world.read_game_model_key(upd_door.inst, key1, game_id);
        let new_text2: DescriptionText = world.read_game_model_key(upd_door.inst, key2, game_id);
        assert_eq!(new_txt1, new_text1.text.clone(), "Description1 should be updated");
        assert_eq!(new_txt2, new_text2.text.clone(), "Description2 should be updated");
        assert_ne!(new_txt1, original_text1.text.clone(), "Original Description1 should not be updated");
        // assert_ne!(new_txt2, original_text2.text.clone(), "Original Description2 should not be updated");
        assert(upd_door_exit.is_enterable == true, 'Exit should be updated');
    }
}

