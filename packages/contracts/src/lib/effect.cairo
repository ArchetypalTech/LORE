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
        variable_property::{VariablePropertyTrait, PropertyAccess, ComponentVariable},
        trigger::TriggerContext
    },
};

#[derive(Clone, Drop, Serde, Debug, Introspect)]
#[dojo::model]
pub struct Effect {
    #[key]
    pub key: felt252,              // Unique identifier
    pub target: felt252,           // Target entity
    pub component: Components,     // Component to affect
    pub property: ByteArray,       // Property to modify
    pub value: felt252,            // New value to set
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

#[derive(Clone, Drop, Serde, Debug, Introspect)]
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

#[derive(Clone, Drop, Serde, Debug, Introspect)]
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

#[derive(Clone, Drop, Serde, Debug, Introspect)]
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
    ) -> bool {
        let zero: felt252 = 0;
        // Resolve target: use explicit target, fallback to context
        let actual_target = if self.target == @zero {
            @context.target1
        } else {
            self.target
        };

        let mut success = false;

        match self.component {
            Components::Area => {
                let area_opt = AreaComponent::get_component(world, *actual_target);
                if area_opt.is_none() {
                    return false;
                }
                let mut area = area_opt.unwrap();
                success = Self::update_property(
                    world,
                    @area.inst,
                    self.component.clone(),
                    self.property.clone(),
                    *self.value,
                    context
                );
            },
            Components::Exit => {
                let exit_opt = ExitComponent::get_component(world, *actual_target);
                if exit_opt.is_none() {
                    return false;
                }
                let mut exit = exit_opt.unwrap();
                success = Self::update_property(
                    world,
                    @exit.inst,
                    self.component.clone(),
                    self.property.clone(),
                    *self.value,
                    context
                );
            },
            Components::Inspectable => {
                let inspect_opt = InspectableComponent::get_component(world, *actual_target);
                if inspect_opt.is_none() {
                    return false;
                }
                let mut inspectable = inspect_opt.unwrap();
                success = Self::update_property(
                    world,
                    @inspectable.inst,
                    self.component.clone(),
                    self.property.clone(),
                    *self.value,
                    context
                );
            },
            Components::InventoryItem => {
                let item_opt = InventoryItemComponent::get_component(world, *actual_target);
                if item_opt.is_none() {
                    return false;
                }
                let mut item = item_opt.unwrap();
                success = Self::update_property(
                    world,
                    @item.inst,
                    self.component.clone(),
                    self.property.clone(),
                    *self.value,
                    context
                );
            },
            Components::Container => {
                let cont_opt = ContainerComponent::get_component(world, *actual_target);
                if cont_opt.is_none() {
                    return false;
                }
                let mut container = cont_opt.unwrap();
                success = Self::update_property(
                    world,
                    @container.inst,
                    self.component.clone(),
                    self.property.clone(),
                    *self.value,
                    context
                );
            },
            Components::Player => {
                let player_opt = PlayerComponent::get_component(world, *actual_target);
                if player_opt.is_none() {
                    return false;
                }
                let mut player = player_opt.unwrap();
                success = Self::update_property(
                    world,
                    @player.inst,
                    self.component.clone(),
                    self.property.clone(),
                    *self.value,
                    context
                );
            },
            _ => {
                return false;
            },
        }

        success
    }

    fn update_property(
    mut world: WorldStorage,
    key: @felt252,
    component_type: Components,
    property: ByteArray,
    value: felt252,
    context: TriggerContext
    ) -> bool {
        let (_current_value_opt, access_opt) =
            VariablePropertyTrait::get_property(@world, key, @property);

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
                    last_updated: 0, // TODO: set timestamp using context later
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
