use dojo::{world::WorldStorage};
use lore::{
    models::{
        dictionary::{Dict, DictionaryTrait},
        entity::{Entity, EntityImpl},
        player::{Player, PlayerImpl},
    },
    types::command_type::{
        Command, CommandTrait,
        CommandType,
        Token, TokenType,
    },
    constants::errors::Error,
};

#[starknet::interface]
pub trait ILexer<T> {
    fn initialize_dictionary(self: @T, world: WorldStorage);
    fn parse(self: @T, world: WorldStorage, message: ByteArray, player: Player) -> Result<Command, Error>;
}

#[dojo::library]
pub mod lexer {
    use super::{ILexer, LexerTrait};
    use dojo::{world::WorldStorage};

    use lore::{
        models::{
            dictionary::{DictionaryTrait},
            player::{Player},
        },
        types::command_type::{Command},
        constants::errors::Error,
    };

    #[abi(embed_v0)]
    impl LexerImpl of ILexer<ContractState> {
        fn initialize_dictionary(self: @ContractState,
            mut world: WorldStorage,
        ) {
            DictionaryTrait::initialize_dictionary(ref world)
        }
        fn parse(self: @ContractState,
            world: WorldStorage,
            message: ByteArray,
            player: Player,
        ) -> Result<Command, Error> {
            LexerTrait::parse(@world, message, player)
        }
    }
}


//---------------------------------
// Lexer Trait
//
use dojo::world::IWorldDispatcherTrait;
use core::array::{ArrayTrait, ArrayImpl, Array};
use lore::{
    lib::{
        utils::{ByteArrayTraitExt, ClousureTraitImp},
    },
};

#[generate_trait]
pub impl LexerImpl of LexerTrait {

    fn parse(
        world: @WorldStorage,
        message: ByteArray,
        player: Player,
    ) -> Result<Command, Error> {
        let words: Array<ByteArray> = message.split_into_words();
        let lowercased: Array<ByteArray> = Self::lowercase(words.clone());
        let tokens: Array<Token> = Self::match_tokens(world, lowercased);
        let mut command: Command = Command {
            command_id: world.dispatcher.uuid().try_into().unwrap(),
            text: message,
            words,
            token_count: tokens.len().try_into().unwrap(),
            action_type: 0,
            tokens,
            command_type: CommandType::Unknown,
        };
        command.match_player_context(world, player);
        command.post_process_command(world, player);
        command.pretty_print();
        Result::Ok(command)
    }

    fn match_tokens(world: @WorldStorage, words: Array<ByteArray>) -> Array<Token> {
        let mut tokens: Array<Token> = array![];
        for i in 0..words.len() {
            // iterate over the words in the string and find a dictionary match
            let mut token: Token = Token {
                position: i,
                text: words[i].clone(),
                token_type: TokenType::Unknown,
                token_value: 0,
                target: 0,
            };
            let dict_entry: Option<Dict> = world.get_dict_entry(words[i].clone());
            if dict_entry.is_some() {
                let dict_entry: Dict = dict_entry.unwrap();
                token =
                    Token {
                        position: i,
                        text: words[i].clone(),
                        token_type: dict_entry.tokenType,
                        token_value: dict_entry.n_value,
                        target: 0,
                    };
            }
            tokens.append(token);
        };
        tokens
    }

    fn match_player_context(ref self: Command, world: @WorldStorage, player: Player) {
        // get player for their context (room + room objects + inventory)
        let context: Array<Entity> = player.get_full_context(world);
        let mut newTokens: Array<Token> = array![];
        for i in 0..self.tokens.len() {
            let mut token: Token = self.tokens.at(i).clone();
            for item in context.clone() {
                let names: Span<ByteArray> = item.get_names();
                for name in names {
                    if @token.text == name {
                        token.target = item.inst;
                        token.token_type = TokenType::Noun;
                        token.token_value = i.into();
                        // println!("MATCH: {} : {:?}", name, token);
                        break;
                    }
                }
            };
            newTokens.append(token);
        };
        self.tokens = newTokens;
    }

