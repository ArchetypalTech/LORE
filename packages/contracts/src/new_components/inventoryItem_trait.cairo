use lore::models::index::InventoryItem;

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
