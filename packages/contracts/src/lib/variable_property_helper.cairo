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
    lib::{ utils::ByteArrayTraitExt, variable_property::{PropertyRegistry, PropertyAccess} },
    constants::errors::Error, 
};
use core::traits::{Into};

#[generate_trait]
pub impl VariablePropertyHelper of VariablePropertyHelperTrait {
    // GET PROPERTIES
    fn get_area_property(component: Area, name: @ByteArray, property: @PropertyRegistry) -> (Option<felt252>, Option<PropertyAccess>) {
        // Define expected property names
        let is_area: ByteArray = "is_area";
        let mut value: Option<felt252> = Option::None;
        let mut access: Option<PropertyAccess> = Option::None;

        for prop in property.properties.clone() {
            if prop.name == name.clone() {
                if name == @is_area {
                    value = Option::Some(component.is_area.into());
                    access = Option::Some(prop.access_flags);
                }
                break;
            }
        };
        return (value, access);
    }

    fn get_exit_property(component: Exit, name: @ByteArray, property: @PropertyRegistry) -> (Option<felt252>, Option<PropertyAccess>) {
        // Define expected property names
        let is_exit: ByteArray = "is_exit";
        let is_enterable: ByteArray = "is_enterable";
        let leads_to: ByteArray = "leads_to";        
        let direction_type: ByteArray = "direction_type";
        let mut value: Option<felt252> = Option::None;
        let mut access: Option<PropertyAccess> = Option::None;

        for prop in property.properties.clone() {
            if prop.name == name.clone() {
                if name == @is_exit {
                    value = Option::Some(component.is_exit.into());
                    access = Option::Some(prop.access_flags);
                } else if name == @is_enterable {
                    value = Option::Some(component.is_enterable.into());
                    access = Option::Some(prop.access_flags);
                } else if name == @leads_to {
                    value = Option::Some(component.leads_to);
                    access = Option::Some(prop.access_flags);
                } else if name == @direction_type {
                    value = Option::Some(ByteArrayTraitExt::to_felt252_word(
                        @ByteArrayTraitExt::byte_array_from_direction(component.direction_type)
                    ).unwrap());
                    access = Option::Some(prop.access_flags);
                }
                break;
            }
        };
        return (value, access);
    }

    fn get_inspectable_property(component: Inspectable, name: @ByteArray, property: @PropertyRegistry) -> (Option<felt252>, Option<PropertyAccess>) {
        // Define expected property names
        let is_visible: ByteArray = "is_visible";
        let is_inspectable: ByteArray = "is_inspectable";
        let description: ByteArray = "description";
        let mut value: Option<felt252> = Option::None;
        let mut access: Option<PropertyAccess> = Option::None;

        for prop in property.properties.clone() {
            if prop.name == name.clone() {
                if name == @is_visible {
                    value = Option::Some(component.is_visible.into());
                    access = Option::Some(prop.access_flags);
                } else if name == @is_inspectable {
                    value = Option::Some(component.is_inspectable.into());
                    access = Option::Some(prop.access_flags);
                } else if name == @description {
                    value = Option::Some(component.description.len().into());
                    access = Option::Some(prop.access_flags);
                }
                break;
            }
        };
        return (value, access);
    }

    fn get_inventory_item_property(component: InventoryItem, name: @ByteArray, property: @PropertyRegistry) -> (Option<felt252>, Option<PropertyAccess>) {
        // Define expected property names
        let owner_id: ByteArray = "owner_id";
        let can_be_picked_up: ByteArray = "can_be_picked_up";
        let can_go_in_container: ByteArray = "can_go_in_container";
        let mut value: Option<felt252> = Option::None;
        let mut access: Option<PropertyAccess> = Option::None;

        for prop in property.properties.clone() {
            if prop.name == name.clone() {
                if name == @owner_id {
                    value = Option::Some(component.owner_id.into());
                    access = Option::Some(prop.access_flags);
                } else if name == @can_be_picked_up {
                    value = Option::Some(component.can_be_picked_up.into());
                    access = Option::Some(prop.access_flags);
                } else if name == @can_go_in_container {
                    value = Option::Some(component.can_go_in_container.into());
                    access = Option::Some(prop.access_flags);
                }
                break;
            }
        };
        return (value, access);
    }

    fn get_container_property(component: Container, name: @ByteArray, property: @PropertyRegistry) -> (Option<felt252>, Option<PropertyAccess>) {
        // Define expected property names
        let is_container: ByteArray = "is_container";
        let can_be_opened: ByteArray = "can_be_opened";
        let can_receive_items: ByteArray = "can_receive_items";
        let is_open: ByteArray = "is_open";
        let num_slots: ByteArray = "num_slots";
        let mut value: (Option<felt252>, Option<PropertyAccess>) = (Option::None, Option::None);

        for prop in property.properties.clone() {
            if prop.name == name.clone() {
                if name == @is_container {
                    value = (Option::Some(component.is_container.into()), Option::Some(prop.access_flags));
                } else if name == @can_be_opened {
                    value = (Option::Some(component.can_be_opened.into()), Option::Some(prop.access_flags));
                } else if name == @can_receive_items {
                    value = (Option::Some(component.can_receive_items.into()), Option::Some(prop.access_flags));
                } else if name == @is_open {
                    value = (Option::Some(component.is_open.into()), Option::Some(prop.access_flags));
                } else if name == @num_slots {
                    value = (Option::Some(component.num_slots.into()), Option::Some(prop.access_flags));
                }
                break;
            }
        };
        return value;
    }

