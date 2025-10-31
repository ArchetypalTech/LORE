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
    fn set_minting_paused(ref self: TState, is_paused: bool);
    fn update_token_metadata(ref self: TState, token_id: u256);
    fn update_tokens_metadata(ref self: TState, from_token_id: u256, to_token_id: u256);
    fn update_contract_metadata(ref self: TState);
}

#[starknet::interface]
pub trait IGameTokenPublic<TState> {
    fn create_game(ref self: TState, recipient: ContractAddress) -> u128;
    // fn burn(ref self: TState, token_id: u256);
    // admin
    fn set_minting_paused(ref self: TState, is_paused: bool);
    fn update_token_metadata(ref self: TState, token_id: u256);
    fn update_tokens_metadata(ref self: TState, from_token_id: u256, to_token_id: u256);
    fn update_contract_metadata(ref self: TState);
    fn create_trophies(ref self: TState);
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
    use achievement::components::achievable::AchievableComponent;
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: ERC721ComboComponent, storage: erc721_combo, event: ERC721ComboEvent);
    component!(path: AchievableComponent, storage: achievable, event: AchievableEvent);
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;
    impl ERC721ComboInternalImpl = ERC721ComboComponent::InternalImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721ComboMixinImpl = ERC721ComboComponent::ERC721ComboMixinImpl<ContractState>;
    impl AchievableInternalImpl = AchievableComponent::InternalImpl<ContractState>;
    #[storage]
    struct Storage {
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        erc721_combo: ERC721ComboComponent::Storage,
        #[substorage(v0)]
        achievable: AchievableComponent::Storage,
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
        #[flat]
        AchievableEvent: AchievableComponent::Event,
    }
    //
    // ERC721 end
    //-----------------------------------

    use lore::models::{
        game_token_info::{
            GameTokenInfo, GameTokenInfoTrait,
            PlayerGameTrait,
            GameCreatedEvent,
        },
        trail_token_info::{
            TrailProgressTrait,
        },
    };
    use lore::constants::token_metadata::{orug_metadata, game_metadata};
    use lore::lib::{
        dns::{SELECTORS},
        access::{AccessTrait},
        utils::{HashImpl, ByteArrayTraitExt},
        trophies::{Trophy, TrophyTrait, TROPHIES},
    };
    use nft_combo::utils::renderer::{Attribute};

    mod Errors {
        pub const INVALID_CALLER: felt252   = 'ORUG: Invalid caller';
    }

    fn dojo_init(ref self: ContractState) {
        // initialize ERC721
        self.erc721_combo.initializer(
            game_metadata::TOKEN_NAME(),
            game_metadata::TOKEN_SYMBOL(),
            Option::None, // use hooks
            Option::None, // use hooks
            Option::None, // infinite supply
        );

        // create trophies/achievements
        let mut world: WorldStorage = self.world_default();
        self._create_trophies(ref world);
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
            });

            // switch to this game
            PlayerGameTrait::switch_game_id(ref world, recipient, token_id);

            // event...
            world.emit_event(@GameCreatedEvent{
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
        fn set_minting_paused(ref self: ContractState, is_paused: bool) {
            let world: WorldStorage = self.world_default();
            self._assert_caller_is_admin(@world);
            self.erc721_combo._set_minting_paused(is_paused);
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
        fn create_trophies(ref self: ContractState) {
            let mut world: WorldStorage = self.world_default();
            self._assert_caller_is_admin(@world);
            self._create_trophies(ref world);
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
                world.is_player_admin(starknet::get_caller_address())
            )
        }
        
        fn _create_trophies(ref self: ContractState, ref world: WorldStorage) {
            let mut trophy_id: u8 = 1;
            while (trophy_id <= TROPHIES::COUNT) {
                let trophy: Trophy = trophy_id.into();
                self.achievable.create(
                    world,
                    id: trophy.identifier(),
                    hidden: trophy.hidden(),
                    index: trophy.index(),
                    points: trophy.points(),
                    start: trophy.start(),
                    end: trophy.end(),
                    group: trophy.group(),
                    icon: trophy.icon(),
                    title: trophy.title(),
                    description: trophy.description(),
                    tasks: trophy.tasks(),
                    data: trophy.data(),
                );
                trophy_id += 1;
            }
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
            let game_id: u128 = token_id.low;
            let token_info: GameTokenInfo = world.read_model(game_id);
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
                    value: format!("{}%25", world.current_trail_progress(token_info.game_id, 0)),
                },
                Attribute {
                    key: "Completed",
                    value: ByteArrayTraitExt::byte_array_from_bool(world.has_finished_trail(token_info.game_id, 0)),
                },
                Attribute {
                    key: "Vitality",
                    value: if GameTokenInfoTrait::is_dead(@world, game_id) {"Dead"} else {"Alive"},
                },
            ].span();
            let mut additional_metadata: Span<Attribute> = array![
                Attribute {
                    key: "Seed",
                    value: format!("0x{:x}", token_info.seed),
                },
            ].span();
            // https://docs.opensea.io/docs/metadata-standards#metadata-structure
            let metadata: TokenMetadata = TokenMetadata {
                token_id,
                name: format!("{} #{}", game_metadata::TOKEN_NAME(), game_id),
                description: orug_metadata::DESCRIPTION(),
                image: Option::Some(orug_metadata::CONTRACT_IMAGE()),
                image_data: Option::None,
                external_url: Option::Some(orug_metadata::EXTERNAL_LINK()), // TODO: format external token link
                background_color: Option::Some(orug_metadata::BACKGROUND_COLOR()),
                animation_url: Option::None,
                youtube_url: Option::None,
                attributes: Option::Some(attributes),
                additional_metadata: Option::Some(additional_metadata),
            };
            (Option::Some(metadata))
        }
    }

}
