use dojo::{world::WorldStorage, model::{ModelStorage, Model}};
use lore::{
    models::{
        entity::{Entity, EntityImpl},
        components::{Instance, Component},
        game_instance::{GameModelImpl},
        player::{Player, PlayerImpl},
        inventory_item::{InventoryItem, InventoryItemImpl},
    },
    types::{command_type::{Command, Token},
    component_type::{ContainerActions, ActionMapContainer}},
    lib::{
        a_lexer::CommandImpl,
    },
    constants::errors::Error,
};


#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct Container {
    #[key]
    pub inst: felt252,
    pub is_container: bool,
    /// Properties ///
    /// If the container can be opened
    pub can_be_opened: bool,
    /// If the container can receive items
    pub can_receive_items: bool,
    /// If the container is open
    pub is_open: bool,
    /// Total number of slots of the container
    pub num_slots: u32,
    // pub accept_tags: Array<Tag>,
    pub action_map: Array<ActionMapContainer>,
}


//---------------------------------
// Model Trait
//
#[generate_trait]
pub impl ContainerImpl of ContainerTrait {
    fn is_container(self: @Container) -> bool {
        *self.is_container
    }

    fn set_open(ref self: Container, ref world: WorldStorage, opened: bool, game_id: u128) {
        // world.write_game_member<Container>(self, selector!("is_open"), opened, game_id);
        self.is_open = opened;
        world.write_game_model(@self, game_id);
    }

    fn set_can_be_opened(ref self: Container, ref world: WorldStorage, can_be_opened: bool, game_id: u128) {
        // world.write_game_member<Container>(self, selector!("can_be_opened"), can_be_opened, game_id);
        self.can_be_opened = can_be_opened;
        world.write_game_model(@self, game_id);
    }

    fn set_can_receive_items(ref self: Container, ref world: WorldStorage, can_receive_items: bool, game_id: u128) {
        // world.write_game_member<Container>(self, selector!("can_receive_items"), can_receive_items, game_id);
        self.can_receive_items = can_receive_items;
        world.write_game_model(@self, game_id);
    }

    fn is_full(self: @Container, world: @WorldStorage, game_id: u128) -> bool {
        (self.entity(world).get_children_count(world, game_id) >= *self.num_slots)
    }

    fn is_empty(self: @Container, world: @WorldStorage, game_id: u128) -> bool {
        (self.entity(world).get_children_count(world, game_id) == 0)
    }

