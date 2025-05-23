use lore::{
    components::{ 
        area::{Area, AreaComponent},
        exit::{Exit, ExitComponent},
        inspectable::{Inspectable, InspectableComponent},
        inventoryItem::{InventoryItem,InventoryItemComponent},
        container::{Container, ContainerComponent},
        player::{Player, PlayerComponent},
    },
    lib::{ utils::ByteArrayTraitExt, variable_property::{PropertyRegistry,} },
};

#[generate_trait]
pub impl VariablePropertyHelper of VariablePropertyHelperTrait {
    fn get_area_property(component: Area, name: ByteArray, property: PropertyRegistry) -> felt252 {
        // Define expected property names
        let is_area: ByteArray = "is_area";
        let mut property_value: felt252 = 999; // default fallback value

        for prop in property.properties {
            if prop.name == name {
                if name == is_area {
                    property_value = component.is_area.into();
                }
                break;
            }
        };
        return property_value;
    }

    fn get_exit_property(component: Exit, name: ByteArray, property: PropertyRegistry) -> felt252 {
        // Define expected property names
        let is_exit: ByteArray = "is_exit";
        let is_enterable: ByteArray = "is_enterable";
        let leads_to: ByteArray = "leads_to";        
        let direction_type: ByteArray = "direction_type";

        let mut property_value: felt252 = 999; // default fallback value

        for prop in property.properties {
            if prop.name == name {
                if name == is_exit {
                    property_value = component.is_exit.into();
                } else if name == is_enterable {
                    property_value = component.is_enterable.into();
                } else if name == leads_to {
                    property_value = component.leads_to;
                } else if name == direction_type {
                    property_value = ByteArrayTraitExt::to_felt252_word(
                        @ByteArrayTraitExt::byte_array_from_direction(component.direction_type)
                    ).unwrap();
                }
                break;
            }
        };
        return property_value;
    }

    fn get_inspectable_property(component: Inspectable, name: ByteArray, property: PropertyRegistry) -> felt252 {
        // Define expected property names
        let is_visible: ByteArray = "is_visible";
        let is_inspectable: ByteArray = "is_inspectable";
        let description: ByteArray = "description";
        let mut property_value: felt252 = 999; // default fallback value

        for prop in property.properties {
            if prop.name == name {
                if name == is_visible {
                    property_value = component.is_visible.into();
                } else if name == is_inspectable {
                    property_value = component.is_inspectable.into();
                } else if name == description {
                    property_value = component.description.len().into();
                }
                break;
            }
        };
        return property_value;
    }

    fn get_inventory_item_property(component: InventoryItem, name: ByteArray, property: PropertyRegistry) -> felt252 {
        // Define expected property names
        let owner_id: ByteArray = "owner_id";
        let can_be_picked_up: ByteArray = "can_be_picked_up";
        let can_go_in_container: ByteArray = "can_go_in_container";
        let mut property_value: felt252 = 999; // default fallback value

        for prop in property.properties {
            if prop.name == name {
                if name == owner_id {
                    property_value = component.owner_id.into();
                } else if name == can_be_picked_up {
                    property_value = component.can_be_picked_up.into();
                } else if name == can_go_in_container {
                    property_value = component.can_go_in_container.into();
                }
                break;
            }
        };
        return property_value;
    }

    fn get_container_property(component: Container, name: ByteArray, property: PropertyRegistry) -> felt252 {
        // Define expected property names
        let is_container: ByteArray = "is_container";
        let can_be_opened: ByteArray = "can_be_opened";
        let can_receive_items: ByteArray = "can_receive_items";
        let is_open: ByteArray = "is_open";
        let num_slots: ByteArray = "num_slots";
        let mut property_value: felt252 = 999; // default fallback value

        for prop in property.properties {
            if prop.name == name {
                if name == is_container {
                    property_value = component.is_container.into();
                } else if name == can_be_opened {
                    property_value = component.can_be_opened.into();
                } else if name == can_receive_items {
                    property_value = component.can_receive_items.into();
                } else if name == is_open {
                    property_value = component.is_open.into();
                } else if name == num_slots {
                    property_value = component.num_slots.into();
                }
                break;
            }
        };
        return property_value;
    }

    fn get_player_property(component: Player, name: ByteArray, property: PropertyRegistry) -> felt252 {
        // Define expected property names
        let location: ByteArray = "location";
        let mut property_value: felt252 = 999; // default fallback value

        for prop in property.properties {
            if prop.name == name {
                if name == location {
                    property_value = component.location.into();
                }
                break;
            }
        };
        return property_value;
    }
}