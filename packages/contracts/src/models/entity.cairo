use starknet::ContractAddress;
use dojo::{world::{WorldStorage, IWorldDispatcherTrait}, model::ModelStorage};

use lore::{
    models::{
        index::{DescriptionText},
        components::{Component},
        game_instance::{GameModelImpl, GameInstImpl},
        player::{Player, PlayerImpl},
        reactable::{Reactable},
    },
};

#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug, Default)]
#[dojo::model]
pub struct Entity {
    #[key]
    pub inst: felt252,
    pub is_entity: bool,
    /// Properties ///
    /// Name of the entity
    pub name: ByteArray,
    /// Alternative names of the entity
    pub alt_names: Array<ByteArray>,
    /// Holds the keys of the actions that are attached to this entity
    pub actions_keys: Array<felt252>,
}

#[derive(Clone, Drop, Serde, Introspect)]
#[dojo::model]
pub struct ParentToChildren {
    #[key]
    pub inst: felt252,
    pub is_parent: bool,
    /// Properties ///
    /// The children entities
    pub children: Array<felt252>,
}

#[derive(Clone, Drop, Serde, Introspect)]
#[dojo::model]
pub struct ChildToParent {
    #[key]
    pub inst: felt252,
    pub is_child: bool,
    /// Properties ///
    /// The parent entity
    pub parent: felt252,
}

#[generate_trait]
pub impl EntityImpl of EntityTrait {
    // used for tests
    fn create_entity(ref world: WorldStorage, name: ByteArray) -> Entity {
        let mut entity: Entity = Default::default();
        entity.inst = world.dispatcher.uuid().try_into().unwrap();
        entity.is_entity = true;
        entity.name = name;
        world.write_model(@entity);
        entity
    }

    // mainly for tests
    // the game world should have a player component
    fn create_player_entity(ref world: WorldStorage, inst: felt252, address: ContractAddress) -> Player {
        // create player entity
        let mut entity: Entity = Default::default();
        entity.inst = inst;
        entity.is_entity = true;
        entity.name = "Player";
        world.write_model(@entity);
        // create the player component
        let mut player: Player = Component::add_component(ref world, entity.inst, 0);
        player.address = address;
        player.store(ref world, 0);
        // create the reactable
        let mut reactable: Reactable = Component::add_component(ref world, entity.inst, 0);
        reactable.description = array![0];
        reactable.store(ref world, 0);
        // (reactable) player description
        let descr1 = DescriptionText { inst: entity.inst, key: 0, text: "Looks like a visitor" };
        world.write_model(@descr1);
        // initialize player story
        player.say(ref world, 0, "You feel light, and shiny, in the head");
        // return the player
        (player)
    }

    fn create_player_game_instance(ref world: WorldStorage, player: @Player, game_id: u128) -> Player {
        // clone a new game instance player
        world.write_game_model(player, game_id);
        // initialize player story
        player.say(ref world, game_id, "You feel light, and shiny, in the head");
        // return the player
        (player.clone())
    }

    fn get_names(self: @Entity) -> Array<ByteArray> {
        let mut names = self.alt_names.clone();
        names.append(self.clone().name);
        names
    }

    fn name_is(self: @Entity, name: ByteArray) -> bool {
        if (self.name == @name) {
            return true;
        }
        let mut has_name = false;
        for alt_name in self.alt_names.clone() {
            if (alt_name == name) {
                has_name = true;
                break;
            }
        };
        has_name
    }

    fn get_entity(world: @WorldStorage, inst: felt252) -> Option<Entity> {
        let entity: Entity = world.read_model(inst);
        if (!entity.is_entity) {
            return Option::None;
        }
        Option::Some(entity)
    }

    fn is_entity(world: @WorldStorage, inst: felt252) -> bool {
        let mut entity: Entity = world.read_model(inst);
        entity.is_entity
    }

    fn has_parent(self: @Entity, world: @WorldStorage) -> bool {
        let child_to_parent: ChildToParent = world.read_model(*self.inst);
        return child_to_parent.is_child;
    }

    fn get_parent(self: @Entity, world: @WorldStorage) -> Option<Entity> {
        let child_to_parent: ChildToParent = world.read_model(*self.inst);
        if (child_to_parent.is_child) {
            let parent_entity: Entity = world.read_model(child_to_parent.parent);
            return Option::Some(parent_entity);
        }
        return Option::None;
    }

    fn has_children(self: @Entity, world: @WorldStorage) -> bool {
        let parent_to_children: ParentToChildren = world.read_model(*self.inst);
        (parent_to_children.is_parent && parent_to_children.children.len() > 0)
    }

    fn get_children(self: @Entity, world: @WorldStorage) -> Array<Entity> {
        let mut children: Array<Entity> = ArrayTrait::<Entity>::new();
        let parent_to_children: ParentToChildren = world.read_model(*self.inst);
        if (parent_to_children.is_parent) {
            for childKey in parent_to_children.children {
                let child: Entity = world.read_model(childKey);
                children.append(child);
            }
        }
        children
    }

    fn remove_from_parent(self: @Entity, ref world: WorldStorage, parent: @Entity) {
        let mut parent_relation: ParentToChildren = world.read_model(*parent.inst);
        assert(parent_relation.is_parent, 'Parent is not a parent');

        let mut new_children: Array<felt252> = ArrayTrait::<felt252>::new();
        for child_inst in parent_relation.children {
            if (child_inst != *self.inst) {
                new_children.append(child_inst);
            }
        };
        parent_relation.children = new_children;
        if parent_relation.children.len() == 0 {
            world.erase_model(@parent_relation);
        } else {
            world.write_model(@parent_relation);
        }
        let child: ChildToParent = world.read_model(self.inst.clone());
        world.erase_model(@child);
    }

    // @DEV: the cloning and writing in between is very dangerous, this might need a revision and at
    // least good tests
    fn set_parent(self: @Entity, ref world: WorldStorage, parent: @Entity) {
        if (self.has_parent(@world)) {
            self.remove_from_parent(ref world, @self.get_parent(@world).unwrap());
        }
        let mut parent_relation: ParentToChildren = world.read_model(*parent.inst);
        let mut is_child = false;
        for child_inst in parent_relation.children.clone() {
            if (child_inst == *self.inst) {
                is_child = true;
                break;
            }
        };

        if (!is_child) {
            parent_relation.children.append(*self.inst);
            parent_relation.is_parent = true;
            world.write_model(@parent_relation);
            world
                .write_model(
                    @ChildToParent { inst: *self.inst, is_child: true, parent: *parent.inst },
                );
        }
    }
}

