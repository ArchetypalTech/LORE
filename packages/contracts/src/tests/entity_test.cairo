use dojo::{model::ModelStorage};
use lore::{
    models::{
        entity::{Entity, EntityImpl},
    },
    tests::helpers,
};

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_entity_parent_child_basic() {
        let (mut world, _, _, _, _) = helpers::setup_core();

        // Create parent entity
        let mut parent = EntityImpl::create_entity(ref world, "parent");
        world.write_model(@parent);

        // Create child entity
        let mut child = EntityImpl::create_entity(ref world, "child");
        world.write_model(@child);

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

    #[test]
    fn test_entity_parent_child_removal() {
        let (mut world, _, _, _, _) = helpers::setup_core();

        // Create parent and child
        let mut parent = EntityImpl::create_entity(ref world, "parent");
        world.write_model(@parent);

        let mut child = EntityImpl::create_entity(ref world, "child");
        world.write_model(@child);

        // Set and verify initial relationship
        let game_id: u128 = 0;
        child.set_parent(ref world, @parent, game_id);
        assert(child.has_parent(@world, game_id), 'Child should have parent');

        // Remove relationship
        child.remove_from_parent(ref world, @parent, game_id);

        // Verify removal
        assert(!child.has_parent(@world, game_id), 'Child should not have parent');
        let children = parent.get_children(@world, game_id);
        assert(children.len() == 0, 'Parent should have no children');
    }

    #[test]
    fn test_entity_parent_child_reassignment() {
        let (mut world, _, _, _, _) = helpers::setup_core();

        // Create entities
        let mut parent1 = EntityImpl::create_entity(ref world, "parent1");
        world.write_model(@parent1);

        let mut parent2 = EntityImpl::create_entity(ref world, "parent2");
        world.write_model(@parent2);

        let mut child = EntityImpl::create_entity(ref world, "child");
        world.write_model(@child);

        // Set initial parent
        let game_id: u128 = 0;
        child.set_parent(ref world, @parent1, game_id);
        assert(
            child.get_parent(@world, game_id).unwrap().inst == parent1.inst,
            'Child should have first parent',
        );

        // Reassign to second parent
        child.set_parent(ref world, @parent2, game_id);
        assert(
            child.get_parent(@world, game_id).unwrap().inst == parent2.inst,
            'Child should have second parent',
        );

        // Verify old parent has no children
        let parent1_children = parent1.get_children(@world, game_id);
        assert(parent1_children.len() == 0, 'First parent sh no children');

        // Verify new parent has the child
        let parent2_children = parent2.get_children(@world, game_id);
        assert(parent2_children.len() == 1, 'Second parent sh one child');
        assert(child.has_parent(@world, game_id), 'Child should have parent');
        assert(child.get_parent(@world, game_id).unwrap().inst == parent2.inst, 'Parent mismatch');
    }

    #[test]
    fn test_entity_parent_child_multiple_children() {
        let (mut world, _, _, _, _) = helpers::setup_core();

        // Create parent and multiple children
        let mut parent: Entity = EntityImpl::create_entity(ref world, "parent");
        world.write_model(@parent);

        let mut child1 = EntityImpl::create_entity(ref world, "child1");
        world.write_model(@child1);

        let mut child2 = EntityImpl::create_entity(ref world, "child2");
        world.write_model(@child2);

        // Set relationships
        let game_id: u128 = 0;
        child1.set_parent(ref world, @parent, game_id);
        child2.set_parent(ref world, @parent, game_id);

        // Verify parent has both children
        assert(parent.get_children_count(@world, game_id) == 2, 'parent.children_count()');
        assert(parent.contains_child(@world, child1.inst, game_id), 'parent.contains_child(1))');
        assert(parent.contains_child(@world, child2.inst, game_id), 'parent.contains_child(2)');
        assert(!parent.contains_child(@world, 99, game_id), 'parent.contains_child(99)');
        let children = parent.get_children(@world, game_id);
        assert(children.len() == 2, 'Parent should have two children');

        // Verify each child has correct parent
        assert(
            child1.get_parent(@world, game_id).unwrap().inst == parent.inst, 'First child sh correct parent',
        );
        assert(
            child2.get_parent(@world, game_id).unwrap().inst == parent.inst,
            'Second child sh correct parent',
        );
    }
}
