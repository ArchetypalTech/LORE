use lore::components::{
    inspectable::{Inspectable}, area::Area, exit::Exit, inventoryItem::InventoryItem,
    container::Container, player::Player,
};
use lore::lib::{entity::Entity, relations::{ParentToChildren, ChildToParent},
    trigger::Trigger, condition::Condition, actions::Action, effect::Effect,
};

#[starknet::interface]
pub trait IDesigner<TContractState> {
    fn create_player(ref self: TContractState, t: Array<Player>);
    fn create_entity(ref self: TContractState, t: Array<Entity>);
    fn create_inspectable(ref self: TContractState, t: Array<Inspectable>);
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
    fn delete_inspectable(ref self: TContractState, ids: Array<felt252>);
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
}

#[dojo::contract]
pub mod designer {
    use super::IDesigner;
    use lore::components::{
        inspectable::{Inspectable}, area::Area, exit::Exit, inventoryItem::InventoryItem,
        container::Container, player::Player,
    };
    use lore::lib::{entity::Entity, relations::{ParentToChildren, ChildToParent},
        trigger::{Trigger, TriggerImpl}, condition::Condition, actions::{Action, ActionImpl}, effect::Effect,
    };
    use dojo::{model::ModelStorage, world::WorldStorage};

    #[abi(embed_v0)]
    pub impl DesignerImpl of IDesigner<ContractState> {
        // create
        fn create_entity(ref self: ContractState, t: Array<Entity>) {
            let mut world = self.world(@"lore");
            for o in t {
                world.write_model(@o);
            }
        }

        fn create_player(ref self: ContractState, t: Array<Player>) {
            let mut world = self.world(@"lore");
            for o in t {
                world.write_model(@o);
            }
        }

        fn create_inspectable(ref self: ContractState, t: Array<Inspectable>) {
            let mut world = self.world(@"lore");
            for o in t {
                world.write_model(@o);
            }
        }

        fn create_area(ref self: ContractState, t: Array<Area>) {
            let mut world = self.world(@"lore");
            for o in t {
                world.write_model(@o);
            }
        }

        fn create_exit(ref self: ContractState, t: Array<Exit>) {
            let mut world = self.world(@"lore");
            for o in t {
                world.write_model(@o);
            }
        }

        fn create_inventory_item(ref self: ContractState, t: Array<InventoryItem>) {
            let mut world = self.world(@"lore");
            for o in t {
                world.write_model(@o);
            }
        }

        fn create_container(ref self: ContractState, t: Array<Container>) {
            let mut world = self.world(@"lore");
            for o in t {
                world.write_model(@o);
            }
        }

        fn create_trigger(ref self: ContractState, t: Array<Trigger>) {
            let mut world: WorldStorage = self.world(@"lore");
            for o in t {
                let result = TriggerImpl::register_trigger(world, o.clone());
                if result.is_err() {
                    println!("Trigger: {:?} failed to register with error: {:?}", o, result.unwrap_err());
                }
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
                let result = ActionImpl::register_action(world, o.clone());
                if result.is_err() {
                    println!("Action: {:?} failed to register with error: {:?}", o, result.unwrap_err());
                }
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
                // delete_inspectable(world, model.Inspectable);
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

        fn delete_inspectable(ref self: ContractState, ids: Array<felt252>) {
            let mut world = self.world(@"lore");
            for inst in ids {
                let model: Inspectable = world.read_model(inst);
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
                let result = TriggerImpl::unregister_trigger(world, model.clone());
                if result.is_err() {
                    println!("Trigger: {:?} failed to unregister with error: {:?}", model, result.unwrap_err());
                }
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
                let result = ActionImpl::unregister_action(world, model.clone());
                if result.is_err() {
                    println!("Action: {:?} failed to unregister with error: {:?}", model, result.unwrap_err());
                }
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
