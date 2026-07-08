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

// Three approval buckets per direction (write / delete):
//
//  w_single_keys / d_single_keys
//      Flat list of inst values (felt252) for all single-key component types:
//      Entity, Reactable, Area, Exit, Hub, InventoryItem, Container, Trail,
//      ParentToChildren, ChildToParent.
//
//  w_description_texts / d_description_texts
//      Flat pairs [inst, key_as_felt252, ...] for DescriptionText (inst, u32 key).
//      Kept separate so the owner can approve structural components but reject content.
//
//  w_multi_keys / d_multi_keys
//      Flat pairs [inst, key, ...] for the remaining multi-key types:
//      Trigger, Condition, Effect, Action.
#[derive(Clone, Drop, Serde, Introspect)]
#[dojo::model]
pub struct ApprovedProposal {
    #[key]
    pub trail_id: u128,
    #[key]
    pub proposer: ContractAddress,
    pub w_single_keys:       Array<felt252>,
    pub w_description_texts: Array<felt252>,
    pub w_multi_keys:        Array<felt252>,
    pub d_single_keys:       Array<felt252>,
    pub d_description_texts: Array<felt252>,
    pub d_multi_keys:        Array<felt252>,
}

// Returns true if `inst` is present in `list`.
pub fn contains_inst(mut list: Span<felt252>, inst: felt252) -> bool {
    loop {
        match list.pop_front() {
            Option::None => { break false; },
            Option::Some(i) => { if *i == inst { break true; } },
        }
    }
}

// Returns true if the (inst, key) pair appears as consecutive elements in `list`.
pub fn contains_pair(mut list: Span<felt252>, inst: felt252, key: felt252) -> bool {
    loop {
        match list.pop_front() {
            Option::None => { break false; },
            Option::Some(i) => {
                match list.pop_front() {
                    Option::None => { break false; },
                    Option::Some(k) => { if *i == inst && *k == key { break true; } },
                }
            },
        }
    }
}

#[derive(Drop, Serde)]
#[dojo::event(historical: false)]
pub struct CollabProposalEvent {
    #[key]
    pub trail_id:             u128,
    #[key]
    pub proposer:             ContractAddress,
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
    pub deleted_entity_insts:          Array<felt252>,
    // component-level deletions — single-key (just inst), multi-key (flat [inst, key, ...] pairs)
    pub deleted_reactable_insts:       Array<felt252>,
    pub deleted_area_insts:            Array<felt252>,
    pub deleted_exit_insts:            Array<felt252>,
    pub deleted_container_insts:       Array<felt252>,
    pub deleted_inventory_item_insts:  Array<felt252>,
    pub deleted_hub_insts:             Array<felt252>,
    pub deleted_trail_insts:           Array<felt252>,
    pub deleted_parent_insts:          Array<felt252>,
    pub deleted_child_insts:           Array<felt252>,
    pub deleted_description_text_keys: Array<felt252>,
    pub deleted_trigger_keys:          Array<felt252>,
    pub deleted_condition_keys:        Array<felt252>,
    pub deleted_effect_keys:           Array<felt252>,
    pub deleted_action_keys:           Array<felt252>,
}
