#[cfg(test)]
mod tests {
    use starknet::ContractAddress;
    use dojo::{
        // world::{WorldStorage},
        model::{ModelStorage},
    };
    use lore::{
        systems::{
            designer::{IDesignerDispatcherTrait},
            prompt::{IPromptDispatcherTrait},
            game_token::{IGameTokenDispatcherTrait},
            trail_token::{ITrailTokenDispatcherTrait},
        },
        models::{
            entity::{Entity},
            game_token_info::{GameTokenInfo, GameTokenInfoTrait, PlayerGame, PlayerGameImpl},
            player::{Player, PlayerImpl},
            area::{Area, AreaComponent},
            hub::{Hub, HubImpl},
        },
        lib::{
            access::{AccessTrait, ROLES},
        },
        constants::token_metadata::{game_metadata},
        tests::{
            helpers,
            helpers::{ZERO, OWNER, OTHER},
        },
    };

    fn _mint_token(ref sys: helpers::HelperSystems, recipient: ContractAddress) {
        helpers::set_caller(recipient);
        sys.game_token.create_game(recipient);
    }

    #[test]
    fn test_token_initialized() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        println!("GAME TOKEN NAME: [{}]", sys.game_token.name());
        println!("GAME TOKEN SYMBOL: [{}]", sys.game_token.symbol());
        assert_ne!(sys.game_token.name(), "", "empty name");
        assert_ne!(sys.game_token.symbol(), "", "empty symbol");
        assert_eq!(sys.game_token.name(), game_metadata::TOKEN_NAME(), "wrong name");
        assert_eq!(sys.game_token.symbol(), game_metadata::TOKEN_SYMBOL(), "wrong symbol");
    }


    #[test]
    fn test_token_token_uri() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        _mint_token(ref sys, OWNER());
        let uri: ByteArray = sys.game_token.token_uri(1);
        assert_gt!(uri.len(), 1000, "token_uri.len()");
        println!("GAME TOKEN URI: [{}]", uri);
    }


    //-----------------------------------
    // admin functions
    //

    #[test]
    fn test_token_set_minting_paused() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        helpers::set_caller(OWNER());
        assert_eq!(sys.game_token.is_minting_paused(), false, "default");
        sys.game_token.set_minting_paused(true);
        assert_eq!(sys.game_token.is_minting_paused(), true, "set_minting_paused(true)");
        sys.game_token.set_minting_paused(false);
        assert_eq!(sys.game_token.is_minting_paused(), false, "set_minting_paused(false)");
    }

    #[test]
    #[should_panic(expected: ('ERC721Combo: minting is paused','ENTRYPOINT_FAILED'))]
    fn test_token_set_minting_paused_mint() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        helpers::set_caller(OWNER());
        sys.game_token.set_minting_paused(true);
        assert_eq!(sys.game_token.is_minting_paused(), true, "set_minting_paused(true)");
        _mint_token(ref sys, OWNER());
    }

    #[test]
    #[should_panic(expected: ('ORUG: Invalid caller','ENTRYPOINT_FAILED'))]
    fn test_token_set_minting_paused_not_admin() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        helpers::set_caller(OTHER());
        sys.game_token.set_minting_paused(true);
    }


    //-----------------------------------
    // minting
    //

    #[test]
    fn test_token_mint() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();

        _mint_token(ref sys, OWNER());
        assert_eq!(sys.game_token.total_supply(), 1, "token_1");
        assert_eq!(sys.game_token.owner_of(1), OWNER(), "token_1");
        assert_eq!(sys.game_token.balance_of(OWNER()), 1, "token_1");
        let token_info_1: GameTokenInfo = sys.world.read_model(1);
        assert_ne!(token_info_1.seed, 0, "token_1");
        assert_eq!(token_info_1.act_number, 1, "token_1");
        assert_eq!(sys.world.current_game_progress(1), 0, "token_1");
        assert!(!sys.world.has_finished_game(1), "token_1");
        let player_game: PlayerGame = sys.world.read_model(OWNER());
        assert_eq!(player_game.current_game_id, 1, "token_1");

        _mint_token(ref sys, OTHER());
        assert_eq!(sys.game_token.total_supply(), 2, "token_2");
        assert_eq!(sys.game_token.owner_of(2), OTHER(), "token_2");
        assert_eq!(sys.game_token.balance_of(OTHER()), 1, "token_2");
        let token_info_2: GameTokenInfo = sys.world.read_model(2);
        assert_ne!(token_info_2.seed, 0, "token_2");
        assert_ne!(token_info_2.seed, token_info_1.seed, "token_2");
        assert_eq!(token_info_2.act_number, 1, "token_2");
        assert_eq!(sys.world.current_game_progress(2), 0, "token_2");
        assert!(!sys.world.has_finished_game(2), "token_2");
        let player_game: PlayerGame = sys.world.read_model(OTHER());
        assert_eq!(player_game.current_game_id, 2, "token_2");

        _mint_token(ref sys, OWNER());
        assert_eq!(sys.game_token.total_supply(), 3, "token_3");
        assert_eq!(sys.game_token.owner_of(3), OWNER(), "token_3");
        assert_eq!(sys.game_token.balance_of(OWNER()), 2, "token_3");
        let token_info_3: GameTokenInfo = sys.world.read_model(3);
        assert_ne!(token_info_3.seed, token_info_1.seed, "token_3");
        assert_ne!(token_info_3.seed, token_info_2.seed, "token_3");
        assert_ne!(token_info_3.seed, 0, "token_3");
        assert_eq!(token_info_3.act_number, 1, "token_3");
        assert_eq!(sys.world.current_game_progress(3), 0, "token_3");
        assert!(!sys.world.has_finished_game(3), "token_3");
        let player_game: PlayerGame = sys.world.read_model(OWNER());
        assert_eq!(player_game.current_game_id, 3, "token_3");
    }

    #[test]
    fn test_token_enter_hub_becomes_editor() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        PlayerImpl::caller_as_player(ref sys.world, OWNER(), 0);
        // create an end room
        let room_entity_1: @Entity = @helpers::create_new_entity(1, "Room 1");
        let mut area_1: Area = AreaComponent::add_component(ref sys.world, *room_entity_1.inst);
        sys.world.write_model(room_entity_1);
        area_1.progress_percentage = 20;
        sys.world.write_model(@area_1);
        // Add a Hub -- grants access to editor
        let mut hub_1: Hub = HubImpl::add_component(ref sys.world, *room_entity_1.inst);
        sys.world.write_model(@hub_1);
        // mint game token
        let game_id_1: u128 = 1;
        helpers::set_caller(OTHER());
        sys.prompt.prompt("", Option::None);
        assert_eq!(sys.game_token.owner_of(game_id_1.into()), OTHER(), "owner_of()");
        // set editor
        helpers::set_caller(OWNER());
        assert!(!sys.world.is_player_editor(OTHER()), "!editor");
        // finish game -- granted editor
        GameTokenInfoTrait::set_room(ref sys.world, game_id_1, *room_entity_1.inst);
        assert!(!GameTokenInfoTrait::has_finished_game(@sys.world, game_id_1), "has_finished_game");
        assert!(sys.world.is_player_editor(OTHER()), "editor");
        assert!(sys.designer.is_editor(OTHER()), "editor");
        assert!(sys.designer.has_role(ROLES::EDITOR, OTHER()), "editor");
        assert!(sys.designer.has_role(*room_entity_1.inst, OTHER()), "editor");
        // can mint trail..
        helpers::set_caller(OTHER());
        let trail_id: u128 = sys.trail_token.create_trail(OTHER());
        // can edit...
        helpers::set_caller(OTHER());
        let mut trail_entity: Entity = helpers::create_new_entity(11, "entity_1");
        trail_entity.trail_id = trail_id;
        sys.designer.create_entity(array![trail_entity]);
    }

    #[test]
    fn test_token_finished_game() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        PlayerImpl::caller_as_player(ref sys.world, OWNER(), 0);
        // create an end room
        let room_entity_1: @Entity = @helpers::create_new_entity(1, "Room 1");
        let mut area_1: Area = AreaComponent::add_component(ref sys.world, *room_entity_1.inst);
        sys.world.write_model(room_entity_1);
        area_1.progress_percentage = 100; // finishes game
        sys.world.write_model(@area_1);
        // mint game token
        let game_id_1: u128 = 1;
        helpers::set_caller(OTHER());
        sys.prompt.prompt("", Option::None);
        assert_eq!(sys.game_token.owner_of(game_id_1.into()), OTHER(), "owner_of()");
        // set editor
        helpers::set_caller(OWNER());
        assert!(!sys.world.is_player_editor(OTHER()), "!editor");
        // finishes game
        GameTokenInfoTrait::set_room(ref sys.world, game_id_1, *room_entity_1.inst);
        assert!(GameTokenInfoTrait::has_finished_game(@sys.world, game_id_1), "has_finished_game");
        assert!(!sys.world.is_player_editor(OTHER()), "editor");
    }

    #[test]
    fn test_prompt_mint_game_ok() {
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
        assert_eq!(sys.game_token.total_supply(), 1, "total_supply()");
        assert_eq!(sys.game_token.owner_of(game_id_1.into()), helpers::PLAYER_1, "owner_of()");
        // is current game of player
        assert_eq!(PlayerGameImpl::current_game_id(@sys.world, helpers::PLAYER_1), game_id_1, "player_1.current_game_id");
        // player was created
        let player_1: Player = PlayerImpl::get_player(@sys.world, game_id_1).unwrap();
        story_len_1 += 1;
        assert_eq!(player_1.address, helpers::PLAYER_1, "player_1.address");
        assert_eq!(player_1.game_id, game_id_1, "player_1.game_id");
// helpers::print_game_story_last_line(@sys.world, game_id_1);
        assert_eq!(helpers::game_story_len(@sys.world, game_id_1), story_len_1, "player_1.story");
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id_1), "You feel light, and shiny, in the head", "player_1.story");
        // player zero was created too
        let player_0: Player = PlayerImpl::get_player(@sys.world, 0).unwrap();
        assert_eq!(player_0.address, ZERO(), "player_0.address");
        assert_eq!(player_0.game_id, 0, "player_0.game_id");
        // system command: g_game_id
        sys.prompt.prompt("g_game_id", Option::None);
        story_len_1 += 2;
