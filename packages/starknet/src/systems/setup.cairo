use starknet::{ContractAddress};
use dojo::world::IWorldDispatcher;
use bundle::component::Component::{BundleQuote};

#[starknet::interface]
pub trait ISetup<TState> {
    // IWorldProvider
    fn world_dispatcher(self: @TState) -> IWorldDispatcher;

    //-----------------------------------
    // ISetupPublic (admin)
    fn set_messaging_contract(ref self: TState, messaging_contract: ContractAddress);
    fn set_appchain_contract(ref self: TState, appchain_contract: ContractAddress);
    fn set_cartridge_contract(ref self: TState, cartridge_contract: ContractAddress);
    fn set_permit_type(ref self: TState, permit_type: felt252, actions_count: u32);

    //-----------------------------------
    // IBundle
    fn get_metadata(self: @TState, bundle_id: u32) -> ByteArray;
    fn quote(
        self: @TState, bundle_id: u32, quantity: u32, has_referrer: bool, client_percentage: u8,
    ) -> BundleQuote;
    fn issue(
        ref self: TState,
        recipient: ContractAddress,
        bundle_id: u32,
        quantity: u32,
        referrer: Option<ContractAddress>,
        referrer_group: Option<felt252>,
        client: Option<ContractAddress>,
        client_percentage: u8,
        voucher_key: Option<felt252>,
        signature: Option<Span<felt252>>,
    );
}

#[starknet::interface]
trait ISetupPublic<TState> {
    // admin functions
    fn set_messaging_contract(ref self: TState, messaging_contract: ContractAddress);
    fn set_appchain_contract(ref self: TState, appchain_contract: ContractAddress);
    fn set_cartridge_contract(ref self: TState, cartridge_contract: ContractAddress);
    fn set_permit_type(ref self: TState, permit_type: felt252, actions_count: u32);
}

#[dojo::contract]
pub mod setup {
    use core::num::traits::Zero;
    use starknet::{ContractAddress};
    use dojo::{
        model::ModelStorage,
        world::WorldStorage,
        world::IWorldDispatcherTrait,
    };

    //-----------------------------------
    // Bundle component
    //
    use bundle::component::Component as BundleComponent;
    use bundle::component::Component::{BundleQuote, BundleTrait};
    use bundle::interface::IBundle;
    component!(path: BundleComponent, storage: bundle, event: BundleEvent);
    impl BundleInternalImpl = BundleComponent::InternalImpl<ContractState>;
    impl BundleFeeImpl of BundleComponent::BundleFeeTrait<ContractState> {}
    #[storage]
    struct Storage {
        #[substorage(v0)]
        bundle: BundleComponent::Storage,
    }
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        BundleEvent: BundleComponent::Event,
    }

    use lore_sn::models::{
        permit_config::{PermitConfigTrait},
        permit_token_info::{PermitType},
        appchain::{APPCHAIN},
    };
    use lore_sn::lib::{
        dns::{SELECTORS},
    };

    mod Errors {
        pub const INVALID_CALLER: felt252               = 'SETUP: Invalid caller';
        pub const INVALID_MESSAGING_CONTRACT: felt252   = 'SETUP: Invalid messaging';
        pub const INVALID_APPCHAIN_CONTRACT: felt252    = 'SETUP: Invalid appchain';
        pub const INVALID_CARTIDGE_CONTRACT: felt252    = 'SETUP: Invalid cartridge';
    }

    fn dojo_init(ref self: ContractState,
        messaging_contract: ContractAddress,
        appchain_contract: ContractAddress,
        cartridge_contract: ContractAddress,
    ) {
        // initialize permit config
        let mut world: WorldStorage = self.world_default();
        world.initialize_permit_config(
            messaging_contract,
            appchain_contract,
            cartridge_contract,
        );
        // initialize permit types
        world.write_model(@PermitType {
            permit_type: APPCHAIN::PERMIT_TYPES::STARTER_PACK,
            actions_count: APPCHAIN::STARTER_PACK_ACTIONS_COUNT,
        });
        world.write_model(@PermitType {
            permit_type: APPCHAIN::PERMIT_TYPES::CREATOR_REWARD,
            actions_count: APPCHAIN::CREATOR_REWARD_ACTIONS_COUNT,
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
    impl SetupPublicImpl of super::ISetupPublic<ContractState> {
        /// Admin functions
        fn set_messaging_contract(ref self: ContractState, messaging_contract: ContractAddress) {
            assert(messaging_contract.is_non_zero(), Errors::INVALID_MESSAGING_CONTRACT);
            let mut world: WorldStorage = self.world_default();
            self._assert_caller_is_owner(@world);
            world.set_messaging_contract(messaging_contract);
        }
        fn set_appchain_contract(ref self: ContractState, appchain_contract: ContractAddress) {
            assert(appchain_contract.is_non_zero(), Errors::INVALID_APPCHAIN_CONTRACT);
            let mut world: WorldStorage = self.world_default();
            self._assert_caller_is_owner(@world);
            world.set_appchain_contract(appchain_contract);
        }
        fn set_cartridge_contract(ref self: ContractState, cartridge_contract: ContractAddress) {
            assert(cartridge_contract.is_non_zero(), Errors::INVALID_CARTIDGE_CONTRACT);
            let mut world: WorldStorage = self.world_default();
            self._assert_caller_is_owner(@world);
            world.set_cartridge_contract(cartridge_contract);
        }
        fn set_permit_type(ref self: ContractState, permit_type: felt252, actions_count: u32) {
            let mut world: WorldStorage = self.world_default();
            self._assert_caller_is_owner(@world);
            world.write_model(@PermitType {
                permit_type,
                actions_count,
            });
        }
    }


    //-----------------------------------
    // Bundle interface
    //
    impl BundleImpl of BundleTrait<ContractState> {
        fn on_issue(
            ref self: BundleComponent::ComponentState<ContractState>,
            recipient: ContractAddress,
            bundle_id: u32,
            quantity: u32,
        ) {
        }
        fn supply(
            self: @BundleComponent::ComponentState<ContractState>, bundle_id: u32,
        ) -> Option<u32> {
            Option::None
        }
    }

    #[abi(embed_v0)]
    impl IBundleImpl of IBundle<ContractState> {
        fn get_metadata(self: @ContractState, bundle_id: u32) -> ByteArray {
            let mut world: WorldStorage = self.world_default();
            self.bundle.get_metadata(world, bundle_id)
        }

        fn quote(
            self: @ContractState,
            bundle_id: u32,
            quantity: u32,
            has_referrer: bool,
            client_percentage: u8,
        ) -> BundleQuote {
            let mut world: WorldStorage = self.world_default();
            self.bundle.quote(world, bundle_id, quantity, has_referrer, client_percentage)
        }

        fn issue(
            ref self: ContractState,
            recipient: ContractAddress,
            bundle_id: u32,
            quantity: u32,
            referrer: Option<ContractAddress>,
            referrer_group: Option<felt252>,
            client: Option<ContractAddress>,
            client_percentage: u8,
            voucher_key: Option<felt252>,
            signature: Option<Span<felt252>>,
        ) {
            let mut world: WorldStorage = self.world_default();
            self
                .bundle
                .issue(
                    world,
                    recipient,
                    bundle_id,
                    quantity,
                    referrer,
                    referrer_group,
                    client,
                    client_percentage,
                    voucher_key,
                    signature,
                )
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
            ((*world.dispatcher).is_owner(SELECTORS::SETUP, starknet::get_caller_address()))
        }
    }
}
