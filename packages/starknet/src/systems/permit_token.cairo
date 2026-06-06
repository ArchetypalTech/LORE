use starknet::{ContractAddress};
use dojo::world::IWorldDispatcher;

#[starknet::interface]
pub trait IPermitToken<TState> {
    // IWorldProvider
    fn world_dispatcher(self: @TState) -> IWorldDispatcher;

    //-----------------------------------
    // IERC721ComboABI start
    //
    // (ISRC5)
    fn supports_interface(self: @TState, interface_id: felt252) -> bool;
    // (IERC721)
    fn balance_of(self: @TState, account: ContractAddress) -> u256;
    fn owner_of(self: @TState, token_id: u256) -> ContractAddress;
    fn safe_transfer_from(ref self: TState, from: ContractAddress, to: ContractAddress, token_id: u256, data: Span<felt252>);
    fn transfer_from(ref self: TState, from: ContractAddress, to: ContractAddress, token_id: u256);
    fn approve(ref self: TState, to: ContractAddress, token_id: u256);
    fn set_approval_for_all(ref self: TState, operator: ContractAddress, approved: bool);
    fn get_approved(self: @TState, token_id: u256) -> ContractAddress;
    fn is_approved_for_all(self: @TState, owner: ContractAddress, operator: ContractAddress) -> bool;
    // (IERC721Metadata)
    fn name(self: @TState) -> ByteArray;
    fn symbol(self: @TState) -> ByteArray;
    fn token_uri(self: @TState, token_id: u256) -> ByteArray;
    fn tokenURI(self: @TState, tokenId: u256) -> ByteArray;
    //-----------------------------------
    // IERC721Minter
    fn max_supply(self: @TState) -> u256;
    fn reserved_supply(self: @TState) -> u256;
    fn available_supply(self: @TState) -> u256;
    fn minted_supply(self: @TState) -> u256;
    fn total_supply(self: @TState) -> u256;
    fn last_token_id(self: @TState) -> u256;
    fn is_minting_paused(self: @TState) -> bool;
    fn is_minted_out(self: @TState) -> bool;
    fn is_owner_of(self: @TState, address: ContractAddress, token_id: u256) -> bool;
    fn token_exists(self: @TState, token_id: u256) -> bool;
    //-----------------------------------
    // IERC7572ContractMetadata
    fn contract_uri(self: @TState) -> ByteArray;
    fn contractURI(self: @TState) -> ByteArray;
    //-----------------------------------
    // IERC4906MetadataUpdate
    //-----------------------------------
    // IERC2981RoyaltyInfo
    fn royalty_info(self: @TState, token_id: u256, sale_price: u256) -> (ContractAddress, u256);
    fn default_royalty(self: @TState) -> (ContractAddress, u128, u128);
    fn token_royalty(self: @TState, token_id: u256) -> (ContractAddress, u128, u128);
    // IERC721ComboABI end
    //-----------------------------------

    //-----------------------------------
    // IPermitTokenPublic
    fn use_permits(ref self: TState, token_ids: Span<u128>);
    fn purchased_bundle(ref self: TState, recipient: ContractAddress, permit_type: felt252, quantity: u32, use_tokens: bool) -> Span<u128>;
    fn airdrop_bundle(ref self: TState, recipient: ContractAddress, quantity: u32, use_tokens: bool) -> Span<u128>;
    fn consume_message(ref self: TState, payload: Span<felt252>);
}

#[starknet::interface]
trait IPermitTokenPublic<TState> {
    // public
    fn use_permits(ref self: TState, token_ids: Span<u128>);
    // admin
    fn purchased_bundle(ref self: TState, recipient: ContractAddress, permit_type: felt252, quantity: u32, use_tokens: bool) -> Span<u128>;
    fn airdrop_bundle(ref self: TState, recipient: ContractAddress, quantity: u32, use_tokens: bool) -> Span<u128>;
    // messaging
    fn consume_message(ref self: TState, payload: Span<felt252>);
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

    // piltover messaging interface
    // use piltover::messaging::interface::{IMessagingDispatcher, IMessagingDispatcherTrait};
    use lore_sn::lib::messaging::{IMessagingDispatcher, IMessagingDispatcherTrait};

