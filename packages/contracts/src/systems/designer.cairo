use starknet::ContractAddress;
use lore::{
    models::{
        entity::{Entity, ParentToChildren, ChildToParent},
        description_text::{DescriptionText},
        container::{Container},
        player::{Player},
        area::{Area},
        exit::{Exit},
        inventory_item::{InventoryItem},
        reactable::{Reactable},
        action::{Action},
        effect::{Effect},
        condition::{Condition},
        trigger::{Trigger},
        hub::{Hub, Trail},
        collab_proposal::{CollabReviewResult},
    },
};

#[starknet::interface]
pub trait IDesigner<TContractState> {
    //
    fn is_admin(self: @TContractState, account: ContractAddress) -> bool;
    fn is_editor(self: @TContractState, account: ContractAddress) -> bool;
    fn set_admin(ref self: TContractState, account: ContractAddress, is_admin: bool);
    fn set_editor(ref self: TContractState, account: ContractAddress, is_editor: bool);
    fn grant_access_to_entity(ref self: TContractState, account: ContractAddress, inst: felt252, granting: bool);
    fn grant_access_to_trail(ref self: TContractState, account: ContractAddress, trail_id: u128, granting: bool);
    //
    fn create_player(ref self: TContractState, t: Array<Player>);
    fn create_entity(ref self: TContractState, t: Array<Entity>);
    fn create_reactable(ref self: TContractState, t: Array<Reactable>);
    fn create_description_text(ref self: TContractState, t: Array<DescriptionText>);
    fn create_area(ref self: TContractState, t: Array<Area>);
    fn create_exit(ref self: TContractState, t: Array<Exit>);
    fn create_inventory_item(ref self: TContractState, t: Array<InventoryItem>);
    fn create_container(ref self: TContractState, t: Array<Container>);
    fn create_trigger(ref self: TContractState, t: Array<Trigger>);
    fn create_condition(ref self: TContractState, t: Array<Condition>);
    fn create_effect(ref self: TContractState, t: Array<Effect>);
    fn create_action(ref self: TContractState, t: Array<Action>);
    fn create_hub(ref self: TContractState, t: Array<Hub>);
    fn create_trail(ref self: TContractState, t: Array<Trail>);
    fn create_parent(ref self: TContractState, t: Array<ParentToChildren>);
    fn create_child(ref self: TContractState, t: Array<ChildToParent>);
    //
    fn delete_player(ref self: TContractState, ids: Array<felt252>);
    fn delete_entity(ref self: TContractState, ids: Array<felt252>);
    fn delete_reactable(ref self: TContractState, ids: Array<felt252>);
    fn delete_description_text(ref self: TContractState, ids: Array<(felt252, felt252)>);
    fn delete_area(ref self: TContractState, ids: Array<felt252>);
    fn delete_exit(ref self: TContractState, ids: Array<felt252>);
    fn delete_inventory_item(ref self: TContractState, ids: Array<felt252>);
    fn delete_container(ref self: TContractState, ids: Array<felt252>);
    fn delete_trigger(ref self: TContractState, ids: Array<(felt252, felt252)>);
    fn delete_condition(ref self: TContractState, ids: Array<(felt252, felt252)>);
    fn delete_effect(ref self: TContractState, ids: Array<(felt252, felt252)>);
    fn delete_action(ref self: TContractState, ids: Array<(felt252, felt252)>);
    fn delete_hub(ref self: TContractState, ids: Array<felt252>);
    fn delete_trail(ref self: TContractState, ids: Array<felt252>);
    fn delete_parent(ref self: TContractState, ids: Array<felt252>);
    fn delete_child(ref self: TContractState, ids: Array<felt252>);
    //
    fn register_property_registry(ref self: TContractState, done: Array<bool>);
    //
    fn submit_for_review(
        ref self: TContractState,
        trail_id: u128,
        entities:                      Array<Entity>,
        reactables:                    Array<Reactable>,
        areas:                         Array<Area>,
        exits:                         Array<Exit>,
        hubs:                          Array<Hub>,
        description_texts:             Array<DescriptionText>,
        inventory_items:               Array<InventoryItem>,
        containers:                    Array<Container>,
        trails:                        Array<Trail>,
        triggers:                      Array<Trigger>,
        conditions:                    Array<Condition>,
        effects:                       Array<Effect>,
        actions:                       Array<Action>,
        parents:                       Array<ParentToChildren>,
        children:                      Array<ChildToParent>,
        deleted_entity_insts:          Array<felt252>,
        deleted_reactable_insts:       Array<felt252>,
        deleted_area_insts:            Array<felt252>,
        deleted_exit_insts:            Array<felt252>,
        deleted_container_insts:       Array<felt252>,
        deleted_inventory_item_insts:  Array<felt252>,
        deleted_hub_insts:             Array<felt252>,
        deleted_trail_insts:           Array<felt252>,
        deleted_parent_insts:          Array<felt252>,
        deleted_child_insts:           Array<felt252>,
        deleted_description_text_keys: Array<felt252>,
        deleted_trigger_keys:          Array<felt252>,
        deleted_condition_keys:        Array<felt252>,
        deleted_effect_keys:           Array<felt252>,
        deleted_action_keys:           Array<felt252>,
    );
    fn signal_review_result(ref self: TContractState, trail_id: u128, proposer: ContractAddress, published_count: u32, skipped_count: u32);
    // Monetization: Revenue
    fn add_collaborator(ref self: TContractState, inst: felt252, account: ContractAddress);
    // IAccessControl
    fn has_role(self: @TContractState, role: felt252, account: ContractAddress) -> bool;
    // fn get_role_admin(self: @TContractState, role: felt252) -> felt252;
    // fn grant_role(ref self: TContractState, role: felt252, account: ContractAddress);
    // fn revoke_role(ref self: TContractState, role: felt252, account: ContractAddress);
    // fn renounce_role(ref self: TContractState, role: felt252, account: ContractAddress);
}