    fn can_put_item(
        self: @Container, world: @WorldStorage, item: @InventoryItem, game_id: u128,
    ) -> (bool, Result<(), Error>) {
        let mut can_put_item = false;
        // check if container is open
        if (!*self.is_open) {
            return (can_put_item, Result::Err(Error::NotOpen));
        }
        // check if container is full
        if (self.is_full(world, game_id)) {
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
        if (self.contains(*item.inst, world, game_id)) {
            return (can_put_item, Result::Err(Error::AlreadyStored));
        }
        // if checks pass, container can receive item
        can_put_item = true;
        (can_put_item, Result::Ok(()))
    }

    // put an item into the container
    fn put_item_in(
        self: @Container, ref world: WorldStorage, ref item: InventoryItem, game_id: u128,
    ) -> Result<(), Error> {
        // check if item can be put in container
        let (result_b, result_c) = self.can_put_item(@world, @item, game_id);
        if (!result_b) {
            return Result::Err(result_c.unwrap_err());
        }
        // set parent to be the container's entity
        let item_entity: Entity = EntityImpl::get_entity(@world, item.inst).unwrap();
        item_entity.set_parent(ref world, @self.entity(@world), game_id);
        item.owner_id = *self.inst;
        world.write_game_model(@item, game_id);

        return Result::Ok(());
    }

    // put item out of the container, into the room
    fn put_item_out(
        self: @Container, ref world: WorldStorage, ref item: InventoryItem, player: @Player,
    ) -> Result<(), Error> {
        // check if the item is in the container
        if (!self.contains(item.inst, @world, *player.game_id)) {
            return Result::Err(Error::NotStored);
        }
        // get entities
        let item_entity: Entity = EntityImpl::get_entity(@world, item.inst).unwrap();
        let room_entity: Entity = player.get_room_entity(@world).unwrap();
        // set parent to be the room's entity
        item_entity.set_parent(ref world, @room_entity, *player.game_id);
        item.owner_id = room_entity.inst;
        world.write_game_model(@item, *player.game_id);
        
        return Result::Ok(());
    }

    fn contains(self: @Container, inst: felt252, world: @WorldStorage, game_id: u128) -> bool {
        (self.entity(world).contains_child(world, inst, game_id))
    }

    fn check_container(
        self: Container, ref world: WorldStorage, player: @Player, object: @ByteArray,
    ) -> bool {
        // check if container is open
        // we also check if the container is the player's personal inventory
        if (!self.is_open) {
            if (self.inst == *player.inst) {
                player.say(ref world, format!("{} personal inventory is close", object));
                return true;
            } else {
                player.say(ref world, format!("The {} is closed", object));
                return true;
            }
        } else {
            if (self.inst == *player.inst) {
                player.say(ref world, format!("{} personal inventory is open", object));
            } else {
                player.say(ref world, format!("{} is open", object));
            }
        }
        // check if container is full
        if (self.is_full(@world, *player.game_id)) {
            player.say(ref world, ("It is full."));
        } else {
            player.say(ref world, ("It is not full."));
        }
        // check if container can receive items
        if (!self.can_receive_items) {
            player.say(ref world, ("It cannot receive items"));
        } else {
            player.say(ref world, ("It can receive items"));
        }
        // check if container is empty
        if (self.is_empty(@world, *player.game_id)) {
            player.say(ref world, ("It is empty."));
        } else {
            // Say what it contains
            player.say(ref world, format!("It contains:"));
            let items = self.entity(@world).get_children(@world, *player.game_id);
            for item in items {
                player.say(ref world, format!("{}", item.name));
            };
        }

        return true;
    }
}


//---------------------------------
// Component
//
pub impl ContainerInstance of Instance<Container> {
    #[inline(always)]
    fn inst(self: @Container) -> felt252 {
        (*self.inst)
    }
    #[inline(always)]
    fn set_inst(ref self: Container, new_inst: felt252) {
        self.inst = new_inst;
    }
    #[inline(always)]
    fn is_component(self: @Container) -> bool {
        (*self.is_container)
    }
    fn has_component(self: @WorldStorage, inst: felt252) -> bool {
        (inst != 0 && self.read_member(Model::<Container>::ptr_from_keys(inst), selector!("is_container")))
    }
}

pub impl ContainerComponent of Component<Container> {
    type ComponentType = Container;

    fn entity(self: @Container, world: @WorldStorage) -> Entity {
        EntityImpl::get_entity(world, self.inst()).unwrap()
    }

    fn get_component(world: @WorldStorage, inst: felt252, game_id: u128) -> Option<Container> {
        let container: Container = world.read_game_model(inst, game_id);
        if (container.is_component()) {
            Option::Some(container)
        } else {
            Option::None
        }
    }

    fn store(self: @Container, ref world: WorldStorage, game_id: u128) {
        world.write_game_model(self, game_id);
    }

    fn can_use_command(
        self: @Container, world: @WorldStorage, player: @Player, command: @Command,
    ) -> bool {
        get_action_token(self, world, command).is_some()
    }

    fn execute_command(
        mut self: Container, ref world: WorldStorage, player: @Player, command: @Command,
    ) -> Result<(), Error> {
        // println!("Container execute_command");
        let (action, _token) = get_action_token(@self, @world, command).unwrap();
        let nouns = command.get_nouns();
        match action.action_fn {
            ContainerActions::Open => {
                if (self.is_open) {
                    player
                        .say(
                            ref world,
                            format!("The {} is already open.", self.entity(@world).name),
                        );
                } else {
                    player.say(ref world, format!("You open {}", self.entity(@world).name));
                    self.set_open(ref world, true, *player.game_id);
                }
                return Result::Ok(());
            },
            ContainerActions::Close => {
                if (!self.is_open) {
                    player
                        .say(
                            ref world,
                            format!("The {} is already closed.", self.entity(@world).name),
                        );
                } else {
                    player.say(ref world, format!("You close {}", self.entity(@world).name));
                    self.set_open(ref world, false, *player.game_id);
                }
                return Result::Ok(());
            },
            ContainerActions::Check => {
                // Check container status
                let doneChecking = self.check_container(ref world, player, nouns[0].text);
                if (doneChecking) {
                    return Result::Ok(());
                }
            },
        }
        Result::Err(Error::ActionFailed)
    }

