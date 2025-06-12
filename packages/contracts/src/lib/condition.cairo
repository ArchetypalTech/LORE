use dojo::{world::{WorldStorage}};

use lore::{
    lib::{
        entity::{EntityImpl}, trigger::{TriggerContext, TriggerImpl}, utils::ByteArrayTraitExt,
        variable_property::{VariablePropertyTrait},
    },
    components::{
        inspectable::{InspectableComponent}, area::{AreaComponent}, exit::{ExitComponent},
        inventoryItem::{InventoryItemComponent}, container::{ContainerComponent},
        player::{PlayerComponent}, Components,
    },
};

#[derive(Clone, Drop, Serde, Debug, Introspect, PartialEq)]
#[dojo::model]
pub struct Condition {
    /// Unique identifier attached to the entity
    #[key]
    pub inst: felt252,
    /// Unique identifier of the condition
    #[key]
    pub key: felt252,
    /// The target inst.
    pub target: felt252,
    /// Which component to check
    pub component: Components,
    /// Which property of the component to check
    pub property: ByteArray,
    /// How to compare the values
    pub operator: Operator,
    /// Value to compare against
    pub value: Array<felt252>,
}

/// TODO: Implement more operators later
#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum Operator {
    Equals,
    NotEquals,
}

#[generate_trait]
pub impl ConditionImpl of ConditionTrait {
    fn evaluate_condition(self: @Condition, world: @WorldStorage, context: TriggerContext) -> bool {
        let target = *self.target;
        let mut component_value: Option<Array<felt252>> = Option::None;
        let mut eval_result: bool = false;
        match self.component {
            Components::Area => {
                let container_opt = AreaComponent::get_component(*world, target);
                if container_opt.is_none() {
                    return false;
                }
                let area = OptionTrait::unwrap(container_opt);
                let (b_component_value, _) = VariablePropertyTrait::get_property(
                    world, @area.inst, self.property, *self.component,
                );
                component_value = b_component_value;
            },
            Components::Exit => {
                let container_opt = ExitComponent::get_component(*world, target);
                if container_opt.is_none() {
                    return false;
                }
                let exit = OptionTrait::unwrap(container_opt);
                let (b_component_value, _) = VariablePropertyTrait::get_property(
                    world, @exit.inst, self.property, *self.component,
                );
                component_value = b_component_value;
            },
            Components::Inspectable => {
                let inspectable_opt = InspectableComponent::get_component(*world, target);
                if inspectable_opt.is_none() {
                    return false;
                }
                let inspectable = OptionTrait::unwrap(inspectable_opt);
                let (b_component_value, _) = VariablePropertyTrait::get_property(
                    world, @inspectable.inst, self.property, *self.component,
                );
                component_value = b_component_value;
            },
            Components::InventoryItem => {
                let inventoryItem_opt = InventoryItemComponent::get_component(*world, target);
                if inventoryItem_opt.is_none() {
                    return false;
                }
                let inventoryItem = OptionTrait::unwrap(inventoryItem_opt);
                let (b_component_value, _) = VariablePropertyTrait::get_property(
                    world, @inventoryItem.inst, self.property, *self.component,
                );
                component_value = b_component_value;
            },
            Components::Container => {
                let container_opt = ContainerComponent::get_component(*world, target);
                if container_opt.is_none() {
                    return false;
                }
                let container = OptionTrait::unwrap(container_opt);
                let (b_component_value, _) = VariablePropertyTrait::get_property(
                    world, @container.inst, self.property, *self.component,
                );
                component_value = b_component_value;
            },
            Components::Player => {
                let container_opt = PlayerComponent::get_component(*world, target);
                if container_opt.is_none() {
                    return false;
                }
                let player = OptionTrait::unwrap(container_opt);
                let (b_component_value, _) = VariablePropertyTrait::get_property(
                    world, @player.inst, self.property, *self.component,
                );
                component_value = b_component_value;
            },
            _ => {
                // Return false if no match
                return false;
            },
        };

        // Check if the component value is none
        if component_value.is_none() {
            // println!("component value is none");
            return false;
        }

        // Compare values using the operator
        eval_result = self.compare(component_value.unwrap());
        return eval_result;
    }

