use dojo::{world::{WorldStorage}, model::ModelStorage};

use lore::{
    models::{
        index::{PropertyRegistry},
        player::{PlayerComponent},
        area::{AreaComponent},
        exit::{ExitComponent},
        reactable::{ReactableComponent},
        inventory_item::{InventoryItemComponent},
        container::{ContainerComponent},
    },
    types::{
        action_type::{TriggerContext, EffectType},
        component_type::{ComponentType},
    },
    lib::{
        utils::ByteArrayTraitExt,
        variable_property_helper::{VariablePropertyHelper},
    },
    constants::errors::Error,
};

#[derive(Clone, Drop, Serde, Debug, Introspect, PartialEq)]
#[dojo::model]
pub struct Effect {
    /// Unique identifier attached to the entity
    #[key]
    pub inst: felt252,
    /// Unique identifier of the effect
    #[key]
    pub key: felt252,
    /// Effect name
    pub name: ByteArray,
    /// Target entity
    pub target: felt252,
    /// Effect type
    pub effect_type: EffectType,
    /// Component to affect
    pub component: ComponentType,
    /// Property to modify
    pub property: ByteArray,
    /// New value to set, needs to be tuple array. First element is the value, second is the index
    /// (for texts).
    pub value: Array<(ByteArray, u32)>,
    /// for numbers: the value that will add/substract or replace the current value
    pub n_value: u32,
    // for hex: will be used mostly in owner_id
    pub hex_value: felt252,
}


