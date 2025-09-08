use dojo::{world::{WorldStorage}, model::ModelStorage};
use lore::{
    models::{
        index::{PropertyRegistry},
        area::{Area},
        exit::{Exit},
        reactable::{Reactable},
        inventory_item::{InventoryItem},
        container::{Container},
        player::{Player},
    },
    types::{
        property_type::{PropertyAccess},
        component_type::{ComponentType},
        action_type::{EffectType},
    },
    lib::{
        utils::ByteArrayTraitExt,
        variable_property_helper::VariablePropertyHelperTrait,
        game_instance::GameImpl,
    },
    constants::errors::Error,
};


#[generate_trait]
pub impl VariablePropertyImp of VariablePropertyTrait {
    fn register_component_properties(ref world: WorldStorage, component: ComponentType) {
        VariablePropertyHelperTrait::register_properties(ref world, component);
    }

    fn get_property(
        world: @WorldStorage,
        key: @felt252,
        property_name: @ByteArray,
        component_type: ComponentType,
        game_id: u128,
    ) -> (Option<Array<felt252>>, Option<PropertyAccess>) {
        let property_registry: PropertyRegistry = world.read_model((component_type));
        let mut property_value: Option<Array<felt252>> = Option::None;
        let mut access: Option<PropertyAccess> = Option::None;

        match property_registry.component_type.clone() {
            ComponentType::Area => {
                let component: Area = world.read_game_model(*key, game_id);
                let prop_text = property_name.clone();
                let (property_value_opt, access_opt) =
                    VariablePropertyHelperTrait::get_area_property(
                    component, @prop_text, @property_registry,
                );
                property_value = property_value_opt;
                access = access_opt;
            },
            ComponentType::Exit => {
                let component: Exit = world.read_game_model(*key, game_id);
                let prop_text = property_name.clone();
                let (property_value_opt, access_opt) =
                    VariablePropertyHelperTrait::get_exit_property(
                    component, @prop_text, @property_registry,
                );
                property_value = property_value_opt;
                access = access_opt;
            },
            ComponentType::Reactable => {
                let component: Reactable = world.read_game_model(*key, game_id);
                let prop_text = property_name.clone();
                let (property_value_opt, access_opt) =
                    VariablePropertyHelperTrait::get_reactable_property(
                    component, @prop_text, @property_registry, *world,
                );
                property_value = property_value_opt;
                access = access_opt;
            },
            ComponentType::InventoryItem => {
                let component: InventoryItem = world.read_game_model(*key, game_id);
                let prop_text = property_name.clone();
                let (property_value_opt, access_opt) =
                    VariablePropertyHelperTrait::get_inventory_item_property(
                    component, @prop_text, @property_registry,
                );
                property_value = property_value_opt;
                access = access_opt;
            },
            ComponentType::Container => {
                let component: Container = world.read_game_model(*key, game_id);
                let prop_text = property_name.clone();
                let (property_value_opt, access_opt) =
                    VariablePropertyHelperTrait::get_container_property(
                    component, @prop_text, @property_registry,
                );
                property_value = property_value_opt;
                access = access_opt;
            },
            ComponentType::Player => {
                let component: Player = world.read_game_model(*key, game_id);
                let prop_text = property_name.clone();
                let (property_value_opt, access_opt) =
                    VariablePropertyHelperTrait::get_player_property(
                    component, @prop_text, @property_registry,
                );
                property_value = property_value_opt;
                access = access_opt;
            },
            _ => { // Do nothing
            },
        }
        return (property_value, access);
    }

    fn set_property(
        mut world: @WorldStorage,
        key: @felt252,
        effect_type: @EffectType,
        property_name: @ByteArray,
        new_value: @Array<(ByteArray, u32)>,
        num_value: @u32,
        component_type: ComponentType,
        game_id: u128,
    ) -> Result<(), Error> {
        let property_registry: PropertyRegistry = world.read_model((component_type));
        let mut success: bool = false;
        let mut result: Result::<(), Error> = Result::Err((Error::EffectFailed));
        match component_type.clone() {
            ComponentType::Area => {
                let component: Area = world.read_game_model(*key, game_id);
                let prop_text = property_name.clone();
                let (result_p, success_p) = VariablePropertyHelperTrait::set_area_property(
                    component, *world, @prop_text, @property_registry, new_value, game_id,
                );
                result = result_p;
                success = success_p;
            },
            ComponentType::Exit => {
                let component: Exit = world.read_game_model(*key, game_id);
                let prop_text = property_name.clone();
                let (result_p, success_p) = VariablePropertyHelperTrait::set_exit_property(
                    component, *world, @prop_text, @property_registry, new_value, game_id,
                );
                result = result_p;
                success = success_p;
            },
            ComponentType::Reactable => {
                let component: Reactable = world.read_game_model(*key, game_id);
                let prop_text = property_name.clone();
                let (result_p, success_p) = VariablePropertyHelperTrait::set_reactable_property(
                    component, *world, @prop_text, @property_registry, new_value, game_id,
                );
                result = result_p;
                success = success_p;
            },
            ComponentType::InventoryItem => {
                let component: InventoryItem = world.read_game_model(*key, game_id);
                let prop_text = property_name.clone();
                let (result_p, success_p) =
                    VariablePropertyHelperTrait::set_inventory_item_property(
                    component,
                    *world,
                    @prop_text,
                    effect_type,
                    @property_registry,
                    new_value,
                    num_value,
                    game_id,
                );
                result = result_p;
                success = success_p;
            },
            ComponentType::Container => {
                let component: Container = world.read_game_model(*key, game_id);
                let prop_text = property_name.clone();
                let (result_p, success_p) = VariablePropertyHelperTrait::set_container_property(
                    component,
                    *world,
                    @prop_text,
                    effect_type,
                    @property_registry,
                    new_value,
                    num_value,
                    game_id,
                );
                result = result_p;
                success = success_p;
            },
            ComponentType::Player => {
                let component: Player = world.read_game_model(*key, game_id);
                let prop_text = property_name.clone();
                let (result_p, success_p) = VariablePropertyHelperTrait::set_player_property(
                    component, *world, @prop_text, @property_registry, new_value, game_id,
                );
                result = result_p;
                success = success_p;
            },
            _ => { // Do nothing
            },
        }
        return result;
    }
}

