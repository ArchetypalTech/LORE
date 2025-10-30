#[cfg(test)]
mod tests {
    use starknet::ContractAddress;
    use dojo::{
        // world::{WorldStorage},
        model::{ModelStorage},
    };
    use lore::{
        systems::{
            trail_token::{ITrailTokenDispatcher, ITrailTokenDispatcherTrait},
            designer::{IDesignerDispatcherTrait},
            prompt::{IPromptDispatcherTrait},
        },
        models::{
            entity::{Entity},
            trail_token_info::{TrailTokenInfo, TrailTokenInfoTrait},
            player::{Player, PlayerImpl},
            area::{Area, AreaComponent},
        },
        lib::{
            access::{AccessTrait},
        },
        constants::token_metadata::{trail_metadata},
        tests::{
            helpers,
            helpers::{ZERO, OWNER, OTHER},
        },
    };

    fn _mint_token(ref sys: helpers::HelperSystems, recipient: ContractAddress) {
        helpers::set_caller(recipient);
        sys.trail_token.create_trail(recipient);
    }

    #[test]
    fn test_token_initialized() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        println!("TOKEN NAME: [{}]", sys.trail_token.name());
        println!("TOKEN SYMBOL: [{}]", sys.trail_token.symbol());
        assert_ne!(sys.trail_token.name(), "", "empty name");
        assert_ne!(sys.trail_token.symbol(), "", "empty symbol");
        assert_eq!(sys.trail_token.name(), trail_metadata::TOKEN_NAME(), "wrong name");
        assert_eq!(sys.trail_token.symbol(), trail_metadata::TOKEN_SYMBOL(), "wrong symbol");
    }

    #[test]
    fn test_token_mint() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();

        _mint_token(ref sys, OWNER());
        assert_eq!(sys.trail_token.total_supply(), 1, "total_supply()");
        assert_eq!(sys.trail_token.owner_of(1), OWNER(), "owner_of()");
        assert_eq!(sys.trail_token.balance_of(OWNER()), 1, "balance_of()");
        let token_info_1: TrailTokenInfo = sys.world.read_model(1);
        assert_ne!(token_info_1.seed, 0, "token_info.seed");

        _mint_token(ref sys, OTHER());
        assert_eq!(sys.trail_token.total_supply(), 2, "total_supply()");
        assert_eq!(sys.trail_token.owner_of(2), OTHER(), "owner_of(2)");
        assert_eq!(sys.trail_token.balance_of(OTHER()), 1, "balance_of())");
        let token_info_2: TrailTokenInfo = sys.world.read_model(2);
        assert_ne!(token_info_2.seed, 0, "token_info.seed");
        assert_ne!(token_info_2.seed, token_info_1.seed, "token_info.seed");

        _mint_token(ref sys, OWNER());
        assert_eq!(sys.trail_token.total_supply(), 3, "total_supply()");
        assert_eq!(sys.trail_token.owner_of(3), OWNER(), "owner_of()");
        assert_eq!(sys.trail_token.balance_of(OWNER()), 2, "balance_of()");
        let token_info_3: TrailTokenInfo = sys.world.read_model(3);
        assert_ne!(token_info_3.seed, token_info_1.seed, "token_info.seed");
        assert_ne!(token_info_3.seed, token_info_2.seed, "token_info.seed");
        assert_ne!(token_info_3.seed, 0, "token_info.seed");
    }

    #[test]
    fn test_token_token_uri() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        _mint_token(ref sys, OWNER());
        let uri: ByteArray = sys.trail_token.token_uri(1);
        assert_gt!(uri.len(), 1000, "token_uri.len()");
        println!("TOKEN URI: [{}]", uri);
    }

    #[test]
    fn test_token_set_minting_paused() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        helpers::set_caller(OWNER());
        assert_eq!(sys.trail_token.is_minting_paused(), false, "default");
        sys.trail_token.set_minting_paused(true);
        assert_eq!(sys.trail_token.is_minting_paused(), true, "set_minting_paused(true)");
        sys.trail_token.set_minting_paused(false);
        assert_eq!(sys.trail_token.is_minting_paused(), false, "set_minting_paused(false)");
    }

    #[test]
    #[should_panic(expected: ('ERC721Combo: minting is paused','ENTRYPOINT_FAILED'))]
    fn test_token_set_minting_paused_mint() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        helpers::set_caller(OWNER());
        sys.trail_token.set_minting_paused(true);
        assert_eq!(sys.trail_token.is_minting_paused(), true, "set_minting_paused(true)");
        _mint_token(ref sys, OWNER());
    }

    #[test]
    #[should_panic(expected: ('ORUG: Invalid caller','ENTRYPOINT_FAILED'))]
    fn test_token_set_minting_paused_not_admin() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        helpers::set_caller(OTHER());
        sys.trail_token.set_minting_paused(true);
    }

    #[test]
    fn test_prompt_mint_trail_ok() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        // initialize player singleton
        PlayerImpl::caller_as_player(ref sys.world, OWNER(), 0);
        let room_entity: @Entity = @helpers::create_new_entity(700111, "Room 700111");
        sys.world.write_model(room_entity);
        //
        // player_1 say anything... (will create a game)
        let game_id_1: u128 = 1;
        let mut story_len_1: u32 = 0;
        helpers::set_caller(helpers::PLAYER_1);
        sys.prompt.prompt("", Option::None);
        // game was minted
        assert_eq!(sys.trail_token.total_supply(), 1, "total_supply()");
        assert_eq!(sys.trail_token.owner_of(game_id_1.into()), helpers::PLAYER_1, "owner_of()");
        // player was created
        let player_1: Player = PlayerImpl::get_player(@sys.world, game_id_1).unwrap();
        story_len_1 += 1;
        assert_eq!(player_1.address, helpers::PLAYER_1, "player_1.address");
        assert_eq!(player_1.game_id, game_id_1, "player_1.game_id");
