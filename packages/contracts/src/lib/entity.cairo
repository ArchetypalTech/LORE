use starknet::ContractAddress;
use dojo::{world::{WorldStorage, IWorldDispatcherTrait}, model::ModelStorage};

use lore::{
    lib::relations::{ChildToParent, ParentToChildren},
    components::player::{Player, PlayerImpl, PlayerComponent},
};

#[derive(Clone, PartialEq, Drop, Serde, Introspect, Debug)]
#[dojo::model]
pub struct Entity {
    #[key]
    pub inst: felt252,
    pub is_entity: bool,
    //properties
    pub name: ByteArray,
    pub alt_names: Array<ByteArray>,
}

#[generate_trait]
pub impl EntityImpl of EntityTrait {
    fn create_entity(mut world: WorldStorage) -> Entity {
        let mut entity: Entity = world.read_model(0);
        entity.inst = world.dispatcher.uuid().try_into().unwrap();
        entity.is_entity = true;
        world.write_model(@entity);
        entity
    }

    fn create_player_entity(mut world: WorldStorage, address: ContractAddress) -> Player {
        let mut entity: Entity = world.read_model(0);
        entity.inst = address.try_into().unwrap();
        entity.is_entity = true;
        world.write_model(@entity);
        let mut player = PlayerComponent::add_component(world, address.into());
        player.address = address;
        world.write_model(@player);
        player.say(world, "You feel light, and shiny, in the head");
        player
    }

    fn get_names(self: Entity) -> Array<ByteArray> {
        let mut names = self.alt_names.clone();
        names.append(self.name);
        names
    }

    fn has_name(self: Entity, name: ByteArray) -> bool {
        if (self.name == name) {
            return true;
        }
        let mut has_name = false;
        for alt_name in self.alt_names {
            if (alt_name == name) {
                has_name = true;
                break;
            }
        };
        has_name
    }

    fn get_entity(world: WorldStorage, inst: felt252) -> Option<Entity> {
        let entity: Entity = world.read_model(inst);
        if (!entity.is_entity) {
            return Option::None;
        }
        Option::Some(entity)
    }

    fn is_entity(world: WorldStorage, inst: felt252) -> bool {
        let mut entity: Entity = world.read_model(inst);
        entity.is_entity
    }


    fn has_parent(self: Entity, world: WorldStorage) -> bool {
        let child_to_parent: ChildToParent = world.read_model(self.inst);
        return child_to_parent.is_child;
    }

    fn get_parent(self: Entity, world: WorldStorage) -> Option<Entity> {
        let child_to_parent: ChildToParent = world.read_model(self.inst);
        if (child_to_parent.is_child) {
            let parent_entity: Entity = world.read_model(child_to_parent.parent);
            return Option::Some(parent_entity);
        }
        return Option::None;
    }

    fn get_children(self: Entity, world: WorldStorage) -> Array<Entity> {
        let mut children: Array<Entity> = ArrayTrait::<Entity>::new();
        let parent_to_children: ParentToChildren = world.read_model(self.inst);
        if (parent_to_children.is_parent) {
            for childKey in parent_to_children.children {
                let child: Entity = world.read_model(childKey);
                children.append(child);
            }
        }
        children
    }

    // @DEV: the cloning and writing in between is very dangerous, this might need a revision and at
    // least good tests
    fn set_parent(mut self: Entity, mut world: WorldStorage, parent: Entity) {
        // If we have a current parent, remove from it first
        if (self.clone().has_parent(world)) {
            let current_parent = self.clone().get_parent(world).unwrap();
            self.clone().remove_from_parent(world, current_parent);
        }
        // Add to new parent
        self.clone().add_to_parent(world, parent);
    }

    fn remove_from_parent(mut self: Entity, mut world: WorldStorage, parent: Entity) {
        let mut parent_relation: ParentToChildren = world.read_model(parent.inst);
        assert(parent_relation.is_parent, 'Parent is not a parent');

        let mut new_children: Array<felt252> = ArrayTrait::<felt252>::new();
        for child_inst in parent_relation.children {
            if (child_inst != self.inst) {
                new_children.append(child_inst);
            }
        };
        parent_relation.children = new_children;
        world.write_model(@parent_relation);
        world.write_model(@ChildToParent { inst: self.inst, is_child: false, parent: 0 });
    }

    fn add_to_parent(mut self: Entity, mut world: WorldStorage, parent: Entity) {
        let mut parent_relation: ParentToChildren = world.read_model(parent.inst);
        let mut is_child = false;
        for child_inst in parent_relation.children.clone() {
            if (child_inst == self.inst) {
                is_child = true;
                break;
            }
        };

        if (!is_child) {
            parent_relation.children.append(self.inst);
            parent_relation.is_parent = true;
            world.write_model(@parent_relation);
            world
                .write_model(
                    @ChildToParent { inst: self.inst, is_child: true, parent: parent.inst },
                );
        }
    }
}

