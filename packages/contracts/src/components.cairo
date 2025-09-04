pub mod area;
pub mod container;
pub mod exit;
pub mod inspectable;
pub mod inventory_item;
pub mod player;

use dojo::{world::WorldStorage, model::{Model //ModelStorage, ModelPtr
}};
use lore::{constants::errors::Error, lib::{a_lexer::{Command}, entity::{Entity, EntityImpl}}};

#[derive(Copy, Drop, Serde, Debug, Introspect)]
struct InstanceId {
    inst: felt252,
    has_component: bool,
}

pub trait Component<T, +Model<T>> {
    type ComponentType;
    fn get_component(world: WorldStorage, inst: felt252) -> Option<T>; // {
    //     let component: T = world.read_member(self.ptr(), selector!("inst"));
    //     if (!Self::has_component(@component, world, inst)) {
    //         return Option::None;
    //     }
    //     Option::Some(component)
    // }

    fn inst(self: @T) -> @felt252;

    fn entity(
        self: @T, world: @WorldStorage,
    ) -> Entity {
        EntityImpl::get_entity(world, Self::inst(self)).unwrap()
    }

    fn has_component(self: @T, world: WorldStorage, inst: felt252) -> bool; // {
    //     let component: InstanceId = world
    //         .read_schema(Model::<Self::ComponentType>::ptr_from_keys(inst));
    //     component.has_component
    // }

    fn add_component(world: WorldStorage, inst: felt252) -> T;


    fn can_use_command(
        self: @T, world: WorldStorage, player: @player::Player, command: @Command,
    ) -> bool;

    fn execute_command(
        self: T, world: WorldStorage, player: @player::Player, command: @Command,
    ) -> Result<(), Error>;

    fn store(self: @T, world: WorldStorage);
}
