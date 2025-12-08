use starknet::{ContractAddress};
use dojo::world::IWorldDispatcher;
use lore::{
    types::command_type::{CommandType},
    constants::errors::{Error},
};

#[starknet::interface]
pub trait IActionsToken<TState> {
    // IWorldProvider
    fn world_dispatcher(self: @TState) -> IWorldDispatcher;

    // IERC20
    fn total_supply(self: @TState) -> u256;
    fn balance_of(self: @TState, account: ContractAddress) -> u256;
    fn allowance(self: @TState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(ref self: TState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(ref self: TState, sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool;
    fn approve(ref self: TState, spender: ContractAddress, amount: u256) -> bool;
    // IERC20Metadata
    fn name(self: @TState) -> ByteArray;
    fn symbol(self: @TState) -> ByteArray;
    fn decimals(self: @TState) -> u8;
    // IERC20CamelOnly
    fn totalSupply(self: @TState) -> u256;
    fn balanceOf(self: @TState, account: ContractAddress) -> u256;
    fn transferFrom(ref self: TState, sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool;

    //-----------------------------------
    // IActionsTokenPublic
    fn get_free_actions_count(self: @TState) -> u32;
    fn claim_free_actions(ref self: TState) -> u32;
    fn set_sn_contract(ref self: TState, sn_contract: ContractAddress);
    fn set_action_cost_amount(ref self: TState, action_cost_amount: u128);
    fn mint_to(ref self: TState, recipient: ContractAddress, actions_count: u32);
}

#[starknet::interface]
pub trait IActionsTokenPublic<TState> {
    fn get_free_actions_count(self: @TState) -> u32;
    fn claim_free_actions(ref self: TState) -> u32;
    // admin functions
    fn set_sn_contract(ref self: TState, sn_contract: ContractAddress);
    fn set_action_cost_amount(ref self: TState, action_cost_amount: u128);
    fn mint_to(ref self: TState, recipient: ContractAddress, actions_count: u32);
}

#[starknet::interface]
pub trait IActionsTokenProtected<TState> {
    fn calculate_action_cost(ref self: TState, player_address: ContractAddress, command_type: CommandType) -> Result<u128, Error>;
    fn charge_player_actions(ref self: TState, player_address: ContractAddress, trail_id: u128, actions_amount: u128);
}

#[dojo::contract]
pub mod actions_token {
    use core::num::traits::{Zero, Bounded};
    use starknet::{ContractAddress, SyscallResultTrait};
    use dojo::{
        world::{WorldStorage, IWorldDispatcherTrait},
        model::ModelStorage,
        // event::EventStorage,
    };
    use starknet::syscalls::send_message_to_l1_syscall;

    const MSG_TO_L2_MAGIC: felt252 = 'MSG';

    //-----------------------------------
    // ERC-20 Start
    //
    use openzeppelin_token::erc20::ERC20Component;
    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;
    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
    }
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
    }
    //
    // ERC-20 End
    //-----------------------------------

    use lore::{
        models::{
            actions_config::{ActionsConfig, ActionsConfigTrait},
            player_account::{PlayerAccountTrait, ActionsSource},
        },
        types::{
            command_type::{CommandType},
        },
        lib::{
            access::{AccessTrait},
            dns::{DnsTrait, SELECTORS},
        },
        constants::{
            constants::{CONST},
            errors::{Error},
        },
    };


    mod Errors {
        pub const INVALID_CALLER: felt252           = 'ACTIONS: Invalid caller';
        pub const INVALID_COMMAND: felt252          = 'ACTIONS: Invalid command';
        pub const INVALID_RECIPIENT: felt252        = 'ACTIONS: Invalid recipient';
        pub const INVALID_AMOUNT: felt252           = 'ACTIONS: Invalid amount';
        pub const INVALID_SN_CONTRACT: felt252      = 'ACTIONS: Invalid SN contract';
        pub const NOT_PERMITTED: felt252            = 'ACTIONS: Not permitted';
    }

    //*******************************************
    fn TOKEN_NAME() -> ByteArray {"O'Ruggin Trail Actions"}
    fn TOKEN_SYMBOL() -> ByteArray {"ORUG_ACTIONS"}
    //*******************************************

    fn dojo_init(ref self: ContractState,
        sn_contract: ContractAddress,
        action_cost: u32,
    ) {
        let mut world: WorldStorage = self.world_default();
        self.erc20.initializer(
            TOKEN_NAME(),
            TOKEN_SYMBOL(),
        );
        let action_cost_amount: u128 = (action_cost.into() * CONST::ETH_TO_WEI.low);
        world.initialize_actions_config(sn_contract, action_cost_amount);
    }
    
    #[generate_trait]
    impl WorldDefaultImpl of WorldDefaultTrait {
        #[inline(always)]
        fn world_default(self: @ContractState) -> WorldStorage {
            (self.world(@"lore"))
        }
    }

    /// Handles a message received from Starknet.
    ///
    /// Only functions that are #[l1_handler] can
    /// receive message from Starknet, exactly as we do with L1 messaging.
    ///
    /// # Arguments
    ///
    /// * `from_address` - The Starknet contract sending the message.
    /// * `payload` - Expected value in the payload (automatically deserialized).
    #[l1_handler]
    fn used_permit(ref self: ContractState, from_address: felt252, payload: Array<felt252>) {
        let mut world: WorldStorage = self.world_default();
        // validate caller
        let actions_config: ActionsConfig = world.get_actions_config();
        assert(from_address == actions_config.sn_contract.into(), Errors::INVALID_CALLER);
        // parse payload
        let recipient: ContractAddress = (*payload.at(0)).try_into().unwrap();
        let actions_count: u32 = (*payload.at(1)).try_into().unwrap();
        let _permit_type: felt252 = *payload.at(2);
        // mint actions
        self._mint_to(ref world, recipient, actions_count, ActionsSource::Purchase);
    }

    #[abi(embed_v0)]
    impl IActionsTokenPublicImpl of super::IActionsTokenPublic<ContractState> {
        fn get_free_actions_count(self: @ContractState) -> u32 {
            let world: WorldStorage = self.world_default();
            (world.get_free_actions_count(starknet::get_caller_address()))
        }
        fn claim_free_actions(ref self: ContractState) -> u32 {
            let mut world: WorldStorage = self.world_default();
            let minted_actions_count: u32 = self._claim_free_actions(ref world, starknet::get_caller_address());
            (minted_actions_count)
        }

        fn mint_to(ref self: ContractState, recipient: ContractAddress, actions_count: u32) {
            // validate caller
            self._assert_caller_is_admin(@self.world_default());
            // mint actions...
            let mut world: WorldStorage = self.world_default();
            self._mint_to(ref world, recipient, actions_count, ActionsSource::Airdrop);
        }

        /// Admin functions
        fn set_sn_contract(ref self: ContractState, sn_contract: ContractAddress) {
            let mut world: WorldStorage = self.world_default();
            // validate caller
            self._assert_caller_is_owner(@world);
            // set messaging contract
            assert(sn_contract.is_non_zero(), Errors::INVALID_SN_CONTRACT);
            let mut actions_config: ActionsConfig = world.get_actions_config();
            actions_config.sn_contract = sn_contract;
            world.write_model(@actions_config);
        }

        fn set_action_cost_amount(ref self: ContractState, action_cost_amount: u128) {
            let mut world: WorldStorage = self.world_default();
            // validate caller
            self._assert_caller_is_owner(@world);
            // set action cost amount
            let mut actions_config: ActionsConfig = world.get_actions_config();
            actions_config.action_cost_amount = action_cost_amount;
            world.write_model(@actions_config);
        }
    }

    #[abi(embed_v0)]
    impl IActionsTokenProtectedImpl of super::IActionsTokenProtected<ContractState> {
        fn calculate_action_cost(ref self: ContractState, player_address: ContractAddress, command_type: CommandType) -> Result<u128, Error> {
            let mut world: WorldStorage = self.world_default();
            // validate caller
            self._assert_caller_is_world_contract(@world);
            // check if player has free actions to claim
            self._claim_free_actions(ref world, player_address);
            // calculate actions cost
            let actions_amount: u128 = world.calculate_actions_cost(command_type);
            if actions_amount.is_non_zero() && self.balance_of(player_address).low < actions_amount {
                return Result::Err(Error::InsufficientActionsBalance);
            }
            (Result::Ok(actions_amount))
        }

        fn charge_player_actions(ref self: ContractState, player_address: ContractAddress, trail_id: u128, actions_amount: u128) {
            let mut world: WorldStorage = self.world_default();
            // validate caller
            self._assert_caller_is_world_contract(@world);
            if (trail_id.is_zero()) {
                // burn player actions
               self.erc20.burn(player_address, actions_amount.into());
               world.spent_actions(player_address, actions_amount);
            } else {
                // TODO...
            }
        }
    }

    //-----------------------------------
    // Internal
    //
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        #[inline(always)]
        fn _assert_caller_is_owner(self: @ContractState, world: @WorldStorage) {
            assert(self._caller_is_owner(world), Errors::INVALID_CALLER);
        }
        #[inline(always)]
        fn _assert_caller_is_admin(self: @ContractState, world: @WorldStorage) {
            assert(self._caller_is_admin(world), Errors::INVALID_CALLER);
        }
        #[inline(always)]
        fn _assert_caller_is_world_contract(self: @ContractState, world: @WorldStorage) {
            assert(world.is_world_contract(starknet::get_caller_address()), Errors::INVALID_CALLER);
        }
        fn _caller_is_owner(self: @ContractState, world: @WorldStorage) -> bool {
            ((*world.dispatcher).is_owner(SELECTORS::ACTIONS_TOKEN, starknet::get_caller_address()))
        }
        fn _caller_is_admin(self: @ContractState, world: @WorldStorage) -> bool {
            (
                self._caller_is_owner(world) ||
                world.is_player_admin(starknet::get_caller_address())
            )
        }

        // mint new actions to a recipient
        fn _mint_to(ref self: ContractState, ref world: WorldStorage, recipient: ContractAddress, actions_count: u32, source: ActionsSource) {
            // mint actions
            let amount: u256 = (actions_count.into() * CONST::ETH_TO_WEI);
            assert(recipient.is_non_zero(), Errors::INVALID_RECIPIENT);
            assert(amount.is_non_zero(), Errors::INVALID_AMOUNT);
            self.erc20.mint(recipient, amount);
            // update player account
            if (world.minted_actions(recipient, actions_count, source)) {
                // first purchase: approve world contracts to spend actions
                self.erc20._approve(recipient, starknet::get_contract_address(), Bounded::MAX);
                self.erc20._approve(recipient, world.prompt_address(), Bounded::MAX);
            }
        }

        fn _claim_free_actions(ref self: ContractState, ref world: WorldStorage, player_address: ContractAddress) -> u32 {
            let available_actions_count: u32 = (world.get_free_actions_count(player_address));
            if available_actions_count > 0 {
                self._mint_to(ref world, player_address, available_actions_count, ActionsSource::FreeClaimed);
            }
            (available_actions_count)
        }


        //
        // L3 > L2 messaging
        // based on: https://github.com/glihm/starknet-messaging-dev/blob/l2-l3/cairo/src/contract_msg_starknet.cairo
        //
        fn _send_message(ref self: ContractState, to_address: ContractAddress, value: felt252) {
            // Since the blockifier does not support sending to an address larger than `EthAddress`,
            // we send the address as the first value of the payload, and use the magic value `MSG` as the `to_address`.
            send_message_to_l1_syscall(MSG_TO_L2_MAGIC, array![to_address.into(),value].span()).unwrap_syscall();
        }
    }

    //-----------------------------------
    // ERC20Hooks
    // - block transfers, make it soulbound
    //
    impl ERC20HooksImpl of ERC20Component::ERC20HooksTrait<ContractState> {
        fn before_update(
            ref self: ERC20Component::ComponentState<ContractState>,
            from: ContractAddress,
            recipient: ContractAddress,
            amount: u256,
        ) {
            let self: @ContractState = self.get_contract();
            let world: WorldStorage = self.world_default();
            if (from.is_non_zero() && !world.is_world_contract(starknet::get_caller_address())) {
                // block transfers
                assert(false, Errors::NOT_PERMITTED);
            }
        }

        fn after_update(
            ref self: ERC20Component::ComponentState<ContractState>,
            from: ContractAddress,
            recipient: ContractAddress,
            amount: u256,
        ) {
            // let mut contract_state: ContractState = self.get_contract_mut();
        }
    }
}