// helpers::print_game_story_last_line(@sys.world, game_id_1);
        assert_eq!(helpers::game_story_len(@sys.world, game_id_1), story_len_1, "g_game_id 1");
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id_1), "+sys+game-1");
        //
        // player_2 say ask to create a game...
        let game_id_2: u128 = 2;
        let mut story_len_2: u32 = 0;
        helpers::set_caller(helpers::PLAYER_2);
        sys.prompt.prompt("", Option::None);
        story_len_2 += 1;
        // game was minted
        assert_eq!(sys.game_token.total_supply(), 2, "total_supply()");
        assert_eq!(sys.game_token.owner_of(game_id_2.into()), helpers::PLAYER_2, "owner_of()");
        // player token room was initialized
        let token_info_2: GameTokenInfo = sys.world.read_model(game_id_2);
        assert_eq!(token_info_2.room_name, room_entity.name.clone(), "token room name");
        // is current game of player
        assert_eq!(PlayerGameImpl::current_game_id(@sys.world, helpers::PLAYER_2), game_id_2, "player_2.current_game_id");
        // player was created
        let player_2: Player = PlayerImpl::get_player(@sys.world, game_id_2).unwrap();
        assert_eq!(player_2.address, helpers::PLAYER_2, "player_2.address");
        assert_eq!(player_2.game_id, game_id_2, "player_2.game_id");
