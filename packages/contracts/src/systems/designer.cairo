use lore::{
    models::{
        index::{
            Entity, Area, Exit, Reactable, InventoryItem, Container, Player, Trigger, Condition,
            Effect, Action, DescriptionText, ParentToChildren, ChildToParent,
        },
    },
};

#[starknet::interface]
pub trait IDesigner<TContractState> {
    fn create_player(ref self: TContractState, t: Array<Player>);
    fn create_entity(ref self: TContractState, t: Array<Entity>);
    fn create_reactable(ref self: TContractState, t: Array<Reactable>);
    fn create_description_text(ref self: TContractState, t: Array<DescriptionText>);
    fn create_area(ref self: TContractState, t: Array<Area>);
    fn create_exit(ref self: TContractState, t: Array<Exit>);
    fn create_inventory_item(ref self: TContractState, t: Array<InventoryItem>);
    fn create_container(ref self: TContractState, t: Array<Container>);
    fn create_trigger(ref self: TContractState, t: Array<Trigger>);
    fn create_condition(ref self: TContractState, t: Array<Condition>);
    fn create_effect(ref self: TContractState, t: Array<Effect>);
    fn create_action(ref self: TContractState, t: Array<Action>);
    fn create_parent(ref self: TContractState, t: Array<ParentToChildren>);
    fn create_child(ref self: TContractState, t: Array<ChildToParent>);
    //
    fn delete_player(ref self: TContractState, ids: Array<felt252>);
    fn delete_entity(ref self: TContractState, ids: Array<felt252>);
    fn delete_reactable(ref self: TContractState, ids: Array<felt252>);
    fn delete_description_text(ref self: TContractState, ids: Array<(felt252, felt252)>);
    fn delete_area(ref self: TContractState, ids: Array<felt252>);
    fn delete_exit(ref self: TContractState, ids: Array<felt252>);
    fn delete_inventory_item(ref self: TContractState, ids: Array<felt252>);
    fn delete_container(ref self: TContractState, ids: Array<felt252>);
    fn delete_trigger(ref self: TContractState, ids: Array<(felt252, felt252)>);
    fn delete_condition(ref self: TContractState, ids: Array<(felt252, felt252)>);
    fn delete_effect(ref self: TContractState, ids: Array<(felt252, felt252)>);
    fn delete_action(ref self: TContractState, ids: Array<(felt252, felt252)>);
    fn delete_parent(ref self: TContractState, ids: Array<felt252>);
    fn delete_child(ref self: TContractState, ids: Array<felt252>);
    //
    fn register_property_registry(ref self: TContractState, done: Array<bool>);
}

#[dojo::contract]
pub mod designer {
    use super::IDesigner;
    use dojo::{model::ModelStorage, world::WorldStorage};
    use lore::{
        models::{
            index::{
                Entity, Area, Exit, Reactable, InventoryItem, Container, Player, Trigger, Condition,
                Effect, Action, DescriptionText, ParentToChildren, ChildToParent,
            },
        },
        new_components::{
            entity_trait::EntityImpl, trigger_trait::TriggerImpl, effect_trait::EffectImpl,
            action_trait::ActionImpl,
        },
        types::{component_type::ComponentType, command_type::TokenType},
        lib::{
            dictionary::{add_to_dictionary, get_dict_entry}, utils::{ByteArrayTraitExt},
            variable_property::{VariablePropertyImp},
        },
    };

    #[abi(embed_v0)]
    pub impl DesignerImpl of IDesigner<ContractState> {
        // register
        fn register_property_registry(ref self: ContractState, done: Array<bool>) {
            let mut world: WorldStorage = self.world(@"lore");
            for d in done {
                if d {
                    println!("Registering properties for component: {:?}", ComponentType::Area);
                    VariablePropertyImp::register_component_properties(ref world, ComponentType::Area);
                    println!("Registering properties for component: {:?}", ComponentType::Exit);
                    VariablePropertyImp::register_component_properties(ref world, ComponentType::Exit);
                    println!("Registering properties for component: {:?}", ComponentType::Reactable);
                    VariablePropertyImp::register_component_properties(
                        ref world, ComponentType::Reactable,
                    );
                    println!("Registering properties for component: {:?}", ComponentType::InventoryItem);
                    VariablePropertyImp::register_component_properties(
                        ref world, ComponentType::InventoryItem,
                    );
                    println!("Registering properties for component: {:?}", ComponentType::Container);
                    VariablePropertyImp::register_component_properties(
                        ref world, ComponentType::Container,
                    );
                    println!("Registering properties for component: {:?}", ComponentType::Player);
                    VariablePropertyImp::register_component_properties(
                        ref world, ComponentType::Player,
                    );
                }
            }
        }

