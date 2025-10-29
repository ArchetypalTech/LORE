use dojo::{world::WorldStorage};
use lore::{
    models::{
        index::{Dict},
        entity::{Entity, EntityImpl},
        player::{Player, PlayerImpl},
    },
    types::command_type::{
        Command, CommandTrait,
        Token, TokenType,
    },
    constants::errors::Error,
};

#[starknet::interface]
pub trait ILexer<T> {
    fn parse(self: @T, message: ByteArray, world: WorldStorage, player: Player) -> Result<Command, Error>;
}

#[dojo::library]
pub mod lexer {
    use super::{ILexer, LexerTrait};
    use dojo::{world::WorldStorage};

    use lore::{
        models::player::{Player},
        types::command_type::{Command},
        constants::errors::Error,
    };

    #[abi(embed_v0)]
    impl LexerImpl of ILexer<ContractState> {
        fn parse(self: @ContractState,
            message: ByteArray, world: WorldStorage, player: Player,
        ) -> Result<Command, Error> {
            LexerTrait::parse(message, world, player)
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
        dictionary::{get_dict_entry, initialize_dictionary},
    },
};

#[generate_trait]
pub impl LexerImpl of LexerTrait {

    fn parse(
        message: ByteArray, world: WorldStorage, player: Player,
    ) -> Result<Command, Error> {
        initialize_dictionary(world);
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
        };
        command = Self::match_player_context(world, player, command);
        command = Self::post_process_command(world, player, command);
        command.pretty_print();
        Result::Ok(command)
    }

    fn match_tokens(world: WorldStorage, words: Array<ByteArray>) -> Array<Token> {
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
            let dict_entry: Option<Dict> = get_dict_entry(world, words[i].clone());
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

    fn match_player_context(world: WorldStorage, player: Player, mut command: Command) -> Command {
        // get player for their context (room + room objects + inventory)
        let context: Array<Entity> = player.get_full_context(@world);
        let mut newTokens: Array<Token> = array![];
        for i in 0..command.tokens.len() {
            let mut token: Token = command.tokens.at(i).clone();
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
        command.tokens = newTokens;
        command
    }

    fn post_process_command(world: WorldStorage, player: Player, mut command: Command) -> Command {
        // here we do fancy stuff
        // when there is a preposition, can we assume the next token is a noun? we know more about
        // the context now and what objects we recognize. Do we need to figure out adjectives.
        let _verbs: Span<Token> = command.get_verbs();
        let _nouns: Span<Token> = command.get_nouns();
        let _directions: Span<Token> = command.get_directions();
        let _targets: Span<Token> = command.get_Targets();
        command
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
        models::player::{Player, PlayerImpl},
        types::command_type::{
            Command, CommandImpl,
            Token, TokenType,
            IntoTokenTypeFelt252,
        },
        lib::{
            level_test::create_test_level,
            dictionary::{add_to_dictionary},
        },
        constants::errors::Error,
        tests::helpers,
    };

    #[test]
    fn Lexer_test_prompt() {
        let (mut world, _, _, _, player_1, _) = helpers::setup_core();
        let promptText: ByteArray = "look, how illegal is it to call the door on a boat a lexer";
        // println!("promptText: {:?}", promptText);
        create_test_level(ref world);
        let game_id: u128 = 0;
        let player: Player = PlayerImpl::caller_as_player(ref world, player_1, game_id);
        player.move_to_room(ref world, 2826);
        let _command: Result<Command, Error> = LexerTrait::parse(promptText, world, player);
        // println!("command: {:?}", command);
    // TODO: finish writing test
    // let prepositionToken: felt252 = TokenType::Preposition.into();
    // assert(command.tokens[1].token_value == prepositionToken, 'token value is 4');
    }

    #[test]
    fn test_get_verbs() {
        let (mut world, _, _, _, player_1, _) = helpers::setup_core();
        let prompt_text: ByteArray = "look at the magic circle";
        let expected_verb: ByteArray = "look"; // Correctly set verb as a ByteArray

        // Setup environment
        create_test_level(ref world);
        let game_id: u128 = 0;
        let player: Player = PlayerImpl::caller_as_player(ref world, player_1, game_id);
        player.move_to_room(ref world, 2826);

        // Parse command
        let g_command: Result<Command, Error> = LexerTrait::parse(prompt_text, world, player);
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
        let (mut world, _, _, _, player_1, _) = helpers::setup_core();
        let prompt_text: ByteArray = "look at the ball";
        let expected_noun: ByteArray = "ball"; // Correctly set verb as a ByteArray

        // Setup environment
        create_test_level(ref world);
        let game_id: u128 = 0;
        let player: Player = PlayerImpl::caller_as_player(ref world, player_1, game_id);
        player.move_to_room(ref world, 2826);
        let _ = add_to_dictionary(world, expected_noun.clone(), TokenType::Noun, 2826);

        // Parse command
        let g_command: Result<Command, Error> = LexerTrait::parse(prompt_text, world, player);
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
