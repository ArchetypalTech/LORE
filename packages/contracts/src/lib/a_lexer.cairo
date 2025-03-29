#[derive(Serde, Copy, Drop, Debug, Introspect, PartialEq)]
pub enum TokenType {
    Unknown,
    Verb, // go, take, drop, look, inventory, spawn
    Direction, // north, south, east, west
    Article, // the, a
    Preposition, // in, on, at, to
    Pronoun, // they, it, me, you
    Adjective, // good, bad, happy, sad
    Noun, // noun, object
    Quantifier, // number, quantity
    Interrogative // who, what, where, why, how
}

pub impl TokenTypeFelt252 of Into<TokenType, felt252> {
    fn into(self: TokenType) -> felt252 {
        match self {
            TokenType::Unknown => 0,
            TokenType::Verb => 1,
            TokenType::Direction => 2,
            TokenType::Article => 3,
            TokenType::Preposition => 4,
            TokenType::Pronoun => 5,
            TokenType::Adjective => 6,
            TokenType::Noun => 7,
            TokenType::Quantifier => 8,
            TokenType::Interrogative => 9,
        }
    }
}

#[derive(Clone, Drop, Serde, Debug)]
pub struct Token {
    pub position: u32, // Token position in the command
    pub text: ByteArray, // The token text as ByteArray
    pub token_type: TokenType, // Type of token (using TokenType enum as u8)
    pub token_value: felt252, // Value of token (ie directionId, obj inst)
    pub target: felt252 // Target object for token
}

#[derive(Clone, Drop, Serde, Debug)]
pub struct Command {
    #[key]
    pub command_id: felt252, // Unique ID of this command
    pub text: ByteArray, // Full command text
    pub words: Array<ByteArray>, // Split words
    pub token_count: u8, // Number of tokens in the command
    pub action_type: u8, // Type of action (using ActionType enum as u8)
    pub tokens: Array<Token> // Array of tokens in the command
}

pub mod lexer {
    use dojo::world::IWorldDispatcherTrait;
    use core::array::{ArrayTrait, ArrayImpl, Array};
    use super::super::utils::ByteArrayTraitExt;
    use super::{TokenType, Command, Token};

    use dojo::{world::WorldStorage};
    use lore::constants::errors::Error;
    use lore::components::{player::Player};
    use lore::lib::dictionary::{get_dict_entry, initialize_dictionary};


    pub fn parse(
        message: ByteArray, world: WorldStorage, player: Player,
    ) -> Result<Command, Error> {
        initialize_dictionary(world.clone());
        let words = message.clone().split_into_words();
        let tokens = match_tokens(world.clone(), words.clone());
        let mut command = Command {
            command_id: world.dispatcher.uuid().try_into().unwrap(),
            text: message,
            words,
            token_count: tokens.len().try_into().unwrap(),
            action_type: 0,
            tokens,
        };
        Result::Ok(command)
    }

    fn match_tokens(world: WorldStorage, words: Array<ByteArray>) -> Array<Token> {
        let mut tokens: Array<Token> = array![];
        for i in 0..words.len() {
            let mut token = Token {
                position: i,
                text: words[i].clone(),
                token_type: TokenType::Unknown,
                token_value: 0,
                target: 0,
            };
            let dict_entry = get_dict_entry(world, words[i].clone());
            if dict_entry.is_some() {
                let dict_entry = dict_entry.unwrap();
                token =
                    Token {
                        position: i,
                        text: words[i].clone(),
                        token_type: dict_entry.tokenType.clone(),
                        token_value: dict_entry.n_value,
                        target: 0,
                    };

                println!("Found dictionary match for {:?}", dict_entry);
            } else {
                println!("No dictionary match for {:?}", words[i]);
            }
            println!("token: {:?}", token);
            tokens.append(token);
        };
        tokens
    }

    fn match_player_context(world: WorldStorage, player: Player, mut command: Command) -> Command {
        // ask the player for their context

        command
    }
}

#[cfg(test)]
mod tests {
    use super::lexer;
    use lore::tests::helpers;
    use lore::components::{player::{caller_as_player}};
    use lore::lib::a_lexer::{TokenTypeFelt252};

    #[test]
    fn Lexer_test_prompt() {
        let (world, _, _, player_1, _) = helpers::setup_core();
        let promptText: ByteArray = "how illegal is it to call the door a lexer";
        println!("promptText: {:?}", promptText);
        let player = caller_as_player(world, player_1);
        let command = lexer::parse(promptText, world, player);
        println!("command: {:?}", command);
        // TODO: finish writing test
    // let prepositionToken: felt252 = TokenType::Preposition.into();
    // assert(command.tokens[1].token_value == prepositionToken, 'token value is 4');
    }
}
