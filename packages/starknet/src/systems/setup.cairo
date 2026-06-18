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
    fn update_bundles(ref self: TState);

    //-----------------------------------
    // IBundle
    fn get_metadata(self: @TState, bundle_id: u32) -> ByteArray;
    fn quote(self: @TState, bundle_id: u32, quantity: u32, has_referrer: bool, client_percentage: u8) -> BundleQuote;
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
    fn update_bundles(ref self: TState);
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
    // components start
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
    //
    // components end
    //-----------------------------------

    use lore_sn::models::{
        permit_config::{PermitConfigTrait},
    };
    use lore_sn::lib::{
        dns::{
            DnsTrait, SELECTORS,
            IPermitTokenDispatcherTrait,
        },
        bundle::{BUNDLE_COUNT, PermitBundleTrait, BundleDescriptor},
    };
    use bundle::models::{
        index::{Bundle},
        bundle::{BundleAssertTrait},
    };

    mod Errors {
        pub const INVALID_CALLER: felt252               = 'SETUP: Invalid caller';
        pub const INVALID_MESSAGING_CONTRACT: felt252   = 'SETUP: Invalid messaging';
        pub const INVALID_APPCHAIN_CONTRACT: felt252    = 'SETUP: Invalid appchain';
        pub const INVALID_CARTIDGE_CONTRACT: felt252    = 'SETUP: Invalid cartridge';
        pub const INVALID_BUNDLE_ID: felt252            = 'SETUP: Invalid bundle id';
    }

    fn dojo_init(ref self: ContractState,
        messaging_contract: ContractAddress,
        appchain_contract: ContractAddress,
    ) {
        // initialize permit config
        let mut world: WorldStorage = self.world_default();
        // burn uuid 0x0
        let _: u32 = world.dispatcher.uuid();
        // init config singleton
        world.initialize_permit_config(
            messaging_contract,
            appchain_contract,
        );
        // create bundle 0
        for i in 0..BUNDLE_COUNT {
            let bundle_id = self.bundle.register(
                world: world,
                referral_percentage: 0,
                reissuable: false,
                price: 0,
                payment_token: 0.try_into().unwrap(),
                payment_receiver: 0.try_into().unwrap(),
                metadata: "{\"name\":\"Reserved\"}",
                allower: 0.try_into().unwrap(),
            );
            assert(bundle_id == i, Errors::INVALID_BUNDLE_ID);
        }
        self._update_bundles(ref world);
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

        //
        // to update bundles
        // 1. edit to_bundle_descriptor()
        // 2. deploy a contract update
        // 3. call this function
        fn update_bundles(ref self: ContractState) {
            let mut world: WorldStorage = self.world_default();
            self._assert_caller_is_owner(@world);
            // update existing bundles
            self._update_bundles(ref world);
        }
    }


    //-----------------------------------
    // Bundle interface
    //
    impl BundleImpl of BundleTrait<ContractState> {
        fn on_issue(ref self: BundleComponent::ComponentState<ContractState>,
            recipient: ContractAddress,
            bundle_id: u32,
            quantity: u32,
        ) {
            let mut contract = self.get_contract_mut();
            let mut world: WorldStorage = contract.world_default();
            // mint bundles
            let mut permit_token_dispatcher = world.permit_token_dispatcher();
            let permit_type = bundle_id.to_permit_type();
            permit_token_dispatcher.purchased_bundle(recipient, permit_type, quantity, false);
        }
        fn supply(self: @BundleComponent::ComponentState<ContractState>,
            bundle_id: u32,
        ) -> Option<u32> {
            Option::None
        }
    }

    #[abi(embed_v0)]
    impl IBundleImpl of IBundle<ContractState> {
        fn get_metadata(self: @ContractState,
            bundle_id: u32,
        ) -> ByteArray {
            let mut world: WorldStorage = self.world_default();
            self.bundle.get_metadata(world, bundle_id)
        }

        fn quote(self: @ContractState,
            bundle_id: u32,
            quantity: u32,
            has_referrer: bool,
            client_percentage: u8,
        ) -> BundleQuote {
            let mut world: WorldStorage = self.world_default();
            self.bundle.quote(world, bundle_id, quantity, has_referrer, client_percentage)
        }

        fn issue(ref self: ContractState,
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
            // assert bundle exists
            let bundle: Bundle = world.read_model(bundle_id);
            bundle.assert_does_exist();
            // issue...
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
        fn _update_bundles(ref self: ContractState, ref world: WorldStorage) {
            for bundle_id in 0..BUNDLE_COUNT {
                let descriptor: Option<BundleDescriptor> = bundle_id.to_bundle_descriptor(@world);
                match descriptor {
                    Option::Some(descriptor) => {
                        self.bundle.update(
                            world: world,
                            bundle_id: bundle_id,
                            referral_percentage: descriptor.referral_percentage,
                            reissuable: descriptor.reissuable,
                            price: descriptor.price,
                            payment_token: descriptor.payment_token,
                            payment_receiver: descriptor.payment_receiver,
                            allower: descriptor.allower,
                        );
                        self.bundle.update_metadata(
                            world: world,
                            bundle_id: bundle_id,
                            metadata: descriptor.to_bundle_metadata(),
                        );
                    },
                    Option::None => {break;},
                };
            }
        }
    }
}
