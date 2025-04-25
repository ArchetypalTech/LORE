use dojo::{world::{WorldStorage}, model::ModelStorage};
use lore::{
    constants::errors::Error,
    lib::{
        entity::{Entity, EntityImpl}, a_lexer::{Command, Token, CommandImpl},
        utils::ByteArrayTraitExt,
    },
    components::area::{AreaComponent},
};
use super::{Component, player::{Player, PlayerImpl, PlayerTrait}};


#[derive(Clone, Drop, Serde)]
#[dojo::model]
pub struct InventoryItem {
    #[key]
    pub inst: felt252,
    pub is_inventory_item: bool,
    // properties
    pub owner_id: felt252,
    pub can_be_picked_up: bool,
    pub can_go_in_container: bool,
    pub action_map: Array<ActionMapInventoryItem>,
}

#[derive(Clone, Drop, Serde, Introspect, Debug)]
pub struct ActionMapInventoryItem {
    pub action: ByteArray,
    pub inst: felt252,
    pub action_fn: InventoryItemActions,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum InventoryItemActions {
    UseItem,
}

#[generate_trait]
pub impl InventoryItemImpl of InventoryItemTrait {
    fn is_inventory_item(self: InventoryItem) -> bool {
        self.is_inventory_item
    }

    fn set_can_be_picked_up(ref self: InventoryItem, can_be_picked_up: bool) {
        self.can_be_picked_up = can_be_picked_up;
    }

    fn set_can_go_in_container(ref self: InventoryItem, can_go_in_container: bool) {
        self.can_go_in_container = can_go_in_container;
    }
}

pub impl InventoryItemComponent of Component<InventoryItem> {
    type ComponentType = InventoryItem;

    fn inst(self: @InventoryItem) -> @felt252 {
        self.inst
    }

    fn entity(self: @InventoryItem, world: @WorldStorage) -> Entity {
        EntityImpl::get_entity(world, self.inst).unwrap()
    }

    fn has_component(self: @InventoryItem, world: WorldStorage, inst: felt252) -> bool {
        let inventory_item: InventoryItem = world.read_model(inst);
        inventory_item.is_inventory_item
    }

    fn add_component(mut world: WorldStorage, inst: felt252) -> InventoryItem {
        let mut inventory_item: InventoryItem = world.read_model(inst);
        inventory_item.inst = inst;
        inventory_item.is_inventory_item = true;
        inventory_item
            .action_map =
                array![
                    ActionMapInventoryItem {
                        action: "pickup", inst: 0, action_fn: InventoryItemActions::UseItem,
                    },
                    ActionMapInventoryItem {
                        action: "drop", inst: 0, action_fn: InventoryItemActions::UseItem,
                    },
                ];
        inventory_item.store(world);
        inventory_item
    }

    fn get_component(world: WorldStorage, inst: felt252) -> Option<InventoryItem> {
        let inventory_item: InventoryItem = world.read_model(inst);
        if (!inventory_item.has_component(world, inst)) {
            return Option::None;
        }
        let inventory_item: InventoryItem = world.read_model(inst);
        Option::Some(inventory_item)
    }

    fn can_use_command(
        self: @InventoryItem, world: WorldStorage, player: @Player, command: @Command,
    ) -> bool {
        get_action_token(self, world, command).is_some()
    }

    fn execute_command(
        mut self: InventoryItem, mut world: WorldStorage, player: @Player, command: @Command,
    ) -> Result<(), Error> {
        println!("InventoryItem execute_command");
        player.say(world, format!("You are executing inventory item"));
        let (action, _token) = get_action_token(@self, world, command).unwrap();
        let nouns = command.get_nouns();
        match action.action_fn {
            InventoryItemActions::UseItem => {
                player.say(world, format!("You are trying to pick or drop:{:?}", nouns[0]));
                // HERE SHOULD GO THE LOGIC FOR HANDLING THE COMMAND
                // LIKE PUT ITEM IN CONTAINER, TAKE ITEM FROM CONTAINER, DROP ITEM, etc.
                return Result::Ok(());
            },
        }
        Result::Err(Error::ActionFailed)
    }

    fn store(self: @InventoryItem, mut world: WorldStorage) {
        world.write_model(self);
    }
}

// @dev: wip how to access tokens
fn get_action_token(
    self: @InventoryItem, world: WorldStorage, command: @Command,
) -> Option<(ActionMapInventoryItem, Token)> {
    let mut action_token: Option<(ActionMapInventoryItem, Token)> = Option::None;
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
