use dojo::{world::{WorldStorage}, model::ModelStorage};
use lore::{
    components::{ 
        area::{Area, AreaComponent},
        exit::{Exit, ExitComponent},
        inspectable::{Inspectable, InspectableComponent},
        inventoryItem::{InventoryItem,InventoryItemComponent},
        container::{Container, ContainerComponent},
        player::{Player, PlayerComponent},
        Components,
    },
    lib::{ utils::ByteArrayTraitExt, variable_property_helper::VariablePropertyHelperTrait},
    constants::errors::Error, 
};

// ========== VARIABLE PROXY MODEL ==========
// DONT KNOW IF THIS IS NEEDED YET
#[derive(Clone, Drop, Serde, Debug)]
#[dojo::model]
pub struct ComponentVariable {
    #[key]
    pub key: felt252,
    pub component_type: Components,
    pub entity_id: felt252,
    pub property_name: ByteArray,
    pub value: felt252,
    pub last_updated: u64,
}

// ========== REGISTRY STRUCTS ==========
#[derive(Clone, Drop, Serde, Introspect)]
#[dojo::model]
pub struct PropertyRegistry {
    #[key]
    pub key: felt252,
    pub component_type: Components,
    pub properties: Array<ComponentProperty>,
}

#[derive(Clone, Drop, Serde, Introspect)]
pub struct ComponentProperty {
    pub name: ByteArray,
    pub property_type: PropertyType,
    pub access_flags: PropertyAccess,
}

// ========== ENUMS & TRAITS ==========
#[derive(Clone, Drop, Serde, Debug, PartialEq, Introspect)]
pub enum PropertyType {
    Boolean,
    Integer,
    Felt252,
    Direction,
    ContractAddress,
    String,
    ByteArray,
    Enum,
}

#[derive(Clone, Drop, Serde, Debug, PartialEq, Introspect)]
pub enum PropertyAccess {
    ReadOnly,
    WriteOnly,
    ReadWrite,
}

#[derive(Copy, Drop, Serde, Debug, PartialEq, Introspect)]
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
pub impl VariablePropertyImp of VariablePropertyTrait {
    fn register_component_properties(mut world: WorldStorage, registry: PropertyRegistry) {
        // Save the variable property registry in storage
        world.write_model(@registry);
    }

    fn get_property(
        world: @WorldStorage,
        key: @felt252,
        property_name: @ByteArray
    ) ->(Option<felt252>, Option<PropertyAccess>) {
        
        let property_registry: PropertyRegistry = world.read_model(*key);
        let mut property_value: Option<felt252> = Option::None;
        let mut access: Option<PropertyAccess> = Option::None;

        match property_registry.component_type.clone() {
            Components::Area => {
                let component: Area = world.read_model(*key);
                let prop_text = property_name.clone();
                let (property_value_opt, access_opt) = VariablePropertyHelperTrait::get_area_property(component, @prop_text, @property_registry);
                property_value = property_value_opt;
                access = access_opt;
            }, 
            Components::Exit => {
                let component: Exit = world.read_model(*key);
                let prop_text = property_name.clone();
                let (property_value_opt, access_opt) = VariablePropertyHelperTrait::get_exit_property(component, @prop_text, @property_registry);
                property_value = property_value_opt;
                access = access_opt;
            },
            Components::Inspectable => {
                let component: Inspectable = world.read_model(*key);
                let prop_text = property_name.clone();
                let (property_value_opt, access_opt) = VariablePropertyHelperTrait::get_inspectable_property(component, @prop_text, @property_registry);
                property_value = property_value_opt;
                access = access_opt;
            },
            Components::InventoryItem => {
                let component: InventoryItem = world.read_model(*key);
                let prop_text = property_name.clone();
                let (property_value_opt, access_opt) = VariablePropertyHelperTrait::get_inventory_item_property(component, @prop_text, @property_registry);
                property_value = property_value_opt;
                access = access_opt;
            },
            Components::Container => {
                let component: Container = world.read_model(*key);
                let prop_text = property_name.clone();
                let (property_value_opt, access_opt) = VariablePropertyHelperTrait::get_container_property(component, @prop_text, @property_registry);
                property_value = property_value_opt;
                access = access_opt;
            },
            Components::Player => {
                let component: Player = world.read_model(*key);
                let prop_text = property_name.clone();
                let (property_value_opt, access_opt) = VariablePropertyHelperTrait::get_player_property(component, @prop_text, @property_registry);
                property_value = property_value_opt;
                access = access_opt;
            },
            _ => {
                // Do nothing
            }
        }
        return (property_value, access);
    }

    fn set_property(
        mut world: @WorldStorage,
        key: @felt252,
        property_name: @ByteArray,
        new_value: @Array<felt252>,
        
    ) -> Result<(), Error> {
        let mut property_registry: PropertyRegistry = world.read_model(*key);
        let mut success: bool = false;
        let mut result: Result::<(), Error> = Result::Err((Error::EffectFailed));

        match property_registry.component_type.clone() {
            Components::Area => {
                let component: Area = world.read_model(*key);
                let prop_text = property_name.clone();
                let (result_p, success_p) = VariablePropertyHelperTrait::set_area_property(component, *world, @prop_text, @property_registry, new_value);
                result = result_p;
                success = success_p;                
            },
            Components::Exit => {
                let component: Exit = world.read_model(*key);
                let prop_text = property_name.clone();
                let (result_p, success_p) = VariablePropertyHelperTrait::set_exit_property(component, *world, @prop_text, @property_registry, new_value);
                result = result_p;
                success = success_p;
            },
            Components::Inspectable => {
                let component: Inspectable = world.read_model(*key);
                let prop_text = property_name.clone();
                let (result_p, success_p) = VariablePropertyHelperTrait::set_inspectable_property(component, *world, @prop_text, @property_registry, new_value);
                result = result_p;
                success = success_p;
            },
            Components::InventoryItem => {
                let component: InventoryItem = world.read_model(*key);
                let prop_text = property_name.clone();
                let (result_p, success_p) = VariablePropertyHelperTrait::set_inventory_item_property(component, *world, @prop_text, @property_registry, new_value);
                result = result_p;
                success = success_p;
            },
            Components::Container => {
                let component: Container = world.read_model(*key);
                let prop_text = property_name.clone();
                let (result_p, success_p) = VariablePropertyHelperTrait::set_container_property(component, *world, @prop_text, @property_registry, new_value);
                result = result_p;
                success = success_p;
            },
            Components::Player => {
                let component: Player = world.read_model(*key);
                let prop_text = property_name.clone();
                let (result_p, success_p) = VariablePropertyHelperTrait::set_player_property(component, *world, @prop_text, @property_registry, new_value);
                result = result_p;
                success = success_p;
            },
            _ => { 
                // Do nothing 
            }
        }
        return result;
    }
}