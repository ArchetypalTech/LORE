use lore::{
    models::{
        entity::{Entity, ParentToChildren, ChildToParent},
        index::{
            DescriptionText,
        },
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
    },
};

#[starknet::interface]
pub trait IDesigner<TContractState> {
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
    fn delete_parent(ref self: TContractState, ids: Array<felt252>);
    fn delete_child(ref self: TContractState, ids: Array<felt252>);
    //
    fn register_property_registry(ref self: TContractState, done: Array<bool>);
}

#[dojo::contract]
pub mod designer {
    use super::IDesigner;
    use core::num::traits::Zero;
    use dojo::{model::ModelStorage, world::WorldStorage};
    use lore::{
        models::{
            admin::{AccountPermissions, AccountPermissionsTrait},
            entity::{Entity, EntityImpl, ParentToChildren, ChildToParent},
            index::{
                DescriptionText,
            },
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
        },
        types::{
            component_type::ComponentType,
            command_type::TokenType,
        },
        lib::{
            dictionary::{add_to_dictionary, get_dict_entry},
            utils::{ByteArrayTraitExt},
            variable_property_helper::{VariablePropertyHelper},
        },
    };

    mod Errors {
        pub const NOT_EDITOR: felt252       = 'DESIGNER: Not editor';
        pub const NOT_YOUR_ENTITY: felt252  = 'DESIGNER: Not your entity';
        pub const INVALID_ENTITY: felt252    = 'DESIGNER: Invalid entity';
    }

    fn dojo_init(ref self: ContractState) {
        let mut world: WorldStorage = self.world(@"lore");
        self._register_property_registry(ref world, array![true]);
    }

    #[abi(embed_v0)]
    pub impl DesignerImpl of IDesigner<ContractState> {
        // register
        fn register_property_registry(ref self: ContractState, done: Array<bool>) {
            let mut world: WorldStorage = self.world(@"lore");
            self._assert_caller_is_editor(@world);
            self._register_property_registry(ref world, done);
        }

        // create
        fn create_entity(ref self: ContractState, t: Array<Entity>) {
            let mut world = self.world(@"lore");
            let config: AccountPermissions = world.read_model(starknet::get_caller_address());
            for o in t {
                self._assert_can_edit_entity(@world, @config, o.inst);
                for alt_name in o.alt_names.clone() {
                    let pos_entry = get_dict_entry(world, alt_name.clone());
                    if pos_entry.is_none() {
                        add_to_dictionary(world, alt_name.clone(), TokenType::Noun, 1).unwrap();
                    }
                };
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
                let mut e: Entity = o.clone();
                e.creator_address = match EntityImpl::get_entity(@world, o.inst) {
                    // new entity: set caller as creator
                    Option::None => {config.account_address},
                    // entity exists: keep original creator
                    Option::Some(entity) => {entity.creator_address}
                };
                world.write_model(@e);
            }
        }

        fn create_player(ref self: ContractState, t: Array<Player>) {
            let mut world = self.world(@"lore");
            let config: AccountPermissions = world.read_model(starknet::get_caller_address());
            VariablePropertyHelper::register_component_properties(ref world, ComponentType::Player);
            for o in t {
                self._assert_can_edit_entity(@world, @config, o.inst);
                world.write_model(@o);
            }
        }

        fn create_reactable(ref self: ContractState, t: Array<Reactable>) {
            let mut world = self.world(@"lore");
            let config: AccountPermissions = world.read_model(starknet::get_caller_address());
            VariablePropertyHelper::register_component_properties(ref world, ComponentType::Reactable);
            for o in t {
                self._assert_can_edit_entity(@world, @config, o.inst);
                world.write_model(@o);
            }
        }

        fn create_description_text(ref self: ContractState, t: Array<DescriptionText>) {
            let mut world = self.world(@"lore");
            let config: AccountPermissions = world.read_model(starknet::get_caller_address());
            for o in t {
                self._assert_can_edit_entity(@world, @config, o.inst);
                world.write_model(@o);
            }
        }

        fn create_area(ref self: ContractState, t: Array<Area>) {
            let mut world = self.world(@"lore");
            let config: AccountPermissions = world.read_model(starknet::get_caller_address());
            VariablePropertyHelper::register_component_properties(ref world, ComponentType::Area);
            for o in t {
                self._assert_can_edit_entity(@world, @config, o.inst);
                world.write_model(@o);
            }
        }

        fn create_exit(ref self: ContractState, t: Array<Exit>) {
            let mut world = self.world(@"lore");
            let config: AccountPermissions = world.read_model(starknet::get_caller_address());
            VariablePropertyHelper::register_component_properties(ref world, ComponentType::Exit);
            for o in t {
                self._assert_can_edit_entity(@world, @config, o.inst);
                world.write_model(@o);
            }
        }

