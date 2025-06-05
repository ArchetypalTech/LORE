use dojo::{world::WorldStorage, model::ModelStorage};

use lore::{
    components::{
        area::{AreaComponent},
        exit::{ExitComponent},
        inspectable::{InspectableComponent},
        inventoryItem::{InventoryItemComponent},
        container::{ContainerComponent},
        player::{PlayerComponent},
        Components,
    },
    lib::{
        utils::ByteArrayTraitExt,
        variable_property::{VariablePropertyImp, PropertyAccess, ComponentVariable},
        trigger::TriggerContext, 
    },
    constants::errors::Error,
};

#[derive(Clone, Drop, Serde, Debug, Introspect, PartialEq)]
#[dojo::model]
pub struct Effect {
    #[key]
    pub inst: felt252,              // Unique identifier of the entity it is attached to
    #[key]
    pub key: felt252,              // Unique identifier of this effect
    pub target: felt252,           // Target entity
    pub component: Components,     // Component to affect
    pub property: ByteArray,       // Property to modify
    pub value: Array<ByteArray>,   // New value to set, needs to be array for multiple values such as description.
}

// A registry-style effect template
#[derive(Clone, Drop, Serde, Debug, Introspect)]
pub struct EffectTemplate {
    #[key]
    pub key: felt252,
    pub name: ByteArray,
    pub effect_type: EffectType,
    pub required_parameters: Array<ParameterDefinition>,
    pub optional_parameters: Array<ParameterDefinition>,
}

#[derive(Clone, Drop, Serde, Debug, Introspect)]
pub struct ParameterDefinition {
    pub name: ByteArray,
    pub param_type: ParameterType,
    pub description: ByteArray,
}

#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum ParameterType {
    Boolean,
    Integer,
    Felt252,
    Direction,
    ContractAddress,
    String,
    ByteArray,
    Enum,
    EntityReference,
}

#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum EffectType {
    ModifyComponent,
    TriggerEvent,
    CustomLogic,
}


// Runtime tracking for debugging
#[derive(Clone, Drop, Serde, Debug, Introspect)]
#[dojo::model]
pub struct EffectExecution {
    #[key]
    pub key: felt252,
    pub effect_key: felt252,
    pub timestamp: u64,
    pub parameters: Array<EffectParameter>,
    pub status: ExecutionStatus,
    pub error_message: ByteArray,
}

#[derive(Serde, Copy, Drop, Debug, PartialEq,Introspect)]
pub enum ExecutionStatus {
    Success,
    Failure,
}

#[derive(Clone, Drop, Serde, Debug, Introspect)]
pub struct EffectParameter {
    pub name: ByteArray,
    pub value: felt252,
}

#[generate_trait]
pub impl EffectImpl of EffectTrait {
    fn apply_effect(
        self: @Effect,
        mut world: WorldStorage,
        context: TriggerContext,
    ) -> Result<(), Error> {
        let zero: felt252 = 0;
        let mut result: Result::<(), Error> = Result::Err(Error::EffectFailed);
        // Resolve target: use explicit target, fallback to context
        let actual_target = if self.target == @zero {
            @context.target1
        } else {
            self.target
        };
        
        match self.component {
            Components::Area => {
                let area_opt = AreaComponent::get_component(world, *actual_target);
                if area_opt.is_none() {
                    result = Result::Err(Error::NoAreaComponent);
                }
                let mut area = area_opt.unwrap();
                // Direct modification to component
                result = VariablePropertyImp::set_property(@world, @area.inst, self.property, self.value, self.component.clone());
                // THIS WOULD BE FOR THE COMPONENT VARIABLE TO UPDATE CHANGES ON THE COMPONENT WHEN changed?
                // success = Self::update_property(
                //     world,
                //     @area.inst,
                //     self.component.clone(),
                //     self.property.clone(),
                //     *self.value,
                //     context
                // );
            },
            Components::Exit => {
                let exit_opt = ExitComponent::get_component(world, *actual_target);
                if exit_opt.is_none() {
                    result = Result::Err(Error::NoExitComponent);
                }
                let mut exit = exit_opt.unwrap();
                result = VariablePropertyImp::set_property(@world, @exit.inst, self.property, self.value, self.component.clone());
                // success = Self::update_property(
                //     world,
                //     @exit.inst,
                //     self.component.clone(),
                //     self.property.clone(),
                //     *self.value,
                //     context
                // );
            },
            Components::Inspectable => {
                let inspect_opt = InspectableComponent::get_component(world, *actual_target);
                if inspect_opt.is_none() {
                    result = Result::Err(Error::NoInspectableComponent);
                }
                let mut inspectable = inspect_opt.unwrap();
                result = VariablePropertyImp::set_property(@world, @inspectable.inst, self.property, self.value, self.component.clone());
                // success = Self::update_property(
                //     world,
                //     @inspectable.inst,
                //     self.component.clone(),
                //     self.property.clone(),
                //     *self.value,
                //     context
                // );
            },
            Components::InventoryItem => {
                let item_opt = InventoryItemComponent::get_component(world, *actual_target);
                if item_opt.is_none() {
                    result = Result::Err(Error::NoInventoryItemComponent);
                }
                let mut item = item_opt.unwrap();
                result = VariablePropertyImp::set_property(@world, @item.inst, self.property, self.value, self.component.clone());
                // success = Self::update_property(
                //     world,
                //     @item.inst,
                //     self.component.clone(),
                //     self.property.clone(),
                //     *self.value,
                //     context
                // );
            },
            Components::Container => {
                let cont_opt = ContainerComponent::get_component(world, *actual_target);
                if cont_opt.is_none() {
                    result = Result::Err(Error::NoContainerComponent);
                }
                let mut container = cont_opt.unwrap();
                result = VariablePropertyImp::set_property(@world, @container.inst, self.property, self.value, self.component.clone());
                // success = Self::update_property(
                //     world,
                //     @container.inst,
                //     self.component.clone(),
                //     self.property.clone(),
                //     *self.value,
                //     context
                // );
            },
            Components::Player => {
                let player_opt = PlayerComponent::get_component(world, *actual_target);
                if player_opt.is_none() {
                    result = Result::Err(Error::NoPlayerComponent);
                }
                let mut player = player_opt.unwrap();
                result = VariablePropertyImp::set_property(@world, @player.inst, self.property, self.value, self.component.clone());
                // success = Self::update_property(
                //     world,
                //     @player.inst,
                //     self.component.clone(),
                //     self.property.clone(),
                //     *self.value,
                //     context
                // );
            },
            _ => {
                result = Result::Err(Error::NoComponent);
            },
        }

        result
    }