//---------------------------------
// Model Trait
//
#[generate_trait]
pub impl EffectImpl of EffectTrait {
    fn apply_effect(
        self: @Effect, ref world: WorldStorage, context: @TriggerContext, game_id: u128,
    ) -> Result<(), Error> {
        let zero: felt252 = 0;
        let mut result: Result::<(), Error> = Result::Err(Error::EffectFailed);
        // Resolve target: use explicit target, fallback to context
        let actual_target = if self.target == @zero {
            *context.target1
        } else {
            *self.target
        };

        match self.component {
            ComponentType::Area => {
                let comp = AreaComponent::get_component(@world, actual_target, game_id);
                match comp {
                    Option::Some(mut area) => {
                        let property_registry: PropertyRegistry = world.read_model(*self.component);
                        // Direct modification to component
                        let (result_p, _success_p) = VariablePropertyHelper::set_area_property(
                            ref area, ref world, self.property, @property_registry, self.value.span(), game_id,
                        );
                        result = result_p;
                    },
                    Option::None => {
                        result = Result::Err(Error::NoAreaComponent);
                    }
                }
            },
            ComponentType::Exit => {
                let comp = ExitComponent::get_component(@world, actual_target, game_id);
                match comp {
                    Option::Some(mut exit) => {
                        let property_registry: PropertyRegistry = world.read_model(*self.component);
                        // Direct modification to component
                        let (result_p, _success_p) = VariablePropertyHelper::set_exit_property(
                            ref exit, ref world, self.property, @property_registry, self.value.span(), self.hex_value, game_id,
                        );
                        result = result_p;
                    },
                    Option::None => {
                        result = Result::Err(Error::NoExitComponent);
                    }
                }
            },
            ComponentType::Reactable => {
                let comp = ReactableComponent::get_component(@world, actual_target, game_id);
                match comp {
                    Option::Some(mut reactable) => {
                        let property_registry: PropertyRegistry = world.read_model(*self.component);
                        // Direct modification to component
                        let (result_p, _success_p) = VariablePropertyHelper::set_reactable_property(
                            ref reactable, ref world, self.property, @property_registry, self.value.span(), game_id,
                        );
                        result = result_p;
                    },
                    Option::None => {
                        result = Result::Err(Error::NoReactableComponent);
                    }
                }
            },
            ComponentType::InventoryItem => {
                let comp = InventoryItemComponent::get_component(@world, actual_target, game_id);
                match comp {
                    Option::Some(mut item) => {
                        let property_registry: PropertyRegistry = world.read_model(*self.component);
                        println!("Component applying effect: {:?}", item);
                        // Direct modification to component
                        let (result_p, _success_p) =
                            VariablePropertyHelper::set_inventory_item_property(
                                ref item, ref world, self, @property_registry, game_id,
                            );
                        result = result_p;
                    },
                    Option::None => {
                        result = Result::Err(Error::NoInventoryItemComponent);
                    }
                }
            },
            ComponentType::Container => {
                let comp = ContainerComponent::get_component(@world, actual_target, game_id);
                match comp {
                    Option::Some(mut container) => {
                        let property_registry: PropertyRegistry = world.read_model(*self.component);
                        // Direct modification to component
                        let (result_p, _success_p) =
                            VariablePropertyHelper::set_container_property(
                                ref container,
                                ref world,
                                self.property,
                                self.effect_type,
                                @property_registry,
                                self.value.span(),
                                *self.n_value,
                                game_id,
                            );
                        result = result_p;
                    },
                    Option::None => {
                        result = Result::Err(Error::NoContainerComponent);
                    }
                }
            },
            ComponentType::Player => {
                let comp = PlayerComponent::get_component(@world, actual_target, game_id);
                match comp {
                    Option::Some(mut player) => {
                        let property_registry: PropertyRegistry = world.read_model(*self.component);
                        // Direct modification to component
                        let (result_p, _success_p) = VariablePropertyHelper::set_player_property(
                            ref player, ref world, self.property, @property_registry, self.value.span(), self.hex_value, game_id,
                        );
                        result = result_p;
                    },
                    Option::None => {
                        result = Result::Err(Error::NoPlayerComponent);
                    }
                }
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
            entity::{EntityImpl},
            index::{DescriptionText},
            reactable::{Reactable},
            trigger::{TriggerImpl},
            player::{Player, PlayerImpl},
            components::{Component}, 
        },
        types::{
            action_type::{TriggerContext, EffectType},
            component_type::{ComponentType, ActionMapReactable, ReactableActions},
        },
        lib::{
            variable_property_helper::{VariablePropertyHelper},
        },
    };

    fn create_test_effect(
        inst: felt252,
        key: felt252,
        name: ByteArray,
        effect_type: EffectType,
        target: felt252,
        component: ComponentType,
        property: ByteArray,
        value: Array<(ByteArray, u32)>,
        n_value: u32,
        hex_value: felt252,
    ) -> Effect {
        Effect { inst, key, name, target, effect_type, component, property, value, n_value, hex_value, }
    }

    // used for tests
    fn create_trigger_context(
        doer: felt252, target1: felt252, target2: felt252, inventory_object: felt252,
    ) -> TriggerContext {
        TriggerContext { doer, target1, target2, inventory_object }
    }

    #[test]
    fn Effect_test_apply_effect() {
        let (mut world, _, _, _, player_1, _) = helpers::setup_core();
        // create door entity
        let mut door = EntityImpl::create_entity(ref world, "door");
        world.write_model(@door);
        let mut reactable: Reactable = Component::add_component(ref world, door.inst);
        let desc1: DescriptionText = DescriptionText { inst: door.inst, key: 0, text: "A door" };
        world.write_model(@desc1);
        reactable.is_reactable = true;
        reactable.is_visible = true;
        reactable.description = array![0];
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
        reactable.store(ref world, 0);
        let old_insp_door: Reactable = world.read_model(door.inst);
        let old_key: u32 = *old_insp_door.description.at(0);
        let old_txt: DescriptionText = world.read_model((door.inst, old_key));

        // Create player
        let game_id: u128 = 0;
        let mut player: Player = PlayerImpl::caller_as_player(ref world, player_1, game_id);
        world.write_model(@player);

        // Create trigger context
        let mut context = create_trigger_context(player.inst, door.inst, 0, 0);

        // register variable properties
        VariablePropertyHelper::register_component_properties(ref world, ComponentType::Reactable);

        // Test description new value
        let new_value: Array<(ByteArray, u32)> = array![
            ("A door that is open", 0), ("Looks that it leads somewhere", 1),
        ];
        let key: felt252 = 1;
        let name: ByteArray = "Effect name";
        let n_value: u32 = 0;
        let hex_value: felt252 = 0;
        let mut effect = create_test_effect(
            door.inst,
            key,
            name,
            EffectType::ModifyProperty,
            door.inst,
            ComponentType::Reactable,
            "description",
            new_value.clone(),
            n_value,
            hex_value,
        );
        world.write_model(@effect);
        let result = effect.apply_effect(ref world, @context, game_id);

        let new_reactable: Reactable = world.read_model(door.inst);
        let key: u32 = *new_reactable.description.at(0);
        let key2: u32 = *new_reactable.description.at(1);
        let new_txt1: DescriptionText = world.read_model((door.inst, key));
        let new_txt2: DescriptionText = world.read_model((door.inst, key2));

        let (defTxt2, _defKey2) = new_value.at(1);

        assert_ne!(old_txt.text, new_txt1.text.clone(), "Effect should update description");
        assert_eq!(new_txt2.text.clone(), defTxt2.clone(), "Effect should update description");
        assert_eq!(result.is_ok(), true, "Effect should apply successfully");
    }
}

