use dojo::{world::{WorldStorage}, model::ModelStorage};
use lore::{
    models::{
        index::{Area, Exit, Inspectable, InventoryItem, Container, Player, PropertyRegistry},
        area::AreaComponent, exit::ExitComponent, inspectable::InspectableComponent,
        inventoryItem::InventoryItemComponent, container::ContainerComponent,
        player::PlayerComponent,
    },
    types::{
        property_type::{ComponentProperty, PropertyType, PropertyAccess},
        component_type::ComponentType, direction_type::IntoDirectionByteArray,
    },
    lib::{utils::ByteArrayTraitExt}, constants::errors::Error,
};
use core::traits::{Into};

#[generate_trait]
pub impl VariablePropertyHelper of VariablePropertyHelperTrait {
    // Register Component Properties
    fn register_properties(mut world: WorldStorage, component: ComponentType) {
        let pos_property_registry: PropertyRegistry = world.read_model(component);
        if pos_property_registry.properties.len() > 0 {
            // Registry already exists, skip
            return;
        }

        let props = match component {
            ComponentType::Area => array![
                ComponentProperty {
                    name: "is_area",
                    property_type: PropertyType::Boolean,
                    access_flags: PropertyAccess::ReadOnly,
                },
                ComponentProperty {
                    name: "is_spawn_point",
                    property_type: PropertyType::Boolean,
                    access_flags: PropertyAccess::ReadWrite,
                },
            ],
            ComponentType::Inspectable => array![
                ComponentProperty {
                    name: "is_inspectable",
                    property_type: PropertyType::Boolean,
                    access_flags: PropertyAccess::ReadOnly,
                },
                ComponentProperty {
                    name: "is_visible",
                    property_type: PropertyType::Boolean,
                    access_flags: PropertyAccess::ReadWrite,
                },
                ComponentProperty {
                    name: "description",
                    property_type: PropertyType::ByteArray,
                    access_flags: PropertyAccess::ReadWrite,
                },
                ComponentProperty {
                    name: "already_shown",
                    property_type: PropertyType::Boolean,
                    access_flags: PropertyAccess::ReadWrite,
                },
                ComponentProperty {
                    name: "new_entry",
                    property_type: PropertyType::ByteArray,
                    access_flags: PropertyAccess::ReadWrite,
                },
            ],
            ComponentType::Exit => array![
                ComponentProperty {
                    name: "is_exit",
                    property_type: PropertyType::Boolean,
                    access_flags: PropertyAccess::ReadOnly,
                },
                ComponentProperty {
                    name: "is_enterable",
                    property_type: PropertyType::Boolean,
                    access_flags: PropertyAccess::ReadWrite,
                },
                ComponentProperty {
                    name: "leads_to",
                    property_type: PropertyType::Felt252,
                    access_flags: PropertyAccess::ReadWrite,
                },
                ComponentProperty {
                    name: "direction_type",
                    property_type: PropertyType::Enum,
                    access_flags: PropertyAccess::ReadWrite,
                },
            ],
            ComponentType::InventoryItem => array![
                ComponentProperty {
                    name: "owner_id",
                    property_type: PropertyType::Felt252,
                    access_flags: PropertyAccess::ReadWrite,
                },
                ComponentProperty {
                    name: "can_be_picked_up",
                    property_type: PropertyType::Boolean,
                    access_flags: PropertyAccess::ReadWrite,
                },
                ComponentProperty {
                    name: "can_go_in_container",
                    property_type: PropertyType::Boolean,
                    access_flags: PropertyAccess::ReadWrite,
                },
                ComponentProperty {
                    name: "already_used",
                    property_type: PropertyType::Boolean,
                    access_flags: PropertyAccess::ReadWrite,
                },
                ComponentProperty {
                    name: "multiple_use",
                    property_type: PropertyType::Boolean,
                    access_flags: PropertyAccess::ReadWrite,
                },
            ],
            ComponentType::Container => array![
                ComponentProperty {
                    name: "is_container",
                    property_type: PropertyType::Boolean,
                    access_flags: PropertyAccess::ReadOnly,
                },
                ComponentProperty {
                    name: "can_be_opened",
                    property_type: PropertyType::Boolean,
                    access_flags: PropertyAccess::ReadWrite,
                },
                ComponentProperty {
                    name: "can_receive_items",
                    property_type: PropertyType::Boolean,
                    access_flags: PropertyAccess::ReadWrite,
                },
                ComponentProperty {
                    name: "is_open",
                    property_type: PropertyType::Boolean,
                    access_flags: PropertyAccess::ReadWrite,
                },
                ComponentProperty {
                    name: "num_slots",
                    property_type: PropertyType::U8,
                    access_flags: PropertyAccess::ReadWrite,
                },
            ],
            ComponentType::Player => array![
                ComponentProperty {
                    name: "location",
                    property_type: PropertyType::Felt252,
                    access_flags: PropertyAccess::ReadWrite,
                },
            ],
            _ => array![],
        };

        if props.len() > 0 {
            let mut registry = PropertyRegistry { component_type: component, properties: props };
            world.write_model(@registry);
        }
    }


