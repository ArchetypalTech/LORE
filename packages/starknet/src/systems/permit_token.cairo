use starknet::{ContractAddress};
use dojo::world::IWorldDispatcher;

#[starknet::interface]
pub trait IPermitToken<TState> {
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
    // IPermitTokenPublic
    fn purchased_starter_pack(ref self: TState, recipient: ContractAddress);
    fn consume_message_value(ref self: TState, value: felt252);
    fn set_messaging_contract(ref self: TState, messaging_contract: ContractAddress);
    fn set_appchain_contract(ref self: TState, appchain_contract: ContractAddress);
}

#[starknet::interface]
trait IPermitTokenPublic<TState> {
    fn purchased_starter_pack(ref self: TState, recipient: ContractAddress);
    fn consume_message_value(ref self: TState, value: felt252);
    // admin functions
    fn set_messaging_contract(ref self: TState, messaging_contract: ContractAddress);
    fn set_appchain_contract(ref self: TState, appchain_contract: ContractAddress);
}

#[dojo::contract]
pub mod permit_token {
    use core::num::traits::Zero;
    use starknet::{ContractAddress};
    use dojo::{
        model::ModelStorage,
        world::WorldStorage,
        world::IWorldDispatcherTrait,
        // event::EventStorage,
    };
    use piltover::messaging::interface::{IMessagingDispatcher, IMessagingDispatcherTrait};

    //-----------------------------------
    // ERC-20 Start
    //
    use openzeppelin_token::erc20::ERC20Component;
    use openzeppelin_token::erc20::ERC20HooksEmptyImpl;
    use lore_sn::components::coin_component::{
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

    use lore_sn::models::{
        actions_supply::{ActionsSupply},
        messaging::{MessagingConfig},
    };
    use lore_sn::lib::dns::{SELECTORS};

    mod Errors {
        pub const INVALID_CALLER: felt252               = 'PERMIT: Invalid caller';
        pub const INVALID_MESSAGING_CONTRACT: felt252   = 'PERMIT: Invalid messaging';
        pub const INVALID_APPCHAIN_CONTRACT: felt252    = 'PERMIT: Invalid appchain';
        pub const NOT_IMPLEMENTED: felt252              = 'PERMIT: Not implemented';
    }

    //*******************************************
    fn COIN_NAME() -> ByteArray {("Trail Permit")}
    fn COIN_SYMBOL() -> ByteArray {("ORUG_PERMIT")}
    //*******************************************

    fn dojo_init(ref self: ContractState,
        messaging_contract: ContractAddress,
        appchain_contract: ContractAddress,
    ) {
        let mut world: WorldStorage = self.world_default();
        self.erc20.initializer(
            COIN_NAME(),
            COIN_SYMBOL(),
        );
        self.coin.initialize(
            0x0.try_into().unwrap(),
            faucet_amount: 0,
        );
        world.write_model(@MessagingConfig {
            key: 1,
            messaging_contract,
            appchain_contract,
        });
        world.write_model(@ActionsSupply {
            contract_address: starknet::get_contract_address(),
            amount_minted: 0,
            amount_locked: 0,
            amount_burned: 0,
        });
    }
    
    #[generate_trait]
    impl WorldDefaultImpl of WorldDefaultTrait {
        #[inline(always)]
        fn world_default(self: @ContractState) -> WorldStorage {
            (self.world(@"lore_sn"))
        }
    }

    #[abi(embed_v0)]
    impl PermitTokenPublicImpl of super::IPermitTokenPublic<ContractState> {
        /// L2 > L3
        /// Sends a message with the given value.
        fn purchased_starter_pack(ref self: ContractState,
            recipient: ContractAddress,
        ) {
            //
            // TODO: check sender is Cartridge
            //
            let payload: Span<felt252> = array![
                recipient.into(),
                20.into(),
            ].span();
            self._send_message(selector!("purchased_starter_pack"), payload);
        }

        /// L3 > L2
        /// Consume a message registered by the appchain.
        fn consume_message_value(ref self: ContractState,
            value: felt252,
        ) {
            let payload: Span<felt252> = array![value].span();
            self._consume_message_value(payload);
        }

        /// Admin functions
        fn set_messaging_contract(ref self: ContractState, messaging_contract: ContractAddress) {
            let mut world: WorldStorage = self.world_default();
            self._assert_caller_is_owner(@world);
            assert(messaging_contract.is_non_zero(), Errors::INVALID_MESSAGING_CONTRACT);
            let mut messaging_config: MessagingConfig = world.read_model(1);
            messaging_config.messaging_contract = messaging_contract;
            world.write_model(@messaging_config);
        }
        fn set_appchain_contract(ref self: ContractState, appchain_contract: ContractAddress) {   
            let mut world: WorldStorage = self.world_default();
            self._assert_caller_is_owner(@world);
            assert(appchain_contract.is_non_zero(), Errors::INVALID_APPCHAIN_CONTRACT);
            let mut messaging_config: MessagingConfig = world.read_model(1);
            messaging_config.appchain_contract = appchain_contract;
            world.write_model(@messaging_config);
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
        fn _caller_is_owner(self: @ContractState, world: @WorldStorage) -> bool {
            ((*world.dispatcher).is_owner(SELECTORS::PERMIT_TOKEN, starknet::get_caller_address()))
        }

        //
        // L2 > L3 messaging
        // based on: https://github.com/glihm/starknet-messaging-dev/blob/l2-l3/cairo/src/sn_1.cairo
        //
        
        fn _send_message(ref self: ContractState,
            selector: felt252,
            payload: Span<felt252>,
        ) {
            let messaging_config: MessagingConfig = self.world_default().read_model(1);
            assert(messaging_config.messaging_contract.is_non_zero(), Errors::INVALID_MESSAGING_CONTRACT);
            assert(messaging_config.appchain_contract.is_non_zero(), Errors::INVALID_APPCHAIN_CONTRACT);

            // serialize payload
            let mut serialized_payload: Array<felt252> = array![];
            payload.serialize(ref serialized_payload);

            let messaging: IMessagingDispatcher = IMessagingDispatcher {
                contract_address: messaging_config.messaging_contract,
            };
            messaging.send_message_to_appchain(messaging_config.appchain_contract, selector, serialized_payload.span());
        }

        fn _consume_message_value(ref self: ContractState,
            payload: Span<felt252>,
        ) {
            let messaging_config: MessagingConfig = self.world_default().read_model(1);
            assert(messaging_config.messaging_contract.is_non_zero(), Errors::INVALID_MESSAGING_CONTRACT);
            assert(messaging_config.appchain_contract.is_non_zero(), Errors::INVALID_APPCHAIN_CONTRACT);

            let messaging: IMessagingDispatcher = IMessagingDispatcher {
                contract_address: messaging_config.messaging_contract,
            };

            // Will revert in case of failure if the message is not registered
            // as consumable.
            let _msg_hash: felt252 = messaging.consume_message_from_appchain(
                messaging_config.appchain_contract,
                payload,
            );

            // msg successfully consumed, we can proceed and process the data
            // in the payload.
        }
    }

}