        fn create_inventory_item(ref self: ContractState, t: Array<InventoryItem>) {
            let mut world = self.world(@"lore");
            let config: AccountPermissions = world.read_model(starknet::get_caller_address());
            VariablePropertyHelper::register_component_properties(
                ref world, ComponentType::InventoryItem,
            );
            for o in t {
                self._assert_can_edit_entity(@world, @config, o.inst);
                world.write_model(@o);
            }
        }

        fn create_container(ref self: ContractState, t: Array<Container>) {
            let mut world = self.world(@"lore");
            let config: AccountPermissions = world.read_model(starknet::get_caller_address());
            VariablePropertyHelper::register_component_properties(ref world, ComponentType::Container);
            for o in t {
                self._assert_can_edit_entity(@world, @config, o.inst);
                world.write_model(@o);
            }
        }

        fn create_trigger(ref self: ContractState, t: Array<Trigger>) {
            let mut world: WorldStorage = self.world(@"lore");
            let config: AccountPermissions = world.read_model(starknet::get_caller_address());
            for o in t {
                self._assert_can_edit_entity(@world, @config, o.inst);
                let _result = TriggerImpl::register_trigger(ref world, @o);
                // if result.is_err() {
            //     println!(
            //         "Trigger: {:?} failed to register with error: {:?}", o,
            //         result.unwrap_err(),
            //     );
            // }
            }
        }

        fn create_condition(ref self: ContractState, t: Array<Condition>) {
            let mut world = self.world(@"lore");
            let config: AccountPermissions = world.read_model(starknet::get_caller_address());
            for o in t {
                self._assert_can_edit_entity(@world, @config, o.inst);
                world.write_model(@o);
            }
        }

        fn create_effect(ref self: ContractState, t: Array<Effect>) {
            let mut world = self.world(@"lore");
            let config: AccountPermissions = world.read_model(starknet::get_caller_address());
            for o in t {
                self._assert_can_edit_entity(@world, @config, o.inst);
                world.write_model(@o);
            }
        }

        fn create_action(ref self: ContractState, t: Array<Action>) {
            let mut world: WorldStorage = self.world(@"lore");
            let config: AccountPermissions = world.read_model(starknet::get_caller_address());
            for o in t {
                self._assert_can_edit_entity(@world, @config, o.inst);
                let _result = ActionImpl::register_action(ref world, @o);
                // if result.is_err() {
            //     println!(
            //         "Action: {:?} failed to register with error: {:?}", o,
            //         result.unwrap_err(),
            //     );
            // }
            }
        }

        fn create_parent(ref self: ContractState, t: Array<ParentToChildren>) {
            let mut world = self.world(@"lore");
            // let config: AccountPermissions = world.read_model(starknet::get_caller_address());
            for o in t {
                // TODO: validate children ownership, or something better
                // need this permission to create the player's entrance
                // self._assert_can_edit_entity(@world, @config, o.inst);
                world.write_model(@o);
            }
        }

        fn create_child(ref self: ContractState, t: Array<ChildToParent>) {
            let mut world = self.world(@"lore");
            let config: AccountPermissions = world.read_model(starknet::get_caller_address());
            for o in t {
                self._assert_can_edit_entity(@world, @config, o.inst);
                world.write_model(@o);
            }
        }

        // delete
        fn delete_entity(ref self: ContractState, ids: Array<felt252>) {
            let mut world = self.world(@"lore");
            let config: AccountPermissions = world.read_model(starknet::get_caller_address());
            for inst in ids {
                self._assert_can_delete_entity(@world, @config, inst);
                let model: Entity = world.read_model(inst);
                world.erase_model(@model);
                // delete_reactable(world, model.Reactable);
            // delete_area(world, model.Area);
            // delete_exit(world, model.Exit);
            }
        }

        fn delete_player(ref self: ContractState, ids: Array<felt252>) {
            let mut world = self.world(@"lore");
            let config: AccountPermissions = world.read_model(starknet::get_caller_address());
            for inst in ids {
                self._assert_can_delete_entity(@world, @config, inst);
                let model: Player = world.read_model(inst);
                world.erase_model(@model);
            }
        }

        fn delete_reactable(ref self: ContractState, ids: Array<felt252>) {
            let mut world = self.world(@"lore");
            let config: AccountPermissions = world.read_model(starknet::get_caller_address());
            for inst in ids {
                self._assert_can_delete_entity(@world, @config, inst);
                let model: Reactable = world.read_model(inst);
                world.erase_model(@model);
            }
        }

        fn delete_description_text(ref self: ContractState, ids: Array<(felt252, felt252)>) {
            let mut world = self.world(@"lore");
            let config: AccountPermissions = world.read_model(starknet::get_caller_address());
            for (inst, key) in ids {
                self._assert_can_delete_entity(@world, @config, inst);
                let model: DescriptionText = world.read_model((inst, key),);
                world.erase_model(@model);
            }
        }

        fn delete_area(ref self: ContractState, ids: Array<felt252>) {
            let mut world = self.world(@"lore");
            let config: AccountPermissions = world.read_model(starknet::get_caller_address());
            for inst in ids {
                self._assert_can_delete_entity(@world, @config, inst);
                let model: Area = world.read_model(inst);
                world.erase_model(@model);
            }
        }