    // GET PROPERTIES
    fn get_area_property(
        component: Area, name: @ByteArray, property: @PropertyRegistry,
    ) -> (Option<Array<felt252>>, Option<PropertyAccess>) {
        // Define expected property names
        let is_area: ByteArray = "is_area";
        let is_spawn_point: ByteArray = "is_spawn_point";
        let mut value: Option<Array<felt252>> = Option::None;
        let mut access: Option<PropertyAccess> = Option::None;

        for prop in property.properties.clone() {
            if prop.name == name.clone() {
                let mut arr: Array<felt252> = ArrayTrait::new();
                if name == @is_area {
                    arr.append(component.is_area.into());
                } else if name == @is_spawn_point {
                    arr.append(component.is_spawn_point.into());
                }
                value = Option::Some(arr);
                access = Option::Some(prop.access_flags);
                break;
            }
        };
        return (value, access);
    }

    fn get_exit_property(
        component: Exit, name: @ByteArray, property: @PropertyRegistry,
    ) -> (Option<Array<felt252>>, Option<PropertyAccess>) {
        // Define expected property names
        let is_exit: ByteArray = "is_exit";
        let is_enterable: ByteArray = "is_enterable";
        let leads_to: ByteArray = "leads_to";
        let direction_type: ByteArray = "direction_type";
        let mut value: Option<Array<felt252>> = Option::None;
        let mut access: Option<PropertyAccess> = Option::None;

        for prop in property.properties.clone() {
            if prop.name == name.clone() {
                let mut arr: Array<felt252> = ArrayTrait::new();
                if name == @is_exit {
                    arr.append(component.is_exit.into());
                } else if name == @is_enterable {
                    arr.append(component.is_enterable.into());
                } else if name == @leads_to {
                    arr.append(component.leads_to);
                } else if name == @direction_type {
                    arr
                        .append(
                            ByteArrayTraitExt::to_felt252_word(@component.direction_type.into())
                                .unwrap(),
                        );
                }
                value = Option::Some(arr);
                access = Option::Some(prop.access_flags);
                break;
            }
        };
        return (value, access);
    }

    fn get_inspectable_property(
        component: Inspectable, name: @ByteArray, property: @PropertyRegistry,
    ) -> (Option<Array<felt252>>, Option<PropertyAccess>) {
        // Define expected property names
        let is_visible: ByteArray = "is_visible";
        let is_inspectable: ByteArray = "is_inspectable";
        let description: ByteArray = "description";
        let mut value: Option<Array<felt252>> = Option::None;
        let mut access: Option<PropertyAccess> = Option::None;

        for prop in property.properties.clone() {
            if prop.name == name.clone() {
                let mut arr: Array<felt252> = ArrayTrait::new();
                if name == @is_visible {
                    arr.append(component.is_visible.into());
                } else if name == @is_inspectable {
                    arr.append(component.is_inspectable.into());
                } else if name == @description {
                    let desc = component.description;
                    for i in 0..desc.len() {
                        let part: ByteArray = desc.at(i).clone();
                        let felt = ByteArrayTraitExt::to_felt252_word(@part).unwrap();
                        arr.append(felt);
                    }
                }
                value = Option::Some(arr);
                access = Option::Some(prop.access_flags);
                break;
            }
        };
        return (value, access);
    }

