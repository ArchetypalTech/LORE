use dojo::{world::{WorldStorage}, model::ModelStorage};
use lore::{
    models::{
        entity::{EntityImpl},
        index::{PropertyRegistry},
        area::{AreaComponent},
        exit::{ExitComponent},
        reactable::{ReactableComponent},
        inventory_item::{InventoryItemComponent},
        container::{ContainerComponent},
        player::{PlayerComponent},
        trigger::{TriggerImpl},
    },
    types::{
        component_type::ComponentType,
        action_type::{TriggerContext, Operator},
    },
    lib::{
        utils::ByteArrayTraitExt,
        variable_property_helper::VariablePropertyHelperTrait,
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
    /// Condition name
    pub name: ByteArray,
    /// The target inst.
    pub target: felt252,
    /// Which component to check
    pub component: ComponentType,
    /// Which property of the component to check
    pub property: ByteArray,
    /// How to compare the values
    pub operator: Operator,
    /// Value to compare against
    pub value: Array<felt252>,
}

#[generate_trait]
pub impl ConditionImpl of ConditionTrait {
    fn evaluate_condition(self: @Condition, world: @WorldStorage, context: TriggerContext) -> bool {
        let target = *self.target;
        let mut component_value: Option<Array<felt252>> = Option::None;
        let mut eval_result: bool = false;
        let property_registry: PropertyRegistry = world.read_model(*self.component);
        match self.component {
            ComponentType::Area => {
                let container_opt = AreaComponent::get_component(*world, target);
                if container_opt.is_none() {
                    return false;
                }
                let area = OptionTrait::unwrap(container_opt);
                let (b_component_value, _) = VariablePropertyHelperTrait::get_area_property(
                    area, self.property, @property_registry,
                );
                component_value = b_component_value;
            },
            ComponentType::Exit => {
                let container_opt = ExitComponent::get_component(*world, target);
                if container_opt.is_none() {
                    return false;
                }
                let exit = OptionTrait::unwrap(container_opt);
                let (b_component_value, _) = VariablePropertyHelperTrait::get_exit_property(
                    exit, self.property, @property_registry,
                );
                component_value = b_component_value;
            },
            ComponentType::Reactable => {
                let reactable_opt = ReactableComponent::get_component(*world, target);
                if reactable_opt.is_none() {
                    return false;
                }
                let reactable = OptionTrait::unwrap(reactable_opt);
                let (b_component_value, _) = VariablePropertyHelperTrait::get_reactable_property(
                    reactable, self.property, @property_registry, *world,
                );
                component_value = b_component_value;
            },
            ComponentType::InventoryItem => {
                let inventory_item_opt = InventoryItemComponent::get_component(*world, target);
                if inventory_item_opt.is_none() {
                    return false;
                }
                let inventory_item = OptionTrait::unwrap(inventory_item_opt);
                let (b_component_value, _) =
                    VariablePropertyHelperTrait::get_inventory_item_property(
                    inventory_item, self.property, @property_registry,
                );
                component_value = b_component_value;
            },
            ComponentType::Container => {
                let container_opt = ContainerComponent::get_component(*world, target);
                if container_opt.is_none() {
                    return false;
                }
                let container = OptionTrait::unwrap(container_opt);
                let (b_component_value, _) = VariablePropertyHelperTrait::get_container_property(
                    container, self.property, @property_registry,
                );
                component_value = b_component_value;
            },
            ComponentType::Player => {
                let container_opt = PlayerComponent::get_component(*world, target);
                if container_opt.is_none() {
                    return false;
                }
                let player = OptionTrait::unwrap(container_opt);
                let (b_component_value, _) = VariablePropertyHelperTrait::get_player_property(
                    player, self.property, @property_registry,
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
                // If not, they can't be compared, so return false immediately.
                if component_value.len() != condition_value.len() {
                    result = false;
                }

                if result {
                    // Iterate through each index and compare the corresponding elements.
                    // If any pair of elements differ, return false.
                    for i in 0..component_value.len() {
                        if component_value.at(i) != condition_value.at(i) {
                            result = false;
                            break;
                        };
                    };
                }

                // If we get here, all elements matched, so return true.
                return result;
            },
            Operator::NotEquals => {
                // First, check if the lengths of the two arrays are equal.
                // If not, they can't be compared, so return false immediately.
                if component_value.len() != condition_value.len() {
                    result = false;
                }

                if result {
                    // Iterate through each element and check if any pair differs.
                    // If so, return true, indicating arrays are not equal.
                    for i in 0..component_value.len() {
                        if component_value.at(i) == condition_value.at(i) {
                            result = false;
                            break;
                        };
                    };
                }

                // If all elements matched and lengths are equal, arrays are equal,
                // so return false for NotEquals.
                return result;
            },
            Operator::GreaterThan => {
                // First, check if the lengths of the two arrays are equal.
                // If not, they can't be compared, so return false immediately.
                if component_value.len() != condition_value.len() {
                    result = false;
                }

                if result {
                    // Iterate through each element and check if any pair differs.
                    // If component value is less than condition value, return false.
                    for i in 0..component_value.len() {
                        let comp_val: felt252 = *(component_value.at(i)); // dereference
                        let cond_val: felt252 = *(condition_value.at(i)); // dereference

                        // Now convert to u256 for comparison
                        let comp_u256: u256 = comp_val.try_into().unwrap();
                        let cond_u256: u256 = cond_val.try_into().unwrap();
                        if comp_u256 < cond_u256 {
                            // Not greater than
                            result = false;
                            break;
                        }
                    };
                }

                // If all elements matches length and they are greater than, return true
                return result;
            },
            Operator::LessThan => {
                // First, check if the lengths of the two arrays are equal.
                // If not, they can't be compared, so return false immediately.
                if component_value.len() != condition_value.len() {
                    result = false;
                }

                if result {
                    // Iterate through each element and check if any pair differs.
                    // If component value is greater than condition value, return false.
                    for i in 0..component_value.len() {
                        let comp_val: felt252 = *(component_value.at(i)); // dereference
                        let cond_val: felt252 = *(condition_value.at(i)); // dereference

                        // Now convert to u256 for comparison
                        let comp_u256: u256 = comp_val.try_into().unwrap();
                        let cond_u256: u256 = cond_val.try_into().unwrap();
                        if comp_u256 > cond_u256 {
                            // Not less than
                            result = false;
                            break;
                        }
                    };
                }

                // If all elements matches length and they are less than, return true
                return result;
            },
            _ => { // Do nothing
            },
        }
        result
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use dojo::{model::ModelStorage};
    use lore::tests::helpers;
    use lore::{
        models::{
            entity::{EntityImpl},
            index::{DescriptionText},
            reactable::{Reactable},
            condition::{Condition},
            components::{Component},
            reactable::ReactableComponent,
        },
        types::{component_type::{ComponentType, ActionMapReactable, ReactableActions}},
        lib::{variable_property::VariablePropertyImp},
    };

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

    #[test]
    fn Condition_test_evaluate_condition() {
        let (mut world, _, _, _, _) = helpers::setup_core();
        // Create entity and attach ReactableComponent
        let mut door = EntityImpl::create_entity(world);
        door.name = "door";
        world.write_model(@door);

        let new_entry: ByteArray = "A door";
        let mut reactable: Reactable = Component::add_component(world, door.inst);
        let desc1: DescriptionText = DescriptionText {
            inst: door.inst, key: 0, text: new_entry.clone(),
        };
        world.write_model(@desc1);
        reactable.is_reactable = true;
        reactable.is_visible = true;
        reactable.already_shown = false;
        reactable.description = array![0];
        reactable.new_entry = new_entry;
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
        reactable.store(world);

        // Register component variable properties
        VariablePropertyImp::register_component_properties(world, ComponentType::Reactable);

        // Test: is_reactable == true (should pass)
        let key2: felt252 = 2;
        let name2: ByteArray = "Condition name2";
        let mut array_true = ArrayTrait::new();
        array_true.append(1);
        let mut condition = create_test_condition(
            door.inst,
            key2,
            name2,
            door.inst,
            ComponentType::Reactable,
            "is_reactable",
            Operator::Equals,
            array_true,
        );
        world.write_model(@condition);
        assert(
            condition
                .evaluate_condition(
                    @world, TriggerContext { doer: 0, target1: 0, target2: 0, inventory_object: 0 },
                ),
            'is_reactable should be true',
        );

        // Test: is_reactable == false (should fail)
        let key3: felt252 = 3;
        let name3: ByteArray = "Condition name3";
        let mut array_false = ArrayTrait::new();
        array_false.append(0);
        let mut condition2 = create_test_condition(
            door.inst,
            key3,
            name3,
            door.inst,
            ComponentType::Reactable,
            "is_reactable",
            Operator::Equals,
            array_false,
        );
        world.write_model(@condition2);
        assert(
            !condition2
                .evaluate_condition(
                    @world, TriggerContext { doer: 0, target1: 0, target2: 0, inventory_object: 0 },
                ),
            'is_reactable should be false',
        );

        // Test: is_visible == true (should pass)
        let key4: felt252 = 4;
        let name4: ByteArray = "Condition name4";
        let mut array3 = ArrayTrait::new();
        array3.append(1);
        let mut condition3 = create_test_condition(
            door.inst,
            key4,
            name4,
            door.inst,
            ComponentType::Reactable,
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
        let name5: ByteArray = "Condition name5";
        let mut array4 = ArrayTrait::new();
        array4.append(0);
        let mut condition4 = create_test_condition(
            door.inst,
            key5,
            name5,
            door.inst,
            ComponentType::Reactable,
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
        let name6: ByteArray = "Condition name6";
        let mut not_eq_array = ArrayTrait::new();
        not_eq_array.append(0);
        let mut condition5 = create_test_condition(
            door.inst,
            key6,
            name6,
            door.inst,
            ComponentType::Reactable,
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
        let name7: ByteArray = "Condition name7";
        let mut not_eq_array2 = ArrayTrait::new();
        not_eq_array2.append(1);
        let mut condition6 = create_test_condition(
            door.inst,
            key7,
            name7,
            door.inst,
            ComponentType::Reactable,
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