#[starknet::interface]
pub trait IDesignerPublic<TContractState> {
    //
    fn is_admin(self: @TContractState, account: ContractAddress) -> bool;
    fn is_editor(self: @TContractState, account: ContractAddress) -> bool;
    fn set_admin(ref self: TContractState, account: ContractAddress, is_admin: bool);
    fn set_editor(ref self: TContractState, account: ContractAddress, is_editor: bool);
    fn grant_access_to_entity(ref self: TContractState, account: ContractAddress, inst: felt252, granting: bool);
    fn grant_access_to_trail(ref self: TContractState, account: ContractAddress, trail_id: u128, granting: bool);
    //
    fn create_player(ref self: TContractState, t: Array<Player>);
    fn create_entity(ref self: TContractState, t: Array<Entity>);
    fn create_reactable(ref self: TContractState, t: Array<Reactable>);
    fn create_description_text(ref self: TContractState, t: Array<DescriptionText>);
    fn create_area(ref self: TContractState, t: Array<Area>);
    fn create_exit(ref self: TContractState, t: Array<Exit>);
    fn create_inventory_item(ref self: TContractState, t: Array<InventoryItem>);
    fn create_container(ref self: TContractState, t: Array<Container>);
    fn create_trigger(ref self: TContractState, t: Array<Trigger>);
    fn create_condition(ref self: TContractState, t: Array<Condition>);
    fn create_effect(ref self: TContractState, t: Array<Effect>);
    fn create_action(ref self: TContractState, t: Array<Action>);
    fn create_hub(ref self: TContractState, t: Array<Hub>);
    fn create_trail(ref self: TContractState, t: Array<Trail>);
    fn create_parent(ref self: TContractState, t: Array<ParentToChildren>);
    fn create_child(ref self: TContractState, t: Array<ChildToParent>);
    //
    fn delete_player(ref self: TContractState, ids: Array<felt252>);
    fn delete_entity(ref self: TContractState, ids: Array<felt252>);
    fn delete_reactable(ref self: TContractState, ids: Array<felt252>);
    fn delete_description_text(ref self: TContractState, ids: Array<(felt252, felt252)>);
    fn delete_area(ref self: TContractState, ids: Array<felt252>);
    fn delete_exit(ref self: TContractState, ids: Array<felt252>);
    fn delete_inventory_item(ref self: TContractState, ids: Array<felt252>);
    fn delete_container(ref self: TContractState, ids: Array<felt252>);
    fn delete_trigger(ref self: TContractState, ids: Array<(felt252, felt252)>);
    fn delete_condition(ref self: TContractState, ids: Array<(felt252, felt252)>);
    fn delete_effect(ref self: TContractState, ids: Array<(felt252, felt252)>);
    fn delete_action(ref self: TContractState, ids: Array<(felt252, felt252)>);
    fn delete_hub(ref self: TContractState, ids: Array<felt252>);
    fn delete_trail(ref self: TContractState, ids: Array<felt252>);
    fn delete_parent(ref self: TContractState, ids: Array<felt252>);
    fn delete_child(ref self: TContractState, ids: Array<felt252>);
    //
    fn register_property_registry(ref self: TContractState, done: Array<bool>);
    //
    fn submit_for_review(
        ref self: TContractState,
        trail_id: u128,
        entities:                      Array<Entity>,
        reactables:                    Array<Reactable>,
        areas:                         Array<Area>,
        exits:                         Array<Exit>,
        hubs:                          Array<Hub>,
        description_texts:             Array<DescriptionText>,
        inventory_items:               Array<InventoryItem>,
        containers:                    Array<Container>,
        trails:                        Array<Trail>,
        triggers:                      Array<Trigger>,
        conditions:                    Array<Condition>,
        effects:                       Array<Effect>,
        actions:                       Array<Action>,
        parents:                       Array<ParentToChildren>,
        children:                      Array<ChildToParent>,
        deleted_entity_insts:          Array<felt252>,
        deleted_reactable_insts:       Array<felt252>,
        deleted_area_insts:            Array<felt252>,
        deleted_exit_insts:            Array<felt252>,
        deleted_container_insts:       Array<felt252>,
        deleted_inventory_item_insts:  Array<felt252>,
        deleted_hub_insts:             Array<felt252>,
        deleted_trail_insts:           Array<felt252>,
        deleted_parent_insts:          Array<felt252>,
        deleted_child_insts:           Array<felt252>,
        deleted_description_text_keys: Array<felt252>,
        deleted_trigger_keys:          Array<felt252>,
        deleted_condition_keys:        Array<felt252>,
        deleted_effect_keys:           Array<felt252>,
        deleted_action_keys:           Array<felt252>,
    );
    fn add_collaborator(ref self: TContractState, inst: felt252, account: ContractAddress);
    fn signal_review_result(ref self: TContractState, trail_id: u128, proposer: ContractAddress, published_count: u32, skipped_count: u32);
}

#[dojo::contract]
pub mod designer {
    use starknet::ContractAddress;
    use core::num::traits::Zero;
    use dojo::{
        world::{WorldStorage, IWorldDispatcherTrait},
        model::{ModelStorage},
        event::{EventStorage},
    };