    // used for tests only
    fn add_component(ref world: WorldStorage, inst: felt252) -> Container {
        let mut container: Container = world.read_model(inst);
        container.inst = inst;
        container.is_container = true;
        container.can_be_opened = true;
        container.can_receive_items = true;
        container.is_open = true;
        container.num_slots = 10;
        container
            .action_map =
                array![
                    ActionMapContainer {
                        action: "open", inst: 0, action_fn: ContainerActions::Open,
                    },
                    ActionMapContainer {
                        action: "close", inst: 0, action_fn: ContainerActions::Close,
                    },
                    ActionMapContainer {
                        action: "check", inst: 0, action_fn: ContainerActions::Check,
                    },
                ];
        container.store(ref world, 0);
        // Return the component
        container
    }
}

// @dev: wip how to access tokens
fn get_action_token(
    self: @Container, world: @WorldStorage, command: @Command,
) -> Option<(ActionMapContainer, Token)> {
    let mut action_token: Option<(ActionMapContainer, Token)> = Option::None;
    for token in command.tokens.clone() {
        for action in self.action_map.clone() {
            if (token.text == action.action) {
                action_token = Option::Some((action, token));
                break;
            }
        }
    };
    action_token
}



#[cfg(test)]
mod tests {
    // use dojo::{model::ModelStorage};
    use super::*;
    use lore::{
        tests::helpers,
        models::{
            entity::{EntityImpl},
            game_instance::{GameModelImpl},
            inventory_item::{InventoryItemComponent},
        },
    };

    #[test]
    fn test_container_game_comp() {
        let (mut world, _, _, _, _, _) = helpers::setup_core();
        //
        // create container
        let container: Container = ContainerComponent::add_component(ref world, 111);
        assert!(container.is_container);
        assert_eq!(container.inst, 111);
        //
        // read game inst version, same as inst
        let game_id: u128 = 222;
        let comp_null: Option<Container> = ContainerComponent::get_component(@world, 1234, 0);
        let comp_inst: Option<Container> = ContainerComponent::get_component(@world, container.inst, 0);
        let comp_game: Option<Container> = ContainerComponent::get_component(@world, container.inst, 1);
        assert!(comp_null.is_none(), "null");
        assert!(comp_inst.is_some(), "baseline");
        assert!(comp_game.is_some(), "baseline");
        let mut comp_inst: Container = comp_inst.unwrap();
        let mut comp_game: Container = comp_game.unwrap();
        assert!(comp_inst.is_component(), "baseline");
        assert!(comp_game.is_component(), "baseline");
        assert_eq!(comp_inst.inst(), container.inst, "baseline");
        assert_eq!(comp_game.inst(), container.inst, "baseline");
        assert_eq!(comp_inst.can_be_opened, true, "baseline");
        assert_eq!(comp_game.can_be_opened, true, "baseline");
        //
        // save game inst version
        comp_inst.num_slots = 20;
        comp_inst.store(ref world, 0);
        comp_game.num_slots = 10;
        comp_game.store(ref world, game_id);
        // inst does not change!
        assert_eq!(comp_inst.inst(), container.inst, "saved");
        assert_eq!(comp_game.inst(), container.inst, "saved");
        //
        // read game inst version, updated, original is preserved
        let new_comp_inst: Container = ContainerComponent::get_component(@world, container.inst, 0).unwrap();
        let new_comp_game: Container = ContainerComponent::get_component(@world, container.inst, game_id).unwrap();
        assert_eq!(new_comp_inst.inst(), container.inst, "new_component");
        assert_eq!(new_comp_game.inst(), container.inst, "new_component");
        assert_eq!(new_comp_inst.num_slots, 20, "new_component");
        assert_eq!(new_comp_game.num_slots, 10, "new_component");
        //
        // edit some more
        comp_inst.can_be_opened = true;
        comp_inst.is_open = false;
        comp_inst.store(ref world, 0);
        comp_game.can_be_opened = false;
        comp_game.is_open = true;
        comp_game.store(ref world, game_id);
        // results...
        let new_comp_inst: Container = ContainerComponent::get_component(@world, container.inst, 0).unwrap();
        let new_comp_game: Container = ContainerComponent::get_component(@world, container.inst, game_id).unwrap();
        assert_eq!(new_comp_inst.inst(), container.inst, "newer_component");
        assert_eq!(new_comp_game.inst(), container.inst, "newer_component");
        assert_eq!(new_comp_inst.num_slots, 20, "newer_component");
        assert_eq!(new_comp_inst.can_be_opened, true, "newer_component");
        assert_eq!(new_comp_inst.is_open, false, "newer_component");
        assert_eq!(new_comp_game.num_slots, 10, "newer_component");
        assert_eq!(new_comp_game.can_be_opened, false, "newer_component");
        assert_eq!(new_comp_game.is_open, true, "newer_component");
    }