// helpers::print_player_story_last_line(@sys.world, game_id_1);
        assert_eq!(helpers::player_story_len(@sys.world, game_id_1), story_len_1, "player_1.story");
        assert_eq!(helpers::player_story_last_line(@sys.world, game_id_1), "You feel light, and shiny, in the head", "player_1.story");
        // player zero was created too
        let player_0: Player = PlayerImpl::get_player(@sys.world, 0).unwrap();
        assert_eq!(player_0.address, ZERO(), "player_0.address");
        assert_eq!(player_0.game_id, 0, "player_0.game_id");
        // system command: g_game_id
        sys.prompt.prompt("g_game_id", Option::None);
        story_len_1 += 2;
// helpers::print_player_story_last_line(@sys.world, game_id_1);
        assert_eq!(helpers::player_story_len(@sys.world, game_id_1), story_len_1, "g_game_id 1");
        assert_eq!(helpers::player_story_last_line(@sys.world, game_id_1), "+sys+game-1");
        //
        // player_2 say ask to create a game...
        let game_id_2: u128 = 2;
        let mut story_len_2: u32 = 0;
        helpers::set_caller(helpers::PLAYER_2);
        sys.prompt.prompt("", Option::None);
        story_len_2 += 1;
        // game was minted
        assert_eq!(sys.trail_token.total_supply(), 2, "total_supply()");
        assert_eq!(sys.trail_token.owner_of(game_id_2.into()), helpers::PLAYER_2, "owner_of()");
        // player was created
        let player_2: Player = PlayerImpl::get_player(@sys.world, game_id_2).unwrap();
        assert_eq!(player_2.address, helpers::PLAYER_2, "player_2.address");
        assert_eq!(player_2.game_id, game_id_2, "player_2.game_id");
// helpers::print_player_story_last_line(@sys.world, game_id_2);
        assert_eq!(helpers::player_story_len(@sys.world, game_id_2), story_len_2, "player_2.story");
        assert_eq!(helpers::player_story_last_line(@sys.world, game_id_2), "You feel light, and shiny, in the head", "player_2.story");
        // assert_eq!(helpers::player_story_last_line(@sys.world, game_id_2), "+sys+game-2", "player_2.story");
        // system command: g_game_id
        sys.prompt.prompt("g_game_id", Option::None);
        story_len_2 += 2;
// helpers::print_player_story_last_line(@sys.world, game_id_2);
        assert_eq!(helpers::player_story_len(@sys.world, game_id_2), story_len_2, "g_game_id 2");
        assert_eq!(helpers::player_story_last_line(@sys.world, game_id_2), "+sys+game-2");
        //
        // player 1 can play their own game by id...
        helpers::set_caller(helpers::PLAYER_1);
        sys.prompt.prompt("hello", Option::Some(game_id_1));
        story_len_1 += 3;
        // no new game was minted
        assert_eq!(sys.trail_token.total_supply(), 2, "total_supply()");
        // more story was added
        assert_eq!(helpers::player_story_len(@sys.world, game_id_1), story_len_1, "said");
        //
        // ADMIN can play their someone else's game for debugging
        helpers::set_caller(OWNER());
        sys.prompt.prompt("hello", Option::Some(game_id_2));
        story_len_2 += 3;
        // no new game was minted
        assert_eq!(sys.trail_token.total_supply(), 2, "total_supply()");
        // more story was added
        assert_eq!(helpers::player_story_len(@sys.world, game_id_2), story_len_2, "said");
    }

}