    fn post_process_command(ref self: Command, world: @WorldStorage, player: Player) {
        // here we do fancy stuff
        // when there is a preposition, can we assume the next token is a noun? we know more about
        // the context now and what objects we recognize. Do we need to figure out adjectives.

        // let _verbs: Span<Token> = self.get_verbs();
        // let _nouns: Span<Token> = self.get_nouns();
        // let _directions: Span<Token> = self.get_directions();
        // let _targets: Span<Token> = self.get_targets();

        if (self.is_system_command()) {
            self.command_type = CommandType::System;
        } else if (self.text.len() > 0) {
            self.command_type = CommandType::Action;
        }
    }

    fn lowercase(self: Array<ByteArray>) -> Array<ByteArray> {
        let mut lowercased: Array<ByteArray> = ArrayTrait::new();
        for word in self {
            lowercased.append(word.to_lowercase());
        };
        lowercased
        // CANNOT BE USED CURRENTLY //
        // Using the map clousure function, we can apply the lowercase function to each element in
        // the array
        // let lowercased = self.map(|word| word.to_lowercase());
        // // Return the lowercased array
        // lowercased
    }
}

#[cfg(test)]
mod tests {
    use super::{LexerTrait};
    use lore::{
        models::{
            player::{Player, PlayerImpl},
            dictionary::{DictionaryTrait},
        },
        types::command_type::{
            Command, CommandImpl,
            Token, TokenType,
            IntoTokenTypeFelt252,
        },
        lib::{
            level_test::create_test_level,
        },
        constants::errors::Error,
        tests::helpers,
    };

    #[test]
    fn Lexer_test_prompt() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let promptText: ByteArray = "look, how illegal is it to call the door on a boat a lexer";
        // println!("promptText: {:?}", promptText);
        create_test_level(ref sys.world);
        let game_id: u128 = 0;
        let player: Player = PlayerImpl::caller_as_player(ref sys.world, helpers::PLAYER_1, game_id);
        player.move_to_room(ref sys.world, 2826);
        let _command: Result<Command, Error> = LexerTrait::parse(@sys.world, promptText, player);
        // println!("command: {:?}", command);
    // TODO: finish writing test
    // let prepositionToken: felt252 = TokenType::Preposition.into();
    // assert(command.tokens[1].token_value == prepositionToken, 'token value is 4');
    }

    #[test]
    fn test_get_verbs() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let prompt_text: ByteArray = "look at the magic circle";
        let expected_verb: ByteArray = "look"; // Correctly set verb as a ByteArray

        // Setup environment
        create_test_level(ref sys.world);
        let game_id: u128 = 0;
        let player: Player = PlayerImpl::caller_as_player(ref sys.world, helpers::PLAYER_1, game_id);
        player.move_to_room(ref sys.world, 2826);

        // Parse command
        let g_command: Result<Command, Error> = LexerTrait::parse(@sys.world, prompt_text, player);
        assert!(g_command.is_ok(), "Command parsing should succeed");
        let command: Command = g_command.unwrap(); // Safely unwrap since we assert it is Ok
        // Get verbs from the parsed command
        let verbs: Span<Token> = command.get_verbs();
        // println!("Verbs: {:?}", verbs);
        // Check the number of verbs found
        assert_eq!(verbs.len(), 1, "There should be exactly one verb");
        // Check if the first verb matches the expected verb ("look")
        assert_eq!(verbs[0].text, @expected_verb, "The verb should be 'look'");
    }

    #[test]
    fn test_get_nouns() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let prompt_text: ByteArray = "look at the ball";
        let expected_noun: ByteArray = "ball"; // Correctly set verb as a ByteArray

        // Setup environment
        create_test_level(ref sys.world);
        let game_id: u128 = 0;
        let player: Player = PlayerImpl::caller_as_player(ref sys.world, helpers::PLAYER_1, game_id);
        player.move_to_room(ref sys.world, 2826);
        let _ = sys.world.add_to_dictionary(expected_noun.clone(), TokenType::Noun, 2826);

        // Parse command
        let g_command: Result<Command, Error> = LexerTrait::parse(@sys.world, prompt_text, player);
        assert!(g_command.is_ok(), "Command parsing should succeed");
        let command: Command = g_command.unwrap(); // Safely unwrap since we assert it is Ok
        // Get verbs from the parsed command
        let nouns: Span<Token> = command.get_nouns();
        // println!("Nouns: {:?}", nouns);
        // Check the number of verbs found
        assert_eq!(nouns.len(), 1, "There should be exactly one noun");
        // Check if the first verb matches the expected verb ("look")
        assert_eq!(nouns[0].text, @expected_noun, "The noun should be 'door'");
    }
}
