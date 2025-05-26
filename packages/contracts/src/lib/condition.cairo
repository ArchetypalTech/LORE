use dojo::{world::{WorldStorage}};

use lore::{
    lib::{
        entity::{EntityImpl},
        trigger::{TriggerContext, TriggerImpl},
        utils::ByteArrayTraitExt,
        variable_property::{VariablePropertyTrait, PropertyAccess},
    },
    components::{ 
        inspectable::{InspectableComponent},
        area::{AreaComponent},
        exit::{ExitComponent},
        inventoryItem::{InventoryItemComponent},
        container::{ContainerComponent},
        player::{PlayerComponent},
        Components,
    },
};

#[derive(Clone, Drop, Serde, Debug)]
#[dojo::model]
pub struct Condition {
    #[key]
    pub key: felt252,        // Unique identifier
    pub target: felt252,     // Entity to check (can be optional for global conditions)
    pub component: Components,  // Which component to check
    pub property: ByteArray,   // Which property of the component to check
    pub operator: Operator,  // How to compare the values
    pub value: felt252,      // Value to compare against
}

#[derive(Clone, Drop, Serde, Debug, PartialEq, Introspect)]
pub enum Operator {
    Equals,
    NotEquals,
    // Implement more operators later
}

#[generate_trait]
pub impl ConditionImpl of ConditionTrait {
    fn evaluate_condition(
        self: @Condition,
        world: @WorldStorage,
        context: TriggerContext
    ) -> bool {
        let target = *self.target;
        let mut component_value: Option<felt252> = Option::None;
        let mut eval_result: bool = false;

        match self.component {
            Components::Area => {
                let container_opt = AreaComponent::get_component(*world, target);
                if container_opt.is_none() {
                    return false;
                }
                let area = OptionTrait::unwrap(container_opt);
                let(b_component_value, _) = VariablePropertyTrait::get_property(world, @area.inst, self.property);
                component_value = b_component_value;
            },
            Components::Exit => {
                let container_opt = ExitComponent::get_component(*world, target);
                if container_opt.is_none() {
                    return false;
                }
                let exit = OptionTrait::unwrap(container_opt);
                let(b_component_value, _) = VariablePropertyTrait::get_property(world, @exit.inst, self.property);
                component_value = b_component_value;
            },
            Components::Inspectable => {
                let inspectable_opt = InspectableComponent::get_component(*world, target);
                if inspectable_opt.is_none() {
                    return false;
                }
                let inspectable = OptionTrait::unwrap(inspectable_opt);
                let(b_component_value, _) = VariablePropertyTrait::get_property(world, @inspectable.inst, self.property);
                component_value = b_component_value;
            },
            Components::InventoryItem => {
                let container_opt = InventoryItemComponent::get_component(*world, target);
                if container_opt.is_none() {
                    return false;
                }
                let inventoryItem = OptionTrait::unwrap(container_opt);
                let(b_component_value, _) = VariablePropertyTrait::get_property(world, @inventoryItem.inst, self.property);
                component_value = b_component_value;
            },
            Components::Container => {
                let container_opt = ContainerComponent::get_component(*world, target);
                if container_opt.is_none() {
                    return false;
                }
                let container = OptionTrait::unwrap(container_opt);
                let(b_component_value, _) = VariablePropertyTrait::get_property(world, @container.inst, self.property);
                component_value = b_component_value;
            },
            Components::Player => {
                let container_opt = PlayerComponent::get_component(*world, target);
                if container_opt.is_none() {
                    return false;
                }
                let player = OptionTrait::unwrap(container_opt);
                let(b_component_value, _) = VariablePropertyTrait::get_property(world, @player.inst, self.property);
                component_value = b_component_value;
            },            
            _ => { 
                // Return false if no match
                return false;
            },
        }

        // Check if the component value is none
        if component_value.is_none() {
            return false;
        }

        // Compare values using the operator
        eval_result = self.compare(component_value.unwrap());
        return eval_result;
    }

    fn compare(self: @Condition, component_value: felt252) -> bool {
        match self.operator {
            Operator::Equals => {
                if component_value == *self.value {
                    return true;
                } else {
                    return false;
                }
            },
            Operator::NotEquals => {
                if component_value != *self.value {
                    return true;
                } else {
                    return false;
                }
            },
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use dojo::{model::ModelStorage};
    use lore::tests::helpers;
    use lore::lib::{
        entity::{EntityImpl},
        condition::Condition,
    };
    use lore::components::{Component, Components,inspectable::{Inspectable, InspectableComponent, ActionMapInspectable, InspectableActions}};

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
    
    #[test]
    fn Condition_test_evaluate_condition() {
        let (mut world, _, _, _, _) = helpers::setup_core();
        let mut door = EntityImpl::create_entity(world);
        door.name = "door";
        world.write_model(@door);
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
        
        // Test description property (length == 1)
        let mut condition = create_test_condition(door.inst, door.inst, Components::Inspectable, "description", Operator::Equals, 1);
        world.write_model(@condition);
        assert(condition.evaluate_condition(@world, TriggerContext { doer: 0, target1: 0, target2: 0, inventory_object: 0 }), 'condition should be true');
        // Test description property (length == 1) — should fail
        condition = create_test_condition(door.inst, door.inst, Components::Inspectable, "description", Operator::Equals, 2);
        world.write_model(@condition);
        assert(!condition.evaluate_condition(@world, TriggerContext { doer: 0, target1: 0, target2: 0, inventory_object: 0 }), 'condition should be false');

        // Test is_inspectable == true (1)
        condition = create_test_condition(door.inst + 1, door.inst, Components::Inspectable, "is_inspectable", Operator::Equals, 1);
        world.write_model(@condition);
        assert(condition.evaluate_condition(@world, TriggerContext { doer: 0, target1: 0, target2: 0, inventory_object: 0 }), 'is_inspectable should be true');

        // Test is_inspectable == false (0) — should fail
        condition = create_test_condition(door.inst + 2, door.inst, Components::Inspectable, "is_inspectable", Operator::Equals, 0);
        world.write_model(@condition);
        assert(!condition.evaluate_condition(@world, TriggerContext { doer: 0, target1: 0, target2: 0, inventory_object: 0 }), 'is_inspectable should be false');

        // Test is_visible == true (1)
        condition = create_test_condition(door.inst + 3, door.inst, Components::Inspectable, "is_visible", Operator::Equals, 1);
        world.write_model(@condition);
        assert(condition.evaluate_condition(@world, TriggerContext { doer: 0, target1: 0, target2: 0, inventory_object: 0 }), 'is_visible should be true');

        // Test is_visible == false (0) — should fail
        condition = create_test_condition(door.inst + 4, door.inst, Components::Inspectable, "is_visible", Operator::Equals, 0);
        world.write_model(@condition);
        assert(!condition.evaluate_condition(@world, TriggerContext { doer: 0, target1: 0, target2: 0, inventory_object: 0 }), 'is_visible should be false');

    }
}