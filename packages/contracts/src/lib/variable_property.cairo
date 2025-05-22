use dojo::{world::{WorldStorage}, model::ModelStorage};
use lore::{
    components::{ 
        area::{Area, AreaComponent},
        exit::{Exit, ExitComponent},
        inspectable::{Inspectable, InspectableComponent},
        inventoryItem::{InventoryItem,InventoryItemComponent},
        container::{Container, ContainerComponent},
        player::{Player, PlayerComponent},
    },
    lib::utils::ByteArrayTraitExt,
};

// ========== VARIABLE PROXY MODEL ==========
// DONT KNOW IF THIS IS NEEDED YET
#[derive(Clone, Drop, Serde, Debug)]
#[dojo::model]
pub struct ComponentVariable {
    #[key]
    pub key: felt252,
    pub component_type: ComponentType,
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
    pub component_type: ComponentType,
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
        world: WorldStorage,
        key: felt252,
        property_name: ByteArray
    ) -> felt252 {        
        
        let property_registry: PropertyRegistry = world.read_model(key);
        let none_value: felt252 = 999;
        let mut property_value: felt252 = none_value;

        match property_registry.component_type {
            ComponentType::Area => {
                let component: Exit = world.read_model(key);
                let prop_text = property_name.clone();
                property_value = Self::get_exit_property(component, prop_text, property_registry);
            },
            _ => {
                // let component: Exit = world.read_model(key);
                // property_value = Self::get_exit_property(component, property_name, property_registry);
            }
 
        }
        return property_value;
    }

    fn get_exit_property(component: Exit, name: ByteArray, property: PropertyRegistry) -> felt252 {
        let is_exit: ByteArray = "is_exit";
        let is_enterable: ByteArray = "is_enterable";
        let leads_to: ByteArray = "leads_to";        
        let direction_type: ByteArray = "direction_type";
        let mut property_value: felt252 = 0;
        let not_property_value: felt252 = 999;

        for property in property.properties {
            if property.name == name {
                //property_value = property.value;
                break;
            }
        };

        return property_value;

        // match name {
        //     name = is_exit => (component.is_exit.into()),
        //     is_enterable =>(component.is_enterable.into()),
        //     leads_to => (component.leads_to),
        //     direction_type => (ByteArrayTraitExt::to_felt252_word(@ByteArrayTraitExt::byte_array_from_direction(component.direction_type)).into()),
        //     _ => 999,
        // }
    }
}