        // create
        fn create_entity(ref self: ContractState, t: Array<Entity>) {
            let mut world = self.world(@"lore");
            let mut worldSt: WorldStorage = self.world(@"lore");
            for o in t {
                for alt_name in o.alt_names.clone() {
                    let pos_entry = get_dict_entry(worldSt, alt_name.clone());
                    if pos_entry.is_none() {
                        add_to_dictionary(worldSt, alt_name.clone(), TokenType::Noun, 1).unwrap();
                    }
                };
                // TODO LATER ON
                // if o.name.len() > 0 {
                //     let words = ByteArrayTraitExt::split_into_words(@o.name);
                //     for word in words {
                //         let lowercased = ByteArrayTraitExt::to_lowercase(word.clone());
                //         let pos_entry = get_dict_entry(worldSt, lowercased.clone());
                //         if pos_entry.is_none() {
                //             add_to_dictionary(worldSt, lowercased.clone(), TokenType::Noun,
                //             1).unwrap();
                //         }
                //     };
                // }
                world.write_model(@o);
            }
        }

        fn create_player(ref self: ContractState, t: Array<Player>) {
            let mut world = self.world(@"lore");
            let mut  worldSt: WorldStorage = self.world(@"lore");
            VariablePropertyImp::register_component_properties(ref worldSt, ComponentType::Player);
            for o in t {
                world.write_model(@o);
            }
        }

        fn create_reactable(ref self: ContractState, t: Array<Reactable>) {
            let mut world = self.world(@"lore");
            let mut worldSt: WorldStorage = self.world(@"lore");
            VariablePropertyImp::register_component_properties(ref worldSt, ComponentType::Reactable);
            for o in t {
                world.write_model(@o);
            }
        }

        fn create_description_text(ref self: ContractState, t: Array<DescriptionText>) {
            let mut world = self.world(@"lore");
            for o in t {
                world.write_model(@o);
            }
        }

        fn create_area(ref self: ContractState, t: Array<Area>) {
            let mut world = self.world(@"lore");
            let mut worldSt: WorldStorage = self.world(@"lore");
            VariablePropertyImp::register_component_properties(ref worldSt, ComponentType::Area);
            for o in t {
                world.write_model(@o);
            }
        }

        fn create_exit(ref self: ContractState, t: Array<Exit>) {
            let mut world = self.world(@"lore");
            let mut worldSt: WorldStorage = self.world(@"lore");
            VariablePropertyImp::register_component_properties(ref worldSt, ComponentType::Exit);
            for o in t {
                world.write_model(@o);
            }
        }

        fn create_inventory_item(ref self: ContractState, t: Array<InventoryItem>) {
            let mut world = self.world(@"lore");
            let mut worldSt: WorldStorage = self.world(@"lore");
            VariablePropertyImp::register_component_properties(
                ref worldSt, ComponentType::InventoryItem,
            );
            for o in t {
                world.write_model(@o);
            }
        }

        fn create_container(ref self: ContractState, t: Array<Container>) {
            let mut world = self.world(@"lore");
            let mut worldSt: WorldStorage = self.world(@"lore");
            VariablePropertyImp::register_component_properties(ref worldSt, ComponentType::Container);
            for o in t {
                world.write_model(@o);
            }
        }

        fn create_trigger(ref self: ContractState, t: Array<Trigger>) {
            let mut world: WorldStorage = self.world(@"lore");
            for o in t {
                let _result = TriggerImpl::register_trigger(world, o.clone());
                // if result.is_err() {
            //     println!(
            //         "Trigger: {:?} failed to register with error: {:?}", o,
            //         result.unwrap_err(),
            //     );
            // }
            }
        }

        fn create_condition(ref self: ContractState, t: Array<Condition>) {
            let mut world = self.world(@"lore");
            for o in t {
                world.write_model(@o);
            }
        }

        fn create_effect(ref self: ContractState, t: Array<Effect>) {
            let mut world = self.world(@"lore");
            for o in t {
                world.write_model(@o);
            }
        }

        fn create_action(ref self: ContractState, t: Array<Action>) {
            let world: WorldStorage = self.world(@"lore");
            for o in t {
                let _result = ActionImpl::register_action(world, o.clone());
                // if result.is_err() {
            //     println!(
            //         "Action: {:?} failed to register with error: {:?}", o,
            //         result.unwrap_err(),
            //     );
            // }
            }
        }