    fn get_player_property(component: Player, name: @ByteArray, property: @PropertyRegistry) -> (Option<felt252>, Option<PropertyAccess>) {
        // Define expected property names
        let location: ByteArray = "location";
        let mut value: Option<felt252> = Option::None;
        let mut access: Option<PropertyAccess> = Option::None;

        for prop in property.properties.clone() {
            if prop.name == name.clone() {
                if name == @location {
                    value = Option::Some(component.location.into());
                    access = Option::Some(prop.access_flags);
                }
                break;
            }
        };
        return (value, access);
    }

    // SET PROPERTIES
    fn set_area_property(mut component: Area, mut world: WorldStorage, name: @ByteArray, property: @PropertyRegistry, new_value: @Array<felt252>) -> (Result::<(), Error>, bool) {
        // Define expected property names
        let is_area: ByteArray = "is_area";
        let mut success: bool = false;
        let mut result: Result::<(), Error> = Result::Ok(());

        for prop in property.properties.clone() {
            if prop.name == name.clone() {
                match prop.access_flags {
                    PropertyAccess::ReadOnly => {
                        result = Result::Err(Error::ReadOnlyVariable);
                    },
                    PropertyAccess::WriteOnly | PropertyAccess::ReadWrite => {
                        if name == @is_area {
                            let new_var_value = ByteArrayTraitExt::bool_from_felt252(*new_value[0]);
                            component.is_area = new_var_value;
                            success = true;
                        }
                    },
                }
                
            }
            world.write_model(@component);
            break;
        };
        return (result, success);
    }

    fn set_exit_property(mut component: Exit, mut world: WorldStorage, name: @ByteArray, property: @PropertyRegistry, new_value: @Array<felt252>) -> (Result::<(), Error>, bool) {
        // Define expected property names
        let is_exit: ByteArray = "is_exit";
        let is_enterable: ByteArray = "is_enterable";
        let leads_to: ByteArray = "leads_to";        
        let direction_type: ByteArray = "direction_type";
        let mut success: bool = false;
        let mut result: Result::<(), Error> = Result::Ok(());

        for prop in property.properties.clone() {
            if prop.name == name.clone() {
                match prop.access_flags {
                    PropertyAccess::ReadOnly => {
                        result = Result::Err(Error::ReadOnlyVariable);
                    },
                    PropertyAccess::WriteOnly | PropertyAccess::ReadWrite => {
                        if name == @is_exit {
                            let new_var_value = ByteArrayTraitExt::bool_from_felt252(*new_value[0]);
                            component.is_exit = new_var_value;
                            success = true;
                        } else if name == @is_enterable {
                            let new_var_value = ByteArrayTraitExt::bool_from_felt252(*new_value[0]);
                            component.is_enterable = new_var_value;
                            success = true;
                        } else if name == @leads_to {
                            component.leads_to = *new_value[0];
                            success = true;
                        } else if name == @direction_type {
                            let new_dir = ByteArrayTraitExt::direction_from_felt252(*new_value[0]);
                            component.direction_type = new_dir;
                            success = true;
                        }
                    },
                }
                world.write_model(@component);
                break;
            }
        };
        return (result, success);
    }

    fn set_inspectable_property(mut component: Inspectable, mut world: WorldStorage, name: @ByteArray, property: @PropertyRegistry, new_value: @Array<felt252>) -> (Result::<(), Error>, bool) {
        // Define expected property names
        let is_visible: ByteArray = "is_visible";
        let is_inspectable: ByteArray = "is_inspectable";
        let description: ByteArray = "description";
        let mut success: bool = false;
        let mut result: Result::<(), Error> = Result::Ok(());

        for prop in property.properties.clone() {
            if prop.name == name.clone() {
                match prop.access_flags {
                    PropertyAccess::ReadOnly => {
                        result = Result::Err(Error::ReadOnlyVariable);
                    },
                    PropertyAccess::WriteOnly | PropertyAccess::ReadWrite => {
                        if name == @is_visible {
                            let new_var_value = ByteArrayTraitExt::bool_from_felt252(*new_value[0]);
                            component.is_visible = new_var_value;
                            success = true;
                        } else if name == @is_inspectable {
                            let new_var_value = ByteArrayTraitExt::bool_from_felt252(*new_value[0]);
                            component.is_inspectable = new_var_value;
                            success = true;
                        } else if name == @description {
                            // FOR NOW REPLACES THE WHOLE ARRAY,
                            // TODO: implement a way that supports updating/replacing/removing at certain indices
                            // Build a temporary mutable copy of description
                            let mut new_description: Array<ByteArray> = ArrayTrait::new();

                            // Copy the original description
                            for item in new_value.clone() {
                                let new_byte = ByteArrayTraitExt::byte_array_from_felt252(item);
                                new_description.append(new_byte);
                            };

                            component.description = new_description;
                            success = true;
                        }
                    },
                }
                world.write_model(@component);
                break;
            }
        };
        return (result, success);
    }

