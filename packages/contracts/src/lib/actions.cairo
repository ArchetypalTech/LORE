use dojo::{world::WorldStorage, model::ModelStorage};

use lore::{
    components::{
        area::{AreaComponent},
        exit::{ExitComponent},
        inspectable::{InspectableComponent},
        inventoryItem::{InventoryItemComponent},
        container::{ContainerComponent},
        player::{PlayerComponent},
    },
    lib::{
        utils::ByteArrayTraitExt,
        variable_property::{VariablePropertyImp},
        trigger::{Trigger,TriggerContext, TriggerImpl},
        condition::{Condition, ConditionImpl},
        effect::{Effect, EffectImpl},
    },
    constants::{errors::Error},
};

#[derive(Clone, Drop, Serde, Debug)]
#[dojo::model]
pub struct Action {
    #[key]
    pub key: felt252,        // Unique identifier
    pub name: ByteArray,     // Human-readable name for the editor
    pub description: ByteArray, // Optional description
    pub is_enabled: bool,    // For toggling the entire action

    // The complete trigger definition
    pub trigger: Array<Trigger>,    // When this action can occur
    // pub conditions: Array<Condition>, // What must be true
    pub effects: Array<Effect>, // What happens when triggered

    // Optional metadata for the editor
    pub tags: Array<ByteArray>,  // For searching/filtering
}

