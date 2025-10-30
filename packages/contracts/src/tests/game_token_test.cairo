#[cfg(test)]
mod tests {
    use starknet::ContractAddress;
    use dojo::{
        // world::{WorldStorage},
        model::{ModelStorage},
    };
    use lore::{
        systems::{
            game_token::{IGameTokenDispatcher, IGameTokenDispatcherTrait},
            designer::{IDesignerDispatcherTrait},
            prompt::{IPromptDispatcherTrait},
        },
        models::{
            entity::{Entity},
            token_config::{GameTokenInfo, GameTokenInfoTrait, PlayerAccount, PlayerAccountImpl},
            player::{Player, PlayerImpl},
            area::{Area, AreaComponent},
        },
        lib::{
            access::{AccessTrait},
        },
        constants::{token as constants},
        tests::{
            helpers,
            helpers::{ZERO, OWNER, OTHER},
        },
    };

    fn _mint_token(token: IGameTokenDispatcher, recipient: ContractAddress) {
        helpers::set_caller(recipient);
        token.create_game(recipient);
    }

    #[test]
    fn test_token_initialized() {
        let (_, _, _, token, _, _) = helpers::setup_core();
        println!("TOKEN NAME: [{}]", token.name());
        println!("TOKEN SYMBOL: [{}]", token.symbol());
        assert_ne!(token.name(), "", "empty name");
        assert_ne!(token.symbol(), "", "empty symbol");
        assert_eq!(token.name(), constants::TOKEN_NAME(), "wrong name");
        assert_eq!(token.symbol(), constants::TOKEN_SYMBOL(), "wrong symbol");
    }

    #[test]
    fn test_token_mint() {
        let (mut world, _, _, token, _, _) = helpers::setup_core();

        _mint_token(token, OWNER());
        assert_eq!(token.total_supply(), 1, "total_supply()");
        assert_eq!(token.owner_of(1), OWNER(), "owner_of()");
        assert_eq!(token.balance_of(OWNER()), 1, "balance_of()");
        let token_info_1: GameTokenInfo = world.read_model(1);
        assert_ne!(token_info_1.seed, 0, "token_info.seed");
        assert_eq!(token_info_1.act_number, 1, "token_info.act_number");
        assert_eq!(token_info_1.progress, 0, "token_info.progress");
        assert_eq!(token_info_1.completed, false, "token_info.completed");
        let account: PlayerAccount = world.read_model(OWNER());
        assert_eq!(account.current_game_id, 1, "account.current_game_id");

        _mint_token(token, OTHER());
        assert_eq!(token.total_supply(), 2, "total_supply()");
        assert_eq!(token.owner_of(2), OTHER(), "owner_of(2)");
        assert_eq!(token.balance_of(OTHER()), 1, "balance_of())");
        let token_info_2: GameTokenInfo = world.read_model(2);
        assert_ne!(token_info_2.seed, 0, "token_info.seed");
        assert_ne!(token_info_2.seed, token_info_1.seed, "token_info.seed");
        assert_eq!(token_info_2.act_number, 1, "token_info.act_number");
        assert_eq!(token_info_2.progress, 0, "token_info.progress");
        assert_eq!(token_info_2.completed, false, "token_info.completed");
        let account: PlayerAccount = world.read_model(OTHER());
        assert_eq!(account.current_game_id, 2, "account.current_game_id");

        _mint_token(token, OWNER());
        assert_eq!(token.total_supply(), 3, "total_supply()");
        assert_eq!(token.owner_of(3), OWNER(), "owner_of()");
        assert_eq!(token.balance_of(OWNER()), 2, "balance_of()");
        let token_info_3: GameTokenInfo = world.read_model(3);
        assert_ne!(token_info_3.seed, token_info_1.seed, "token_info.seed");
        assert_ne!(token_info_3.seed, token_info_2.seed, "token_info.seed");
        assert_ne!(token_info_3.seed, 0, "token_info.seed");
        assert_eq!(token_info_3.act_number, 1, "token_info.act_number");
        assert_eq!(token_info_3.progress, 0, "token_info.progress");
        assert_eq!(token_info_3.completed, false, "token_info.completed");
        let account: PlayerAccount = world.read_model(OWNER());
        assert_eq!(account.current_game_id, 3, "account.current_game_id");
    }

    #[test]
    fn test_token_token_uri() {
        let (mut _world, _, _, token, _, _) = helpers::setup_core();
        _mint_token(token, OWNER());
        let uri: ByteArray = token.token_uri(1);
        assert_gt!(uri.len(), 1000, "token_uri.len()");
        println!("TOKEN URI: [{}]", uri);
    }