    //-----------------------------------
    // ERC721 start
    //
    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_token::erc721::ERC721Component;
    use nft_combo::erc721::erc721_combo::ERC721ComboComponent;
    use nft_combo::erc721::erc721_combo::ERC721ComboComponent::{ERC721HooksImpl};
    use nft_combo::utils::renderer::{ContractMetadata, TokenMetadata};
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: ERC721ComboComponent, storage: erc721_combo, event: ERC721ComboEvent);
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;
    impl ERC721ComboInternalImpl = ERC721ComboComponent::InternalImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721ComboMixinImpl = ERC721ComboComponent::ERC721ComboMixinImpl<ContractState>;
    #[storage]
    struct Storage {
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        erc721_combo: ERC721ComboComponent::Storage,
    }
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        ERC721ComboEvent: ERC721ComboComponent::Event,
    }
    //
    // ERC721 end
    //-----------------------------------

    use lore_sn::models::{
        permit_config::{PermitConfig, PermitConfigTrait},
        permit_token_info::{PermitTokenInfo, PermitTokenInfoTrait},
        appchain::{APPCHAIN, PermitTypeTrait},
    };
    use lore_sn::lib::{
        dns::{DnsTrait, SELECTORS},
        constants::{permit_metadata, orug_metadata},
        utils::{ByteArrayTrait},
    };
    use nft_combo::utils::renderer::{Attribute};

    pub mod Errors {
        pub const INVALID_CALLER: felt252               = 'PERMIT: Invalid caller';
        pub const PERMIT_ALREADY_USED: felt252          = 'PERMIT: Already used';
        pub const INVALID_PERMIT_TYPE: felt252          = 'PERMIT: Invalid permit';
        pub const INVALID_ACTIONS_COUNT: felt252        = 'PERMIT: Invalid actions count';
        pub const INVALID_MESSAGING_CONTRACT: felt252   = 'PERMIT: Invalid messaging';
        pub const INVALID_APPCHAIN_CONTRACT: felt252    = 'PERMIT: Invalid appchain';
    }

    fn dojo_init(ref self: ContractState) {
        // initialize ERC721
        self.erc721_combo.initializer(
            permit_metadata::TOKEN_NAME(),
            permit_metadata::TOKEN_SYMBOL(),
            Option::None, // use hooks
            Option::None, // use hooks
            Option::None, // infinite supply
        );
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
        fn purchased_bundle(ref self: ContractState,
            recipient: ContractAddress,
            permit_type: felt252,
            quantity: u32,
            use_tokens: bool,
        ) -> Span<u128> {
            let mut world: WorldStorage = self.world_default();
            assert(starknet::get_caller_address() == world.setup_address(), Errors::INVALID_CALLER);
            // validate permit
            let actions_count: u32 = permit_type.actions_count();
            assert(actions_count > 0, Errors::INVALID_PERMIT_TYPE);
            // mint
            let token_ids: Span<u128> = self._mint_bundles(ref world,
                recipient,
                quantity,
                permit_type,
            );
            // use automatically
            if (use_tokens) {
                for mut i in 0..quantity {
                    self._use_permit(ref world, *token_ids[i]);
                    i += 1;
                }
            }
            (token_ids)
        }

        fn airdrop_bundle(ref self: ContractState,
            recipient: ContractAddress,
            quantity: u32,
            use_tokens: bool,
        ) -> Span<u128> {
            let mut world: WorldStorage = self.world_default();
            self._assert_caller_is_owner(@world);
            // mint
            let token_ids: Span<u128> = self._mint_bundles(ref world,
                recipient,
                quantity,
                APPCHAIN::PERMIT_TYPES::PERMIT_AIRDROP,
            );
            // use automatically
            if (use_tokens) {
                for mut i in 0..quantity {
                    self._use_permit(ref world, *token_ids[i]);
                    i += 1;
                }
            }
            (token_ids)
        }

        /// will trigger L2 > L3 message
        fn use_permits(ref self: ContractState,
            token_ids: Span<u128>,
        ) {
            let mut world: WorldStorage = self.world_default();
            let caller = starknet::get_caller_address();
            for mut i in 0..token_ids.len() {
                let token_id = *token_ids[i];
                assert(self.erc721_combo.is_owner_of(caller, token_id.into()), Errors::INVALID_CALLER);
                self._use_permit(ref world, token_id);
                i += 1;
            }
        }

        //-----------------------------------
        /// L3 > L2
        /// Consume a message registered by the appchain.
        fn consume_message(ref self: ContractState,
            payload: Span<felt252>,
        ) {
            self._consume_message(payload);
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

        fn _mint_bundles(ref self: ContractState,
            ref world: WorldStorage,
            recipient: ContractAddress,
            quantity: u32,
            permit_type: felt252,
        ) -> Span<u128> {
            let mut token_ids: Array<u128> = array![];

            while token_ids.len() < quantity {
                // mint
                let token_id: u128 = self.erc721_combo._mint_next(recipient).low;

                // save token
                let mut world: WorldStorage = self.world_default();
                world.write_model(@PermitTokenInfo {
                    permit_id: token_id,
                    permit_type,
                    is_used: false,
                    trail_name: "",
                });

                token_ids.append(token_id);
            }

            (token_ids.span())
        }

        fn _use_permit(ref self: ContractState,
            ref world: WorldStorage,
            permit_id: u128,
        ) {
            // set used
            let permit_info: PermitTokenInfo = world.read_model(permit_id);
            assert(!permit_info.is_used, Errors::PERMIT_ALREADY_USED);
            world.set_is_used(permit_id);
            //
            // mint actions to permit owner in L3
            let actions_count: u32 = permit_info.permit_type.actions_count();
            assert(actions_count > 0, Errors::INVALID_ACTIONS_COUNT);
            let recipient: ContractAddress = self.owner_of(permit_id.into());
            let payload: Span<felt252> = array![
                recipient.into(),
                actions_count.into(),
                permit_info.permit_type,
            ].span();
            self._send_message(selector!("used_permit"), payload);
        }


        //-----------------------------------
        // L2 > L3 messaging
        // based on: https://github.com/glihm/starknet-messaging-dev/blob/l2-l3/cairo/src/sn_1.cairo
        //
        
        fn _send_message(ref self: ContractState,
            selector: felt252,
            payload: Span<felt252>,
        ) {
            let world: WorldStorage = self.world_default();
            let messaging_config: PermitConfig = world.get_permit_config();
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

        fn _consume_message(ref self: ContractState,
            payload: Span<felt252>,
        ) {
            let world: WorldStorage = self.world_default();
            let messaging_config: PermitConfig = world.get_permit_config();
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
            // for i in 0..payload.len() {
            //     let payload_item: felt252 = *payload.at(i);
            //     println!("payload[{}]: {}", i, payload_item);
            // }
        }
    }



    //-----------------------------------
    // ERC721ComboHooksTrait
    //
    pub impl ERC721ComboHooksImpl of ERC721ComboComponent::ERC721ComboHooksTrait<ContractState> {
        fn render_contract_uri(self: @ERC721ComboComponent::ComponentState<ContractState>) -> Option<ContractMetadata> {
            // https://docs.opensea.io/docs/contract-level-metadata
            let metadata: ContractMetadata = ContractMetadata {
                name: self.name(),
                symbol: self.symbol(),
                description: orug_metadata::DESCRIPTION(),
                image: Option::Some(orug_metadata::CONTRACT_IMAGE()),
                banner_image: Option::Some(orug_metadata::BANNER_IMAGE()),
                featured_image: Option::None,
                external_link: Option::Some(orug_metadata::EXTERNAL_LINK()),
                collaborators: Option::None,
                background_color: Option::Some(orug_metadata::BACKGROUND_COLOR()),
            };
            (Option::Some(metadata))
        }

        fn render_token_uri(self: @ERC721ComboComponent::ComponentState<ContractState>, token_id: u256) -> Option<TokenMetadata> {
            let self: @ContractState = self.get_contract(); // get the component's contract state
            let mut world: WorldStorage = self.world_default();
            // attributes and metadata
            let permit_id: u128 = token_id.low;
            let token_info: PermitTokenInfo = world.read_model(permit_id);
            let permit_type: felt252 = token_info.permit_type;
            let actions_count: u32 = permit_type.actions_count();
            let mut attributes: Array<Attribute> = array![
                Attribute { 
                    key: "Type",
                    value: ByteArrayTrait::byte_array_from_felt252(permit_type),
                },
                Attribute { 
                    key: "Actions",
                    value: format!("{}", actions_count),
                },
                Attribute {
                    key: "Used",
                    value: ByteArrayTrait::byte_array_from_bool(token_info.is_used),
                },
            ];
            if (token_info.trail_name.clone().len() > 0) {
                attributes.append(Attribute {
                    key: "Trail",
                    value: token_info.trail_name.clone(),
                });
            }
            let additional_metadata: Span<Attribute> = array![].span();
            // https://docs.opensea.io/docs/metadata-standards#metadata-structure
            let metadata: TokenMetadata = TokenMetadata {
                token_id,
                name: format!("{} #{}", permit_metadata::TOKEN_NAME(), permit_id),
                description: orug_metadata::DESCRIPTION(),
                image: Option::Some(orug_metadata::CONTRACT_IMAGE()),
                image_data: Option::None,
                external_url: Option::Some(orug_metadata::EXTERNAL_LINK()), // TODO: format external token link
                background_color: Option::Some(orug_metadata::BACKGROUND_COLOR()),
                animation_url: Option::None,
                youtube_url: Option::None,
                attributes: Option::Some(attributes.span()),
                additional_metadata: Option::Some(additional_metadata),
            };
            (Option::Some(metadata))
        }
    }
}
