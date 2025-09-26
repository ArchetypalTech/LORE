use starknet::{ContractAddress};
use dojo::world::IWorldDispatcher;

#[starknet::interface]
pub trait IGameToken<TState> {
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

    // game_token
    fn create_game(ref self: TState, recipient: ContractAddress) -> u128;
    // fn burn(ref self: TState, token_id: u256);
    fn set_paused(ref self: TState, is_paused: bool);
    fn set_admin(ref self: TState, account_address: ContractAddress, is_admin: bool);
    fn set_editor(ref self: TState, account_address: ContractAddress, is_editor: bool);
    fn update_token_metadata(ref self: TState, token_id: u256);
    fn update_tokens_metadata(ref self: TState, from_token_id: u256, to_token_id: u256);
    fn update_contract_metadata(ref self: TState);
}

#[starknet::interface]
pub trait IGameTokenPublic<TState> {
    fn create_game(ref self: TState, recipient: ContractAddress) -> u128;
    // fn burn(ref self: TState, token_id: u256);
    // admin
    fn set_paused(ref self: TState, is_paused: bool);
    fn set_admin(ref self: TState, account_address: ContractAddress, is_admin: bool);
    fn set_editor(ref self: TState, account_address: ContractAddress, is_editor: bool);
    fn update_token_metadata(ref self: TState, token_id: u256);
    fn update_tokens_metadata(ref self: TState, from_token_id: u256, to_token_id: u256);
    fn update_contract_metadata(ref self: TState);
}

#[dojo::contract]
pub mod game_token {
    use starknet::ContractAddress;
    use dojo::{
        world::{WorldStorage, IWorldDispatcherTrait},
        model::{ModelStorage},
        event::{EventStorage},
    };

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

    use lore::models::{
        admin::{AccountPermissionsTrait},
        token_config::{
            GameTokenInfo, GameTokenInfoTrait,
            PlayerAccountTrait,
            GameCreatedEvent,
        },
    };
    use lore::constants::{token as constants};
    use lore::lib::{
        dns::{SELECTORS},
        utils::{HashImpl, ByteArrayTraitExt},
    };
    use nft_combo::utils::renderer::{Attribute};

    mod Errors {
        pub const INVALID_CALLER: felt252   = 'ORUG: Invalid caller';
    }

    fn dojo_init(ref self: ContractState, admin_accounts: Array<ContractAddress>) {
        // initialize ERC721
        self.erc721_combo.initializer(
            constants::TOKEN_NAME(),
            constants::TOKEN_SYMBOL(),
            Option::None, // use hooks
            Option::None, // use hooks
            Option::None, // infinite supply
        );

        // set deployer as admin
        let mut world: WorldStorage = self.world_default();
        let deployer_address: ContractAddress = starknet::get_execution_info().tx_info.account_contract_address;
        AccountPermissionsTrait::set_is_admin(ref world, deployer_address, true);
        AccountPermissionsTrait::set_is_editor(ref world, deployer_address, true);
        // set admin accounts
        for account_address in admin_accounts {
            AccountPermissionsTrait::set_is_admin(ref world, account_address, true);
            AccountPermissionsTrait::set_is_editor(ref world, account_address, true);
        };
    }

    #[generate_trait]
    impl WorldDefaultImpl of WorldDefaultTrait {
        #[inline(always)]
        fn world_default(self: @ContractState) -> WorldStorage {
            (self.world(@"lore"))
        }
    }


    //-----------------------------------
    // IGameTokenPublic
    //
    #[abi(embed_v0)]
    impl GameTokenPublicImpl of super::IGameTokenPublic<ContractState> {
        fn create_game(ref self: ContractState, recipient: ContractAddress) -> u128 {
            let mut world: WorldStorage = self.world_default();

            // mint
            let token_id: u128 = self.erc721_combo._mint_next(recipient).low;

            // generate seed
            let contract_address: ContractAddress = starknet::get_contract_address();
            let seed: felt252 = HashImpl::hash_values(array![
                contract_address.into(),
                token_id.into(),
                recipient.into(),
                HashImpl::make_block_hash(),
            ].span());

            // save token
            world.write_model(@GameTokenInfo {
                game_id: token_id,
                minter_address: recipient,
                seed,
                act_number: 1,
                room_name: "The Void",
                progress: 0,
                completed: false,
            });

            // switch to this game
            PlayerAccountTrait::switch_game_id(ref world, recipient, token_id);

            // event...
            world.emit_event(@GameCreatedEvent{
                contract_address,
                game_id: token_id,
                recipient,
            });

            (token_id)
        }

        // fn burn(ref self: ContractState, token_id: u256) {
        //     let owner: ContractAddress = self.owner_of(token_id);
        //     self.erc721_combo._burn(token_id);
        // }

