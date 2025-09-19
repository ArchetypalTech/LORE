use dojo::{world::{WorldStorage}, model::ModelStorage};
use lore::{
    models::{
        index::{
            DescriptionText,
            PropertyRegistry,
        },
        area::{Area, AreaComponent},
        exit::{Exit},
        reactable::{Reactable},
        inventory_item::{InventoryItem},
        container::{Container, ContainerImpl},
        player::{Player, PlayerImpl},
        game_instance::{GameModelImpl},
        effect::{Effect},
    },
    types::{
        property_type::{ComponentProperty, PropertyType, PropertyAccess},
        component_type::ComponentType,
        direction_type::{Direction, IntoDirectionByteArray, IntoFelt252Direction},
        action_type::EffectType,
    },
    lib::{utils::ByteArrayTraitExt}, constants::errors::Error,
};
use core::traits::{Into};

#[generate_trait]
pub impl VariablePropertyHelper of VariablePropertyHelperTrait {
    
    fn register_component_properties(ref world: WorldStorage, component: ComponentType) {
        Self::register_properties(ref world, component);
    }
    
    // Register Component Properties
    fn register_properties(ref world: WorldStorage, component: ComponentType) {
        // println!("Attempting to register properties for component: {:?}", component);
        let pos_property_registry: PropertyRegistry = world.read_model(component);
        // println!("Pos property registry: {:?}", pos_property_registry);
        if pos_property_registry.properties.len() > 0 {
            // Registry already exists, skip
            // println!("Registry already exists, skipping");
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
            ComponentType::Reactable => array![
                ComponentProperty {
                    name: "is_reactable",
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
                    name: "quantity",
                    property_type: PropertyType::U32,
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
                    property_type: PropertyType::U32,
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
            // println!("Writing registry: {:?}", registry);
            world.write_model(@registry);
        }
    }


    //--------------------------------
    // GETTERS
    //

    fn get_area_property(
        component: @Area, name: @ByteArray, property: @PropertyRegistry,
    ) -> (Option<Array<felt252>>, Option<PropertyAccess>) {
        // Define expected property names
        let is_area: ByteArray = "is_area";
        let is_spawn_point: ByteArray = "is_spawn_point";
        let mut value: Option<Array<felt252>> = Option::None;
        let mut access: Option<PropertyAccess> = Option::None;

        for prop in property.properties.clone() {
            if @prop.name == name {
                let mut arr: Array<felt252> = array![];
                if name == @is_area {
                    arr.append((*component.is_area).into());
                } else if name == @is_spawn_point {
                    arr.append((*component.is_spawn_point).into());
                }
                value = Option::Some(arr);
                access = Option::Some(prop.access_flags);
                break;
            }
        };
        return (value, access);
    }

    fn get_exit_property(
        component: @Exit, name: @ByteArray, property: @PropertyRegistry,
    ) -> (Option<Array<felt252>>, Option<PropertyAccess>) {
        // Define expected property names
        let is_exit: ByteArray = "is_exit";
        let is_enterable: ByteArray = "is_enterable";
        let leads_to: ByteArray = "leads_to";
        let direction_type: ByteArray = "direction_type";
        let mut value: Option<Array<felt252>> = Option::None;
        let mut access: Option<PropertyAccess> = Option::None;

        for prop in property.properties.clone() {
            if @prop.name == name {
                let mut arr: Array<felt252> = array![];
                if name == @is_exit {
                    arr.append((*component.is_exit).into());
                } else if name == @is_enterable {
                    arr.append((*component.is_enterable).into());
                } else if name == @leads_to {
                    arr.append((*component.leads_to));
                } else if name == @direction_type {
                    arr
                        .append(
                            ByteArrayTraitExt::to_felt252_word(@(*component.direction_type).into())
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

    fn get_reactable_property(
        component: @Reactable, name: @ByteArray, property: @PropertyRegistry, world: WorldStorage,
    ) -> (Option<Array<felt252>>, Option<PropertyAccess>) {
        // Define expected property names
        let is_visible: ByteArray = "is_visible";
        let is_reactable: ByteArray = "is_reactable";
        let description: ByteArray = "description";
        let mut value: Option<Array<felt252>> = Option::None;
        let mut access: Option<PropertyAccess> = Option::None;

        for prop in property.properties.clone() {
            if @prop.name == name {
                let mut arr: Array<felt252> = array![];
                if name == @is_visible {
                    arr.append((*component.is_visible).into());
                } else if name == @is_reactable {
                    arr.append((*component.is_reactable).into());
                } else if name == @description {
                    let desc = component.description;
                    for i in 0..desc.len() {
                        let key: u32 = *desc.at(i);
                        let desc_text: DescriptionText = world.read_model((*component.inst, key),);
                        let felt = ByteArrayTraitExt::to_felt252_word(@desc_text.text).unwrap();
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
        component: @InventoryItem, name: @ByteArray, property: @PropertyRegistry,
    ) -> (Option<Array<felt252>>, Option<PropertyAccess>) {
        // Define expected property names
        let owner_id: ByteArray = "owner_id";
        let can_be_picked_up: ByteArray = "can_be_picked_up";
        let can_go_in_container: ByteArray = "can_go_in_container";
        let quantity: ByteArray = "quantity";
        let already_used: ByteArray = "already_used";
        let multiple_use: ByteArray = "multiple_use";
        let mut value: Option<Array<felt252>> = Option::None;
        let mut access: Option<PropertyAccess> = Option::None;

        for prop in property.properties.clone() {
            if @prop.name == name {
                let mut arr: Array<felt252> = array![];
                if name == @owner_id {
                    arr.append((*component.owner_id));
                } else if name == @can_be_picked_up {
                    arr.append((*component.can_be_picked_up).into());
                } else if name == @can_go_in_container {
                    arr.append((*component.can_go_in_container).into());
                } else if name == @quantity {
                    arr.append((*component.quantity).into());
                } else if name == @already_used {
                    arr.append((*component.already_used).into());
                } else if name == @multiple_use {
                    arr.append((*component.multiple_use).into());
                }
                value = Option::Some(arr);
                access = Option::Some(prop.access_flags);
                break;
            }
        };
        return (value, access);
    }

    fn get_container_property(
        component: @Container, name: @ByteArray, property: @PropertyRegistry,
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
            if @prop.name == name {
                let mut arr: Array<felt252> = array![];
                if name == @is_container {
                    arr.append((*component.is_container).into());
                } else if name == @can_be_opened {
                    arr.append((*component.can_be_opened).into());
                } else if name == @can_receive_items {
                    arr.append((*component.can_receive_items).into());
                } else if name == @is_open {
                    arr.append((*component.is_open).into());
                } else if name == @num_slots {
                    arr.append((*component.num_slots).into());
                }
                value = Option::Some(arr);
                access = Option::Some(prop.access_flags);
                break;
            }
        };
        return (value, access);
    }

    fn get_player_property(
        component: @Player, name: @ByteArray, property: @PropertyRegistry,
    ) -> (Option<Array<felt252>>, Option<PropertyAccess>) {
        // Define expected property names
        let location: ByteArray = "location";
        let mut value: Option<Array<felt252>> = Option::None;
        let mut access: Option<PropertyAccess> = Option::None;

        for prop in property.properties.clone() {
            if @prop.name == name {
                let mut arr: Array<felt252> = array![];
                if name == @location {
                    arr.append((*component.location).into());
                }
                value = Option::Some(arr);
                access = Option::Some(prop.access_flags);
                break;
            }
        };
        return (value, access);
    }


    //--------------------------------
    // SETTERS
    //

    fn set_area_property(
        ref component: Area,
        ref world: WorldStorage,
        name: @ByteArray,
        property: @PropertyRegistry,
        new_value: Span<(ByteArray, u32)>,
        game_id: u128,
    ) -> (Result::<(), Error>, bool) {
        // Define expected property names
        let is_area: ByteArray = "is_area";
        let is_spawn_point: ByteArray = "is_spawn_point";
        let mut success: bool = false;
        let mut result: Result::<(), Error> = Result::Ok(());

        for prop in property.properties.clone() {
            if @prop.name == name {
                match prop.access_flags {
                    PropertyAccess::ReadOnly => {
                        if name == @is_area {
                            result = Result::Err(Error::ReadOnlyVariable);
                        }
                    },
                    PropertyAccess::ReadWrite => {
                        if name == @is_spawn_point {
                            let (value, _index) = new_value[0];
                            let new_var_value = ByteArrayTraitExt::bool_from_byte_array(value);
                            component.is_spawn_point = new_var_value;
                            success = true;
                        }
                    },
                }
            }
            component.store(ref world, game_id);
            break;
        };
        return (result, success);
    }

    fn set_exit_property(
        ref component: Exit,
        ref world: WorldStorage,
        name: @ByteArray,
        property: @PropertyRegistry,
        new_value: Span<(ByteArray, u32)>,
        hex_value: @felt252,
        game_id: u128,
    ) -> (Result::<(), Error>, bool) {
        // Define expected property names
        let is_exit: ByteArray = "is_exit";
        let is_enterable: ByteArray = "is_enterable";
        let leads_to: ByteArray = "leads_to";
        let direction_type: ByteArray = "direction_type";
        let mut success: bool = false;
        let mut result: Result::<(), Error> = Result::Ok(());

        for prop in property.properties.clone() {
            if @prop.name == name {
                match prop.access_flags {
                    PropertyAccess::ReadOnly => { result = Result::Err(Error::ReadOnlyVariable); },
                    PropertyAccess::ReadWrite => {
                        if name == @is_exit {
                            let (value, _index) = new_value[0];
                            let new_var_value = ByteArrayTraitExt::bool_from_byte_array(value);
                            component.is_exit = new_var_value;
                            success = true;
                        } else if name == @is_enterable {
                            let (value, _index) = new_value[0];
                            let new_var_value = ByteArrayTraitExt::bool_from_byte_array(value);
                            component.is_enterable = new_var_value;
                            success = true;
                        } else if name == @leads_to {
                            let new_destination = hex_value.clone();
                            component.leads_to = new_destination;
                            success = true;
                        } else if name == @direction_type {
                            let (value, _index) = new_value[0];
                            let lowercased = ByteArrayTraitExt::to_lowercase(value);
                            let to_felt252_direction = ByteArrayTraitExt::to_felt252_word(
                                @lowercased,
                            )
                                .unwrap();
                            let new_dir: Direction = IntoFelt252Direction::into(
                                to_felt252_direction,
                            );
                            component.direction_type = new_dir;
                            success = true;
                        }
                    },
                }
                component.store(ref world, game_id);
                break;
            }
        };
        return (result, success);
    }

    fn set_reactable_property(
        ref component: Reactable,
        ref world: WorldStorage,
        name: @ByteArray,
        property: @PropertyRegistry,
        new_value: Span<(ByteArray, u32)>,
        game_id: u128,
    ) -> (Result::<(), Error>, bool) {
        // Define expected property names
        let is_visible: ByteArray = "is_visible";
        let is_reactable: ByteArray = "is_reactable";
        let description: ByteArray = "description";
        let new_entry: ByteArray = "new_entry";
        let mut success: bool = false;
        let mut result: Result::<(), Error> = Result::Ok(());
        for prop in property.properties.clone() {
            if @prop.name == name {
                match prop.access_flags {
                    PropertyAccess::ReadOnly => { result = Result::Err(Error::ReadOnlyVariable); },
                    PropertyAccess::ReadWrite => {
                        if name == @is_visible {
                            let (value, _index) = new_value[0];
                            let new_var_value = ByteArrayTraitExt::bool_from_byte_array(value);
                            component.is_visible = new_var_value;
                            success = true;
                        } else if name == @is_reactable {
                            let (value, _index) = new_value[0];
                            let new_var_value = ByteArrayTraitExt::bool_from_byte_array(value);
                            component.is_reactable = new_var_value;
                            success = true;
                        } else if name == @description {
                            for (value, index) in new_value {
                                let mut found: bool = false;

                                // Check if index is already in component.description
                                for key in component.description.clone() {
                                    if key == *index {
                                        // Update existing description
                                        let mut desc_text: DescriptionText = world
                                            .read_model((component.inst, *index));
                                        desc_text.text = value.clone();
                                        world.write_model(@desc_text);
                                        found = true;
                                        break;
                                    }
                                };

                                if !found {
                                    // Add new description
                                    let new_desc = DescriptionText {
                                        inst: component.inst, key: *index, text: value.clone(),
                                    };
                                    world.write_model(@new_desc);
                                    component.description.append(*index);
                                };
                            };
                            success = true;
                        } else if name == @new_entry {
                            let (value, _index) = new_value[0].clone();
                            component.new_entry = value;
                            success = true;
                        }
                    },
                }
                component.store(ref world, game_id);
                break;
            }
        };
        return (result, success);
    }

    fn set_inventory_item_property(
        ref component: InventoryItem,
        ref world: WorldStorage,
        effect: @Effect,
        property: @PropertyRegistry,
        game_id: u128,
    ) -> (Result::<(), Error>, bool) {
        // Define expected property names
        let owner_id: ByteArray = "owner_id";
        let can_be_picked_up: ByteArray = "can_be_picked_up";
        let can_go_in_container: ByteArray = "can_go_in_container";
        let quantity: ByteArray = "quantity";
        let already_used: ByteArray = "already_used";
        let multiple_use: ByteArray = "multiple_use";
        let mut success: bool = false;
        let mut result: Result::<(), Error> = Result::Ok(());

        for prop in property.properties.clone() {
            if @prop.name == effect.property {
                match prop.access_flags {
                    PropertyAccess::ReadOnly => { result = Result::Err(Error::ReadOnlyVariable); },
                    PropertyAccess::ReadWrite => {
                        if effect.property == @owner_id {
                            let new_owner_id = effect.hex_value.clone();
                            component.owner_id = new_owner_id;
                            // move item to new owner
                            let new_owner_container: Container = world.read_game_model(component.owner_id, game_id);
                            let res = new_owner_container.put_item_in(ref world, ref component, game_id);
                            match res {
                                Result::Ok(()) => {
                                    success = true;
                                },
                                Result::Err(err) => {
                                    result = Result::Err(err);
                                },
                            }
                        } else if effect.property == @can_be_picked_up {
                            let (value, _index) = effect.value[0];
                            let new_var_value = ByteArrayTraitExt::bool_from_byte_array(value);
                            component.can_be_picked_up = new_var_value;
                            success = true;
                        } else if effect.property == @can_go_in_container {
                            let (value, _index) = effect.value[0];
                            let new_var_value = ByteArrayTraitExt::bool_from_byte_array(value);
                            component.can_go_in_container = new_var_value;
                            success = true;
                        } else if effect.property == @quantity {
                            match effect.effect_type.clone() {
                                EffectType::AddQuantity => {
                                    component.quantity += *effect.n_value;
                                    success = true;
                                },
                                EffectType::RemoveQuantity => {
                                    if component.quantity >= *effect.n_value {
                                        component.quantity -= *effect.n_value;
                                        success = true;
                                    } else {
                                        let zero: u32 = 0;
                                        component.quantity = zero;
                                        success = true;
                                    }
                                },
                                EffectType::ModifyProperty => {
                                    // Overwrite the quantity
                                    component.quantity = *effect.n_value;
                                    success = true;
                                },
                                _ => { // Do nothing for now
                                },
                            }
                        } else if effect.property == @already_used {
                            let (value, _index) = effect.value[0];
                            let new_var_value = ByteArrayTraitExt::bool_from_byte_array(value);
                            component.already_used = new_var_value;
                            success = true;
                        } else if effect.property == @multiple_use {
                            let (value, _index) = effect.value[0];
                            let new_var_value = ByteArrayTraitExt::bool_from_byte_array(value);
                            component.multiple_use = new_var_value;
                            success = true;
                        }
                    },
                }
                component.store(ref world, game_id);
                break;
            }
        };
        return (result, success);
    }

    fn set_container_property(
        ref component: Container,
        ref world: WorldStorage,
        name: @ByteArray,
        effect_type: @EffectType,
        property: @PropertyRegistry,
        new_value: Span<(ByteArray, u32)>,
        num_value: u32,
        game_id: u128,
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
            if @prop.name == name {
                match prop.access_flags {
                    PropertyAccess::ReadOnly => { result = Result::Err(Error::ReadOnlyVariable); },
                    PropertyAccess::ReadWrite => {
                        if name == @is_container {
                            let (value, _index) = new_value[0];
                            let new_var_value = ByteArrayTraitExt::bool_from_byte_array(value);
                            component.is_container = new_var_value;
                            success = true;
                        } else if name == @can_be_opened {
                            let (value, _index) = new_value[0];
                            let new_var_value = ByteArrayTraitExt::bool_from_byte_array(value);
                            component.can_be_opened = new_var_value;
                            success = true;
                        } else if name == @can_receive_items {
                            let (value, _index) = new_value[0];
                            let new_var_value = ByteArrayTraitExt::bool_from_byte_array(value);
                            component.can_receive_items = new_var_value;
                            success = true;
                        } else if name == @is_open {
                            let (value, _index) = new_value[0];
                            let new_var_value = ByteArrayTraitExt::bool_from_byte_array(value);
                            component.is_open = new_var_value;
                            success = true;
                        } else if name == @num_slots {
                            match effect_type {
                                EffectType::ModifyProperty => {
                                    component.num_slots = num_value;
                                    success = true;
                                },
                                EffectType::AddQuantity => {
                                    component.num_slots += num_value;
                                    success = true;
                                },
                                EffectType::RemoveQuantity => {
                                    if component.num_slots >= num_value {
                                        component.num_slots -= num_value;
                                        success = true;
                                    } else {
                                        component.num_slots = 0;
                                        success = true;
                                    }
                                },
                                _ => { // Do nothing for now
                                },
                            }
                            component.store(ref world, game_id);
                        }
                    },
                }
                component.store(ref world, game_id);
                break;
            }
        };
        return (result, success);
    }

    fn set_player_property(
        ref component: Player,
        ref world: WorldStorage,
        name: @ByteArray,
        property: @PropertyRegistry,
        new_value: Span<(ByteArray, u32)>,
        hex_value: @felt252,
        game_id: u128,
    ) -> (Result::<(), Error>, bool) {
        // Define expected property names
        let location: ByteArray = "location";
        let mut success: bool = false;
        let mut result: Result::<(), Error> = Result::Ok(());

        for prop in property.properties.clone() {
            if @prop.name == name {
                match prop.access_flags {
                    PropertyAccess::ReadOnly => { result = Result::Err(Error::ReadOnlyVariable); },
                    PropertyAccess::ReadWrite => {
                        if name == @location {
                            let new_location = hex_value.clone();
                            // move player to new location
                            component.move_to_room(ref world, new_location);
                            // describe room
                            let _ = component.describe_room(ref world);
                            success = true;
                        }
                    },
                }
                component.store(ref world, game_id);
                break;
            }
        };
        return (result, success);
    }
}
