use dojo::{model::ModelStorage};
use lore::{
    models::{
        entity::{Entity, EntityImpl},
    },
    tests::helpers,
};

#[cfg(test)]
mod tests {
    use dojo::world::WorldStorage;
    use super::*;

    fn _setup_entities(ref world: WorldStorage) -> (Entity, Entity, Entity, Entity, Entity) {
        let parent1 = EntityImpl::create_entity(ref world, "parent1");
        let parent2 = EntityImpl::create_entity(ref world, "parent2");
        let child1 = EntityImpl::create_entity(ref world, "child1");
        let child2 = EntityImpl::create_entity(ref world, "child2");
        let child3 = EntityImpl::create_entity(ref world, "child3");
        world.write_model(@parent1);
        world.write_model(@parent2);
        world.write_model(@child1);
        world.write_model(@child2);
        world.write_model(@child3);
        (parent1, parent2, child1, child2, child3)
    }

    #[test]
    fn test_entity_parent_child_basic() {
        let (mut world, _, _, _, _, _) = helpers::setup_core();
        let (mut parent, _, mut child, _, _) = _setup_entities(ref world);

        // Set parent-child relationship
        let game_id: u128 = 0;
        child.set_parent(ref world, @parent, game_id);

        // Verify relationship
        assert(child.has_parent(@world, game_id), 'child.has_parent()');
        assert(
            child.get_parent(@world, game_id).unwrap().inst == parent.inst, 'C parent should match parent',
        );

        assert(parent.has_children(@world, game_id) == true, 'parent.has_children()');
        assert(parent.get_children_count(@world, game_id) == 1, 'parent.children_count()');
        assert(parent.contains_child(@world, child.inst, game_id), 'parent.contains_child()');
        let children_ids = parent.get_children_keys(@world, game_id);
        assert(children_ids.len() == 1, 'parent.get_children_keys()');
        assert(*children_ids.at(0) == child.inst, 'children_ids[0]');

        let children = parent.get_children(@world, game_id);
        assert(children.len() == 1, 'children.len()');
        assert(child.has_parent(@world, game_id), 'child.has_parent()');
        assert(child.get_parent(@world, game_id).unwrap().inst == parent.inst, 'child.get_parent()');
    }

    fn _assert_parent_children(world: @WorldStorage, parent: @Entity, expected_children: Span<Entity>, game_id: u128, prefix: ByteArray) {
        assert_eq!(parent.has_children(world, game_id), expected_children.len() > 0, "[{}].has_children()", prefix);
        assert_eq!(parent.get_children_count(world, game_id), expected_children.len(), "[{}].get_children_count()", prefix);
        let children_entities = parent.get_children(world, game_id);
        let children_ids = parent.get_children_keys(world, game_id);
        assert_eq!(children_entities.len(), expected_children.len(), "[{}].get_children()", prefix);
        assert_eq!(children_ids.len(), expected_children.len(), "[{}].get_children_keys()", prefix);
        let mut i: u32 = 0;
        while i < expected_children.len() {
            let child = expected_children.at(i);
            assert_eq!(child.has_parent(world, game_id), true, "[{}].has_parent()[{}]", prefix, i);
            assert_eq!(child.get_parent(world, game_id).unwrap().inst, *parent.inst, "[{}].get_parent()[{}]", prefix, i);
            // parent
            assert_eq!(parent.contains_child(world, *child.inst, game_id), true, "[{}].contains_child()[{}]", prefix, i);
            assert_eq!(children_entities.at(i).inst, child.inst, "[{}].children_entities[{}]", prefix, i);
            assert_eq!(children_ids.at(i), child.inst, "[{}].children_entities[{}]", prefix, i);
            i += 1;
        }
    }