    fn set_inventory_item_property(mut component: InventoryItem, mut world: WorldStorage, name: @ByteArray, property: @PropertyRegistry, new_value: @Array<felt252>) -> (Result::<(), Error>, bool) {
        // Define expected property names
        let owner_id: ByteArray = "owner_id";
        let can_be_picked_up: ByteArray = "can_be_picked_up";
        let can_go_in_container: ByteArray = "can_go_in_container";
        let mut success: bool = false;
        let mut result: Result::<(), Error> = Result::Ok(());

        for prop in property.properties.clone() {
            if prop.name == name.clone() {
                match prop.access_flags {
                    PropertyAccess::ReadOnly => {
                        result = Result::Err(Error::ReadOnlyVariable);
                    },
                    PropertyAccess::WriteOnly | PropertyAccess::ReadWrite => {
                        if name == @owner_id {
                            component.owner_id = *new_value[0];
                            success = true;
                        } else if name == @can_be_picked_up {
                            let new_var_value = ByteArrayTraitExt::bool_from_felt252(*new_value[0]);
                            component.can_be_picked_up = new_var_value;
                            success = true;
                        } else if name == @can_go_in_container {
                            let new_var_value = ByteArrayTraitExt::bool_from_felt252(*new_value[0]);
                            component.can_go_in_container = new_var_value;
                            success = true;
                        }
                    },
                }
                world.write_model(@component);
                break;
            }
        };
        return (result, success);
    }

    fn set_container_property(mut component: Container, mut world: WorldStorage, name: @ByteArray, property: @PropertyRegistry, new_value: @Array<felt252>) -> (Result::<(), Error>, bool) {
        // Define expected property names
        let is_container: ByteArray = "is_container";
        let can_be_opened: ByteArray = "can_be_opened";
        let can_receive_items: ByteArray = "can_receive_items";
        let is_open: ByteArray = "is_open";
        let num_slots: ByteArray = "num_slots";
        let mut success: bool = false;
        let mut result: Result::<(), Error> = Result::Ok(());

        for prop in property.properties.clone() {
            if prop.name == name.clone() {
                match prop.access_flags {
                    PropertyAccess::ReadOnly => {
                        result = Result::Err(Error::ReadOnlyVariable);
                    },
                    PropertyAccess::WriteOnly | PropertyAccess::ReadWrite => {
                        if name == @is_container {
                            let new_var_value = ByteArrayTraitExt::bool_from_felt252(*new_value[0]);
                            component.is_container = new_var_value;
                            success = true;
                        } else if name == @can_be_opened {
                            let new_var_value = ByteArrayTraitExt::bool_from_felt252(*new_value[0]);
                            component.can_be_opened = new_var_value;
                            success = true;
                        } else if name == @can_receive_items {
                            let new_var_value = ByteArrayTraitExt::bool_from_felt252(*new_value[0]);
                            component.can_receive_items = new_var_value;
                            success = true;
                        } else if name == @is_open {
                            let new_var_value = ByteArrayTraitExt::bool_from_felt252(*new_value[0]);
                            component.is_open = new_var_value;
                            success = true;
                        } else if name == @num_slots {
                            let new_var_value = ByteArrayTraitExt::u32_from_felt252(*new_value[0]);
                            component.num_slots = new_var_value;
                            success = true;
                        }
                    },                    
                }
                world.write_model(@component);
                break;
            }
        };
        return (result, success);
    }

    fn set_player_property(mut component: Player, mut world: WorldStorage, name: @ByteArray, property: @PropertyRegistry, new_value: @Array<felt252>) -> (Result::<(), Error>, bool) {
        // Define expected property names
        let location: ByteArray = "location";
        let mut success: bool = false;
        let mut result: Result::<(), Error> = Result::Ok(());

        for prop in property.properties.clone() {
            if prop.name == name.clone() {
                match prop.access_flags {
                    PropertyAccess::ReadOnly => {
                        result = Result::Err(Error::ReadOnlyVariable);
                    },
                    PropertyAccess::WriteOnly | PropertyAccess::ReadWrite => {
                        if name == @location {
                            component.location = *new_value[0];
                            success = true;
                        }
                    },  
                }
                world.write_model(@component);
                break;
            }
        };
        return (result, success);
    }
}