    fn get_inventory_item_property(
        component: InventoryItem, name: @ByteArray, property: @PropertyRegistry,
    ) -> (Option<Array<felt252>>, Option<PropertyAccess>) {
        // Define expected property names
        let owner_id: ByteArray = "owner_id";
        let can_be_picked_up: ByteArray = "can_be_picked_up";
        let can_go_in_container: ByteArray = "can_go_in_container";
        let already_used: ByteArray = "already_used";
        let multiple_use: ByteArray = "multiple_use";
        let mut value: Option<Array<felt252>> = Option::None;
        let mut access: Option<PropertyAccess> = Option::None;

        for prop in property.properties.clone() {
            if prop.name == name.clone() {
                let mut arr: Array<felt252> = ArrayTrait::new();
                if name == @owner_id {
                    arr.append(component.owner_id);
                } else if name == @can_be_picked_up {
                    arr.append(component.can_be_picked_up.into());
                } else if name == @can_go_in_container {
                    arr.append(component.can_go_in_container.into());
                } else if name == @already_used {
                    arr.append(component.already_used.into());
                } else if name == @multiple_use {
                    arr.append(component.multiple_use.into());
                }
                value = Option::Some(arr);
                access = Option::Some(prop.access_flags);
                break;
            }
        };
        return (value, access);
    }

    fn get_container_property(
        component: Container, name: @ByteArray, property: @PropertyRegistry,
    ) -> (Option<Array<felt252>>, Option<PropertyAccess>) {
        // Define expected property names
        let is_container: ByteArray = "is_container";
        let can_be_opened: ByteArray = "can_be_opened";
        let can_receive_items: ByteArray = "can_receive_items";
        let is_open: ByteArray = "is_open";
        let num_slots: ByteArray = "num_slots";
        let mut value: Option<Array<felt252>> = Option::None;
        let mut access: Option<PropertyAccess> = Option::None;

        for prop in property.properties.clone() {
            if prop.name == name.clone() {
                let mut arr: Array<felt252> = ArrayTrait::new();
                if name == @is_container {
                    arr.append(component.is_container.into());
                } else if name == @can_be_opened {
                    arr.append(component.can_be_opened.into());
                } else if name == @can_receive_items {
                    arr.append(component.can_receive_items.into());
                } else if name == @is_open {
                    arr.append(component.is_open.into());
                } else if name == @num_slots {
                    arr.append(component.num_slots.into());
                }
                value = Option::Some(arr);
                access = Option::Some(prop.access_flags);
                break;
            }
        };
        return (value, access);
    }

    fn get_player_property(
        component: Player, name: @ByteArray, property: @PropertyRegistry,
    ) -> (Option<Array<felt252>>, Option<PropertyAccess>) {
        // Define expected property names
        let location: ByteArray = "location";
        let mut value: Option<Array<felt252>> = Option::None;
        let mut access: Option<PropertyAccess> = Option::None;

        for prop in property.properties.clone() {
            if prop.name == name.clone() {
                let mut arr: Array<felt252> = ArrayTrait::new();
                if name == @location {
                    arr.append(component.location.into());
                }
                value = Option::Some(arr);
                access = Option::Some(prop.access_flags);
                break;
            }
        };
        return (value, access);
    }

    // SET PROPERTIES
    fn set_area_property(
        mut component: Area,
        mut world: WorldStorage,
        name: @ByteArray,
        property: @PropertyRegistry,
        new_value: @Array<ByteArray>,
    ) -> (Result::<(), Error>, bool) {
        // Define expected property names
        let is_area: ByteArray = "is_area";
        let is_spawn_point: ByteArray = "is_spawn_point";
        let mut success: bool = false;
        let mut result: Result::<(), Error> = Result::Ok(());

        for prop in property.properties.clone() {
            if prop.name == name.clone() {
                match prop.access_flags {
                    PropertyAccess::ReadOnly => {
                        if name == @is_area {
                            result = Result::Err(Error::ReadOnlyVariable);
                        }
                    },
                    PropertyAccess::ReadWrite => {
                        if name == @is_spawn_point {
                            let new_var_value = ByteArrayTraitExt::bool_from_byte_array(
                                new_value[0].clone(),
                            );
                            component.is_spawn_point = new_var_value;
                            success = true;
                        }
                    },
                }
            }
            component.store(world);
            break;
        };
        return (result, success);
    }

