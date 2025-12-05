use starknet::{ContractAddress};
use dojo::world::IWorldDispatcher;

#[starknet::interface]
pub trait IActionsLore<TState> {
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
    // IActionsPublicStarknet
    fn set_sn_contract(ref self: TState, sn_contract: ContractAddress);
    fn mint_to(ref self: TState, recipient: ContractAddress, actions: u8);
}

#[starknet::interface]
trait IActionsPublicStarknet<TState> {
    // admin functions
    fn set_sn_contract(ref self: TState, sn_contract: ContractAddress);
    fn mint_to(ref self: TState, recipient: ContractAddress, actions: u8);
}

#[dojo::contract]
pub mod actions_lore {
    use core::num::traits::Zero;
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
    use openzeppelin_token::erc20::ERC20HooksEmptyImpl;
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

    use lore::models::{
        actions_config::{
            ActionsConfig, ActionsConfigTrait,
        },
    };
    use lore::lib::{
        access::{AccessTrait},
        dns::{SELECTORS},
    };
    use lore::constants::constants::{CONST};


    mod Errors {
        pub const INVALID_CALLER: felt252           = 'ACTIONS: Invalid caller';
        pub const INVALID_COMMAND: felt252          = 'ACTIONS: Invalid command';
        pub const INVALID_RECIPIENT: felt252        = 'ACTIONS: Invalid recipient';
        pub const INVALID_AMOUNT: felt252           = 'ACTIONS: Invalid amount';
        pub const INVALID_SN_CONTRACT: felt252      = 'ACTIONS: Invalid SN contract';
    }

    //*******************************************
    fn TOKEN_NAME() -> ByteArray {"O'Ruggin Trail Actions"}
    fn TOKEN_SYMBOL() -> ByteArray {"ORUG_ACTIONS"}
    //*******************************************

    fn dojo_init(ref self: ContractState,
        sn_contract: ContractAddress,
    ) {
        let mut world: WorldStorage = self.world_default();
        self.erc20.initializer(
            TOKEN_NAME(),
            TOKEN_SYMBOL(),
        );
        world.initialize_actions_config(sn_contract);
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
    fn purchased_starter_pack(ref self: ContractState, from_address: felt252, payload: Array<felt252>) {
        let world: WorldStorage = self.world_default();
        // validate caller
        let actions_config: ActionsConfig = world.get_actions_config();
        assert(from_address == actions_config.sn_contract.into(), Errors::INVALID_CALLER);
        // parse payload
        let recipient: ContractAddress = (*payload.at(0)).try_into().unwrap();
        let actions: u8 = (*payload.at(1)).try_into().unwrap();
        let amount: u256 = (actions.into() * CONST::ETH_TO_WEI);
        self._mint_to(recipient, amount);
    }

    #[abi(embed_v0)]
    impl IActionsPublicStarknetImpl of super::IActionsPublicStarknet<ContractState> {
        fn mint_to(ref self: ContractState, recipient: ContractAddress, actions: u8) {
            // validate caller
            self._assert_caller_is_admin(@self.world_default());
            // mint actions...
            let amount: u256 = actions.into() * CONST::ETH_TO_WEI;
            self._mint_to(recipient, amount);
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
        fn _caller_is_owner(self: @ContractState, world: @WorldStorage) -> bool {
            ((*world.dispatcher).is_owner(SELECTORS::ACTIONS_LORE, starknet::get_caller_address()))
        }
        fn _caller_is_admin(self: @ContractState, world: @WorldStorage) -> bool {
            (
                self._caller_is_owner(world) ||
                world.is_player_admin(starknet::get_caller_address())
            )
        }

        // mint new actions to a recipient
        fn _mint_to(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            assert(recipient.is_non_zero(), Errors::INVALID_RECIPIENT);
            assert(amount.is_non_zero(), Errors::INVALID_AMOUNT);
            self.erc20.mint(recipient, amount);
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

}