// helpers::print_game_story_last_line(@sys.world, game_id_2);
        assert_eq!(helpers::game_story_len(@sys.world, game_id_2), story_len_2, "player_2.story");
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id_2), "You feel light, and shiny, in the head", "player_2.story");
        // assert_eq!(helpers::game_story_last_line(@sys.world, game_id_2), "+sys+game-2", "player_2.story");
        // system command: g_game_id
        sys.prompt.prompt("g_game_id", Option::None);
        story_len_2 += 2;
// helpers::print_game_story_last_line(@sys.world, game_id_2);
        assert_eq!(helpers::game_story_len(@sys.world, game_id_2), story_len_2, "g_game_id 2");
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id_2), "+sys+game-2");
        //
        // player 1 can play their own game by id...
        helpers::set_caller(helpers::PLAYER_1);
        sys.prompt.prompt("hello", Option::Some(game_id_1));
        story_len_1 += 3;
        // no new game was minted
        assert_eq!(sys.game_token.total_supply(), 2, "total_supply()");
        // more story was added
        assert_eq!(helpers::game_story_len(@sys.world, game_id_1), story_len_1, "said");
        //
        // ADMIN can play their someone else's game for debugging
        helpers::set_caller(OWNER());
        sys.prompt.prompt("hello", Option::Some(game_id_2));
        story_len_2 += 3;
        // no new game was minted
        assert_eq!(sys.game_token.total_supply(), 2, "total_supply()");
        // more story was added
        assert_eq!(helpers::game_story_len(@sys.world, game_id_2), story_len_2, "said");
    }

    #[test]
    fn test_prompt_create_load_game_ok() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        // initialize player singleton
        PlayerImpl::caller_as_player(ref sys.world, OWNER(), 0);
        let room_entity: @Entity = @helpers::create_new_entity(700111, "Room 700111");
        sys.world.write_model(room_entity);
        //
        // player_1 say anything... (will create a game)
        let game_id_1: u128 = 1;
        helpers::set_caller(helpers::PLAYER_1);
        sys.prompt.prompt("", Option::None);
        // game was minted
        assert_eq!(sys.game_token.total_supply(), 1, "total_supply()");
        assert_eq!(sys.game_token.owner_of(game_id_1.into()), helpers::PLAYER_1, "owner_of()");
        // is current game of player
        assert_eq!(PlayerGameImpl::current_game_id(@sys.world, helpers::PLAYER_1), game_id_1, "current_game_id = 1");
        // player was created
        let player_1: Player = PlayerImpl::get_player(@sys.world, game_id_1).unwrap();
        assert_eq!(player_1.address, helpers::PLAYER_1, "player_1.address");
        assert_eq!(player_1.game_id, game_id_1, "player_1.game_id");
        // build some story...
        sys.prompt.prompt("hello", Option::None);
        let story_len_1: u32 = helpers::game_story_len(@sys.world, game_id_1);
        assert_gt!(story_len_1, 1, "game_1.story");
        //
        // create a new game...
        let game_id_2: u128 = 2;
        sys.prompt.prompt("g_create_game", Option::None);
        // game was minted
        assert_eq!(sys.game_token.total_supply(), 2, "total_supply()");
        assert_eq!(sys.game_token.owner_of(game_id_2.into()), helpers::PLAYER_1, "owner_of()");
        // is current game of player
        assert_eq!(PlayerGameImpl::current_game_id(@sys.world, helpers::PLAYER_1), game_id_2, "current_game_id = 2");
        // player was created
        let player_2: Player = PlayerImpl::get_player(@sys.world, game_id_2).unwrap();
        assert_eq!(player_2.address, helpers::PLAYER_1, "player_2.address");
        assert_eq!(player_2.game_id, game_id_2, "player_2.game_id");
        // clean story...
        let story_len_2: u32 = helpers::game_story_len(@sys.world, game_id_2);
        assert_eq!(story_len_2, 1, "game_2.story");
        assert_lt!(story_len_2, story_len_1, "game_2.story");
        // buil story...
        sys.prompt.prompt("hello", Option::None);
        sys.prompt.prompt("hello", Option::None);
        let story_len_2: u32 = helpers::game_story_len(@sys.world, game_id_2);
        assert_gt!(story_len_2, story_len_1, "story_len_2 > story_len_1");
        //
        // switch to game 1...
        sys.prompt.prompt("g_load_game 1", Option::None);
        assert_eq!(PlayerGameImpl::current_game_id(@sys.world, helpers::PLAYER_1), game_id_1, "current_game_id = 1 (loaded)");
        sys.prompt.prompt("hello", Option::None);
        sys.prompt.prompt("hello", Option::None);
        let story_len_1: u32 = helpers::game_story_len(@sys.world, game_id_1);
        assert_gt!(story_len_1, story_len_2, "story_len_1 > story_len_2");
        //
        // switch to game 2...
        sys.prompt.prompt("g_load_game 2", Option::None);
        assert_eq!(PlayerGameImpl::current_game_id(@sys.world, helpers::PLAYER_1), game_id_2, "current_game_id = 2 (loaded)");
        sys.prompt.prompt("hello", Option::None);
        sys.prompt.prompt("hello", Option::None);
        let story_len_2: u32 = helpers::game_story_len(@sys.world, game_id_2);
        assert_gt!(story_len_2, story_len_1, "story_len_2 > story_len_1 (2)");
    }

    #[test]
    #[should_panic(expected: ('PROMPT: Not your game','ENTRYPOINT_FAILED'))]
    fn test_prompt_unknown_game() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        //
        // player_1 say something...
        helpers::set_caller(helpers::PLAYER_1);
        sys.prompt.prompt("", Option::Some(1212));
    }

    #[test]
    #[should_panic(expected: ('PROMPT: Not your game','ENTRYPOINT_FAILED'))]
    fn test_prompt_not_your_game() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        // initialize player singleton
        PlayerImpl::caller_as_player(ref sys.world, OWNER(), 0);
        //
        // player_1 say something...
        let game_id_1: u128 = 1;
        helpers::set_caller(helpers::PLAYER_1);
        sys.prompt.prompt("", Option::None);
        assert_eq!(sys.game_token.total_supply(), 1, "total_supply()");
        assert_eq!(sys.game_token.owner_of(game_id_1.into()), helpers::PLAYER_1, "owner_of()");
        //
        // player_2 tries to play player_1's game...
        helpers::set_caller(helpers::PLAYER_2);
        sys.prompt.prompt("", Option::Some(game_id_1));
    }

    #[test]
    fn test_prompt_game_zero_ok() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        // initialize player singleton
        PlayerImpl::caller_as_player(ref sys.world, OWNER(), 0);
        //
        // owner say something...
        let game_id_0: u128 = 0;
        helpers::set_caller(OWNER());
        sys.prompt.prompt("", Option::Some(game_id_0));
        // no game was minted
        assert_eq!(sys.game_token.total_supply(), 0, "total_supply()");
        // player zero was created
        let player_0: Player = PlayerImpl::get_player(@sys.world, 0).unwrap();
        assert_eq!(player_0.address, ZERO(), "player_0.address");
        assert_eq!(player_0.game_id, 0, "player_0.game_id");
        // system command: g_game_id
        sys.prompt.prompt("g_game_id", Option::Some(game_id_0));
// helpers::print_game_story_last_line(@sys.world, game_id_0);
        assert_eq!(helpers::game_story_len(@sys.world, game_id_0), 3, "said");
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id_0), "+sys+game-0");
    }

    #[test]
    #[should_panic(expected: ('PROMPT: Not admin','ENTRYPOINT_FAILED'))]
    fn test_prompt_game_zero_not_editor() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        // initialize player singleton
        PlayerImpl::caller_as_player(ref sys.world, OWNER(), 0);
        //
        // player_1 say something...
        helpers::set_caller(OTHER());
        sys.prompt.prompt("hello", Option::Some(0));
    }
}