    fn set_exit_property(
        mut component: Exit,
        mut world: WorldStorage,
        name: @ByteArray,
        property: @PropertyRegistry,
        new_value: @Array<ByteArray>,
    ) -> (Result::<(), Error>, bool) {
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
                    PropertyAccess::ReadOnly => { result = Result::Err(Error::ReadOnlyVariable); },
                    PropertyAccess::ReadWrite => {
                        if name == @is_exit {
                            let new_var_value = ByteArrayTraitExt::bool_from_byte_array(
                                new_value[0].clone(),
                            );
                            component.is_exit = new_var_value;
                            success = true;
                        } else if name == @is_enterable {
                            let new_var_value = ByteArrayTraitExt::bool_from_byte_array(
                                new_value[0].clone(),
                            );
                            component.is_enterable = new_var_value;
                            success = true;
                        } else if name == @leads_to {
                            component
                                .leads_to =
                                    ByteArrayTraitExt::to_felt252_word(@new_value[0].clone())
                                .unwrap();
                            success = true;
                        } else if name == @direction_type {
                            let new_dir = ByteArrayTraitExt::direction_from_felt252(
                                ByteArrayTraitExt::to_felt252_word(
                                    @ByteArrayTraitExt::to_lowercase(new_value[0].clone()),
                                )
                                    .unwrap(),
                            );
                            component.direction_type = new_dir;
                            success = true;
                        }
                    },
                }
                component.store(world);
                break;
            }
        };
        return (result, success);
    }

    fn set_inspectable_property(
        mut component: Inspectable,
        mut world: WorldStorage,
        name: @ByteArray,
        property: @PropertyRegistry,
        new_value: @Array<ByteArray>,
    ) -> (Result::<(), Error>, bool) {
        // Define expected property names
        let is_visible: ByteArray = "is_visible";
        let is_inspectable: ByteArray = "is_inspectable";
        let description: ByteArray = "description";
        let mut success: bool = false;
        let mut result: Result::<(), Error> = Result::Ok(());
        for prop in property.properties.clone() {
            if prop.name == name.clone() {
                match prop.access_flags {
                    PropertyAccess::ReadOnly => { result = Result::Err(Error::ReadOnlyVariable); },
                    PropertyAccess::ReadWrite => {
                        if name == @is_visible {
                            let new_var_value = ByteArrayTraitExt::bool_from_byte_array(
                                new_value[0].clone(),
                            );
                            component.is_visible = new_var_value;
                            success = true;
                        } else if name == @is_inspectable {
                            let new_var_value = ByteArrayTraitExt::bool_from_byte_array(
                                new_value[0].clone(),
                            );
                            component.is_inspectable = new_var_value;
                            success = true;
                        } else if name == @description {
                            // FOR NOW REPLACES THE WHOLE ARRAY,
                            // TODO: implement a way that supports updating/replacing/removing at
                            // certain indices Build a temporary mutable copy of description
                            let mut new_description = array![];

                            // Copy the original description
                            for item in new_value.clone() {
                                let new_byte = item;
                                new_description.append(new_byte.clone());
                            };
                            component.description = new_description;
                            success = true;
                        }
                    },
                }
                component.store(world);
                break;
            }
        };
        return (result, success);
    }

    fn set_inventory_item_property(
        mut component: InventoryItem,
        mut world: WorldStorage,
        name: @ByteArray,
        property: @PropertyRegistry,
        new_value: @Array<ByteArray>,
    ) -> (Result::<(), Error>, bool) {
        // Define expected property names
        let owner_id: ByteArray = "owner_id";
        let can_be_picked_up: ByteArray = "can_be_picked_up";
        let can_go_in_container: ByteArray = "can_go_in_container";
        let already_used: ByteArray = "already_used";
        let multiple_use: ByteArray = "multiple_use";
        let mut success: bool = false;
        let mut result: Result::<(), Error> = Result::Ok(());

        for prop in property.properties.clone() {
            if prop.name == name.clone() {
                match prop.access_flags {
                    PropertyAccess::ReadOnly => { result = Result::Err(Error::ReadOnlyVariable); },
                    PropertyAccess::ReadWrite => {
                        if name == @owner_id {
                            component.owner_id = new_value[0].to_felt252_word().unwrap();
                            success = true;
                        } else if name == @can_be_picked_up {
                            let new_var_value = ByteArrayTraitExt::bool_from_byte_array(
                                new_value[0].clone(),
                            );
                            component.can_be_picked_up = new_var_value;
                            success = true;
                        } else if name == @can_go_in_container {
                            let new_var_value = ByteArrayTraitExt::bool_from_byte_array(
                                new_value[0].clone(),
                            );
                            component.can_go_in_container = new_var_value;
                            success = true;
                        } else if name == @already_used {
                            let new_var_value = ByteArrayTraitExt::bool_from_byte_array(
                                new_value[0].clone(),
                            );
                            component.already_used = new_var_value;
                            success = true;
                        } else if name == @multiple_use {
                            let new_var_value = ByteArrayTraitExt::bool_from_byte_array(
                                new_value[0].clone(),
                            );
                            component.multiple_use = new_var_value;
                            success = true;
                        }
                    },
                }
                component.store(world);
                break;
            }
        };
        return (result, success);
    }

    fn set_container_property(
        mut component: Container,
        mut world: WorldStorage,
        name: @ByteArray,
        property: @PropertyRegistry,
        new_value: @Array<ByteArray>,
    ) -> (Result::<(), Error>, bool) {
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
                    PropertyAccess::ReadOnly => { result = Result::Err(Error::ReadOnlyVariable); },
                    PropertyAccess::ReadWrite => {
                        if name == @is_container {
                            let new_var_value = ByteArrayTraitExt::bool_from_byte_array(
                                new_value[0].clone(),
                            );
                            component.is_container = new_var_value;
                            success = true;
                        } else if name == @can_be_opened {
                            let new_var_value = ByteArrayTraitExt::bool_from_byte_array(
                                new_value[0].clone(),
                            );
                            component.can_be_opened = new_var_value;
                            success = true;
                        } else if name == @can_receive_items {
                            let new_var_value = ByteArrayTraitExt::bool_from_byte_array(
                                new_value[0].clone(),
                            );
                            component.can_receive_items = new_var_value;
                            success = true;
                        } else if name == @is_open {
                            let new_var_value = ByteArrayTraitExt::bool_from_byte_array(
                                new_value[0].clone(),
                            );
                            component.is_open = new_var_value;
                            success = true;
                        } else if name == @num_slots {
                            let new_var_value = ByteArrayTraitExt::u32_from_byte_array(
                                new_value[0].clone(),
                            );
                            component.num_slots = new_var_value;
                            success = true;
                        }
                    },
                }
                component.store(world);
                break;
            }
        };
        return (result, success);
    }

    fn set_player_property(
        mut component: Player,
        mut world: WorldStorage,
        name: @ByteArray,
        property: @PropertyRegistry,
        new_value: @Array<ByteArray>,
    ) -> (Result::<(), Error>, bool) {
        // Define expected property names
        let location: ByteArray = "location";
        let mut success: bool = false;
        let mut result: Result::<(), Error> = Result::Ok(());

        for prop in property.properties.clone() {
            if prop.name == name.clone() {
                match prop.access_flags {
                    PropertyAccess::ReadOnly => { result = Result::Err(Error::ReadOnlyVariable); },
                    PropertyAccess::ReadWrite => {
                        if name == @location {
                            component
                                .location = ByteArrayTraitExt::to_felt252_word(new_value[0])
                                .unwrap();
                            success = true;
                        }
                    },
                }
                component.store(world);
                break;
            }
        };
        return (result, success);
    }
}
