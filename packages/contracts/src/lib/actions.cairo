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

#[derive(Clone, Drop, Serde, Debug, Introspect)]
#[dojo::model]
pub struct Action {
    #[key]
    pub key: felt252,        // Unique identifier
    pub name: ByteArray,     // Human-readable name for the editor
    pub description: ByteArray, // Optional description
    pub is_enabled: bool,    // For toggling the entire action

    // The complete trigger definition
    pub trigger: Array<Trigger>,    // When this action can occur
    pub conditions: Array<Condition>, // What must be true
    pub effects: Array<Effect>, // What happens when triggered

    // Optional metadata for the editor
    pub tags: Array<ByteArray>,  // For searching/filtering
}

// Implementation for processing actions
#[generate_trait]
impl ActionImpl of ActionTrait {
    fn process_action(
        self: @Action,
        mut world: WorldStorage,
        context: TriggerContext
    ) -> (Result<(), Error>, bool, Result<(), Error>) {
        // Trigger
        let mut result_t: Result<(), Error> = Result::Ok(());
        //Conditions
        let mut result: bool = false;
        let mut result_c: Result<(), Error> = Result::Ok(());
        //Effects
        let mut result_e: Result<(), Error> = Result::Ok(());
        // First check if the trigger/s are valid
        for trigger in self.trigger.clone() {
            let result_opt = TriggerImpl::evaluate_trigger(world, @trigger);
            if result_opt.is_err() {
                result_t = result_opt;
                break;
            }
        };

        // Then evaluate all conditions
        for condition in self.conditions.clone() {
            result = condition.evaluate_condition(@world, context);
            if !result {
                result_c = Result::Ok(()); // Conditions not met, but not an error
            }
        };

        // Finally execute all effects if conditions are met
        if result {
            for effect in self.effects.clone() {
                let result_pos = effect.apply_effect(world, context);
                if result_pos.is_err() {
                    result_e = result_pos;
                }
            };
        } else {
            result_e = Result::Err(Error::ConditionFailed)
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
    
    use starknet::ContractAddress;
    use dojo::{model::ModelStorage, world::WorldStorage};
    use lore::tests::helpers;
    use lore::{lib::{entity::{EntityImpl}, 
        trigger::{Trigger,TriggerType, TriggerImpl, TriggerParameter, TriggerContext}, 
        condition::{Condition, Operator},
        effect::Effect,
        actions::{Action, ActionImpl},
        utils::ByteArrayTraitExt},

        components::{
        area::{AreaComponent},
        exit::{ExitComponent},
        inspectable::{InspectableComponent, InspectableActions, ActionMapInspectable},
        inventoryItem::{InventoryItemComponent},
        container::{ContainerComponent}, player::{Player, PlayerComponent, caller_as_player, PlayerImpl},
        Components}
    };
    use lore::constants::constants::Direction;
    use lore::lib::{ a_lexer::{Token, TokenType, Command}, c_handler::handle_command, entity::{Entity}};

    fn set_rooms(mut world: WorldStorage) -> (Entity, Entity) {
        // create room entity 1
        let mut room_entity_1 = EntityImpl::create_entity(world);
        // create room entity 2
        let mut room_entity_2 = EntityImpl::create_entity(world);
        
        // add area component to room entity 1
        let mut _area_component = AreaComponent::add_component(world, room_entity_1.inst);
        // add exit component to room entity 1
        let mut exit_component_1 = ExitComponent::add_component(world, room_entity_1.inst);
        // update exit component
        exit_component_1.is_enterable = true;
        exit_component_1.leads_to = room_entity_2.inst;
        exit_component_1.direction_type = Direction::North;
        world.write_model(@exit_component_1);
        
        // add area component to room entity 2
        let mut _area_component = AreaComponent::add_component(world, room_entity_2.inst);

        // return room entities
        (room_entity_1, room_entity_2)
    }

    fn create_door(mut world: WorldStorage, leads_to: felt252, direction: Direction) -> Entity {
        // create door entity
        let mut door = EntityImpl::create_entity(world);
        door.name = "door";
        world.write_model(@door);
        // add inspectable component to door
        let mut inspectable = InspectableComponent::add_component(world, door.inst);
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
        world.write_model(@inspectable);
        // add exit component to door
        let mut exit_component = ExitComponent::add_component(world, door.inst);
        exit_component.is_exit = true;
        exit_component.is_enterable = false;
        exit_component.leads_to = leads_to;
        exit_component.direction_type = direction;
        world.write_model(@exit_component);
        
        // return door entity
        door
    }

    fn create_item(mut world: WorldStorage, owner_id: felt252) -> Entity {
        // create item entity
        let mut item = EntityImpl::create_entity(world);
        item.name = "ball";
        world.write_model(@item);
        // add inspectable component to item
        let mut inspectable = InspectableComponent::add_component(world, item.inst);
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
        world.write_model(@inspectable);
        // add inventory item component to item
        let mut inventory_item = InventoryItemComponent::add_component(world, item.inst);
        inventory_item.is_inventory_item = true;
        inventory_item.can_be_picked_up = true;
        inventory_item.can_go_in_container = true;
        inventory_item.owner_id = owner_id;
        world.write_model(@inventory_item);
        
        // return item entity
        item
    }

    fn create_player1(mut world: WorldStorage, address1: ContractAddress) -> Player {
        let mut player = caller_as_player(world, address1);
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
            is_enabled: false,
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

    fn create_test_action(key: felt252, name: ByteArray, description: ByteArray, is_enabled: bool, trigger: Array<Trigger>, conditions: Array<Condition>, effects: Array<Effect>, tags: Array<ByteArray>) -> Action {
        Action {
            key,
            name,
            description,
            is_enabled,
            trigger,
            conditions,
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
        // set rooms
        let (room_1, room_2) = set_rooms(world);
        // create door entity in room 2
        let mut door = create_door(world, room_1.inst, Direction::South);
        door.set_parent(world, @room_2);
        world.write_model(@door);
        world.write_model(@room_2);

        // create item
        let mut item = create_item(world, room_1.inst);
        item.set_parent(world, @room_2);
        world.write_model(@item);
        // create player 1
        let mut player1 = create_player1(world, player_1);
        player1.location = room_2.inst;
        world.write_model(@player1);

        // create trigger for when entering room 2
        let mut trigger = create_test_trigger(room_2.inst, "TestTrigger", TriggerType::PlayerEntersArea);
        world.write_model(@trigger);

        // create condition for when player1 has item
        let condition =  create_test_condition(room_2.inst, item.inst, Components::InventoryItem, "owner_id", Operator::Equals, player1.inst);
        world.write_model(@condition);

        // create effect for when player1 has item
        let mut description = ArrayTrait::<felt252>::new();
        let text1: felt252 = 'A door';
        let text2: felt252 = 'It is open';
        let text3: felt252 = 'Leads somewhere';
        description.append(text1);
        description.append(text2);
        description.append(text3);
        let mut new_value = ArrayTrait::<felt252>::new();
        let is_open: felt252 = true.into();
        new_value.append(is_open);
        let mut effect = create_test_effect(room_2.inst, door.inst, Components::Inspectable, "description", description);
        let mut effect2 = create_test_effect(room_2.inst, door.inst, Components::Exit, "is_open", new_value);
        world.write_model(@effect);
        world.write_model(@effect2);
        
        // create action
        let mut action = create_test_action(room_2.inst, "TestAction", "TestAction", true, array![trigger], array![condition], array![effect, effect2], array!["test"]);
        world.write_model(@action);

        // create trigger context
        let mut context = create_test_trigger_context(player1.inst, room_2.inst, 0, item.inst);

        // move player to room 2
        player1.move_to_room(world, room_2.inst);
        
        // execute action
        let (trig_res, cond_res, eff_res) = ActionImpl::process_action(@action, world, context);
        assert(trig_res.is_ok(), 'Trigger should jump');
        assert(cond_res == false, 'Condition must fail');
        assert(eff_res.is_err(), 'Effect must fail');
    }
}    