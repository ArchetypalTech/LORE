use dojo::{world::WorldStorage, model::ModelStorage, model::Model};
use lore::{
    models::{
        entity::{Entity, EntityImpl},
        components::{Component},
        container::{Container, ContainerComponent},
        player::{Player},
        inventory_item::{InventoryItem},
    },
    new_components::{player_trait::PlayerImpl},
    lib::{a_lexer::CommandImpl},
    constants::errors::Error,
};

#[generate_trait]
pub impl ContainerImpl of ContainerTrait {
    fn is_container(self: Container) -> bool {
        self.is_container
    }

    fn get_item_ids(self: Container, world: @WorldStorage) -> Array<felt252> {
        let mut item_ids: Array<felt252> = ArrayTrait::new();
        let items = self.entity(world).get_children(world);
        for item in items {
            item_ids.append(item.inst);
        };
        item_ids
    }

    fn set_open(self: Container, mut world: WorldStorage, opened: bool) {
        let mut model: Container = world.read_model(self.clone());
        model.is_open = opened;
        world
            .write_member(
                Model::<Container>::ptr_from_keys(self.inst), selector!("is_open"), model.is_open,
            );
        // world.write_model(@model);
    }

    fn set_can_be_opened(self: Container, mut world: WorldStorage, can_be_opened: bool) {
        let mut model: Container = world.read_model(self.clone());
        model.can_be_opened = can_be_opened;
        world
            .write_member(
                Model::<Container>::ptr_from_keys(self.inst),
                selector!("can_be_opened"),
                model.can_be_opened,
            );
        // world.write_model(@model);
    }

    fn set_can_receive_items(self: Container, mut world: WorldStorage, can_receive_items: bool) {
        let mut model: Container = world.read_model(self.clone());
        model.can_receive_items = can_receive_items;
        world
            .write_member(
                Model::<Container>::ptr_from_keys(self.inst),
                selector!("can_receive_items"),
                model.can_receive_items,
            );
        // world.write_model(@model);
    }

    fn is_full(self: @Container, world: @WorldStorage) -> bool {
        let itemAmount: u32 = self.clone().get_item_ids(world).len().try_into().unwrap();
        return itemAmount >= *self.num_slots;
    }

    fn is_empty(self: Container, world: @WorldStorage) -> bool {
        return self.clone().get_item_ids(world).len() == 0;
    }

    fn can_put_item(
        self: @Container, world: @WorldStorage, item: @InventoryItem,
    ) -> (bool, Result<(), Error>) {
        let mut can_put_item = false;
        // check if container is open
        if (!*self.is_open) {
            return (can_put_item, Result::Err(Error::NotOpen));
        }
        // check if container is full
        if (self.clone().is_full(world)) {
            return (can_put_item, Result::Err(Error::ContainerFull));
        }
        // check if container can receive items
        if (!*self.can_receive_items) {
            return (can_put_item, Result::Err(Error::CantStore));
        }
        // check if item can be picked up
        if (!*item.can_be_picked_up) {
            return (can_put_item, Result::Err(Error::CantBePicked));
        }
        // check if item can go into the container
        if (!*item.can_go_in_container) {
            return (can_put_item, Result::Err(Error::CantBeStored));
        }
        // check if item is already in the container
        if (self.contains(*item.inst, world)) {
            return (can_put_item, Result::Err(Error::AlreadyStored));
        }
        // if checks pass, container can receive item
        can_put_item = true;
        (can_put_item, Result::Ok(()))
    }

    fn put_item_in(
        self: Container, mut world: WorldStorage, mut item: InventoryItem,
    ) -> Result<(), Error> {
        // get container
        let mut container: Container = world.read_model(self.inst);

        // get item entity
        let item_entity: Entity = world.read_model(item.inst);

        // check if item can be put in container
        let (result_b, result_c) = container.clone().can_put_item(@world, @item.clone());
        if (!result_b) {
            return Result::Err(result_c.unwrap_err());
        }
        // set parent to be the container's entity
        item_entity.set_parent(world, @container.entity(@world));
        item.owner_id = container.inst;
        // update container
        world.write_model(@container);
        // update item
        world
            .write_member(
                Model::<InventoryItem>::ptr_from_keys(item.inst),
                selector!("owner_id"),
                item.owner_id,
            );
        //world.write_model(@item);
        return Result::Ok(());
    }


    fn put_item_out(
        self: Container, mut world: WorldStorage, mut item: InventoryItem, player: @Player,
    ) -> Result<(), Error> {
        // get container
        let mut container: Container = world.read_model(self.inst);
        // get item entity
        let item_entity: Entity = world.read_model(item.inst);
        // get room
        let room: Entity = player.get_room(@world).unwrap();

        // check if the item is in the container
        if (!container.clone().contains(item_entity.inst, @world)) {
            return Result::Err(Error::NotStored);
        }
        // remove item from container:
        // set parent to be the room's entity
        item_entity.set_parent(world, @room);
        item.owner_id = room.inst;
        //item_entity.remove_from_parent(world, @container);
        // update container
        world.write_model(@container);
        // update item
        world
            .write_member(
                Model::<InventoryItem>::ptr_from_keys(item.inst),
                selector!("owner_id"),
                item.owner_id,
            );
        //world.write_model(@item);
        return Result::Ok(());
    }

    fn contains(self: @Container, itemID: felt252, world: @WorldStorage) -> bool {
        let mut already_inside = false;
        // check if item is already in container
        for item_id in self.clone().get_item_ids(world) {
            if (item_id == itemID) {
                already_inside = true;
                break;
            }
        };
        already_inside
    }

    fn check_container(
        self: Container, world: @WorldStorage, player: @Player, object: @ByteArray,
    ) -> bool {
        // check if container is open
        // we also check if the container is the player's personal inventory
        if (!self.is_open) {
            if (self.inst == *player.inst) {
                player.say(*world, format!("{} personal inventory is close", object));
                return true;
            } else {
                player.say(*world, format!("The {} is closed", object));
                return true;
            }
        } else {
            if (self.inst == *player.inst) {
                player.say(*world, format!("{} personal inventory is open", object));
            } else {
                player.say(*world, format!("{} is open", object));
            }
        }
        // check if container is full
        if (self.clone().is_full(world)) {
            player.say(*world, ("It is full."));
        } else {
            player.say(*world, ("It is not full."));
        }
        // check if container can receive items
        if (!self.can_receive_items) {
            player.say(*world, ("It cannot receive items"));
        } else {
            player.say(*world, ("It can receive items"));
        }
        // check if container is empty
        if (self.clone().is_empty(world)) {
            player.say(*world, ("It is empty."));
        } else {
            // Say what it contains
            player.say(*world, format!("It contains:"));
            let items_id = self.get_item_ids(world);
            for item_id in items_id {
                let item = EntityImpl::get_entity(world, @item_id).unwrap();
                player.say(*world, format!("{}", item.name));
            };
        }

        return true;
    }
}
