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
    fn purchased_starter_pack(ref self: TState, recipient: ContractAddress);
    fn set_messaging_contract(ref self: TState, messaging_contract: ContractAddress);
    fn set_appchain_contract(ref self: TState, appchain_contract: ContractAddress);
    fn set_cartridge_contract(ref self: TState, cartridge_contract: ContractAddress);
    fn set_permit_type(ref self: TState, permit_type: felt252, actions_count: u32);
    fn consume_message_value(ref self: TState, value: felt252);
}

#[starknet::interface]
trait IPermitTokenPublic<TState> {
    fn purchased_starter_pack(ref self: TState, recipient: ContractAddress) -> u128;
    // admin functions
    fn set_messaging_contract(ref self: TState, messaging_contract: ContractAddress);
    fn set_appchain_contract(ref self: TState, appchain_contract: ContractAddress);
    fn set_cartridge_contract(ref self: TState, cartridge_contract: ContractAddress);
    fn set_permit_type(ref self: TState, permit_type: felt252, actions_count: u32);
    // messaging
    fn consume_message_value(ref self: TState, value: felt252);
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
        permit_token_info::{PermitTokenInfo, PermitType},
        permit_metadata::{permit_metadata, orug_metadata},
        appchain::{PERMIT_TYPES},
    };
    use lore_sn::lib::{
        dns::{SELECTORS},
        utils::{ByteArrayTrait},
    };
    use nft_combo::utils::renderer::{Attribute};

    mod Errors {
        pub const INVALID_CALLER: felt252               = 'PERMIT: Invalid caller';
        pub const INVALID_MESSAGING_CONTRACT: felt252   = 'PERMIT: Invalid messaging';
        pub const INVALID_APPCHAIN_CONTRACT: felt252    = 'PERMIT: Invalid appchain';
        pub const INVALID_CARTIDGE_CONTRACT: felt252    = 'PERMIT: Invalid cartridge';
        pub const PERMIT_ALREADY_USED: felt252          = 'PERMIT: Already used';
        pub const INVALID_ACTIONS_COUNT: felt252        = 'PERMIT: Invalid actions count';
    }

    fn dojo_init(ref self: ContractState,
        messaging_contract: ContractAddress,
        appchain_contract: ContractAddress,
        cartridge_contract: ContractAddress,
    ) {
        // initialize ERC721
        self.erc721_combo.initializer(
            permit_metadata::TOKEN_NAME(),
            permit_metadata::TOKEN_SYMBOL(),
            Option::None, // use hooks
            Option::None, // use hooks
            Option::None, // infinite supply
        );
        // initialize permit config
        let mut world: WorldStorage = self.world_default();
        world.initialize_permit_config(
            messaging_contract,
            appchain_contract,
            cartridge_contract,
        );
        // initialize permit types
        world.write_model(@PermitType {
            permit_type: PERMIT_TYPES::STARTER_PACK,
            actions_count: PERMIT_TYPES::STARTER_PACK_ACTIONS_COUNT,
        });
        world.write_model(@PermitType {
            permit_type: PERMIT_TYPES::TRAIL_REWARD,
            actions_count: PERMIT_TYPES::TRAIL_REWARD_ACTIONS_COUNT,
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
        ) -> u128 {
            let mut world: WorldStorage = self.world_default();
            let permit_config: PermitConfig = world.read_model(1);
            assert(permit_config.cartridge_contract == starknet::get_caller_address(), Errors::INVALID_CALLER);

            // mint
            let token_id: u128 = self.erc721_combo._mint_next(recipient).low;

            // save token
            let mut world: WorldStorage = self.world_default();
            world.write_model(@PermitTokenInfo {
                permit_id: token_id,
                permit_type: PERMIT_TYPES::STARTER_PACK,
                is_used: false,
                trail_name: "",
            });

            // use automatically
            self._use_permit(ref world, token_id);

            (token_id)
        }

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


        //-----------------------------------
        /// L3 > L2
        /// Consume a message registered by the appchain.
        fn consume_message_value(ref self: ContractState,
            value: felt252,
        ) {
            let payload: Span<felt252> = array![value].span();
            self._consume_message_value(payload);
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

        fn _use_permit(ref self: ContractState, ref world: WorldStorage, permit_id: u128) {
            // set used
            let mut permit_info: PermitTokenInfo = world.read_model(permit_id);
            assert(!permit_info.is_used, Errors::PERMIT_ALREADY_USED);
            permit_info.is_used = true;
            world.write_model(@permit_info);
            //
            // mint actions to permit owner in L3
            let permit_type: PermitType = world.read_model(permit_info.permit_type);
            assert(permit_type.actions_count > 0, Errors::INVALID_ACTIONS_COUNT);
            let recipient: ContractAddress = self.owner_of(permit_id.into());
            let payload: Span<felt252> = array![
                recipient.into(),
                permit_type.actions_count.into(),
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
            let messaging_config: PermitConfig = self.world_default().read_model(1);
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
            let messaging_config: PermitConfig = self.world_default().read_model(1);
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
            };
            (Option::Some(metadata))
        }

        fn render_token_uri(self: @ERC721ComboComponent::ComponentState<ContractState>, token_id: u256) -> Option<TokenMetadata> {
            let self: @ContractState = self.get_contract(); // get the component's contract state
            let mut world: WorldStorage = self.world_default();
            // attributes and metadata
            let permit_id: u128 = token_id.low;
            let token_info: PermitTokenInfo = world.read_model(permit_id);
            let permit_type: PermitType = world.read_model(token_info.permit_type);
            let mut attributes: Array<Attribute> = array![
                Attribute { 
                    key: "Type",
                    value: ByteArrayTrait::byte_array_from_felt252(permit_type.permit_type),
                },
                Attribute { 
                    key: "Actions",
                    value: format!("{}", permit_type.actions_count),
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
