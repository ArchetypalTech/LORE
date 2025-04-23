use dojo::{world::WorldStorage, model::ModelStorage};
use lore::{
    components::{inventoryItem::InventoryItem},
    lib::{entity::{Entity, EntityImpl}, relations::{ChildToParent}},
};

#[derive(Clone, Drop, Serde, Introspect)]
#[dojo::model]
pub struct Container {
    #[key]
    pub inst: felt252,
    pub is_container: bool,
    pub childToParent: ChildToParent,
    // properties
    pub can_be_opened: bool,
    pub can_receive_items: bool,
    pub is_open: bool,
    pub num_slots: u32,
    pub item_ids: Array<felt252>,
    // pub accept_tags: Array<Tag>,
    pub action_map: Array<ByteArray>,
}

#[generate_trait]
pub impl ContainerImpl of ContainerTrait {
    fn is_container(self: Container) -> bool {
        self.is_container
    }

    fn get_item_ids(self: Container) -> Array<felt252> {
        self.item_ids
    }

    fn set_open(self: Container, mut world: WorldStorage, opened: bool) {
        let mut model: Container = world.read_model(self);
        model.is_open = opened;
        world.write_model(@model);
    }

    fn set_can_be_opened(self: Container, mut world: WorldStorage, can_be_opened: bool) {
        let mut model: Container = world.read_model(self);
        model.can_be_opened = can_be_opened;
        world.write_model(@model);
    }

    fn set_can_receive_items(self: Container, mut world: WorldStorage, can_receive_items: bool) {
        let mut model: Container = world.read_model(self);
        model.can_receive_items = can_receive_items;
        world.write_model(@model);
    }

    fn is_full(self: Container) -> bool {
        let itemAmount: u32 = self.item_ids.len().try_into().unwrap();
        return itemAmount >= self.num_slots;
    }

    fn is_empty(self: Container) -> bool {
        return self.item_ids.len() == 0;
    }

    fn can_put_item(self: Container, world: WorldStorage, item: InventoryItem) -> bool {
        let mut can_put_item = false;
        // check if container is full
        if (self.clone().is_full()) {
            return can_put_item;
        }
        // check if container can receive items
        if (!self.can_receive_items) {
            return can_put_item;
        }
        // check if item can go into the container
        if (!item.can_go_in_container) {
            return can_put_item;
        }
        // check if item is already in the container
        if (self.contains(item.inst)) {
            return can_put_item;
        }
        // if checks pass, container can receive item
        can_put_item = true;
        can_put_item
    }

    fn put_item(self: Container, mut world: WorldStorage, item: InventoryItem) {
        // get container
        let mut container: Container = world.read_model(self.inst);
        // get item entity
        let item_entity: Entity = world.read_model(item.inst);
        // check if container is full
        if (container.clone().is_full()) {
            return;
        }
        // check if item can be put in container
        if (!container.clone().can_put_item(world, item.clone())) {
            return;
        }
        // add item to container by getting the parent of the container which can be the player or a
        // chest, etc
        let mut container_parent: Entity = world.read_model(container.childToParent.parent);
        // set parent to be the container_parent
        item_entity.set_parent(world, @container_parent);
        // add item to container
        container.item_ids.append(item.inst);
        // update container
        world.write_model(@container);
    }


    fn take_item(self: Container, world: WorldStorage, item: InventoryItem) {
        assert(true == false, 'take_item not yet implemented');
    }

    fn contains(self: Container, itemID: felt252) -> bool {
        let mut already_inside = false;
        // check if item is already in container
        for item_id in self.item_ids.clone() {
            if (item_id == itemID) {
                already_inside;
                break;
            }
        };
        already_inside
    }
}
