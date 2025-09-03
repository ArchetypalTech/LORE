use dojo::{world::WorldStorage, model::ModelStorage};
use lore::{
    models::{
        entity::{Entity, EntityImpl},
        index::{Area, Exit, Reactable, DescriptionText},
        components::Component,
        area::AreaComponent,
        exit::ExitComponent,
        reactable::ReactableComponent,
    },
};

pub fn create_test_level(mut world: WorldStorage) {
    room_start(world);
    room_two(world);
}

fn room_start(mut world: WorldStorage) {
    let obj = Entity {
        inst: 2826,
        is_entity: true,
        name: "The Bang",
        alt_names: array!["bang", "explosion"],
        actions_keys: array![],
    };
    world.write_model(@obj);
    let mut reactable: Reactable = Component::add_component(world, obj.inst);
    let descr1 = DescriptionText {
        inst: 2826,
        key: 0,
        text: "The first thing you've ever seen, it's pretty wild, flaring colors like flower petals but kaleidoscopically distorted",
    };
    let descr2 = DescriptionText { inst: 2826, key: 1, text: "Pretty colors" };
    world.write_model(@descr1);
    world.write_model(@descr2);
    reactable.description = array![0, 1];
    reactable.store(world);
    let _: Area = Component::add_component(world, obj.inst);
    object_room_one(world, obj);
}

fn object_room_one(mut world: WorldStorage, parent: Entity) {
    let obj = Entity {
        inst: 9999,
        is_entity: true,
        name: "a portal",
        alt_names: array!["portal", "door"],
        actions_keys: array![],
    };
    world.write_model(@obj);
    let mut reactable: Reactable = Component::add_component(world, obj.inst);
    let descr1 = DescriptionText { inst: 9999, key: 0, text: "A portal" };
    let descr2 = DescriptionText {
        inst: 9999, key: 1, text: "A swirling circle of colors, it doesn't seem solid",
    };
    world.write_model(@descr1);
    world.write_model(@descr2);
    reactable.description = array![0, 1];
    reactable.store(world);
    let mut exit: Exit = Component::add_component(world, obj.inst);
    exit.leads_to = 1234;
    exit.store(world);
    obj.set_parent(world, @parent);
}

fn room_two(mut world: WorldStorage) {
    let mut entity = EntityImpl::create_entity(world);
    entity.inst = 1234;
    entity.name = "Idyllic garden";
    entity.alt_names = array!["garden"];
    world.write_model(@entity);
    let mut reactable: Reactable = Component::add_component(world, entity.inst);
    let descr1 = DescriptionText {
        inst: 1234, key: 0, text: "Just suddenly it's all flowers and trees and grass",
    };
    let descr2 = DescriptionText {
        inst: 1234, key: 1, text: "Still pretty colors, but now it all has definition",
    };
    world.write_model(@descr1);
    world.write_model(@descr2);
    reactable.description = array![0, 1];
    reactable.store(world);
    let _: Area = Component::add_component(world, entity.inst);
}
