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
}

#[dojo::contract]
pub mod actions_lore {
    use starknet::{ContractAddress, SyscallResultTrait};
    use dojo::{
        world::WorldStorage,
        // model::ModelStorage,
        // event::EventStorage,
    };
    use starknet::syscalls::send_message_to_l1_syscall;

    const MSG_TO_L2_MAGIC: felt252 = 'MSG';

    //-----------------------------------
    // ERC-20 Start
    //
    use openzeppelin_token::erc20::ERC20Component;
    use openzeppelin_token::erc20::ERC20HooksEmptyImpl;
    use lore::components::coin_component::{
        CoinComponent,
        // CoinComponent::{Errors as CoinErrors},
    };
    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    component!(path: CoinComponent, storage: coin, event: CoinEvent);
    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;
    impl CoinComponentInternalImpl = CoinComponent::CoinComponentInternalImpl<ContractState>;
    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        #[substorage(v0)]
        coin: CoinComponent::Storage,
    }
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
        #[flat]
        CoinEvent: CoinComponent::Event,
    }
    //
    // ERC-20 End
    //-----------------------------------


    mod Errors {
        pub const INVALID_CALLER: felt252   = 'ACTIONS: Invalid caller';
        pub const NOT_IMPLEMENTED: felt252  = 'ACTIONS: Not implemented';
    }

    //*******************************************
    fn COIN_NAME() -> ByteArray {("Actions")}
    fn COIN_SYMBOL() -> ByteArray {("ACTIONS")}
    //*******************************************

    fn dojo_init(ref self: ContractState) {
        // let mut world: WorldStorage = self.world_default();
        self.erc20.initializer(
            COIN_NAME(),
            COIN_SYMBOL(),
        );
        self.coin.initialize(
            0x0.try_into().unwrap(),
            faucet_amount: 0,
        );
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
    /// * `value` - Expected value in the payload (automatically deserialized).
    #[l1_handler]
    fn msg_handler_value(ref self: ContractState, from_address: felt252, value: felt252) {
        // assert(from_address == ...);
        assert(value == 888, 'Invalid value');
    }


    //-----------------------------------
    // Internal
    //
    #[generate_trait]
    impl InternalImpl of InternalTrait {
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
