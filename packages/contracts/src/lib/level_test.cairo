use dojo::{world::WorldStorage, model::ModelStorage};
use lore::components::{Component, inspectable::{Inspectable, InspectableComponent}, area::{Area}};
use lore::lib::{entity::Entity};

pub fn create_test_level(mut world: WorldStorage) {
    let alt_names: Array<ByteArray> = array!["test", "level"];
    let obj = Entity { inst: 2826, is_entity: true, name: "test_level", alt_names };
    world.write_model(@obj);
    let _: Inspectable = Component::add_component(world, obj.inst);
    let _: Area = Component::add_component(world, obj.inst);
}