    #[test]
    fn test_token_set_minting_paused() {
        let (_, _, _, token, _, _) = helpers::setup_core();
        helpers::set_caller(OWNER());
        assert_eq!(token.is_minting_paused(), false, "default");
        token.set_minting_paused(true);
        assert_eq!(token.is_minting_paused(), true, "set_minting_paused(true)");
        token.set_minting_paused(false);
        assert_eq!(token.is_minting_paused(), false, "set_minting_paused(false)");
    }

    #[test]
    #[should_panic(expected: ('ERC721Combo: minting is paused','ENTRYPOINT_FAILED'))]
    fn test_token_set_minting_paused_mint() {
        let (_, _, _, token, _, _) = helpers::setup_core();
        helpers::set_caller(OWNER());
        token.set_minting_paused(true);
        assert_eq!(token.is_minting_paused(), true, "set_minting_paused(true)");
        _mint_token(token, OWNER());
    }

    #[test]
    #[should_panic(expected: ('ORUG: Invalid caller','ENTRYPOINT_FAILED'))]
    fn test_token_set_minting_paused_not_admin() {
        let (_, _, _, token, _, _) = helpers::setup_core();
        helpers::set_caller(OTHER());
        token.set_minting_paused(true);
    }

    #[test]
    fn test_token_winner_becomes_editor() {
        let (mut world, designer, prompt, token, _, _) = helpers::setup_core();
        PlayerImpl::caller_as_player(ref world, OWNER(), 0);
        // create an end room
        let room_entity_1: @Entity = @helpers::create_new_entity(1, "Room 1");
        let mut area_1: Area = AreaComponent::add_component(ref world, *room_entity_1.inst);
        world.write_model(room_entity_1);
        area_1.progress_percentage = 100;
        world.write_model(@area_1);
        // mint game token
        let game_id_1: u128 = 1;
        helpers::set_caller(OTHER());
        prompt.prompt("", Option::None);
        assert_eq!(token.owner_of(game_id_1.into()), OTHER(), "owner_of()");
        // set editor
        helpers::set_caller(OWNER());
        assert!(!AccessTrait::is_editor(@world, OTHER()), "!editor");
        // finish game -- granted editor
        GameTokenInfoTrait::set_room(ref world, game_id_1, *room_entity_1.inst);
        assert!(GameTokenInfoTrait::has_finished_game(@world, game_id_1), "has_finished_game");
        assert!(AccessTrait::is_editor(@world, OTHER()), "editor");
        // can edit...
        helpers::set_caller(OTHER());
        designer.create_entity(array![helpers::create_new_entity(1, "entity_1")]);
    }

