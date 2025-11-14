use dojo::{world::{WorldStorage}, model::ModelStorage};
use lore::{
    models::{
        entity::{EntityImpl},
        index::{PropertyRegistry},
        area::{Area, AreaComponent},
        exit::{Exit, ExitComponent},
        reactable::{Reactable, ReactableComponent},
        inventory_item::{InventoryItem, InventoryItemComponent},
        container::{Container, ContainerComponent},
        player::{Player, PlayerComponent},
        trigger::{TriggerImpl},
    },
    types::{
        component_type::ComponentType,
        action_type::{TriggerContext, Operator},
    },
    lib::{
        utils::ByteArrayTraitExt,
        variable_property_helper::{VariablePropertyHelper},
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


//---------------------------------
// Model Trait
//
#[generate_trait]
pub impl ConditionImpl of ConditionTrait {
    fn evaluate_condition(self: @Condition, world: @WorldStorage, context: @TriggerContext, game_id: u128) -> bool {
        let target: felt252 = *self.target;
        let mut component_value: Option<Array<felt252>> = Option::None;
        let mut eval_result: bool = false;
        let property_registry: PropertyRegistry = world.read_model(*self.component);
        match self.component {
            ComponentType::Area => {
                let container_opt: Option<Area> = AreaComponent::get_component(world, target, game_id);
                if container_opt.is_none() {
                    return false;
                }
                let area: Area = OptionTrait::unwrap(container_opt);
                let (b_component_value, _) = VariablePropertyHelper::get_area_property(
                    @area, self.property, @property_registry,
                );
                component_value = b_component_value;
            },
            ComponentType::Exit => {
                let container_opt: Option<Exit> = ExitComponent::get_component(world, target, game_id);
                if container_opt.is_none() {
                    return false;
                }
                let exit: Exit = OptionTrait::unwrap(container_opt);
                let (b_component_value, _) = VariablePropertyHelper::get_exit_property(
                    @exit, self.property, @property_registry,
                );
                component_value = b_component_value;
            },
            ComponentType::Reactable => {
                let reactable_opt: Option<Reactable> = ReactableComponent::get_component(world, target, game_id);
                if reactable_opt.is_none() {
                    return false;
                }
                let reactable: Reactable = OptionTrait::unwrap(reactable_opt);
                let (b_component_value, _) = VariablePropertyHelper::get_reactable_property(
                    @reactable, self.property, @property_registry, *world, game_id,
                );
                component_value = b_component_value;
            },
            ComponentType::InventoryItem => {
                let inventory_item_opt: Option<InventoryItem> = InventoryItemComponent::get_component(world, target, game_id);
                if inventory_item_opt.is_none() {
                    return false;
                }
                let inventory_item: InventoryItem = OptionTrait::unwrap(inventory_item_opt);
                let (b_component_value, _) =
                    VariablePropertyHelper::get_inventory_item_property(
                    @inventory_item, self.property, @property_registry,
                );
                component_value = b_component_value;
            },
            ComponentType::Container => {
                let container_opt: Option<Container> = ContainerComponent::get_component(world, target, game_id);
                if container_opt.is_none() {
                    return false;
                }
                let container: Container = OptionTrait::unwrap(container_opt);
                let (b_component_value, _) = VariablePropertyHelper::get_container_property(
                    @container, self.property, @property_registry,
                );
                component_value = b_component_value;
            },
            ComponentType::Player => {
                let container_opt: Option<Player> = PlayerComponent::get_component(world, target, game_id);
                if container_opt.is_none() {
                    return false;
                }
                let player: Player = OptionTrait::unwrap(container_opt);
                let (b_component_value, _) = VariablePropertyHelper::get_player_property(
                    @player, self.property, @property_registry,
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
                (result)
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
                (result)
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
                (result)
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
                (result)
            },
        }
    }
    // (result) // Unreachable code
}

#[cfg(test)]
mod tests {
    use super::*;
    use dojo::{model::ModelStorage};
    use lore::tests::helpers;
    use lore::{
        models::{
            entity::{Entity, EntityImpl},
            description_text::{DescriptionText},
            reactable::{Reactable},
            condition::{Condition},
            components::{Component},
            reactable::ReactableComponent,
        },
        types::{
            component_type::{ComponentType, ActionMapReactable, ReactableActions},
        },
        lib::{
            variable_property_helper::{VariablePropertyHelper},
        },
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
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        // Create entity and attach ReactableComponent
        let mut door: Entity = EntityImpl::create_entity(ref sys.world, "door");
        sys.world.write_model(@door);

        let game_id: u128 = 0;
        let new_entry: ByteArray = "A door";
        let mut reactable: Reactable = Component::add_component(ref sys.world, door.inst);
        let desc1: DescriptionText = DescriptionText {
            inst: door.inst, key: 0, text: new_entry.clone(),
        };
        sys.world.write_model(@desc1);
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
        reactable.store(ref sys.world, 0);

        // Register component variable properties
        VariablePropertyHelper::register_component_properties(ref sys.world, ComponentType::Reactable);

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
        sys.world.write_model(@condition);
        assert(
            condition
                .evaluate_condition(
                    @sys.world,
                    @TriggerContext { doer: 0, target1: 0, target2: 0, inventory_object: 0 },
                    game_id,
                ),
            'is_reactable should be true',
        );

        // Test: is_reactable == false (should fail)
        let key3: felt252 = 3;
        let name3: ByteArray = "Condition name3";
        let mut array_false: Array<felt252> = ArrayTrait::new();
        array_false.append(0);
        let mut condition2: Condition = create_test_condition(
            door.inst,
            key3,
            name3,
            door.inst,
            ComponentType::Reactable,
            "is_reactable",
            Operator::Equals,
            array_false,
        );
        sys.world.write_model(@condition2);
        assert(
            !condition2
                .evaluate_condition(
                    @sys.world,
                    @TriggerContext { doer: 0, target1: 0, target2: 0, inventory_object: 0 },
                    game_id,
                ),
            'is_reactable should be false',
        );

        // Test: is_visible == true (should pass)
        let key4: felt252 = 4;
        let name4: ByteArray = "Condition name4";
        let mut array3: Array<felt252> = ArrayTrait::new();
        array3.append(1);
        let mut condition3: Condition = create_test_condition(
            door.inst,
            key4,
            name4,
            door.inst,
            ComponentType::Reactable,
            "is_visible",
            Operator::Equals,
            array3,
        );
        sys.world.write_model(@condition3);
        assert(
            condition3
                .evaluate_condition(
                    @sys.world,
                    @TriggerContext { doer: 0, target1: 0, target2: 0, inventory_object: 0 },
                    game_id,
                ),
            'is_visible should be true',
        );

        // Test: is_visible == false (should fail)
        let key5: felt252 = 5;
        let name5: ByteArray = "Condition name5";
        let mut array4: Array<felt252> = ArrayTrait::new();
        array4.append(0);
        let mut condition4: Condition = create_test_condition(
            door.inst,
            key5,
            name5,
            door.inst,
            ComponentType::Reactable,
            "is_visible",
            Operator::Equals,
            array4,
        );
        sys.world.write_model(@condition4);
        assert(
            !condition4
                .evaluate_condition(
                    @sys.world,
                    @TriggerContext { doer: 0, target1: 0, target2: 0, inventory_object: 0 },
                    game_id,
                ),
            'is_visible should be false',
        );

        // Test: is_visible != 0 (should pass)
        let key6: felt252 = 6;
        let name6: ByteArray = "Condition name6";
        let mut not_eq_array: Array<felt252> = ArrayTrait::new();
        not_eq_array.append(0);
        let mut condition5: Condition = create_test_condition(
            door.inst,
            key6,
            name6,
            door.inst,
            ComponentType::Reactable,
            "is_visible",
            Operator::NotEquals,
            not_eq_array,
        );
        sys.world.write_model(@condition5);
        assert(
            condition5
                .evaluate_condition(
                    @sys.world,
                    @TriggerContext { doer: 0, target1: 0, target2: 0, inventory_object: 0 },
                    game_id,
                ),
            'should not be equal',
        );

        // Test: is_visible != 1 (should fail)
        let key7: felt252 = 7;
        let name7: ByteArray = "Condition name7";
        let mut not_eq_array2: Array<felt252> = ArrayTrait::new();
        not_eq_array2.append(1);
        let mut condition6: Condition = create_test_condition(
            door.inst,
            key7,
            name7,
            door.inst,
            ComponentType::Reactable,
            "is_visible",
            Operator::NotEquals,
            not_eq_array2,
        );
        sys.world.write_model(@condition6);
        assert(
            !condition6
                .evaluate_condition(
                    @sys.world,
                    @TriggerContext { doer: 0, target1: 0, target2: 0, inventory_object: 0 },
                    game_id,
                ),
            'should not be false',
        );
    }
}