        //
        // admin
        //
        fn set_paused(ref self: ContractState, is_paused: bool) {
            let world: WorldStorage = self.world_default();
            self._assert_caller_is_admin(@world);
            self.erc721_combo._set_minting_paused(is_paused);
        }
        fn set_admin(ref self: ContractState, account_address: ContractAddress, is_admin: bool) {
            let mut world: WorldStorage = self.world_default();
            self._assert_caller_is_admin(@world);
            AccountPermissionsTrait::set_is_admin(ref world, account_address, is_admin);
        }
        fn set_editor(ref self: ContractState, account_address: ContractAddress, is_editor: bool) {
            let mut world: WorldStorage = self.world_default();
            self._assert_caller_is_admin(@world);
            AccountPermissionsTrait::set_is_editor(ref world, account_address, is_editor);
        }
        fn update_token_metadata(ref self: ContractState, token_id: u256) {
            // let mut world: WorldStorage = self.world_default();
            // self._assert_caller_is_admin(@world);
            self.erc721_combo._emit_metadata_update(token_id);
        }
        fn update_tokens_metadata(ref self: ContractState, from_token_id: u256, to_token_id: u256) {
            let world: WorldStorage = self.world_default();
            self._assert_caller_is_admin(@world);
            self.erc721_combo._emit_batch_metadata_update(from_token_id, to_token_id);
        }
        fn update_contract_metadata(ref self: ContractState) {
            let world: WorldStorage = self.world_default();
            self._assert_caller_is_admin(@world);
            self.erc721_combo._emit_contract_uri_updated();
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
            ((*world.dispatcher).is_owner(SELECTORS::GAME_TOKEN, starknet::get_caller_address()))
        }
        fn _caller_is_admin(self: @ContractState, world: @WorldStorage) -> bool {
            (
                self._caller_is_owner(world) ||
                AccountPermissionsTrait::is_admin(world, starknet::get_caller_address())
            )
        }
    }


    //-----------------------------------
    // ERC721ComboHooksTrait
    //
    pub impl ERC721ComboHooksImpl of ERC721ComboComponent::ERC721ComboHooksTrait<ContractState> {
        fn render_contract_uri(self: @ERC721ComboComponent::ComponentState<ContractState>) -> Option<ContractMetadata> {
            // https://docs.opensea.io/docs/contract-level-metadata
            let metadata = ContractMetadata {
                name: self.name(),
                symbol: self.symbol(),
                description: constants::METADATA_DESCRIPTION(),
                image: Option::Some(constants::CONTRACT_IMAGE()),
                banner_image: Option::Some(constants::BANNER_IMAGE()),
                featured_image: Option::None,
                external_link: Option::Some(constants::EXTERNAL_LINK()),
                collaborators: Option::None,
            };
            (Option::Some(metadata))
        }

        fn render_token_uri(self: @ERC721ComboComponent::ComponentState<ContractState>, token_id: u256) -> Option<TokenMetadata> {
            let self = self.get_contract(); // get the component's contract state
            let mut world: WorldStorage = self.world_default();
            // attributes and metadata
            let token_info: GameTokenInfo = world.read_model(token_id.low);
            let mut attributes: Span<Attribute> = array![
                Attribute {
                    key: "Act",
                    value: format!("{}", token_info.act_number),
                },
                Attribute {
                    key: "Room",
                    value: token_info.room_name.clone(),
                },
                Attribute {
                    key: "Progress",
                    value: format!("{}%", token_info.progress),
                },
                Attribute {
                    key: "Completed",
                    value: ByteArrayTraitExt::byte_array_from_bool(token_info.completed),
                },
                Attribute {
                    key: "Vitality",
                    value: if GameTokenInfoTrait::is_dead(@world, token_id.low) {"Dead"} else {"Alive"},
                },
            ].span();
            let mut additional_metadata: Span<Attribute> = array![
                Attribute {
                    key: "Seed",
                    value: format!("{}", token_info.seed),
                },
            ].span();
            // https://docs.opensea.io/docs/metadata-standards#metadata-structure
            let metadata = TokenMetadata {
                token_id,
                name: format!("{} #{}", constants::TOKEN_NAME(), token_id.low),
                description: constants::METADATA_DESCRIPTION(),
                image: Option::Some(constants::CONTRACT_IMAGE()),
                image_data: Option::None,
                external_url: Option::Some(constants::EXTERNAL_LINK()), // TODO: format external token link
                background_color: Option::Some(constants::BACKGROUND_COLOR()),
                animation_url: Option::None,
                youtube_url: Option::None,
                attributes: Option::Some(attributes),
                additional_metadata: Option::Some(additional_metadata),
            };
            (Option::Some(metadata))
        }
    }

}
