use dojo::{world::WorldStorage, model::ModelStorage};
use lore::{
    models::{
        entity::{Entity, EntityImpl},
        index::{DescriptionText},
        components::{Component},
        area::{Area},
        exit::{Exit},
        reactable::{Reactable},
    },
};

pub fn create_test_level(ref world: WorldStorage, game_id: u128) {
    room_start(ref world, game_id);
    room_two(ref world, game_id);
}

fn room_start(ref world: WorldStorage, game_id: u128) {
    let obj = Entity {
        inst: 2826,
        is_entity: true,
        name: "The Bang",
        alt_names: array!["bang", "explosion"],
        actions_keys: array![],
    };
    world.write_model(@obj);
    let mut reactable: Reactable = Component::add_component(ref world, obj.inst, game_id);
    let descr1 = DescriptionText {
        inst: 2826,
        key: 0,
        text: "The first thing you've ever seen, it's pretty wild, flaring colors like flower petals but kaleidoscopically distorted",
    };
    let descr2 = DescriptionText { inst: 2826, key: 1, text: "Pretty colors" };
    world.write_model(@descr1);
    world.write_model(@descr2);
    reactable.description = array![0, 1];
    reactable.store(ref world, game_id);
    let _: Area = Component::add_component(ref world, obj.inst, game_id);
    object_room_one(ref world, obj, game_id);
}

fn object_room_one(ref world: WorldStorage, parent: Entity, game_id: u128) {
    let obj = Entity {
        inst: 9999,
        is_entity: true,
        name: "a portal",
        alt_names: array!["portal", "door"],
        actions_keys: array![],
    };
    world.write_model(@obj);
    let mut reactable: Reactable = Component::add_component(ref world, obj.inst, game_id);
    let descr1 = DescriptionText { inst: 9999, key: 0, text: "A portal" };
    let descr2 = DescriptionText {
        inst: 9999, key: 1, text: "A swirling circle of colors, it doesn't seem solid",
    };
    world.write_model(@descr1);
    world.write_model(@descr2);
    reactable.description = array![0, 1];
    reactable.store(ref world, game_id);
    let mut exit: Exit = Component::add_component(ref world, obj.inst, game_id);
    exit.leads_to = 1234;
    exit.store(ref world, game_id);
    obj.set_parent(ref world, @parent);
}

fn room_two(ref world: WorldStorage, game_id: u128) {
    let mut entity = EntityImpl::create_entity(ref world, "Idyllic garden");
    entity.inst = 1234;
    entity.alt_names = array!["garden"];
    world.write_model(@entity);
    let mut reactable: Reactable = Component::add_component(ref world, entity.inst, game_id);
    let descr1 = DescriptionText {
        inst: 1234, key: 0, text: "Just suddenly it's all flowers and trees and grass",
    };
    let descr2 = DescriptionText {
        inst: 1234, key: 1, text: "Still pretty colors, but now it all has definition",
    };
    world.write_model(@descr1);
    world.write_model(@descr2);
    reactable.description = array![0, 1];
    reactable.store(ref world, game_id);
    let _: Area = Component::add_component(ref world, entity.inst, game_id);
}