    fn compare(self: @Condition, component_value: Array<felt252>) -> bool {
        // Get the condition value, which is also an array of felt252
        let condition_value: Array<felt252> = self.value.clone();
        // Bool variable
        let mut result: bool = true;

        match self.operator {
            Operator::Equals => {
                // First, check if the lengths of the two arrays are equal.
                // If not, they can't be equal, so return false immediately.
                if component_value.len() != condition_value.len() {
                    result = false;
                }

                // Iterate through each index and compare the corresponding elements.
                // If any pair of elements differ, return false.
                for i in 0..component_value.len() {
                    if component_value.at(i) != condition_value.at(i) {
                        result = false;
                    };
                };

                // If we get here, all elements matched, so return true.
                return result;
            },
            Operator::NotEquals => {
                // If the lengths are different, arrays are not equal,
                // so return true for NotEquals.
                if component_value.len() != condition_value.len() {
                    result = false;
                }

                // Iterate through each element and check if any pair differs.
                // If so, return true, indicating arrays are not equal.
                for i in 0..component_value.len() {
                    if component_value.at(i) == condition_value.at(i) {
                        result = false;
                    };
                };

                // If all elements matched and lengths are equal, arrays are equal,
                // so return false for NotEquals.
                return result;
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
        entity::{EntityImpl}, condition::Condition, variable_property::{VariablePropertyImp},
    };
    use lore::components::{
        Component, Components,
        inspectable::{Inspectable, InspectableComponent, ActionMapInspectable, InspectableActions},
    };

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

    #[test]
    fn Condition_test_evaluate_condition() {
        let (mut world, _, _, _, _) = helpers::setup_core();
        // Create entity and attach InspectableComponent
        let mut door = EntityImpl::create_entity(world);
        door.name = "door";
        world.write_model(@door);

        let new_entry: ByteArray = "A door";
        let mut inspectable: Inspectable = Component::add_component(world, door.inst);
        inspectable.is_inspectable = true;
        inspectable.is_visible = true;
        inspectable.already_shown = false;
        inspectable.description = array!["A door"];
        inspectable.new_entry = new_entry;
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

        // Register component variable properties
        VariablePropertyImp::register_component_properties(world, Components::Inspectable);

        // Test: is_inspectable == true (should pass)
        let key2: felt252 = 2;
        let mut array_true = ArrayTrait::new();
        array_true.append(1);
        let mut condition = create_test_condition(
            door.inst,
            key2,
            door.inst,
            Components::Inspectable,
            "is_inspectable",
            Operator::Equals,
            array_true,
        );
        world.write_model(@condition);
        assert(
            condition
                .evaluate_condition(
                    @world, TriggerContext { doer: 0, target1: 0, target2: 0, inventory_object: 0 },
                ),
            'is_inspectable should be true',
        );

        // Test: is_inspectable == false (should fail)
        let key3: felt252 = 3;
        let mut array_false = ArrayTrait::new();
        array_false.append(0);
        let mut condition2 = create_test_condition(
            door.inst,
            key3,
            door.inst,
            Components::Inspectable,
            "is_inspectable",
            Operator::Equals,
            array_false,
        );
        world.write_model(@condition2);
        assert(
            !condition2
                .evaluate_condition(
                    @world, TriggerContext { doer: 0, target1: 0, target2: 0, inventory_object: 0 },
                ),
            'is_inspectable should be false',
        );

        // Test: is_visible == true (should pass)
        let key4: felt252 = 4;
        let mut array3 = ArrayTrait::new();
        array3.append(1);
        let mut condition3 = create_test_condition(
            door.inst,
            key4,
            door.inst,
            Components::Inspectable,
            "is_visible",
            Operator::Equals,
            array3,
        );
        world.write_model(@condition3);
        assert(
            condition3
                .evaluate_condition(
                    @world, TriggerContext { doer: 0, target1: 0, target2: 0, inventory_object: 0 },
                ),
            'is_visible should be true',
        );

        // Test: is_visible == false (should fail)
        let key5: felt252 = 5;
        let mut array4 = ArrayTrait::new();
        array4.append(0);
        let mut condition4 = create_test_condition(
            door.inst,
            key5,
            door.inst,
            Components::Inspectable,
            "is_visible",
            Operator::Equals,
            array4,
        );
        world.write_model(@condition4);
        assert(
            !condition4
                .evaluate_condition(
                    @world, TriggerContext { doer: 0, target1: 0, target2: 0, inventory_object: 0 },
                ),
            'is_visible should be false',
        );

        // Test: is_visible != 0 (should pass)
        let key6: felt252 = 6;
        let mut not_eq_array = ArrayTrait::new();
        not_eq_array.append(0);
        let mut condition5 = create_test_condition(
            door.inst,
            key6,
            door.inst,
            Components::Inspectable,
            "is_visible",
            Operator::NotEquals,
            not_eq_array,
        );
        world.write_model(@condition5);
        assert(
            condition5
                .evaluate_condition(
                    @world, TriggerContext { doer: 0, target1: 0, target2: 0, inventory_object: 0 },
                ),
            'should not be equal',
        );

        // Test: is_visible != 1 (should fail)
        let key7: felt252 = 7;
        let mut not_eq_array2 = ArrayTrait::new();
        not_eq_array2.append(1);
        let mut condition6 = create_test_condition(
            door.inst,
            key7,
            door.inst,
            Components::Inspectable,
            "is_visible",
            Operator::NotEquals,
            not_eq_array2,
        );
        world.write_model(@condition6);
        assert(
            !condition6
                .evaluate_condition(
                    @world, TriggerContext { doer: 0, target1: 0, target2: 0, inventory_object: 0 },
                ),
            'should not be false',
        );
    }
}