        fn create_parent(ref self: ContractState, t: Array<ParentToChildren>) {
            let mut world = self.world(@"lore");
            for o in t {
                world.write_model(@o);
            }
        }

        fn create_child(ref self: ContractState, t: Array<ChildToParent>) {
            let mut world = self.world(@"lore");
            for o in t {
                world.write_model(@o);
            }
        }

        // delete
        fn delete_entity(ref self: ContractState, ids: Array<felt252>) {
            let mut world = self.world(@"lore");
            for inst in ids {
                let model: Entity = world.read_model(inst);
                world.erase_model(@model);
                // delete_reactable(world, model.Reactable);
            // delete_area(world, model.Area);
            // delete_exit(world, model.Exit);
            }
        }

        fn delete_player(ref self: ContractState, ids: Array<felt252>) {
            let mut world = self.world(@"lore");
            for inst in ids {
                let model: Player = world.read_model(inst);
                world.erase_model(@model);
            }
        }

        fn delete_reactable(ref self: ContractState, ids: Array<felt252>) {
            let mut world = self.world(@"lore");
            for inst in ids {
                let model: Reactable = world.read_model(inst);
                world.erase_model(@model);
            }
        }

        fn delete_description_text(ref self: ContractState, ids: Array<(felt252, felt252)>) {
            let mut world = self.world(@"lore");
            for inst in ids {
                let model: DescriptionText = world.read_model(inst);
                world.erase_model(@model);
            }
        }

        fn delete_area(ref self: ContractState, ids: Array<felt252>) {
            let mut world = self.world(@"lore");
            for inst in ids {
                let model: Area = world.read_model(inst);
                world.erase_model(@model);
            }
        }

        fn delete_exit(ref self: ContractState, ids: Array<felt252>) {
            let mut world = self.world(@"lore");
            for inst in ids {
                let model: Exit = world.read_model(inst);
                world.erase_model(@model);
            }
        }

        fn delete_inventory_item(ref self: ContractState, ids: Array<felt252>) {
            let mut world = self.world(@"lore");
            for inst in ids {
                let model: InventoryItem = world.read_model(inst);
                world.erase_model(@model);
            }
        }

        fn delete_container(ref self: ContractState, ids: Array<felt252>) {
            let mut world = self.world(@"lore");
            for inst in ids {
                let model: Container = world.read_model(inst);
                world.erase_model(@model);
            }
        }

        fn delete_trigger(ref self: ContractState, ids: Array<(felt252, felt252)>) {
            let world: WorldStorage = self.world(@"lore");
            for inst in ids {
                let model: Trigger = world.read_model(inst);
                let _result = TriggerImpl::unregister_trigger(world, model.clone());
                // if result.is_err() {
            //     println!(
            //         "Trigger: {:?} failed to unregister with error: {:?}",
            //         model,
            //         result.unwrap_err(),
            //     );
            // }
            }
        }

        fn delete_condition(ref self: ContractState, ids: Array<(felt252, felt252)>) {
            let mut world = self.world(@"lore");
            for inst in ids {
                let model: Condition = world.read_model(inst);
                world.erase_model(@model);
            }
        }

        fn delete_effect(ref self: ContractState, ids: Array<(felt252, felt252)>) {
            let mut world = self.world(@"lore");
            for inst in ids {
                let model: Effect = world.read_model(inst);
                world.erase_model(@model);
            }
        }

        fn delete_action(ref self: ContractState, ids: Array<(felt252, felt252)>) {
            let world: WorldStorage = self.world(@"lore");
            for inst in ids {
                let model: Action = world.read_model(inst);
                let _result = ActionImpl::unregister_action(world, model.clone());
                // if result.is_err() {
            //     println!(
            //         "Action: {:?} failed to unregister with error: {:?}",
            //         model,
            //         result.unwrap_err(),
            //     );
            // }
            }
        }

        fn delete_parent(ref self: ContractState, ids: Array<felt252>) {
            let mut world = self.world(@"lore");
            for inst in ids {
                let model: ParentToChildren = world.read_model(inst);
                world.erase_model(@model);
            }
        }

        fn delete_child(ref self: ContractState, ids: Array<felt252>) {
            let mut world = self.world(@"lore");
            for inst in ids {
                let model: ChildToParent = world.read_model(inst);
                world.erase_model(@model);
            }
        }
    }
}