    #[test]
    fn test_entity_hierarchy() {
        let (mut world, _, _, _, _, _) = helpers::setup_core();
        let (mut parent1, mut parent2, mut child1, mut child2, mut child3) = _setup_entities(ref world);

        // Set relationships
        let game_id: u128 = 0;
        child1.set_parent(ref world, @parent1, game_id);
        child2.set_parent(ref world, @parent1, game_id);
        child3.set_parent(ref world, @parent2, game_id);
        _assert_parent_children(@world, @parent1, array![child1.clone(), child2.clone()].span(), game_id, "baseline:parent1");
        _assert_parent_children(@world, @parent2, array![child3.clone()].span(), game_id, "baseline:parent2");

        // start moving...
        let game_id: u128 = 0;

        child1.set_parent(ref world, @parent2, game_id);
        _assert_parent_children(@world, @parent1, array![child2.clone()].span(), game_id, "child1.set_parent:parent1");
        _assert_parent_children(@world, @parent2, array![child3.clone(), child1.clone()].span(), game_id, "child1.set_parent:parent2");

        child2.set_parent(ref world, @parent2, game_id);
        _assert_parent_children(@world, @parent1, array![].span(), game_id, "child2.set_parent:parent1");
        _assert_parent_children(@world, @parent2, array![child3.clone(), child1.clone(), child2.clone()].span(), game_id, "child2.set_parent:parent2");

        child2.set_parent(ref world, @child1, game_id);
        child3.set_parent(ref world, @child2, game_id);
        _assert_parent_children(@world, @parent1, array![].span(), game_id, "child3.set_parent:parent1");
        _assert_parent_children(@world, @parent2, array![child1.clone()].span(), game_id, "child3.set_parent:parent2");
        _assert_parent_children(@world, @child1, array![child2.clone()].span(), game_id, "child3.set_parent:child1");
        _assert_parent_children(@world, @child2, array![child3.clone()].span(), game_id, "child3.set_parent:child2");

        child2.remove_from_parent(ref world, game_id);
        assert!(!child2.has_parent(@world, game_id), "child2.remove_from_parent");
        _assert_parent_children(@world, @parent1, array![].span(), game_id, "child2.remove_from_parent:parent1");
        _assert_parent_children(@world, @parent2, array![child1.clone()].span(), game_id, "child2.remove_from_parent:parent2");
        _assert_parent_children(@world, @child1, array![].span(), game_id, "child2.remove_from_parent:child1");
        _assert_parent_children(@world, @child2, array![child3.clone()].span(), game_id, "child2.remove_from_parent:child2");

        child1.remove_from_parent(ref world, game_id);
        assert!(!child1.has_parent(@world, game_id), "child1.remove_from_parent");
        assert!(!child2.has_parent(@world, game_id), "child1.remove_from_parent");
        _assert_parent_children(@world, @parent1, array![].span(), game_id, "child1.remove_from_parent:parent1");
        _assert_parent_children(@world, @parent2, array![].span(), game_id, "child1.remove_from_parent:parent2");
        _assert_parent_children(@world, @child1, array![].span(), game_id, "child1.remove_from_parent:child1");
        _assert_parent_children(@world, @child2, array![child3.clone()].span(), game_id, "child1.remove_from_parent:child2");

        // remove everyone
        child3.remove_from_parent(ref world, game_id);
        assert!(!child1.has_parent(@world, game_id), "child3.remove_from_parent");
        assert!(!child2.has_parent(@world, game_id), "child3.remove_from_parent");
        assert!(!child3.has_parent(@world, game_id), "child3.remove_from_parent");
        _assert_parent_children(@world, @parent1, array![].span(), game_id, "child3.remove_from_parent:parent1");
        _assert_parent_children(@world, @parent2, array![].span(), game_id, "child3.remove_from_parent:parent2");
        _assert_parent_children(@world, @child1, array![].span(), game_id, "child3.remove_from_parent:child1");
        _assert_parent_children(@world, @child2, array![].span(), game_id, "child3.remove_from_parent:child2");

        // insert again
        child1.set_parent(ref world, @parent2, game_id);
        child2.set_parent(ref world, @parent1, game_id);
        child3.set_parent(ref world, @parent1, game_id);
        _assert_parent_children(@world, @parent1, array![child2.clone(), child3.clone()].span(), game_id, "inserted again:parent1");
        _assert_parent_children(@world, @parent2, array![child1.clone()].span(), game_id, "inserted again:parent2");
    }