    #[test]
    fn test_prompt_mint_game_ok() {
        let (mut world, _, prompt, token, player_address_1, player_address_2) = helpers::setup_core();
        // initialize player singleton
        PlayerImpl::caller_as_player(ref world, OWNER(), 0);
        let room_entity: @Entity = @helpers::create_new_entity(700111, "Room 700111");
        world.write_model(room_entity);
        //
        // player_1 say anything... (will create a game)
        let game_id_1: u128 = 1;
        let mut story_len_1: u32 = 0;
        helpers::set_caller(player_address_1);
        prompt.prompt("", Option::None);
        // game was minted
        assert_eq!(token.total_supply(), 1, "total_supply()");
        assert_eq!(token.owner_of(game_id_1.into()), player_address_1, "owner_of()");
        // is current game of player
        assert_eq!(PlayerAccountImpl::current_game_id(@world, player_address_1), game_id_1, "player_1.current_game_id");
        // player was created
        let player_1: Player = PlayerImpl::get_player(@world, game_id_1).unwrap();
        story_len_1 += 1;
        assert_eq!(player_1.address, player_address_1, "player_1.address");
        assert_eq!(player_1.game_id, game_id_1, "player_1.game_id");
// helpers::print_player_story_last_line(@world, game_id_1);
        assert_eq!(helpers::player_story_len(@world, game_id_1), story_len_1, "player_1.story");
        assert_eq!(helpers::player_story_last_line(@world, game_id_1), "You feel light, and shiny, in the head", "player_1.story");
        // player zero was created too
        let player_0: Player = PlayerImpl::get_player(@world, 0).unwrap();
        assert_eq!(player_0.address, ZERO(), "player_0.address");
        assert_eq!(player_0.game_id, 0, "player_0.game_id");
        // system command: g_game_id
        prompt.prompt("g_game_id", Option::None);
        story_len_1 += 2;
// helpers::print_player_story_last_line(@world, game_id_1);
        assert_eq!(helpers::player_story_len(@world, game_id_1), story_len_1, "g_game_id 1");
        assert_eq!(helpers::player_story_last_line(@world, game_id_1), "+sys+game-1");
        //
        // player_2 say ask to create a game...
        let game_id_2: u128 = 2;
        let mut story_len_2: u32 = 0;
        helpers::set_caller(player_address_2);
        prompt.prompt("", Option::None);
        story_len_2 += 1;
        // game was minted
        assert_eq!(token.total_supply(), 2, "total_supply()");
        assert_eq!(token.owner_of(game_id_2.into()), player_address_2, "owner_of()");
        // player token room was initialized
        let token_info_2: GameTokenInfo = world.read_model(game_id_2);
        assert_eq!(token_info_2.room_name, room_entity.name.clone(), "token room name");
        // is current game of player
        assert_eq!(PlayerAccountImpl::current_game_id(@world, player_address_2), game_id_2, "player_2.current_game_id");
        // player was created
        let player_2: Player = PlayerImpl::get_player(@world, game_id_2).unwrap();
        assert_eq!(player_2.address, player_address_2, "player_2.address");
        assert_eq!(player_2.game_id, game_id_2, "player_2.game_id");
// helpers::print_player_story_last_line(@world, game_id_2);
        assert_eq!(helpers::player_story_len(@world, game_id_2), story_len_2, "player_2.story");
        assert_eq!(helpers::player_story_last_line(@world, game_id_2), "You feel light, and shiny, in the head", "player_2.story");
        // assert_eq!(helpers::player_story_last_line(@world, game_id_2), "+sys+game-2", "player_2.story");
        // system command: g_game_id
        prompt.prompt("g_game_id", Option::None);
        story_len_2 += 2;
// helpers::print_player_story_last_line(@world, game_id_2);
        assert_eq!(helpers::player_story_len(@world, game_id_2), story_len_2, "g_game_id 2");
        assert_eq!(helpers::player_story_last_line(@world, game_id_2), "+sys+game-2");
        //
        // player 1 can play their own game by id...
        helpers::set_caller(player_address_1);
        prompt.prompt("hello", Option::Some(game_id_1));
        story_len_1 += 3;
        // no new game was minted
        assert_eq!(token.total_supply(), 2, "total_supply()");
        // more story was added
        assert_eq!(helpers::player_story_len(@world, game_id_1), story_len_1, "said");
        //
        // ADMIN can play their someone else's game for debugging
        helpers::set_caller(OWNER());
        prompt.prompt("hello", Option::Some(game_id_2));
        story_len_2 += 3;
        // no new game was minted
        assert_eq!(token.total_supply(), 2, "total_supply()");
        // more story was added
        assert_eq!(helpers::player_story_len(@world, game_id_2), story_len_2, "said");
    }

