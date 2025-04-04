use super::entity::EntityTrait;
use dojo::{world::WorldStorage, model::ModelStorage};
use lore::components::{Component, inspectable::{Inspectable, InspectableComponent}, area::{Area}};
use lore::lib::{entity::{Entity, EntityImpl}};

pub fn create_test_level(mut world: WorldStorage) {
    room_start(world);
    room_two(world);
}

fn room_start(mut world: WorldStorage) {
    let obj = Entity {
        inst: 2826, is_entity: true, name: "The Bang", alt_names: array!["pontoon", "boat"],
    };
    world.write_model(@obj);
    let mut inspectable: Inspectable = Component::add_component(world, obj.inst);
    inspectable
        .description =
            array![
                "The first thing you've ever seen, it's pretty wild, flaring colors like flower petals but kaleidoscopically distorted",
                "Pretty colors",
            ];
    world.write_model(@inspectable);
    let _: Area = Component::add_component(world, obj.inst);
    object_room_one(world, obj);
}

fn object_room_one(mut world: WorldStorage, parent: Entity) {
    let obj = Entity {
        inst: 9999, is_entity: true, name: "a portal", alt_names: array!["portal", "door"],
    };
    world.write_model(@obj);
    let mut inspectable: Inspectable = Component::add_component(world, obj.inst);
    inspectable.description = array!["A swirling circle of colors, it doesn't seem solid"];
    world.write_model(@inspectable);
    obj.set_parent(world, @parent);
}

fn room_two(mut world: WorldStorage) {
    let mut entity = EntityImpl::create_entity(world);
    entity.name = "Idyllic garden";
    entity.alt_names = array!["garden"];
    world.write_model(@entity);
    let mut inspectable: Inspectable = Component::add_component(world, entity.inst);
    inspectable
        .description =
            array![
                "Just suddenly it's all flowers and trees and grass",
                "Still pretty colors, but now it all has definition",
            ];
    world.write_model(@inspectable);
    let _: Area = Component::add_component(world, entity.inst);
}
