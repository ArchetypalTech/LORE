use starknet::ContractAddress;
use lore::models::{
    entity::{Entity, ParentToChildren, ChildToParent},
    description_text::DescriptionText,
    area::Area,
    exit::Exit,
    reactable::Reactable,
    container::Container,
    inventory_item::InventoryItem,
    action::Action,
    effect::Effect,
    condition::Condition,
    trigger::Trigger,
    hub::{Hub, Trail},
};

// Written by the trail owner after publishing a collaborator's proposal.
// Keys: (trail_id, proposer) — one record per collaborator per trail.
// Delivered to the collaborator via the standard entity subscription so they can show
// the appropriate notification (all published / partial / rejected).
#[derive(Clone, Drop, Serde, Introspect)]
#[dojo::model]
pub struct CollabReviewResult {
    #[key] pub trail_id: u128,
    #[key] pub proposer: ContractAddress,
    pub published_count: u32,  // items the owner chose to publish
    pub skipped_count:   u32,  // items from the proposal that were not published (0 = all published)
}

#[derive(Drop, Serde)]
#[dojo::event(historical: false)]
pub struct CollabProposalEvent {
    #[key] pub trail_id:             u128,
    #[key] pub proposer:             ContractAddress,
    // write proposals
    pub entities:             Array<Entity>,
    pub reactables:           Array<Reactable>,
    pub areas:                Array<Area>,
    pub exits:                Array<Exit>,
    pub hubs:                 Array<Hub>,
    pub description_texts:    Array<DescriptionText>,
    pub inventory_items:      Array<InventoryItem>,
    pub containers:           Array<Container>,
    pub trails:               Array<Trail>,
    pub triggers:             Array<Trigger>,
    pub conditions:           Array<Condition>,
    pub effects:              Array<Effect>,
    pub actions:              Array<Action>,
    pub parents:              Array<ParentToChildren>,
    pub children:             Array<ChildToParent>,
    // entity-level deletions (owner-only; collaborators must leave this empty)
    pub deleted_entity_insts:          Array<felt252>,
    // component-level deletions — single-key (flat inst list)
    pub deleted_reactable_insts:       Array<felt252>,
    pub deleted_area_insts:            Array<felt252>,
    pub deleted_exit_insts:            Array<felt252>,
    pub deleted_container_insts:       Array<felt252>,
    pub deleted_inventory_item_insts:  Array<felt252>,
    pub deleted_hub_insts:             Array<felt252>,
    pub deleted_trail_insts:           Array<felt252>,
    pub deleted_parent_insts:          Array<felt252>,
    pub deleted_child_insts:           Array<felt252>,
    // component-level deletions — multi-key (flat [inst, key, ...] pairs)
    pub deleted_description_text_keys: Array<felt252>,
    pub deleted_trigger_keys:          Array<felt252>,
    pub deleted_condition_keys:        Array<felt252>,
    pub deleted_effect_keys:           Array<felt252>,
    pub deleted_action_keys:           Array<felt252>,
}