        fn delete_exit(ref self: ContractState, ids: Array<felt252>) {
            let mut world = self.world(@"lore");
            let config: AccountPermissions = world.read_model(starknet::get_caller_address());
            for inst in ids {
                self._assert_can_delete_entity(@world, @config, inst);
                let model: Exit = world.read_model(inst);
                world.erase_model(@model);
            }
        }

        fn delete_inventory_item(ref self: ContractState, ids: Array<felt252>) {
            let mut world = self.world(@"lore");
            let config: AccountPermissions = world.read_model(starknet::get_caller_address());
            for inst in ids {
                self._assert_can_delete_entity(@world, @config, inst);
                let model: InventoryItem = world.read_model(inst);
                world.erase_model(@model);
            }
        }

        fn delete_container(ref self: ContractState, ids: Array<felt252>) {
            let mut world = self.world(@"lore");
            let config: AccountPermissions = world.read_model(starknet::get_caller_address());
            for inst in ids {
                self._assert_can_delete_entity(@world, @config, inst);
                let model: Container = world.read_model(inst);
                world.erase_model(@model);
            }
        }

        fn delete_trigger(ref self: ContractState, ids: Array<(felt252, felt252)>) {
            let mut world: WorldStorage = self.world(@"lore");
            let config: AccountPermissions = world.read_model(starknet::get_caller_address());
            for (inst, key) in ids {
                self._assert_can_delete_entity(@world, @config, inst);
                let model: Trigger = world.read_model((inst, key),);
                let _result = TriggerImpl::unregister_trigger(ref world, @model);
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
            let mut world = self.world(@"lore");
            let config: AccountPermissions = world.read_model(starknet::get_caller_address());
            for (inst, key) in ids {
                self._assert_can_delete_entity(@world, @config, inst);
                let model: Condition = world.read_model((inst, key),);
                world.erase_model(@model);
            }
        }

        fn delete_effect(ref self: ContractState, ids: Array<(felt252, felt252)>) {
            let mut world = self.world(@"lore");
            let config: AccountPermissions = world.read_model(starknet::get_caller_address());
            for (inst, key) in ids {
                self._assert_can_delete_entity(@world, @config, inst);
                let model: Effect = world.read_model((inst, key),);
                world.erase_model(@model);
            }
        }

        fn delete_action(ref self: ContractState, ids: Array<(felt252, felt252)>) {
            let mut world: WorldStorage = self.world(@"lore");
            let config: AccountPermissions = world.read_model(starknet::get_caller_address());
            for (inst, key) in ids {
                self._assert_can_delete_entity(@world, @config, inst);
                let model: Action = world.read_model((inst, key),);
                let _result = ActionImpl::unregister_action(ref world, @model);
                // if result.is_err() {
            //     println!(
            //         "Action: {:?} failed to unregister with error: {:?}",
            //         model,
            //         result.unwrap_err(),
            //     );
            // }
            }
        }

        fn delete_parent(ref self: ContractState, ids: Array<felt252>) {
            let mut world = self.world(@"lore");
            let config: AccountPermissions = world.read_model(starknet::get_caller_address());
            for inst in ids {
                self._assert_can_delete_entity(@world, @config, inst);
                let model: ParentToChildren = world.read_model(inst);
                world.erase_model(@model);
            }
        }

        fn delete_child(ref self: ContractState, ids: Array<felt252>) {
            let mut world = self.world(@"lore");
            let config: AccountPermissions = world.read_model(starknet::get_caller_address());
            for inst in ids {
                self._assert_can_delete_entity(@world, @config, inst);
                let model: ChildToParent = world.read_model(inst);
                world.erase_model(@model);
            }
        }
    }

    //-----------------------------------
    // Internal
    //
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        #[inline(always)]
        fn _assert_caller_is_editor(self: @ContractState, world: @WorldStorage) {
            assert(AccountPermissionsTrait::is_editor(world, starknet::get_caller_address()), Errors::NOT_EDITOR);
        }
        #[inline(always)]
        fn _assert_can_edit_entity(self: @ContractState, world: @WorldStorage, config: @AccountPermissions, inst: felt252) {
            assert(inst.is_non_zero(), Errors::INVALID_ENTITY);
            assert(*config.is_admin || (*config.is_editor && EntityImpl::can_edit_entity(world, inst, *config.account_address)), Errors::NOT_YOUR_ENTITY);
        }
        #[inline(always)]
        fn _assert_can_delete_entity(self: @ContractState, world: @WorldStorage, config: @AccountPermissions, inst: felt252) {
            assert(inst.is_non_zero(), Errors::INVALID_ENTITY);
            assert(*config.is_admin || (*config.is_editor && EntityImpl::is_creator(world, inst, *config.account_address)), Errors::NOT_YOUR_ENTITY);
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
