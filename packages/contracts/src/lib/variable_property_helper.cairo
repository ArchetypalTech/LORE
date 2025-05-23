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
    fn get_area_property(component: Area, name: @ByteArray, property: @PropertyRegistry) -> Option<felt252> {
        // Define expected property names
        let is_area: ByteArray = "is_area";
        let mut value: Option<felt252> = Option::None;

        for prop in property.properties.clone() {
            if prop.name == name.clone() {
                if name == @is_area {
                    value = Option::Some(component.is_area.into());
                }
                break;
            }
        };
        return value;
    }

    fn get_exit_property(component: Exit, name: @ByteArray, property: @PropertyRegistry) -> Option<felt252> {
        // Define expected property names
        let is_exit: ByteArray = "is_exit";
        let is_enterable: ByteArray = "is_enterable";
        let leads_to: ByteArray = "leads_to";        
        let direction_type: ByteArray = "direction_type";
        let mut value: Option<felt252> = Option::None;

        for prop in property.properties.clone() {
            if prop.name == name.clone() {
                if name == @is_exit {
                    value = Option::Some(component.is_exit.into());
                } else if name == @is_enterable {
                    value = Option::Some(component.is_enterable.into());
                } else if name == @leads_to {
                    value = Option::Some(component.leads_to);
                } else if name == @direction_type {
                    value = Option::Some(ByteArrayTraitExt::to_felt252_word(
                        @ByteArrayTraitExt::byte_array_from_direction(component.direction_type)
                    ).unwrap());
                }
                break;
            }
        };
        return value;
    }

    fn get_inspectable_property(component: Inspectable, name: @ByteArray, property: @PropertyRegistry) -> Option<felt252> {
        // Define expected property names
        let is_visible: ByteArray = "is_visible";
        let is_inspectable: ByteArray = "is_inspectable";
        let description: ByteArray = "description";
        let mut value: Option<felt252> = Option::None;

        for prop in property.properties.clone() {
            if prop.name == name.clone() {
                if name == @is_visible {
                    value = Option::Some(component.is_visible.into());
                } else if name == @is_inspectable {
                    value = Option::Some(component.is_inspectable.into());
                } else if name == @description {
                    value = Option::Some(component.description.len().into());
                }
                break;
            }
        };
        return value;
    }

    fn get_inventory_item_property(component: InventoryItem, name: @ByteArray, property: @PropertyRegistry) -> Option<felt252> {
        // Define expected property names
        let owner_id: ByteArray = "owner_id";
        let can_be_picked_up: ByteArray = "can_be_picked_up";
        let can_go_in_container: ByteArray = "can_go_in_container";
        let mut value: Option<felt252> = Option::None;

        for prop in property.properties.clone() {
            if prop.name == name.clone() {
                if name == @owner_id {
                    value = Option::Some(component.owner_id.into());
                } else if name == @can_be_picked_up {
                    value = Option::Some(component.can_be_picked_up.into());
                } else if name == @can_go_in_container {
                    value = Option::Some(component.can_go_in_container.into());
                }
                break;
            }
        };
        return value;
    }

    fn get_container_property(component: Container, name: @ByteArray, property: @PropertyRegistry) -> Option<felt252> {
        // Define expected property names
        let is_container: ByteArray = "is_container";
        let can_be_opened: ByteArray = "can_be_opened";
        let can_receive_items: ByteArray = "can_receive_items";
        let is_open: ByteArray = "is_open";
        let num_slots: ByteArray = "num_slots";
        let mut value: Option<felt252> = Option::None;

        for prop in property.properties.clone() {
            if prop.name == name.clone() {
                if name == @is_container {
                    value = Option::Some(component.is_container.into());
                } else if name == @can_be_opened {
                    value = Option::Some(component.can_be_opened.into());
                } else if name == @can_receive_items {
                    value = Option::Some(component.can_receive_items.into());
                } else if name == @is_open {
                    value = Option::Some(component.is_open.into());
                } else if name == @num_slots {
                    value = Option::Some(component.num_slots.into());
                }
                break;
            }
        };
        return value;
    }

    fn get_player_property(component: Player, name: @ByteArray, property: @PropertyRegistry) -> Option<felt252> {
        // Define expected property names
        let location: ByteArray = "location";
        let mut value: Option<felt252> = Option::None;

        for prop in property.properties.clone() {
            if prop.name == name.clone() {
                if name == @location {
                    value = Option::Some(component.location.into());
                }
                break;
            }
        };
        return value;
    }
}