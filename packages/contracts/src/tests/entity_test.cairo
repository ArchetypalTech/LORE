use lore::tests::helpers;
use lore::lib::entity::{Entity, EntityTrait, EntityImpl};
use dojo::{model::ModelStorage};

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ParentChild_entity_parent_child_basic() {
        let (mut world, _, _, _, _) = helpers::setup_core();

        // Create parent entity
        let mut parent = EntityImpl::create_entity(world);
        parent.name = "parent";
        world.write_model(@parent);

        // Create child entity
        let mut child = EntityImpl::create_entity(world);
        child.name = "child";
        world.write_model(@child.clone());

        // Set parent-child relationship
        child.set_parent(world, @parent);

        // Verify relationship
        assert(child.has_parent(@world), 'Child should have parent');
        assert(
            child.get_parent(@world).unwrap().inst == parent.inst, 'C parent should match parent',
        );

        let children = parent.get_children(@world);
        assert(children.len() == 1, 'Parent should have one child');
        assert(child.has_parent(@world), 'Child should have parent');
        assert(child.get_parent(@world).unwrap().inst == parent.inst, 'Parent mismatch');
    }

    #[test]
    fn ParentChild_entity_parent_child_removal() {
        let (mut world, _, _, _, _) = helpers::setup_core();

        // Create parent and child
        let mut parent = EntityImpl::create_entity(world);
        parent.name = "parent";
        world.write_model(@parent);

        let mut child = EntityImpl::create_entity(world);
        child.name = "child";
        world.write_model(@child);

        // Set and verify initial relationship
        child.clone().set_parent(world, @parent);
        assert(child.has_parent(@world), 'Child should have parent');

        // Remove relationship
        child.clone().remove_from_parent(world, @parent);

        // Verify removal
        assert(!child.has_parent(@world), 'Child should not have parent');
        let children = parent.get_children(@world);
        assert(children.len() == 0, 'Parent should have no children');
    }

    #[test]
    fn ParentChild_entity_parent_child_reassignment() {
        let (mut world, _, _, _, _) = helpers::setup_core();

        // Create entities
        let mut parent1 = EntityImpl::create_entity(world);
        parent1.name = "parent1";
        world.write_model(@parent1);

        let mut parent2 = EntityImpl::create_entity(world);
        parent2.name = "parent2";
        world.write_model(@parent2);

        let mut child = EntityImpl::create_entity(world);
        child.name = "child";
        world.write_model(@child.clone());

        // Set initial parent
        child.set_parent(world, @parent1);
        assert(
            child.get_parent(@world).unwrap().inst == parent1.inst,
            'Child should have first parent',
        );

        // Reassign to second parent
        child.set_parent(world, @parent2);
        assert(
            child.get_parent(@world).unwrap().inst == parent2.inst,
            'Child should have second parent',
        );

        // Verify old parent has no children
        let parent1_children = parent1.get_children(@world);
        assert(parent1_children.len() == 0, 'First parent sh no children');

        // Verify new parent has the child
        let parent2_children = parent2.get_children(@world);
        assert(parent2_children.len() == 1, 'Second parent sh one child');
        assert(child.has_parent(@world), 'Child should have parent');
        assert(child.get_parent(@world).unwrap().inst == parent2.inst, 'Parent mismatch');
    }

    #[test]
    fn ParentChild_entity_parent_child_multiple_children() {
        let (mut world, _, _, _, _) = helpers::setup_core();

        // Create parent and multiple children
        let mut parent: Entity = EntityImpl::create_entity(world);
        parent.name = "parent";
        world.write_model(@parent);

        let mut child1 = EntityImpl::create_entity(world);
        child1.name = "child1";
        world.write_model(@child1);

        let mut child2 = EntityImpl::create_entity(world);
        child2.name = "child2";
        world.write_model(@child2);

        // Set relationships
        child1.set_parent(world, @parent);
        child2.set_parent(world, @parent);

        // Verify parent has both children
        let children = parent.get_children(@world);
        assert(children.len() == 2, 'Parent should have two children');

        // Verify each child has correct parent
        assert(
            child1.get_parent(@world).unwrap().inst == parent.inst, 'First child sh correct parent',
        );
        assert(
            child2.get_parent(@world).unwrap().inst == parent.inst,
            'Second child sh correct parent',
        );
    }
}