    fn update_property(
    mut world: WorldStorage,
    key: @felt252,
    component_type: Components,
    property: ByteArray,
    value: ByteArray,
    context: TriggerContext
    ) -> bool {
        let (_current_value_opt, access_opt) =
            VariablePropertyImp::get_property(@world, key, @property, component_type);

        if access_opt.is_none() {
            return false;
        }

        let access = access_opt.unwrap();
        match access {
            PropertyAccess::WriteOnly | PropertyAccess::ReadWrite => {
                let comp_var = ComponentVariable {
                    key: key.clone(),
                    component_type,
                    entity_id: *key,
                    property_name: property.clone(),
                    value,
                    last_updated: 0, // TODO: set timestamp using context later?
                };

                world.write_model(@comp_var);
                return true;
            },
            PropertyAccess::ReadOnly => {
                return false;
            },
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use dojo::{model::ModelStorage};
    use lore::tests::helpers;
    use lore::{lib::{entity::{EntityImpl}, trigger::{TriggerImpl}, variable_property::{VariablePropertyImp}},
        components::{area::{AreaComponent}, 
        inspectable::{Inspectable, InspectableComponent, ActionMapInspectable, InspectableActions},
        player::{Player, PlayerComponent, caller_as_player, PlayerImpl},
        Component, Components,},
    };

    fn create_test_effect(inst: felt252, key: felt252, target: felt252, component: Components, property: ByteArray, value: Array<ByteArray>) -> Effect {
        Effect {
            inst,
            key,
            target,
            component,
            property,
            value,
        }
    }

    fn create_trigger_context(doer: felt252, target1: felt252, target2: felt252, inventory_object: felt252) -> TriggerContext {
        TriggerContext {
            doer,
            target1,
            target2,
            inventory_object,
        }
    }
    
    #[test]
    fn Effect_test_apply_effect() {
        let (mut world, _, _, player_1, _) = helpers::setup_core();
        // create door entity
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

        // Create player
        let mut player: Player = caller_as_player(world, player_1);        
        world.write_model(@player);

        // Create trigger context
        let mut context = create_trigger_context(player.inst, door.inst, 0, 0);

        // register variable properties
        VariablePropertyImp::register_component_properties(world, Components::Inspectable);
        
        // Test description new value
        let new_value: Array<ByteArray> = array!["A door that is open", "Looks that it leads somewhere"];
        let key: felt252 = 1;
        let mut effect = create_test_effect(door.inst, key, door.inst, Components::Inspectable, "description", new_value.clone());
        world.write_model(@effect);
        let result = effect.apply_effect(world, context);

        let new_inspectable: Inspectable = world.read_model(door.inst);

        assert_ne!(inspectable.description[0], new_inspectable.description[0], "Effect should update description");
        assert_eq!(new_inspectable.description[1], new_value.at(1), "Effect should update description");
        assert_eq!(result.is_ok(), true, "Effect should apply successfully");
    }
}

