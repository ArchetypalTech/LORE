use dojo::{world::{WorldStorage}};

use lore::{
    lib::{
        entity::{EntityImpl},
        trigger::{TriggerContext, TriggerImpl},
    },
    components::{
        Component, 
        inspectable::{Inspectable,InspectableComponent},
        area::{Area, AreaComponent},
        exit::{Exit, ExitComponent},
        inventoryItem::{InventoryItem,InventoryItemComponent},
        container::{Container,ContainerComponent},
        player::{Player, PlayerComponent},
    },
};

#[derive(Clone, Drop, Serde, Debug)]
#[dojo::model]
pub struct Condition {
    #[key]
    pub key: felt252,        // Unique identifier
    pub target: felt252,     // Entity to check (can be optional for global conditions)
    pub component: ComponentType,  // Which component to check
    pub property: felt252,   // Which property of the component to check
    pub operator: Operator,  // How to compare the values
    pub value: felt252,      // Value to compare against
}

#[derive(Clone, Drop, Serde, Debug, PartialEq, Introspect)]
pub enum Operator {
    Equals,
    // Implement rest later
}

#[derive(Clone, Drop, Serde, Debug, PartialEq, Introspect)]
pub enum ComponentType {
    Area,
    Exit,
    Container,
    Inspectable,
    InventoryItem,
    Player,
    //etc
}

#[generate_trait]
pub impl ConditionImpl of ConditionTrait {
    fn evaluate_condition(
        self: @Condition,
        world: WorldStorage,
        context: TriggerContext
    ) -> bool {
       let target = *self.target;

        match self.component {
            ComponentType::Container => {
                let container_opt = ContainerComponent::get_component(world, target);
                if container_opt.is_none() {
                    return false;
                }
                let container = OptionTrait::unwrap(container_opt);

                return true;

                // match self.property {
                //     "is_open" => {
                //         let field_value = container.is_open.into();
                //         return self.compare(field_value);
                //     },
                //     'can_be_opened' => {
                //         let field_value = container.can_be_opened.into();
                //         return self.compare(field_value);
                //     },
                //     _ => { return false; },
                // }
            },
            ComponentType::Inspectable => {
                let inspectable_opt = InspectableComponent::get_component(world, target);
                if inspectable_opt.is_none() {
                    return false;
                }
                let inspectable = OptionTrait::unwrap(inspectable_opt);

                return true;

                // match self.property {
                //     'is_visible' => {
                //         let field_value = inspectable.is_visible.into();
                //         return self.compare(field_value);
                //     },
                //     _ => {return false; },
                // }
            },
            // Add other components if needed later
            _ => { return false; },
        }
    }

    fn compare(self: @Condition, component_value: felt252) -> bool {
        match self.operator {
            Operator::Equals => 
            { if component_value == *self.value {
                return true;
            } else {
                return false;
            }},
        }
    }
}