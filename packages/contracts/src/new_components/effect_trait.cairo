use dojo::{world::WorldStorage};

use lore::{
    models::{
        index::{Effect}, area::AreaComponent, exit::ExitComponent,
        inspectable::InspectableComponent, inventoryItem::InventoryItemComponent,
        container::ContainerComponent, player::PlayerComponent,
    },
    types::{action_type::TriggerContext, component_type::ComponentType},
    lib::{utils::ByteArrayTraitExt, variable_property::{VariablePropertyImp}},
    constants::errors::Error,
};

#[generate_trait]
pub impl EffectImpl of EffectTrait {
    fn apply_effect(
        self: @Effect, mut world: WorldStorage, context: TriggerContext,
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
            ComponentType::Area => {
                let area_opt = AreaComponent::get_component(world, *actual_target);
                if area_opt.is_none() {
                    result = Result::Err(Error::NoAreaComponent);
                }
                let mut area = area_opt.unwrap();
                // Direct modification to component
                result =
                    VariablePropertyImp::set_property(
                        @world, @area.inst, self.property, self.value, self.component.clone(),
                    );
            },
            ComponentType::Exit => {
                let exit_opt = ExitComponent::get_component(world, *actual_target);
                if exit_opt.is_none() {
                    result = Result::Err(Error::NoExitComponent);
                }
                let mut exit = exit_opt.unwrap();
                result =
                    VariablePropertyImp::set_property(
                        @world, @exit.inst, self.property, self.value, self.component.clone(),
                    );
            },
            ComponentType::Inspectable => {
                let inspect_opt = InspectableComponent::get_component(world, *actual_target);
                if inspect_opt.is_none() {
                    result = Result::Err(Error::NoInspectableComponent);
                }
                let mut inspectable = inspect_opt.unwrap();
                result =
                    VariablePropertyImp::set_property(
                        @world,
                        @inspectable.inst,
                        self.property,
                        self.value,
                        self.component.clone(),
                    );
            },
            ComponentType::InventoryItem => {
                let item_opt = InventoryItemComponent::get_component(world, *actual_target);
                if item_opt.is_none() {
                    result = Result::Err(Error::NoInventoryItemComponent);
                }
                let mut item = item_opt.unwrap();
                result =
                    VariablePropertyImp::set_property(
                        @world, @item.inst, self.property, self.value, self.component.clone(),
                    );
            },
            ComponentType::Container => {
                let cont_opt = ContainerComponent::get_component(world, *actual_target);
                if cont_opt.is_none() {
                    result = Result::Err(Error::NoContainerComponent);
                }
                let mut container = cont_opt.unwrap();
                result =
                    VariablePropertyImp::set_property(
                        @world, @container.inst, self.property, self.value, self.component.clone(),
                    );
            },
            ComponentType::Player => {
                let player_opt = PlayerComponent::get_component(world, *actual_target);
                if player_opt.is_none() {
                    result = Result::Err(Error::NoPlayerComponent);
                }
                let mut player = player_opt.unwrap();
                result =
                    VariablePropertyImp::set_property(
                        @world, @player.inst, self.property, self.value, self.component.clone(),
                    );
            },
            _ => { result = Result::Err(Error::NoComponent); },
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
            index::{Inspectable, Player}, components::Component, area::AreaComponent,
            inspectable::InspectableComponent, player::{PlayerComponent, caller_as_player},
        },
        new_components::{
            entity_trait::EntityImpl, player_trait::PlayerImpl,
            trigger_trait::TriggerImpl,
        },
        types::{
            action_type::TriggerContext,
            component_type::{ComponentType, ActionMapInspectable, InspectableActions},
        },
        lib::{variable_property::VariablePropertyImp},
    };

    fn create_test_effect(
        inst: felt252,
        key: felt252,
        name: ByteArray,
        target: felt252,
        component: ComponentType,
        property: ByteArray,
        value: Array<ByteArray>,
    ) -> Effect {
        Effect { inst, key, name, target, component, property, value }
    }

    fn create_trigger_context(
        doer: felt252, target1: felt252, target2: felt252, inventory_object: felt252,
    ) -> TriggerContext {
        TriggerContext { doer, target1, target2, inventory_object }
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

        // Create player
        let mut player: Player = caller_as_player(world, player_1);
        world.write_model(@player);

        // Create trigger context
        let mut context = create_trigger_context(player.inst, door.inst, 0, 0);

        // register variable properties
        VariablePropertyImp::register_component_properties(world, ComponentType::Inspectable);

        // Test description new value
        let new_value: Array<ByteArray> = array![
            "A door that is open", "Looks that it leads somewhere",
        ];
        let key: felt252 = 1;
        let name: ByteArray = "Effect name";
        let mut effect = create_test_effect(
            door.inst, key, name, door.inst, ComponentType::Inspectable, "description", new_value.clone(),
        );
        world.write_model(@effect);
        let result = effect.apply_effect(world, context);

        let new_inspectable: Inspectable = world.read_model(door.inst);

        assert_ne!(
            inspectable.description[0],
            new_inspectable.description[0],
            "Effect should update description",
        );
        assert_eq!(
            new_inspectable.description[1], new_value.at(1), "Effect should update description",
        );
        assert_eq!(result.is_ok(), true, "Effect should apply successfully");
    }
}

