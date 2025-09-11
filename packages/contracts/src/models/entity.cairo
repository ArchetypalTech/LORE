use dojo::{
    world::{WorldStorage, IWorldDispatcherTrait},
    model::{ModelStorage, Model},
};
use lore::{
    models::{
        components::{Instance},
        game_instance::{GameModelImpl, GameInstImpl},
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


//---------------------------------
// Model Trait
//
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

    fn get_names(self: @Entity) -> Span<ByteArray> {
        let mut names = self.alt_names.clone();
        names.append(self.name.clone());
        (names.span())
    }

    fn name_is(self: @Entity, name: @ByteArray) -> bool {
        if (self.name == name) {
            return true;
        }
        let mut has_name = false;
        for alt_name in self.alt_names.span() {
            if (alt_name == name) {
                has_name = true;
                break;
            }
        };
        has_name
    }

    fn get_entity(world: @WorldStorage, inst: felt252) -> Option<Entity> {
        let entity: Entity = world.read_model(inst);
        if (entity.is_entity) {
            (Option::Some(entity))
        } else {
            (Option::None)
        }
    }

    fn is_entity(world: @WorldStorage, inst: felt252) -> bool {
        (Self::get_entity(world, inst).is_some())
    }

    //---------------------------------
    // Parents
    //

    fn has_children(self: @Entity, world: @WorldStorage, game_id: u128) -> bool {
        let parent: ParentToChildren = world.read_game_model(*self.inst, game_id);
        (parent.children.len() > 0)
    }

    fn contains_child(self: @Entity, world: @WorldStorage, inst: felt252, game_id: u128) -> bool {
        let mut result = false;
        let parent: ParentToChildren = world.read_game_model(*self.inst, game_id);
        for child_inst in parent.children.span() {
            if (child_inst == @inst) {
                result = true;
                break;
            }
        };
        (result)
    }

    fn get_children(self: @Entity, world: @WorldStorage, game_id: u128) -> Span<Entity> {
        let mut result: Array<Entity> = array![];
        let parent: ParentToChildren = world.read_game_model(*self.inst, game_id);
        for child_inst in parent.children.span() {
            let child_entity: Entity = world.read_model(*child_inst);
            result.append(child_entity);
        };
        (result.span())
    }

    fn get_children_keys(self: @Entity, world: @WorldStorage, game_id: u128) -> Span<felt252> {
        let parent: ParentToChildren = world.read_game_model(*self.inst, game_id);
        (parent.children.span())
    }

    fn get_children_count(self: @Entity, world: @WorldStorage, game_id: u128) -> u32 {
        let parent: ParentToChildren = world.read_game_model(*self.inst, game_id);
        (parent.children.len())
    }

    //---------------------------------
    // Children
    //

    fn has_parent(self: @Entity, world: @WorldStorage, game_id: u128) -> bool {
        let child: ChildToParent = world.read_game_model(*self.inst, game_id);
        (child.parent != 0)
    }

    fn get_parent(self: @Entity, world: @WorldStorage, game_id: u128) -> Option<Entity> {
        let child: ChildToParent = world.read_game_model(*self.inst, game_id);
        if (child.parent != 0) {
            let parent_entity: Entity = world.read_model(child.parent);
            (Option::Some(parent_entity))
        } else {
            (Option::None)
        }
    }

    fn remove_from_parent(self: @Entity, ref world: WorldStorage, parent_entity: @Entity, game_id: u128) {
        // validate parent
        let mut parent: ParentToChildren = world.read_game_model(*parent_entity.inst, game_id);
        assert(parent.is_parent, 'remove_from_parent() not parent');
        // update parent
        parent._remove_child(ref world, *self.inst, game_id);
        // update child
        let mut child: ChildToParent = world.read_game_model(*self.inst, game_id);
        child._set_parent(ref world, 0, game_id);
    }

    fn set_parent(self: @Entity, ref world: WorldStorage, parent_entity: @Entity, game_id: u128) {
        // check if the entity is already a child
        let mut child: ChildToParent = world.read_game_model(*self.inst, game_id);
        if (@child.parent != parent_entity.inst) {
            // remove from current parent
            if (child.parent != 0) {
                let mut parent: ParentToChildren = world.read_game_model(child.parent, game_id);
                parent._remove_child(ref world, *self.inst, game_id);
            }
            // update new parent
            let mut parent: ParentToChildren = world.read_game_model(*parent_entity.inst, game_id);
            parent._add_child(ref world, *self.inst, game_id);
            // update child
            child._set_parent(ref world, *parent_entity.inst, game_id);
        }
    }

    //---------------------------------
    // internal
    //
    fn _remove_child(ref self: ParentToChildren, ref world: WorldStorage, child_inst: felt252, game_id: u128) {
        let mut new_children: Array<felt252> = array![];
        for i in self.children.span() {
            if (*i != child_inst) {
                self.children.append(*i);
            }
        };
        self.children = new_children;
        self.is_parent = false;
        world.write_game_model(@self, game_id);
    }
    fn _add_child(ref self: ParentToChildren, ref world: WorldStorage, child_inst: felt252, game_id: u128) {
        self.children.append(child_inst);
        self.is_parent = true;
        world.write_game_model(@self, game_id);
    }
    fn _set_parent(ref self: ChildToParent, ref world: WorldStorage, parent_inst: felt252, game_id: u128) {
        self.parent = parent_inst;
        self.is_child = true;
        world.write_game_model(@self, game_id);
    }
}


//---------------------------------
// Game Instance interfaces
//

pub impl ParentToChildrenInstance of Instance<ParentToChildren> {
    #[inline(always)]
    fn inst(self: @ParentToChildren) -> felt252 {
        (*self.inst)
    }
    #[inline(always)]
    fn set_inst(ref self: ParentToChildren, new_inst: felt252) {
        self.inst = new_inst;
    }
    #[inline(always)]
    fn is_component(self: @ParentToChildren) -> bool {
        (*self.is_parent)
    }
    fn has_component(self: @WorldStorage, inst: felt252) -> bool {
        (inst != 0 && self.read_member(Model::<ParentToChildren>::ptr_from_keys(inst), selector!("is_parent")))
    }
}

pub impl ChildToParentInstance of Instance<ChildToParent> {
    #[inline(always)]
    fn inst(self: @ChildToParent) -> felt252 {
        (*self.inst)
    }
    #[inline(always)]
    fn set_inst(ref self: ChildToParent, new_inst: felt252) {
        self.inst = new_inst;
    }
    #[inline(always)]
    fn is_component(self: @ChildToParent) -> bool {
        (*self.is_child)
    }
    fn has_component(self: @WorldStorage, inst: felt252) -> bool {
        (inst != 0 && self.read_member(Model::<ChildToParent>::ptr_from_keys(inst), selector!("is_child")))
    }
}
