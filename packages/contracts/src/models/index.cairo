// Here you can find all the defined models.

use lore::{
    types::{
        component_type::{
            ComponentType,
        },
        property_type::{ComponentProperty},
    },
};

#[derive(Clone, Drop, Serde, Introspect, Debug, PartialEq)]
#[dojo::model]
pub struct PropertyRegistry {
    #[key]
    pub component_type: ComponentType,
    pub properties: Array<ComponentProperty>,
}

/// NOT USED YET ///

// ========== VARIABLE PROXY MODEL ==========
// DONT KNOW IF THIS IS NEEDED YET //
#[derive(Clone, Drop, Serde, Debug)]
#[dojo::model]
pub struct ComponentVariable {
    #[key]
    pub inst: felt252, // Entity inst
    #[key]
    pub key: felt252, // Component key
    #[key]
    pub id: felt252, // unique id 
    /// Properties ///
    /// The component type
    pub component_type: ComponentType,
    /// The property name
    pub property_name: ByteArray,
    /// The property value
    pub value: ByteArray,
    /// The last time the property was updated
    pub last_updated: u64,
}