    #[test]
    fn test_prompt_create_load_game_ok() {
        let (mut world, _, prompt, token, player_address_1, _) = helpers::setup_core();
        // initialize player singleton
        PlayerImpl::caller_as_player(ref world, OWNER(), 0);
        let room_entity: @Entity = @helpers::create_new_entity(700111, "Room 700111");
        world.write_model(room_entity);
        //
        // player_1 say anything... (will create a game)
        let game_id_1: u128 = 1;
        helpers::set_caller(player_address_1);
        prompt.prompt("", Option::None);
        // game was minted
        assert_eq!(token.total_supply(), 1, "total_supply()");
        assert_eq!(token.owner_of(game_id_1.into()), player_address_1, "owner_of()");
        // is current game of player
        assert_eq!(PlayerAccountImpl::current_game_id(@world, player_address_1), game_id_1, "current_game_id = 1");
        // player was created
        let player_1: Player = PlayerImpl::get_player(@world, game_id_1).unwrap();
        assert_eq!(player_1.address, player_address_1, "player_1.address");
        assert_eq!(player_1.game_id, game_id_1, "player_1.game_id");
        // build some story...
        prompt.prompt("hello", Option::None);
        let story_len_1: u32 = helpers::player_story_len(@world, game_id_1);
        assert_gt!(story_len_1, 1, "game_1.story");
        //
        // create a new game...
        let game_id_2: u128 = 2;
        prompt.prompt("g_create_game", Option::None);
        // game was minted
        assert_eq!(token.total_supply(), 2, "total_supply()");
        assert_eq!(token.owner_of(game_id_2.into()), player_address_1, "owner_of()");
        // is current game of player
        assert_eq!(PlayerAccountImpl::current_game_id(@world, player_address_1), game_id_2, "current_game_id = 2");
        // player was created
        let player_2: Player = PlayerImpl::get_player(@world, game_id_2).unwrap();
        assert_eq!(player_2.address, player_address_1, "player_2.address");
        assert_eq!(player_2.game_id, game_id_2, "player_2.game_id");
        // clean story...
        let story_len_2: u32 = helpers::player_story_len(@world, game_id_2);
        assert_eq!(story_len_2, 1, "game_2.story");
        assert_lt!(story_len_2, story_len_1, "game_2.story");
        // buil story...
        prompt.prompt("hello", Option::None);
        prompt.prompt("hello", Option::None);
        let story_len_2: u32 = helpers::player_story_len(@world, game_id_2);
        assert_gt!(story_len_2, story_len_1, "story_len_2 > story_len_1");
        //
        // switch to game 1...
        prompt.prompt("g_load_game 1", Option::None);
        assert_eq!(PlayerAccountImpl::current_game_id(@world, player_address_1), game_id_1, "current_game_id = 1 (loaded)");
        prompt.prompt("hello", Option::None);
        prompt.prompt("hello", Option::None);
        let story_len_1: u32 = helpers::player_story_len(@world, game_id_1);
        assert_gt!(story_len_1, story_len_2, "story_len_1 > story_len_2");
        //
        // switch to game 2...
        prompt.prompt("g_load_game 2", Option::None);
        assert_eq!(PlayerAccountImpl::current_game_id(@world, player_address_1), game_id_2, "current_game_id = 2 (loaded)");
        prompt.prompt("hello", Option::None);
        prompt.prompt("hello", Option::None);
        let story_len_2: u32 = helpers::player_story_len(@world, game_id_2);
        assert_gt!(story_len_2, story_len_1, "story_len_2 > story_len_1 (2)");
    }

    #[test]
    #[should_panic(expected: ('PROMPT: Not your game','ENTRYPOINT_FAILED'))]
    fn test_prompt_unknown_game() {
        let (_, _, prompt, _, player_address_1, _) = helpers::setup_core();
        //
        // player_1 say something...
        helpers::set_caller(player_address_1);
        prompt.prompt("", Option::Some(1212));
    }

    #[test]
    #[should_panic(expected: ('PROMPT: Not your game','ENTRYPOINT_FAILED'))]
    fn test_prompt_not_your_game() {
        let (mut world, _, prompt, token, player_address_1, player_address_2) = helpers::setup_core();
        // initialize player singleton
        PlayerImpl::caller_as_player(ref world, OWNER(), 0);
        //
        // player_1 say something...
        let game_id_1: u128 = 1;
        helpers::set_caller(player_address_1);
        prompt.prompt("", Option::None);
        assert_eq!(token.total_supply(), 1, "total_supply()");
        assert_eq!(token.owner_of(game_id_1.into()), player_address_1, "owner_of()");
        //
        // player_2 tries to play player_1's game...
        helpers::set_caller(player_address_2);
        prompt.prompt("", Option::Some(game_id_1));
    }

    #[test]
    fn test_prompt_game_zero_ok() {
        let (mut world, _, prompt, token, _, _) = helpers::setup_core();
        // initialize player singleton
        PlayerImpl::caller_as_player(ref world, OWNER(), 0);
        //
        // owner say something...
        let game_id_0: u128 = 0;
        helpers::set_caller(OWNER());
        prompt.prompt("", Option::Some(game_id_0));
        // no game was minted
        assert_eq!(token.total_supply(), 0, "total_supply()");
        // player zero was created
        let player_0: Player = PlayerImpl::get_player(@world, 0).unwrap();
        assert_eq!(player_0.address, ZERO(), "player_0.address");
        assert_eq!(player_0.game_id, 0, "player_0.game_id");
        // system command: g_game_id
        prompt.prompt("g_game_id", Option::Some(game_id_0));
// helpers::print_player_story_last_line(@world, game_id_0);
        assert_eq!(helpers::player_story_len(@world, game_id_0), 3, "said");
        assert_eq!(helpers::player_story_last_line(@world, game_id_0), "+sys+game-0");
    }

    #[test]
    #[should_panic(expected: ('PROMPT: Not admin','ENTRYPOINT_FAILED'))]
    fn test_prompt_game_zero_not_editor() {
        let (mut world, _, prompt, _, _, _) = helpers::setup_core();
        // initialize player singleton
        PlayerImpl::caller_as_player(ref world, OWNER(), 0);
        //
        // player_1 say something...
        helpers::set_caller(OTHER());
        prompt.prompt("hello", Option::Some(0));
    }
}
