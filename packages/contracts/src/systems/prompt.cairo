use core::option::{OptionTraitImpl};

#[starknet::interface]
pub trait IPrompt<T> {
    fn prompt(ref self: T, cmd: ByteArray, game_id: Option<u128>);
}

#[dojo::contract]
pub mod prompt {
    use super::{IPrompt};
    use starknet::{ContractAddress, get_caller_address};
    use core::num::traits::{Zero};
    use dojo::{
        world::{WorldStorage},
        model::{ModelStorage},
    };
    use lore::{
        systems::{
            actions_token::{IActionsTokenProtectedDispatcherTrait},
        },
        models::{
            player::{Player, PlayerImpl, PlayerStory},
            player_account::{PlayerAccountTrait},
            hub::{TrailTrait},
        },
        lib::{
            c_handler::{handle_command},
            access::{AccessTrait},
            random::{random_text},
            errors_texts_output::{ErrorOutputterImpl},
            dns::{DnsTrait, IGameTokenDispatcherTrait, ILexerDispatcherTrait},
        },
        constants::errors::{Error},
    };

    mod Errors {
        pub const NOT_ADMIN: felt252            = 'PROMPT: Not admin';
        pub const NOT_YOUR_GAME: felt252        = 'PROMPT: Not your game';
        pub const NO_PLAYER_COMPONENT: felt252  = 'PROMPT: No Player component';
    }

    // fn dojo_init(ref self: ContractState) {
    // }

    #[abi(embed_v0)]
    pub impl PromptImpl of IPrompt<ContractState> {
        fn prompt(ref self: ContractState, cmd: ByteArray, game_id: Option<u128>) {
            let mut world: WorldStorage = self.world_default();

            let mut player: Player = self.get_player(ref world, game_id);

            // empty prompt, do nothing (good to initialize a game)
            if (cmd.len() > 0) {
                player.log_command(ref world, cmd.clone());
                match (world.lexer_dispatcher().parse(world, cmd, player)) {
                    Result::Ok(command) => {
                        // calculate price per action
                        let actions_amount: Result<u128, Error> = world.actions_token_protected_dispatcher().calculate_action_cost(player, command.command_type);
                        if actions_amount.is_err() {
                            ErrorOutputterImpl::output_error(actions_amount.unwrap_err(), player, ref world);
                            return;
                        }
                        // execute the command
                        match handle_command(@command, ref world, ref player) {
                            Result::Ok(()) => {
                                // charge player
                                let actions_amount: u128 = actions_amount.unwrap();
                                if actions_amount.is_non_zero() {
                                    world.actions_token_protected_dispatcher().charge_player_actions(
                                        player.address,
                                        world.get_entity_trail_id(player.inst),
                                        actions_amount,
                                        player.game_id,
                                    );
                                }
                            },
                            Result::Err(error) => {
                                // println!("Error: {:?}", error);
                                ErrorOutputterImpl::output_error(error, player, ref world);
                            },
                        }
                    },
                    Result::Err(_) => {
                        player.say(ref world, random_text(world, random_error()));
                    },
                }
                if player.use_debug {
                    let player_story: PlayerStory = world.read_model(player.game_id);
                    player.log_debug(ref world, format!("(game-{}, {} lines)", player.game_id, player_story.story_line));
                }
            }
        }
    }

    #[generate_trait]
    impl WorldDefaultImpl of WorldDefaultTrait {
        #[inline(always)]
        fn world_default(self: @ContractState) -> WorldStorage {
            (self.world(@"lore"))
        }
    }


    //-----------------------------------
    // Internal
    //
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn get_player(self: @ContractState, ref world: WorldStorage, game_id: Option<u128>) -> Player {
            let player_address: ContractAddress = get_caller_address();
            let game_id: u128 = match game_id {
                Option::Some(game_id) => {
                    // player was provided
                    if game_id == 0 {
                        // only admins can play game #0
                        assert(world.is_player_admin(player_address), Errors::NOT_ADMIN);
                    } else {
                        // validate ownership
                        assert((
                            // only owner can play
                            world.game_token_dispatcher().is_owner_of(player_address, game_id.into())
                            /// or admins for debugging
                            || world.is_player_admin(player_address)
                        ), Errors::NOT_YOUR_GAME);
                        // set as current
                        PlayerAccountTrait::switch_game_id(ref world, player_address, game_id);
                    }
                    // ok to play...
                    (game_id)
                },
                Option::None => {
                    // player was not provided
                    // get current game
                    let mut game_id: u128 = PlayerAccountTrait::current_game_id(@world, player_address);
                    if game_id == 0 {
                        // create new game
                        game_id = world.game_token_dispatcher().create_game(player_address);
                    }
                    // ok to play...
                    (game_id)
                }
            };
            let player: Option<Player> = PlayerImpl::get_player_for_account(ref world, player_address, game_id);
            assert(player.is_some(), Errors::NO_PLAYER_COMPONENT);
            (player.unwrap())
        }
    }

    pub fn random_error() -> Array<ByteArray> {
        array![
            "I don't know what that means",
            "Nope",
            "Can you repeat that?",
            "I'm at a loss",
            "You're not helping",
            "I can't imagine",
        ]
    }
}
