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

#[derive(Clone, Drop, Serde, Debug)]
#[dojo::model]
pub struct Effect {
    #[key]
    pub key: felt252,              // Unique identifier
    pub target: felt252,           // Target entity
    pub component: Components,     // Component to affect
    pub property: ByteArray,       // Property to modify
    pub value: felt252,            // New value to set
}

#[generate_trait]
pub impl EffectImpl of EffectTrait {
    fn apply_effect(
        self: @Effect,
        mut world: WorldStorage,
        context: TriggerContext
    ) -> bool {
        let target = *self.target;
        let mut success = false;

        match self.component {
            Components::Area => {
                let area_opt = AreaComponent::get_component(world, target);
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
                );
            },
            Components::Exit => {
                let exit_opt = ExitComponent::get_component(world, target);
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
                );
            },
            Components::Inspectable => {
                let inspect_opt = InspectableComponent::get_component(world, target);
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
                );
            },
            Components::InventoryItem => {
                let item_opt = InventoryItemComponent::get_component(world, target);
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
                );
            },
            Components::Container => {
                let cont_opt = ContainerComponent::get_component(world, target);
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
                );
            },
            Components::Player => {
                let player_opt = PlayerComponent::get_component(world, target);
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
                );
            },
            _ => { return false; },
        }

        success
    }

    fn update_property(
        mut world: WorldStorage,
        key: @felt252,
        component_type: Components,
        property: ByteArray,
        value: felt252
    ) -> bool {
        let (_current_value_opt, access_opt) = VariablePropertyTrait::get_property(@world, key, @property);

        // If we cannot access or it's write-only, block it
        if access_opt.is_none() {
            return false;
        }

        let access = access_opt.unwrap();
        match access {
            PropertyAccess::WriteOnly | PropertyAccess::ReadWrite => {
                // Use the ComponentVariable proxy model (if needed)
                let comp_var = ComponentVariable {
                    key: key.clone(),
                    component_type,
                    entity_id: *key,
                    property_name: property.clone(),
                    value,
                    last_updated: 0, // TODO: add proper timestamp logic if needed
                };

                // Write to model (simulates side effect on property)
                world.write_model(@comp_var);
                return true;
            },
            PropertyAccess::ReadOnly => { return false; },
        }
    }
}