    #[test]
    fn test_entity_game_instance() {
        let (mut world, _, _, _, _, _) = helpers::setup_core();
        let (mut parent1, mut parent2, mut child1, mut child2, mut child3) = _setup_entities(ref world);

        let game_id: u128 = 0;
        child1.set_parent(ref world, @parent1, game_id);
        child2.set_parent(ref world, @parent1, game_id);
        child3.set_parent(ref world, @parent2, game_id);
        _assert_parent_children(@world, @parent1, array![child1.clone(), child2.clone()].span(), game_id, "baseline:parent1");
        _assert_parent_children(@world, @parent2, array![child3.clone()].span(), game_id, "baseline:parent2");

        let game_id_1: u128 = 123;
        let game_id_2: u128 = 456;
        let game_id_3: u128 = 789;

        // move game_id_1
        child1.set_parent(ref world, @parent2, game_id_1);
        child2.set_parent(ref world, @parent2, game_id_1);
        child3.set_parent(ref world, @parent1, game_id_1);
        // original always remains the same
        _assert_parent_children(@world, @parent1, array![child1.clone(), child2.clone()].span(), 0, "moved_2:0:parent1");
        _assert_parent_children(@world, @parent2, array![child3.clone()].span(), 0, "moved_2:0:parent2");
        // game_id_1
        _assert_parent_children(@world, @parent1, array![child3.clone()].span(), game_id_1, "moved_1:game_id_1:parent1");
        _assert_parent_children(@world, @parent2, array![child1.clone(), child2.clone()].span(), game_id_1, "moved_1:game_id_1:parent2");
        // game_id_2
        _assert_parent_children(@world, @parent1, array![child1.clone(), child2.clone()].span(), game_id_2, "moved_1::game_id_2:parent1");
        _assert_parent_children(@world, @parent2, array![child3.clone()].span(), game_id_2, "moved_1:game_id_2:parent2");
        // game_id_3 is untouched
        _assert_parent_children(@world, @parent1, array![child1.clone(), child2.clone()].span(), game_id_3, "moved_2:game_id_3:parent1");
        _assert_parent_children(@world, @parent2, array![child3.clone()].span(), game_id_3, "moved_2:game_id_3:parent2");

        // move game_id_2
        child1.set_parent(ref world, @parent2, game_id_2);
        child3.set_parent(ref world, @child2, game_id_2);
        child2.set_parent(ref world, @child1, game_id_2);
        parent2.set_parent(ref world, @parent1, game_id_2);
        // original always remains the same
        _assert_parent_children(@world, @parent1, array![child1.clone(), child2.clone()].span(), 0, "moved_2:0:parent1");
        _assert_parent_children(@world, @parent2, array![child3.clone()].span(), 0, "moved_2:0:parent2");
        // game_id_1
        _assert_parent_children(@world, @parent1, array![child3.clone()].span(), game_id_1, "moved_2:game_id_1:parent1");
        _assert_parent_children(@world, @parent2, array![child1.clone(), child2.clone()].span(), game_id_1, "moved_2:game_id_1:parent2");
        // game_id_2
        _assert_parent_children(@world, @parent1, array![parent2.clone()].span(), game_id_2, "moved_2::game_id_2:parent1");
        _assert_parent_children(@world, @parent2, array![child1.clone()].span(), game_id_2, "moved_2::game_id_2:parent1");
        _assert_parent_children(@world, @child1, array![child2.clone()].span(), game_id_2, "moved_2::game_id_2:child1");
        _assert_parent_children(@world, @child2, array![child3.clone()].span(), game_id_2, "moved_2::game_id_2:child2");
        // game_id_3 is untouched
        _assert_parent_children(@world, @parent1, array![child1.clone(), child2.clone()].span(), game_id_3, "moved_2:game_id_3:parent1");
        _assert_parent_children(@world, @parent2, array![child3.clone()].span(), game_id_3, "moved_2:game_id_3:parent2");

    }

    #[test]
    #[should_panic(expected: ('set_parent() parent self',))]
    fn test_parent_self() {
        let (mut world, _, _, _, _, _) = helpers::setup_core();
        let (_, _, mut child1, _, _) = _setup_entities(ref world);
        // Set relationships
        let game_id: u128 = 0;
        child1.set_parent(ref world, @child1, game_id);
    }
}