    #[test]
    fn test_container_open() {
        let (mut world, _, _, _, _, _) = helpers::setup_core();
        //
        // create container
        let mut container: Container = ContainerComponent::add_component(ref world, 11);
        //
        // open container
        assert!(container.can_be_opened, "can_be_opened");
        assert!(container.is_open, "baseline");
        container.set_open(ref world, false, 0);
        assert!(!container.is_open, "closed");
        assert!(!GameModelImpl::<Container>::read_game_model(@world, container.inst, 0).is_open, "GameModelImpl::closed");
        container.set_open(ref world, true, 0);
        assert!(container.is_open, "opened");
        assert!(GameModelImpl::<Container>::read_game_model(@world, container.inst, 0).is_open, "GameModelImpl:opened");
    }

    #[test]
    fn test_container_items() {
        let (mut world, _, _, _, _, _) = helpers::setup_core();
        //
        // create some items
        let game_id: u128 = 0;
        let mut item1_entity = EntityImpl::create_entity(ref world, "item1");
        let mut item2_entity = EntityImpl::create_entity(ref world, "item2");
        let mut item1: InventoryItem = InventoryItemComponent::add_component(ref world, item1_entity.inst);
        let mut item2: InventoryItem = InventoryItemComponent::add_component(ref world, item2_entity.inst);
        assert!(!item1_entity.has_parent(@world, game_id), "!item1.has_parent");
        assert!(!item2_entity.has_parent(@world, game_id), "!item2.has_parent");
        // create containers
        let mut container1_entity = EntityImpl::create_entity(ref world, "container1");
        let mut container2_entity = EntityImpl::create_entity(ref world, "container2");
        let mut container1: Container = ContainerComponent::add_component(ref world, container1_entity.inst);
        let mut container2: Container = ContainerComponent::add_component(ref world, container2_entity.inst);
        assert!(!container1_entity.has_children(@world, game_id), "!container1.has_children");
        assert!(!container2_entity.has_children(@world, game_id), "!container2.has_children");
        //
        // add items to containers
        assert_eq!(container1.put_item_in(ref world, ref item1, 0), Result::Ok(()), "item1 > container1");
        assert_eq!(container2.put_item_in(ref world, ref item2, 0), Result::Ok(()), "item2 > container2");
        assert!(container1_entity.has_children(@world, game_id), "container1.has_children");
        assert!(container2_entity.has_children(@world, game_id), "container2.has_children");
        assert!(item1_entity.has_parent(@world, game_id), "item1.has_parent");
        assert!(item2_entity.has_parent(@world, game_id), "item2.has_parent");
        assert!(item1_entity.get_parent(@world, game_id).unwrap().inst == container1.inst(), "item1.get_parent");
        assert!(item2_entity.get_parent(@world, game_id).unwrap().inst == container2.inst(), "item2.get_parent");
        //
        // move an item
        assert_eq!(container1.put_item_in(ref world, ref item2, 0), Result::Ok(()), "item2 > container1");
        assert!(container1_entity.has_children(@world, game_id), "moved item2 > container1");
        assert!(!container2_entity.has_children(@world, game_id), "moved item2 > container1");
        assert!(container1_entity.get_children(@world, game_id).len() == 2, "moved item2 > container1");
        assert!(item1_entity.has_parent(@world, game_id), "item1.has_parent");
        assert!(item2_entity.has_parent(@world, game_id), "item2.has_parent");
        assert!(item1_entity.get_parent(@world, game_id).unwrap().inst == container1.inst(), "item1.get_parent");
        assert!(item2_entity.get_parent(@world, game_id).unwrap().inst == container1.inst(), "item2.get_parent");
        //
        // invalid move
        container2.set_can_receive_items(ref world, false, 0);
        assert_eq!(container2.put_item_in(ref world, ref item2, 0), Result::Err(Error::CantStore), "item2 > container2");
        assert!(!container2_entity.has_children(@world, game_id), "invalid move");
        assert!(item2_entity.get_parent(@world, game_id).unwrap().inst == container1.inst(), "item2.get_parent");
    }
}