// Implementation for processing actions
#[generate_trait]
pub impl ActionImpl of ActionTrait {
    fn process_action(
        self: @Action,
        mut world: WorldStorage,
        context: TriggerContext
    ) -> Result<(), Error> {
        // Trigger
        //let mut result_t: Result<(), Error> = Result::Ok(());
        //Conditions
        let mut result: bool = true;
        let mut _result_c: Result<(), Error> = Result::Ok(());
        //Effects
        let mut result_e: Result<(), Error> = Result::Ok(());
        println!("action: {:?}", self);
        println!("context: {:?}", context);

        // // First check if the trigger/s are valid
        // for trigger in self.trigger.clone() {
        //     let result_opt = TriggerImpl::evaluate_trigger(world, @trigger);
        //     if result_opt.is_err() {
        //         result_t = result_opt;
        //         break;
        //     }
        //     println!("result_opt: {:?}", result_opt);
            
        // };
        // println!("result_t: {:?}", result_t);

        // // Then evaluate all conditions
        // for condition in self.conditions.clone() {
        //     result = condition.evaluate_condition(@world, context.clone());
        //     if !result {
        //         result_c = Result::Ok(()); // Conditions not met, but not an error
        //     }
        //     println!("result: {:?}", result);
        // };

        // Finally execute all effects if conditions are met
        if result {
            for effect in self.effects.clone() {
                let result_pos = effect.apply_effect(world, context);
                if result_pos.is_err() {
                    result_e = result_pos;
                }
            };
        } else {
            // result_e = Result::Err(Error::ConditionFailed)
            result_e = Result::Ok(()); // -> THIS IS FOR TESTING ONLY
            println!("result_effect: {:?}, but effect is not applyied as condition failed", result_e);
        }
        

        result_e
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
    use starknet::ContractAddress;
    use dojo::{model::ModelStorage, world::WorldStorage};
    use lore::tests::helpers;
    use lore::{lib::{entity::{Entity, EntityImpl}, 
        trigger::{Trigger, TriggerType, TriggerImpl, TriggerParameter, TriggerContext}, 
        condition::{Condition, Operator},
        effect::{Effect, EffectImpl},
        actions::{Action, ActionTrait},
        utils::ByteArrayTraitExt,
        },

        components::{
        area::{Area, AreaComponent},
        exit::{Exit, ExitComponent},
        inspectable::{Inspectable, InspectableComponent, InspectableActions, ActionMapInspectable},
        inventoryItem::{InventoryItem, InventoryItemComponent},
        container::{Container, ContainerComponent}, player::{Player, PlayerComponent, caller_as_player, PlayerImpl},
        Components, Component}
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
        let mut area_component_2 = AreaComponent::add_component(world, room_entity_2.inst);
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
        inspectable.action_map = array![
                ActionMapInspectable {
                    action: "show", inst: 0, action_fn: InspectableActions::SetVisible,
                },
                ActionMapInspectable {
                    action: "look", inst: 0, action_fn: InspectableActions::ReadRandomDescription,
                },
            ];
        inspectable.store(world);
        // add exit component to door
        let mut exit_component: Exit = Component::add_component(world, door.inst); 
        exit_component.is_exit = true;
        exit_component.is_enterable = false;
        exit_component.leads_to = leads_to;
        exit_component.direction_type = direction;
        exit_component.store(world);
        
        // return door entity
        door
    }

    fn create_item(mut world: WorldStorage, owner_id: felt252) -> Entity {
        // create item entity
        let mut item = EntityImpl::create_entity(world);
        item.name = "ball";
        world.write_model(@item);
        // add inspectable component to item
        let mut inspectable: Inspectable = Component::add_component(world, item.inst);
        inspectable.is_inspectable = true;
        inspectable.is_visible = true;
        inspectable.description = array!["A ball"];
        inspectable.action_map = array![
                ActionMapInspectable {
                    action: "show", inst: 0, action_fn: InspectableActions::SetVisible,
                },
                ActionMapInspectable {
                    action: "look", inst: 0, action_fn: InspectableActions::ReadRandomDescription,
                },
            ];
        inspectable.store(world);
        // add inventory item component to item
        let mut inventory_item: InventoryItem = Component::add_component(world, item.inst);
        inventory_item.owner_id = owner_id;
        inventory_item.is_inventory_item = true;
        inventory_item.can_be_picked_up = true;
        inventory_item.can_go_in_container = true;
        inventory_item.store(world);
        
        // return item entity
        item
    }

    fn create_player1(mut world: WorldStorage, location: felt252, address1: ContractAddress) -> Entity {
        let mut player_entity: Entity = world.read_model(0);
        player_entity.name = "Player";
        player_entity.inst = address1.into();
        player_entity.is_entity = true;
        world.write_model(@player_entity);
        // add player component
        let mut player: Player = Component::add_component(world, address1.into());
        player.address = address1;
        player.location = location;
        player.store(world);
        // add container component to player
        let mut container_component: Container = Component::add_component(world, address1.into());
        container_component.is_container = true;
        container_component.can_be_opened = true;
        container_component.can_receive_items = true;
        container_component.is_open = true;
        container_component.num_slots = 2;
        container_component.store(world);

        // return player entity
        player_entity
    }

    fn create_player2(mut world: WorldStorage, address2: ContractAddress) -> Player {
        let mut player = caller_as_player(world, address2);
        // add container component to player
        let mut container_component = ContainerComponent::add_component(world, player.inst);
        container_component.is_container = true;
        container_component.can_be_opened = true;
        container_component.can_receive_items = true;
        container_component.is_open = true;
        container_component.num_slots = 2;
        world.write_model(@player);
        player
    }

    fn create_test_trigger(key: felt252, nameT: ByteArray, trigger_type: TriggerType) -> Trigger {
        Trigger {
            key,
            name: nameT,
            trigger_type,
            parameters: array![
                TriggerParameter { name: "area", value: key },
            ],
            is_enabled: true,
        }
    }

    fn create_test_condition(key: felt252, target: felt252, component: Components, property: ByteArray, operator: Operator, value: felt252) -> Condition {
        Condition {
            key,
            target,
            component,
            property,
            operator,
            value,
        }
    }

    fn create_test_effect(key: felt252, target: felt252, component: Components, property: ByteArray, value: Array<felt252>) -> Effect {
        Effect {
            key,
            target,
            component,
            property,
            value,
        }
    }

    fn create_test_action(key: felt252, name: ByteArray, description: ByteArray, is_enabled: bool, trigger: Array<Trigger>, effects: Array<Effect>, tags: Array<ByteArray>) -> Action {
        Action {
            key,
            name,
            description,
            is_enabled,
            trigger,
            // conditions,
            effects,
            tags,
        }
    }

    fn create_test_trigger_context(doer: felt252, target1: felt252, target2: felt252, inventory_object: felt252) -> TriggerContext {
        TriggerContext {
            doer,
            target1,
            target2,
            inventory_object,
        }
    }

    #[test]
    // Trigger: player1 enters room 2
    // Condition: player1 has item
    // Effect: door description changes
    // However player1 does not have item
    // Result: throw message with error + item that should had changed
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
        // let mut player1 = create_player1(world, room_1.inst, player_1);
        let mut player1 = caller_as_player(world, player_1);
        world.write_model(@player1);

        // create trigger for when entering room 2
        let mut trigger = create_test_trigger(room_2.inst, "TestTrigger", TriggerType::PlayerEntersArea);
        let result = TriggerImpl::register_trigger(world, trigger.clone());
        println!("result_register: {:?}", result);

        // EFFECT TO APPLY WHEN PLAYER1 HAS ITEM
        // New Description door -> Inspectable
        // 1. New description as bytearray
        let new_txt1: ByteArray = "A door that is open";
        let new_txt2: ByteArray = "Looks that it leads somewhere";
        // 2. Transform description to felt252
        let tx1: felt252 = new_txt1.to_felt252_word().unwrap();
        let tx2: felt252 = new_txt2.to_felt252_word().unwrap();
        // 3. Create array of the new description
        let new_description: Array<felt252> = array![tx1, tx2];
        
        // New is_enterable -> Exit
        // 1. New value as felt252
        let enterable: felt252 = true.into();
        // 2. Create array of the new value
        let new_enterable: Array<felt252> = array![enterable];

        // Properties as bytearray
        let property: ByteArray = "description";
        let property2: ByteArray = "is_enterable";

        // Create effects
        let mut effect = create_test_effect(door.inst, door.inst, Components::Inspectable, property, new_description.clone());
        let mut effect2 = create_test_effect(door.inst, door.inst, Components::Exit, property2, new_enterable);
        world.write_model(@effect);
        world.write_model(@effect2);

        // TODO: create action

        // create trigger context
        let mut context: TriggerContext = create_test_trigger_context(player1.inst, door.inst, 0, item.inst);
        
        // EXECUTE ACTION
        // 1. move player to room 2
        player1.move_to_room(world, room_2.inst);
        // WIP: execute action: For now they are individually executed
        let trig_res = TriggerImpl::evaluate_trigger(world, @trigger);
        let eff_res1 = effect.apply_effect(world, context);
        let eff_res2 = effect2.apply_effect(world, context);
        
        // ASSERT //
        // 1. Trigger should jump
        assert(trig_res.is_ok(), 'Trigger should jump');
        // 2 effects should pass
        assert((eff_res1 == Result::Ok(())),'Effects should not fail');
        assert((eff_res2 == Result::Ok(())),'Effects2 shoul dnot fail');
        // 2. Effects should update        
        let upd_door: Inspectable = world.read_model(door.inst);
        let upd_door_exit: Exit = world.read_model(door.inst);
        let new_text1 = ByteArrayTraitExt::byte_array_from_felt252(*new_description.at(0));
        let new_text2 = ByteArrayTraitExt::byte_array_from_felt252(*new_description.at(1));

        assert_eq!(upd_door.description[0].clone(), new_text1, "Description1 should be updated");
        assert_eq!(upd_door.description[1].clone(), new_text2, "Description2 should be updated");
        assert(upd_door_exit.is_enterable == true, 'Exit should be updated');
    }
}    