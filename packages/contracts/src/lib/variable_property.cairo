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
    lib::{ utils::ByteArrayTraitExt, variable_property_helper::VariablePropertyHelperTrait}
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
    ) -> Option<felt252> {
        
        let property_registry: PropertyRegistry = world.read_model(*key);
        let mut property_value: Option<felt252> = Option::None;

        match property_registry.component_type.clone() {
            Components::Area => {
                let component: Area = world.read_model(*key);
                let prop_text = property_name.clone();
                property_value = VariablePropertyHelperTrait::get_area_property(component, @prop_text, @property_registry);
            },
            Components::Exit => {
                let component: Exit = world.read_model(*key);
                let prop_text = property_name.clone();
                property_value = VariablePropertyHelperTrait::get_exit_property(component, @prop_text, @property_registry);
            },
            Components::Inspectable => {
                let component: Inspectable = world.read_model(*key);
                let prop_text = property_name.clone();
                property_value = VariablePropertyHelperTrait::get_inspectable_property(component, @prop_text, @property_registry);
            },
            Components::InventoryItem => {
                let component: InventoryItem = world.read_model(*key);
                let prop_text = property_name.clone();
                property_value = VariablePropertyHelperTrait::get_inventory_item_property(component, @prop_text, @property_registry);
            },
            Components::Container => {
                let component: Container = world.read_model(*key);
                let prop_text = property_name.clone();
                property_value = VariablePropertyHelperTrait::get_container_property(component, @prop_text, @property_registry);
            },
            Components::Player => {
                let component: Player = world.read_model(*key);
                let prop_text = property_name.clone();
                property_value = VariablePropertyHelperTrait::get_player_property(component, @prop_text, @property_registry);
            },
            _ => {
                // Do nothing
            }
        }
        return property_value;
    }
}