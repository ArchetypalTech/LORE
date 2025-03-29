use lore::components::{inspectable::{Inspectable}};
use lore::lib::{entity::Entity};

#[starknet::interface]
pub trait IDesigner<TContractState> {
    fn create_entity(ref self: TContractState, t: Array<Entity>);
    fn create_inspectable(ref self: TContractState, t: Array<Inspectable>);
    //
    fn delete_entities(ref self: TContractState, ids: Array<felt252>);
    fn delete_inspectables(ref self: TContractState, ids: Array<felt252>);
}

#[dojo::contract]
pub mod designer {
    use super::IDesigner;
    use lore::components::{inspectable::{Inspectable}};
    use lore::lib::{entity::Entity};
    use dojo::{model::ModelStorage};

    #[abi(embed_v0)]
    pub impl DesignerImpl of IDesigner<ContractState> {
        // create
        fn create_entity(ref self: ContractState, t: Array<Entity>) {
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

        // delete
        fn delete_entities(ref self: ContractState, ids: Array<felt252>) {
            let mut world = self.world(@"lore");
            for inst in ids {
                let model: Entity = world.read_model(inst);
                world.erase_model(@model);
            }
        }

        fn delete_inspectables(ref self: ContractState, ids: Array<felt252>) {
            let mut world = self.world(@"lore");
            for inst in ids {
                let model: Inspectable = world.read_model(inst);
                world.erase_model(@model);
            }
        }
    }
}