    //
    // components
    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_access::accesscontrol::{AccessControlComponent, DEFAULT_ADMIN_ROLE};
    use openzeppelin_access::accesscontrol::interface::IAccessControl;
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;
    #[abi(embed_v0)]
    impl AccessControlImpl = AccessControlComponent::AccessControlImpl<ContractState>;
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;
    #[storage]
    struct Storage {
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
    }
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
    }

    //
    // LORE
    use lore::{
        models::{
            dictionary::{Dict, DictionaryImpl},
            entity::{Entity, EntityImpl, ParentToChildren, ChildToParent},
            description_text::{DescriptionText},
            player::{Player},
            area::{Area},
            exit::{Exit},
            reactable::{Reactable},
            container::{Container},
            inventory_item::{InventoryItem},
            action::{Action, ActionImpl},
            effect::{Effect, EffectImpl},
            condition::{Condition},
            trigger::{Trigger, TriggerImpl},
            hub::{Hub, HubTrait, Trail, TrailTrait},
            collab_proposal::{CollabReviewResult, CollabProposalEvent},
        },
        types::{
            component_type::ComponentType,
            command_type::TokenType,
        },
        lib::{
            access::{ROLES, AccessGrantedEvent},
            utils::{ByteArrayTraitExt},
            variable_property_helper::{VariablePropertyHelper},
            dns::{DnsTrait, ILexerDispatcherTrait, ITrailTokenDispatcherTrait},
        },
        constants::errors::{Error},
    };

    mod Errors {
        pub const NOT_ADMIN: felt252           = 'DESIGNER: Not admin';
        pub const NOT_EDITOR: felt252          = 'DESIGNER: Not editor';
        pub const NOT_YOUR_ENTITY: felt252     = 'DESIGNER: Not your entity';
        pub const NOT_YOUR_TRAIL: felt252      = 'DESIGNER: Not your trail';
        pub const INVALID_ENTITY: felt252      = 'DESIGNER: Invalid entity';
        pub const NOT_APPROVED: felt252        = 'DESIGNER: Not approved';
        pub const NOT_TRAIL_OWNER: felt252     = 'DESIGNER: Not trail owner';
        pub const NOT_COLLABORATOR: felt252    = 'DESIGNER: Not collaborator';
        pub const INVALID_COLLABORATOR: felt252    = 'DESIGNER: Invalid collaborator';
        pub const TOO_MANY_COLLABORATORS: felt252  = 'DESIGNER: Too many collabs';
    }

    // Bounds the collaborator-crediting loop in actions_token::charge_player_actions,
    // which runs on every action against an entity (not just at join time — see
    // docs/Monetization/revenue-distribution-implementation-plan.md, Phase 2).
    const MAX_COLLABORATORS: u32 = 200;

    fn dojo_init(ref self: ContractState, admin_accounts: Array<ContractAddress>) {
        let mut world: WorldStorage = self.world_default();

        // increment uuid (avoid entity 0x0)
        let _: u32 = world.dispatcher.uuid();

        // initialize dictionary
        world.lexer_dispatcher().initialize_dictionary(world);
        // initializze properties
        self._register_property_registry(ref world, array![true]);

        // initialize access control
        self.accesscontrol.initializer();
        // intialize admins
        let deployer_address: ContractAddress = starknet::get_execution_info().tx_info.account_contract_address;
        self._grant_admin_roles(ref world, deployer_address);
        for account in admin_accounts {
            self._grant_admin_roles(ref world, account);
        };
    }

    #[generate_trait]
    impl WorldDefaultImpl of WorldDefaultTrait {
        #[inline(always)]
        fn world_default(self: @ContractState) -> WorldStorage {
            (self.world(@"lore"))
        }
    }

    #[abi(embed_v0)]
    pub impl DesignerPublicImpl of super::IDesignerPublic<ContractState> {

        fn is_admin(self: @ContractState, account: ContractAddress) -> bool {
            (self.accesscontrol.has_role(ROLES::ADMIN, account))
        }
        fn is_editor(self: @ContractState, account: ContractAddress) -> bool {
            self.accesscontrol.has_role(ROLES::EDITOR, account)
                || self.accesscontrol.has_role(ROLES::ADMIN, account)
                || self.accesscontrol.has_role(ROLES::COLLABORATOR, account)
        }
        fn set_admin(ref self: ContractState, account: ContractAddress, is_admin: bool) {
            let mut world: WorldStorage = self.world_default();
            self._assert_caller_is_admin(@world);
            self._grant_role(ref world, ROLES::ADMIN, account, is_admin);
        }
        fn set_editor(ref self: ContractState, account: ContractAddress, is_editor: bool) {
            let mut world: WorldStorage = self.world_default();
            self._assert_caller_is_admin(@world);
            self._grant_role(ref world, ROLES::EDITOR, account, is_editor);
        }
        fn grant_access_to_entity(ref self: ContractState, account: ContractAddress, inst: felt252, granting: bool) {
            let mut world: WorldStorage = self.world_default();
            self._grant_role(ref world, inst, account, granting);
        }
        fn grant_access_to_trail(ref self: ContractState, account: ContractAddress, trail_id: u128, granting: bool) {
            let mut world: WorldStorage = self.world_default();
            let caller: ContractAddress = starknet::get_caller_address();
            let is_trail_owner: bool = world.is_owner_of_trail(trail_id, caller);
            assert(
                self.is_admin(caller) || world.is_world_contract(caller) || is_trail_owner,
                Errors::NOT_YOUR_TRAIL,
            );
            self._grant_role(ref world, trail_id.into(), account, granting);
            // Grant COLLABORATOR so the invitee passes _assert_caller_is_editor().
            // Only grant on invite — never auto-revoke, since the player may have other
            // trail collaborations and COLLABORATOR must outlive any single trail revocation.
            if granting {
                self._grant_role(ref world, ROLES::COLLABORATOR, account, true);
            }
        }

        fn submit_for_review(
            ref self: ContractState,
            trail_id: u128,
            entities:                      Array<Entity>,
            reactables:                    Array<Reactable>,
            areas:                         Array<Area>,
            exits:                         Array<Exit>,
            hubs:                          Array<Hub>,
            description_texts:             Array<DescriptionText>,
            inventory_items:               Array<InventoryItem>,
            containers:                    Array<Container>,
            trails:                        Array<Trail>,
            triggers:                      Array<Trigger>,
            conditions:                    Array<Condition>,
            effects:                       Array<Effect>,
            actions:                       Array<Action>,
            parents:                       Array<ParentToChildren>,
            children:                      Array<ChildToParent>,
            deleted_entity_insts:          Array<felt252>,
            deleted_reactable_insts:       Array<felt252>,
            deleted_area_insts:            Array<felt252>,
            deleted_exit_insts:            Array<felt252>,
            deleted_container_insts:       Array<felt252>,
            deleted_inventory_item_insts:  Array<felt252>,
            deleted_hub_insts:             Array<felt252>,
            deleted_trail_insts:           Array<felt252>,
            deleted_parent_insts:          Array<felt252>,
            deleted_child_insts:           Array<felt252>,
            deleted_description_text_keys: Array<felt252>,
            deleted_trigger_keys:          Array<felt252>,
            deleted_condition_keys:        Array<felt252>,
            deleted_effect_keys:           Array<felt252>,
            deleted_action_keys:           Array<felt252>,
        ) {
            let caller: ContractAddress = starknet::get_caller_address();
            let mut world: WorldStorage = self.world_default();
            // caller must have been granted access to this trail (collaborator or owner)
            let has_trail_role: bool = self.accesscontrol.has_role(trail_id.into(), caller);
            let is_trail_owner: bool = world.is_owner_of_trail(trail_id, caller);
            assert(
                self.is_admin(caller) || is_trail_owner || has_trail_role,
                Errors::NOT_COLLABORATOR,
            );
            // Collaborators cannot propose entity deletions — those are owner-only actions.
            assert(
                is_trail_owner || self.is_admin(caller) || deleted_entity_insts.len() == 0,
                Errors::NOT_TRAIL_OWNER,
            );
            world.emit_event(@CollabProposalEvent {
                trail_id,
                proposer: caller,
                entities,
                reactables,
                areas,
                exits,
                hubs,
                description_texts,
                inventory_items,
                containers,
                trails,
                triggers,
                conditions,
                effects,
                actions,
                parents,
                children,
                deleted_entity_insts,
                deleted_reactable_insts,
                deleted_area_insts,
                deleted_exit_insts,
                deleted_container_insts,
                deleted_inventory_item_insts,
                deleted_hub_insts,
                deleted_trail_insts,
                deleted_parent_insts,
                deleted_child_insts,
                deleted_description_text_keys,
                deleted_trigger_keys,
                deleted_condition_keys,
                deleted_effect_keys,
                deleted_action_keys,
            });
        }

        // Called by the trail owner after publishing (some or all of) a collaborator's proposal.
        // Writes a CollabReviewResult model so the collaborator sees the outcome via entity subscription.
        // published_count: number of items published; skipped_count: number not included (0 = all published).
        fn signal_review_result(ref self: ContractState, trail_id: u128, proposer: ContractAddress, published_count: u32, skipped_count: u32) {
            let caller: ContractAddress = starknet::get_caller_address();
            let mut world: WorldStorage = self.world_default();
            let is_trail_owner: bool = world.is_owner_of_trail(trail_id, caller);
            assert(self.is_admin(caller) || is_trail_owner, Errors::NOT_TRAIL_OWNER);
            world.write_model(@CollabReviewResult { trail_id, proposer, published_count, skipped_count });
        }

        // TODO: remove this?? is it necessary to call again?
        fn register_property_registry(ref self: ContractState, done: Array<bool>) {
            let mut world: WorldStorage = self.world_default();
            self._assert_caller_is_admin(@world);
            self._register_property_registry(ref world, done);
        }

        // create
        fn create_entity(ref self: ContractState, t: Array<Entity>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            for mut o in t {
                for alt_name in o.alt_names.clone() {
                    let pos_entry: Option<Dict> = world.get_dict_entry(alt_name.clone());
                    if pos_entry.is_none() {
                        world.add_to_dictionary(alt_name.clone(), TokenType::Noun, 1).unwrap();
                    }
                };
                self._assert_can_edit_entity(@world, o.inst, owned);
                let has_trail_role: bool = o.trail_id.is_non_zero()
                    && self.accesscontrol.has_role(o.trail_id.into(), owned);
                assert(
                    owned.is_zero() || world.is_owner_of_trail(o.trail_id, owned) || has_trail_role,
                    Errors::NOT_YOUR_TRAIL,
                );
                if !owned.is_zero() && o.trail_id.is_non_zero() && !world.is_owner_of_trail(o.trail_id, owned) {
                    assert(false, Errors::NOT_APPROVED);
                }
                //
                // Resolve creator_address:
                // - existing entity: always keep the original creator
                // - new entity: use the address from the struct if non-zero (owner publishing on
                //   behalf of a collaborator passes the proposer's address here), else use caller
                let existing_entity: Option<Entity> = EntityImpl::get_entity(@world, o.inst);
                o.creator_address = match existing_entity {
                    Option::None => {
                        if o.creator_address.is_non_zero() { o.creator_address }
                        else { starknet::get_caller_address() }
                    },
                    Option::Some(entity) => {entity.creator_address}
                };
                // write model
                world.write_model(@o);

                // TODO LATER ON
                // if o.name.len() > 0 {
                //     let words = ByteArrayTraitExt::split_into_words(@o.name);
                //     for word in words {
                //         let lowercased = ByteArrayTraitExt::to_lowercase(word.clone());
                //         let pos_entry = get_dict_entry(world, lowercased.clone());
                //         if pos_entry.is_none() {
                //             add_to_dictionary(world, lowercased.clone(), TokenType::Noun,
                //             1).unwrap();
                //         }
                //     };
                // }
            }
        }

        fn create_player(ref self: ContractState, t: Array<Player>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            VariablePropertyHelper::register_component_properties(ref world, ComponentType::Player);
            for o in t {
                self._assert_can_edit_entity(@world, o.inst, owned);
                world.write_model(@o);
            }
        }

        fn create_reactable(ref self: ContractState, t: Array<Reactable>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            VariablePropertyHelper::register_component_properties(ref world, ComponentType::Reactable);
            for o in t {
                self._assert_can_edit_entity(@world, o.inst, owned);
                let trail_id: u128 = world.get_entity_trail_id(o.inst);
                if !owned.is_zero() && trail_id.is_non_zero() && !world.is_owner_of_trail(trail_id, owned) {
                    assert(false, Errors::NOT_APPROVED);
                }
                world.write_model(@o);
            }
        }

        fn create_description_text(ref self: ContractState, t: Array<DescriptionText>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            for o in t {
                self._assert_can_edit_entity(@world, o.inst, owned);
                let trail_id: u128 = world.get_entity_trail_id(o.inst);
                if !owned.is_zero() && trail_id.is_non_zero() && !world.is_owner_of_trail(trail_id, owned) {
                    assert(false, Errors::NOT_APPROVED);
                }
                world.write_model(@o);
            }
        }

        fn create_area(ref self: ContractState, t: Array<Area>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            VariablePropertyHelper::register_component_properties(ref world, ComponentType::Area);
            for o in t {
                self._assert_can_edit_entity(@world, o.inst, owned);
                let trail_id: u128 = world.get_entity_trail_id(o.inst);
                if !owned.is_zero() && trail_id.is_non_zero() && !world.is_owner_of_trail(trail_id, owned) {
                    assert(false, Errors::NOT_APPROVED);
                }
                world.write_model(@o);
            }
        }

        fn create_exit(ref self: ContractState, t: Array<Exit>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            VariablePropertyHelper::register_component_properties(ref world, ComponentType::Exit);
            for o in t {
                self._assert_can_edit_entity(@world, o.inst, owned);
                let trail_id: u128 = world.get_entity_trail_id(o.inst);
                if !owned.is_zero() && trail_id.is_non_zero() && !world.is_owner_of_trail(trail_id, owned) {
                    assert(false, Errors::NOT_APPROVED);
                }
                world.write_model(@o);
            }
        }

        fn create_inventory_item(ref self: ContractState, t: Array<InventoryItem>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            VariablePropertyHelper::register_component_properties(
                ref world, ComponentType::InventoryItem,
            );
            for o in t {
                self._assert_can_edit_entity(@world, o.inst, owned);
                let trail_id: u128 = world.get_entity_trail_id(o.inst);
                if !owned.is_zero() && trail_id.is_non_zero() && !world.is_owner_of_trail(trail_id, owned) {
                    assert(false, Errors::NOT_APPROVED);
                }
                world.write_model(@o);
            }
        }

        fn create_container(ref self: ContractState, t: Array<Container>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            VariablePropertyHelper::register_component_properties(ref world, ComponentType::Container);
            for o in t {
                self._assert_can_edit_entity(@world, o.inst, owned);
                let trail_id: u128 = world.get_entity_trail_id(o.inst);
                if !owned.is_zero() && trail_id.is_non_zero() && !world.is_owner_of_trail(trail_id, owned) {
                    assert(false, Errors::NOT_APPROVED);
                }
                world.write_model(@o);
            }
        }

        fn create_trigger(ref self: ContractState, t: Array<Trigger>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            for o in t {
                self._assert_can_edit_entity(@world, o.inst, owned);
                let trail_id: u128 = world.get_entity_trail_id(o.inst);
                if !owned.is_zero() && trail_id.is_non_zero() && !world.is_owner_of_trail(trail_id, owned) {
                    assert(false, Errors::NOT_APPROVED);
                }
                let _result: Result<(), Error> = TriggerImpl::register_trigger(ref world, @o);
                // if result.is_err() {
            //     println!(
            //         "Trigger: {:?} failed to register with error: {:?}", o,
            //         result.unwrap_err(),
            //     );
            // }
            }
        }

        fn create_condition(ref self: ContractState, t: Array<Condition>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            for o in t {
                self._assert_can_edit_entity(@world, o.inst, owned);
                let trail_id: u128 = world.get_entity_trail_id(o.inst);
                if !owned.is_zero() && trail_id.is_non_zero() && !world.is_owner_of_trail(trail_id, owned) {
                    assert(false, Errors::NOT_APPROVED);
                }
                world.write_model(@o);
            }
        }

        fn create_effect(ref self: ContractState, t: Array<Effect>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            for o in t {
                self._assert_can_edit_entity(@world, o.inst, owned);
                let trail_id: u128 = world.get_entity_trail_id(o.inst);
                if !owned.is_zero() && trail_id.is_non_zero() && !world.is_owner_of_trail(trail_id, owned) {
                    assert(false, Errors::NOT_APPROVED);
                }
                world.write_model(@o);
            }
        }

        fn create_action(ref self: ContractState, t: Array<Action>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            for o in t {
                self._assert_can_edit_entity(@world, o.inst, owned);
                let trail_id: u128 = world.get_entity_trail_id(o.inst);
                if !owned.is_zero() && trail_id.is_non_zero() && !world.is_owner_of_trail(trail_id, owned) {
                    assert(false, Errors::NOT_APPROVED);
                }
                let _result: Result<(), Error> = ActionImpl::register_action(ref world, @o);
                // if result.is_err() {
            //     println!(
            //         "Action: {:?} failed to register with error: {:?}", o,
            //         result.unwrap_err(),
            //     );
            // }
            }
        }

        fn create_hub(ref self: ContractState, t: Array<Hub>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            for mut o in t {
                self._assert_can_edit_entity(@world, o.inst, owned);
                let trail_id: u128 = world.get_entity_trail_id(o.inst);
                if !owned.is_zero() && trail_id.is_non_zero() && !world.is_owner_of_trail(trail_id, owned) {
                    assert(false, Errors::NOT_APPROVED);
                }
                // Keep original trails -- NOT ALLOWED TO EDIT FROM EDITOR
                // (trails are managed in the contract)
                let existing_hub: Hub = world.read_model(o.inst);
                o.trails_insts = existing_hub.trails_insts.clone();
                // write model
                world.write_model(@o);
            }
        }

        fn create_trail(ref self: ContractState, t: Array<Trail>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            for o in t {
                self._assert_can_edit_entity(@world, o.inst, owned);
                let trail_id: u128 = world.get_entity_trail_id(o.inst);
                if !owned.is_zero() && trail_id.is_non_zero() && !world.is_owner_of_trail(trail_id, owned) {
                    assert(false, Errors::NOT_APPROVED);
                }
                TrailTrait::assert_trail_edit_protection(@world, @o);
                o.append_to_hub(ref world);
                world.write_model(@o);
            }
        }

        fn create_parent(ref self: ContractState, t: Array<ParentToChildren>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            for o in t {
                self._assert_can_edit_entity(@world, o.inst, owned);
                let trail_id: u128 = world.get_entity_trail_id(o.inst);
                if !owned.is_zero() && trail_id.is_non_zero() && !world.is_owner_of_trail(trail_id, owned) {
                    assert(false, Errors::NOT_APPROVED);
                }
                TrailTrait::assert_trail_parent_protection(@world, @o);
                world.write_model(@o);
            }
        }

        fn create_child(ref self: ContractState, t: Array<ChildToParent>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            for o in t {
                self._assert_can_edit_entity(@world, o.inst, owned);
                let trail_id: u128 = world.get_entity_trail_id(o.inst);
                if !owned.is_zero() && trail_id.is_non_zero() && !world.is_owner_of_trail(trail_id, owned) {
                    assert(false, Errors::NOT_APPROVED);
                }
                TrailTrait::assert_trail_child_protection(@world, @o);
                world.write_model(@o);
            }
        }

        // delete
        fn delete_entity(ref self: ContractState, ids: Array<felt252>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            for inst in ids {
                self._assert_can_delete_entity(@world, inst, owned);
                let trail_id: u128 = world.get_entity_trail_id(inst);
                if !owned.is_zero() && trail_id.is_non_zero() && !world.is_owner_of_trail(trail_id, owned) {
                    assert(false, Errors::NOT_APPROVED);
                }
                TrailTrait::assert_trail_delete_protection(@world, inst);
                let model: Entity = world.read_model(inst);
                world.erase_model(@model);
                // delete_reactable(world, model.Reactable);
                // delete_area(world, model.Area);
                // delete_exit(world, model.Exit);
            }
        }

        fn delete_player(ref self: ContractState, ids: Array<felt252>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            for inst in ids {
                self._assert_can_delete_entity(@world, inst, owned);
                let model: Player = world.read_model(inst);
                world.erase_model(@model);
            }
        }

        fn delete_reactable(ref self: ContractState, ids: Array<felt252>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            for inst in ids {
                self._assert_can_delete_entity(@world, inst, owned);
                let trail_id: u128 = world.get_entity_trail_id(inst);
                if !owned.is_zero() && trail_id.is_non_zero() && !world.is_owner_of_trail(trail_id, owned) {
                    assert(false, Errors::NOT_APPROVED);
                }
                TrailTrait::assert_trail_delete_protection(@world, inst);
                let model: Reactable = world.read_model(inst);
                world.erase_model(@model);
            }
        }

        fn delete_description_text(ref self: ContractState, ids: Array<(felt252, felt252)>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            for (inst, key) in ids {
                self._assert_can_delete_entity(@world, inst, owned);
                let trail_id: u128 = world.get_entity_trail_id(inst);
                if !owned.is_zero() && trail_id.is_non_zero() && !world.is_owner_of_trail(trail_id, owned) {
                    assert(false, Errors::NOT_APPROVED);
                }
                TrailTrait::assert_trail_delete_protection(@world, inst);
                let model: DescriptionText = world.read_model((inst, key),);
                world.erase_model(@model);
            }
        }

        fn delete_area(ref self: ContractState, ids: Array<felt252>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            for inst in ids {
                self._assert_can_delete_entity(@world, inst, owned);
                let trail_id: u128 = world.get_entity_trail_id(inst);
                if !owned.is_zero() && trail_id.is_non_zero() && !world.is_owner_of_trail(trail_id, owned) {
                    assert(false, Errors::NOT_APPROVED);
                }
                let model: Area = world.read_model(inst);
                world.erase_model(@model);
            }
        }

        fn delete_exit(ref self: ContractState, ids: Array<felt252>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            for inst in ids {
                self._assert_can_delete_entity(@world, inst, owned);
                let trail_id: u128 = world.get_entity_trail_id(inst);
                if !owned.is_zero() && trail_id.is_non_zero() && !world.is_owner_of_trail(trail_id, owned) {
                    assert(false, Errors::NOT_APPROVED);
                }
                TrailTrait::assert_trail_delete_protection(@world, inst);
                let model: Exit = world.read_model(inst);
                world.erase_model(@model);
            }
        }

        fn delete_inventory_item(ref self: ContractState, ids: Array<felt252>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            for inst in ids {
                self._assert_can_delete_entity(@world, inst, owned);
                let trail_id: u128 = world.get_entity_trail_id(inst);
                if !owned.is_zero() && trail_id.is_non_zero() && !world.is_owner_of_trail(trail_id, owned) {
                    assert(false, Errors::NOT_APPROVED);
                }
                let model: InventoryItem = world.read_model(inst);
                world.erase_model(@model);
            }
        }

        fn delete_container(ref self: ContractState, ids: Array<felt252>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            for inst in ids {
                self._assert_can_delete_entity(@world, inst, owned);
                let trail_id: u128 = world.get_entity_trail_id(inst);
                if !owned.is_zero() && trail_id.is_non_zero() && !world.is_owner_of_trail(trail_id, owned) {
                    assert(false, Errors::NOT_APPROVED);
                }
                let model: Container = world.read_model(inst);
                world.erase_model(@model);
            }
        }

        fn delete_trigger(ref self: ContractState, ids: Array<(felt252, felt252)>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            for (inst, key) in ids {
                self._assert_can_delete_entity(@world, inst, owned);
                let trail_id: u128 = world.get_entity_trail_id(inst);
                if !owned.is_zero() && trail_id.is_non_zero() && !world.is_owner_of_trail(trail_id, owned) {
                    assert(false, Errors::NOT_APPROVED);
                }
                let model: Trigger = world.read_model((inst, key),);
                let _result: Result<(), Error> = TriggerImpl::unregister_trigger(ref world, @model);
                // if result.is_err() {
            //     println!(
            //         "Trigger: {:?} failed to unregister with error: {:?}",
            //         model,
            //         result.unwrap_err(),
            //     );
            // }
            }
        }

        fn delete_condition(ref self: ContractState, ids: Array<(felt252, felt252)>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            for (inst, key) in ids {
                self._assert_can_delete_entity(@world, inst, owned);
                let trail_id: u128 = world.get_entity_trail_id(inst);
                if !owned.is_zero() && trail_id.is_non_zero() && !world.is_owner_of_trail(trail_id, owned) {
                    assert(false, Errors::NOT_APPROVED);
                }
                let model: Condition = world.read_model((inst, key),);
                world.erase_model(@model);
            }
        }

        fn delete_effect(ref self: ContractState, ids: Array<(felt252, felt252)>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            for (inst, key) in ids {
                self._assert_can_delete_entity(@world, inst, owned);
                let trail_id: u128 = world.get_entity_trail_id(inst);
                if !owned.is_zero() && trail_id.is_non_zero() && !world.is_owner_of_trail(trail_id, owned) {
                    assert(false, Errors::NOT_APPROVED);
                }
                let model: Effect = world.read_model((inst, key),);
                world.erase_model(@model);
            }
        }

        fn delete_action(ref self: ContractState, ids: Array<(felt252, felt252)>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            for (inst, key) in ids {
                self._assert_can_delete_entity(@world, inst, owned);
                let trail_id: u128 = world.get_entity_trail_id(inst);
                if !owned.is_zero() && trail_id.is_non_zero() && !world.is_owner_of_trail(trail_id, owned) {
                    assert(false, Errors::NOT_APPROVED);
                }
                let model: Action = world.read_model((inst, key),);
                let _result: Result<(), Error> = ActionImpl::unregister_action(ref world, @model);
                // if result.is_err() {
            //     println!(
            //         "Action: {:?} failed to unregister with error: {:?}",
            //         model,
            //         result.unwrap_err(),
            //     );
            // }
            }
        }

        fn delete_hub(ref self: ContractState, ids: Array<felt252>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            for inst in ids {
                self._assert_can_delete_entity(@world, inst, owned);
                let trail_id: u128 = world.get_entity_trail_id(inst);
                if !owned.is_zero() && trail_id.is_non_zero() && !world.is_owner_of_trail(trail_id, owned) {
                    assert(false, Errors::NOT_APPROVED);
                }
                let model: Hub = world.read_model(inst);
                model.remove_trails_from_hub(ref world);
                world.erase_model(@model);
            }
        }

        fn delete_trail(ref self: ContractState, ids: Array<felt252>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            for inst in ids {
                self._assert_can_delete_entity(@world, inst, owned);
                let trail_id: u128 = world.get_entity_trail_id(inst);
                if !owned.is_zero() && trail_id.is_non_zero() && !world.is_owner_of_trail(trail_id, owned) {
                    assert(false, Errors::NOT_APPROVED);
                }
                TrailTrait::assert_trail_delete_protection(@world, inst);
                let model: Trail = world.read_model(inst);
                model.remove_from_hub(ref world);
                world.erase_model(@model);
            }
        }

        fn delete_parent(ref self: ContractState, ids: Array<felt252>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            for inst in ids {
                self._assert_can_delete_entity(@world, inst, owned);
                let trail_id: u128 = world.get_entity_trail_id(inst);
                if !owned.is_zero() && trail_id.is_non_zero() && !world.is_owner_of_trail(trail_id, owned) {
                    assert(false, Errors::NOT_APPROVED);
                }
                let model: ParentToChildren = world.read_model(inst);
                world.erase_model(@model);
            }
        }

        fn delete_child(ref self: ContractState, ids: Array<felt252>) {
            let owned: ContractAddress = self._assert_caller_is_editor();
            let mut world: WorldStorage = self.world_default();
            for inst in ids {
                self._assert_can_delete_entity(@world, inst, owned);
                let trail_id: u128 = world.get_entity_trail_id(inst);
                if !owned.is_zero() && trail_id.is_non_zero() && !world.is_owner_of_trail(trail_id, owned) {
                    assert(false, Errors::NOT_APPROVED);
                }
                let model: ChildToParent = world.read_model(inst);
                world.erase_model(@model);
            }
        }

        // Monetization
        fn add_collaborator(ref self: ContractState, inst: felt252, account: ContractAddress) {
            let caller: ContractAddress = starknet::get_caller_address();
            let mut world: WorldStorage = self.world_default();
            let trail_id: u128 = world.get_entity_trail_id(inst);
            let owner: ContractAddress = world.trail_token_dispatcher().owner_of(trail_id.into());
            let is_trail_owner: bool = caller == owner;
            assert(self.is_admin(caller) || is_trail_owner, Errors::NOT_TRAIL_OWNER);
            // Blocks the trail owner naming their own second wallet as a "collaborator" to
            // double-dip into the pool at the real creator's expense — see
            // docs/Monetization/monetization-revenue-distribution.md, "Two guardrails".
            // Does not stop a fresh, unlinked wallet — a named, accepted trust assumption.
            assert(account != owner, Errors::INVALID_COLLABORATOR);
            // get entity
            let mut entity: Entity = world.read_model(inst);
            // Bounds the collaborator-crediting loop in charge_player_actions, which runs
            // on every action against this entity, not just at join time.
            assert(entity.collaborators.len() < MAX_COLLABORATORS, Errors::TOO_MANY_COLLABORATORS);
            // add collaborator
            entity.collaborators.append(account);
            world.write_model(@entity);
        }
    }

    //-----------------------------------
    // Internal
    //
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _grant_admin_roles(ref self: ContractState, ref world: WorldStorage, address: ContractAddress) {
            self._grant_role(ref world, DEFAULT_ADMIN_ROLE, address, true);
            self._grant_role(ref world, ROLES::ADMIN, address, true);
            self._grant_role(ref world, ROLES::EDITOR, address, true);
        }
        fn _grant_role(ref self: ContractState, ref world: WorldStorage, role: felt252, address: ContractAddress, granting: bool) {
            let granted: Option<bool> = 
                if (granting && !self.accesscontrol.has_role(role, address)) {
                    self.accesscontrol._grant_role(role, address);
                    (Option::Some(true))
                } else if (!granting && self.accesscontrol.has_role(role, address)) {
                    self.accesscontrol._revoke_role(role, address);
                    (Option::Some(false))
                } else {
                    (Option::None)
                };
            // emit event only if changed
            if let Some(granted) = granted {
                world.emit_event(@AccessGrantedEvent{
                    address,
                    role,
                    granted,
                });
            }
        }
        #[inline(always)]
        fn _assert_caller_is_admin(self: @ContractState, world: @WorldStorage) {
            let caller: ContractAddress = starknet::get_caller_address();
            assert(self.is_admin(caller) || world.is_world_contract(caller), Errors::NOT_ADMIN);
        }
        #[inline(always)]
        fn _assert_caller_is_editor(self: @ContractState) -> ContractAddress {
            if (self.is_admin(starknet::get_caller_address())) {
                // admin fas full access
                (0x0.try_into().unwrap())
            } else {
                assert(self.is_editor(starknet::get_caller_address()), Errors::NOT_EDITOR);
                // access only owned entities
                (starknet::get_caller_address())
            }
        }
        #[inline(always)]
        fn _assert_can_edit_entity(self: @ContractState, world: @WorldStorage, inst: felt252, owned: ContractAddress) {
            assert(inst.is_non_zero(), Errors::INVALID_ENTITY);
            let trail_id: u128 = world.get_entity_trail_id(inst);
            let has_trail_role: bool = trail_id.is_non_zero()
                && self.accesscontrol.has_role(trail_id.into(), owned);
            assert(
                owned.is_zero() || world.can_edit_trail(inst, owned) || has_trail_role,
                Errors::NOT_YOUR_ENTITY,
            );
        }
        #[inline(always)]
        fn _assert_can_delete_entity(self: @ContractState, world: @WorldStorage, inst: felt252, owned: ContractAddress) {
            assert(inst.is_non_zero(), Errors::INVALID_ENTITY);
            let trail_id: u128 = world.get_entity_trail_id(inst);
            let has_trail_role: bool = trail_id.is_non_zero()
                && self.accesscontrol.has_role(trail_id.into(), owned);
            assert(
                owned.is_zero() || world.can_edit_trail(inst, owned) || has_trail_role,
                Errors::NOT_YOUR_ENTITY,
            );
        }

        fn _register_property_registry(ref self: ContractState, ref world: WorldStorage, done: Array<bool>) {
            for d in done {
                if d {
                    // println!("Registering properties for component: {:?}", ComponentType::Area);
                    VariablePropertyHelper::register_component_properties(ref world, ComponentType::Area);
                    // println!("Registering properties for component: {:?}", ComponentType::Exit);
                    VariablePropertyHelper::register_component_properties(ref world, ComponentType::Exit);
                    // println!("Registering properties for component: {:?}", ComponentType::Reactable);
                    VariablePropertyHelper::register_component_properties(
                        ref world, ComponentType::Reactable,
                    );
                    // println!("Registering properties for component: {:?}", ComponentType::InventoryItem);
                    VariablePropertyHelper::register_component_properties(
                        ref world, ComponentType::InventoryItem,
                    );
                    // println!("Registering properties for component: {:?}", ComponentType::Container);
                    VariablePropertyHelper::register_component_properties(
                        ref world, ComponentType::Container,
                    );
                    // println!("Registering properties for component: {:?}", ComponentType::Player);
                    VariablePropertyHelper::register_component_properties(
                        ref world, ComponentType::Player,
                    );
                }
            }
        }

    }
}
