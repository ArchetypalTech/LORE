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
    pub value: felt252,
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
        let mut component_value: Option<felt252> = Option::None;
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

    fn compare(self: @Condition, component_value: felt252) -> bool {
        let mut result = false;
        match self.operator {
            Operator::Equals => { if component_value == *self.value {
                result = true;
            } },
            Operator::NotEquals => { if component_value != *self.value {
                result = true;
            } },
        }
        result
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
        value: felt252,
    ) -> Condition {
        Condition { inst, key, target, component, property, operator, value }
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

        // register variable properties
        VariablePropertyImp::register_component_properties(world, Components::Inspectable);

        // Test is_inspectable == true (1)
        let key2: felt252 = 2;
        let mut condition = create_test_condition(
            door.inst,
            key2,
            door.inst,
            Components::Inspectable,
            "is_inspectable",
            Operator::Equals,
            1,
        );
        world.write_model(@condition);
        assert(
            condition
                .evaluate_condition(
                    @world, TriggerContext { doer: 0, target1: 0, target2: 0, inventory_object: 0 },
                ),
            'is_inspectable should be true',
        );

        // Test is_inspectable == false (0) — should fail
        let key3: felt252 = 3;
        let mut condition2 = create_test_condition(
            door.inst,
            key3,
            door.inst,
            Components::Inspectable,
            "is_inspectable",
            Operator::Equals,
            0,
        );
        world.write_model(@condition);
        assert(
            !condition2
                .evaluate_condition(
                    @world, TriggerContext { doer: 0, target1: 0, target2: 0, inventory_object: 0 },
                ) == true,
            'is_inspectable should be false',
        );

        // Test is_visible == true (1)
        let key4: felt252 = 4;
        let mut condition3 = create_test_condition(
            door.inst, key4, door.inst, Components::Inspectable, "is_visible", Operator::Equals, 1,
        );
        world.write_model(@condition);
        assert(
            condition3
                .evaluate_condition(
                    @world, TriggerContext { doer: 0, target1: 0, target2: 0, inventory_object: 0 },
                ) == true,
            'is_visible should be true',
        );

        // Test is_visible == false (0)
        let key5: felt252 = 5;
        let mut condition4 = create_test_condition(
            door.inst, key5, door.inst, Components::Inspectable, "is_visible", Operator::Equals, 1,
        );
        world.write_model(@condition);
        assert(
            !condition4
                .evaluate_condition(
                    @world, TriggerContext { doer: 0, target1: 0, target2: 0, inventory_object: 0 },
                ) == false,
            'is_visible should be false',
        );
    }
}
