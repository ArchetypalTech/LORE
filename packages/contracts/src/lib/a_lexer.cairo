use dojo::world::IWorldDispatcherTrait;
use core::array::{ArrayTrait, ArrayImpl, Array};
use dojo::{world::WorldStorage};

use lore::{
    components::{player::{Player, PlayerImpl}}, //
    constants::errors::Error, //
    lib::{utils::ByteArrayTraitExt, dictionary::{get_dict_entry, initialize_dictionary}},
};

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
    Interrogative, // who, what, where, why, how
    System //
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
            TokenType::System => 252,
        }
    }
}

#[derive(Clone, Drop, Serde, Debug)]
pub struct Token {
    pub position: u32, // Token position in the command
    pub text: ByteArray, // The token text as ByteArray
    pub token_type: TokenType, // Type of token (using TokenType enum as u8)
    pub token_value: felt252, // Value of token (ie directionId, obj inst)
    pub target: felt252 // Target object INST for token
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

#[generate_trait]
pub impl CommandImpl of CommandTrait {
    fn is_system_command(self: @Command) -> bool {
        let mut is_system_command = false;
        for token in self.clone().tokens {
            if token.token_type == TokenType::System {
                is_system_command = true;
                break;
            }
        };
        is_system_command
    }
    //get_targets() -> Array<Entity>
    // let list = command.get_targets();
    // let amount = list.len();

    fn get_verbs(self: @Command, world: WorldStorage, player: Player) -> Array<Token> {
        let mut verbs: Array<Token> = array![];
        for i in 0..self.tokens.len() {
            let token = self.tokens.at(i).clone();

            // Only proceed if it's a verb
            if token.token_type != TokenType::Verb {
                continue;
            }
            verbs.append(token.clone());
        };
        verbs
    }

    fn get_nouns(self: @Command, world: WorldStorage, player: Player) -> Array<Token> {
        let mut nouns: Array<Token> = array![];
        for i in 0..self.tokens.len() {
            let token = self.tokens.at(i).clone();

            // Only consider tokens labeled as Noun
            if token.token_type != TokenType::Noun {
                continue;
            }
            nouns.append(token.clone());
        };
        nouns
    }

    fn get_directions(self: @Command, world: WorldStorage, player: Player) -> Array<Token> {
        let mut directions: Array<Token> = array![];
        for i in 0..self.tokens.len() {
            let token = self.tokens.at(i).clone();

            // Only consider direction-type tokens
            if token.token_type != TokenType::Direction {
                continue;
            }
            directions.append(token.clone());
        };
        directions
    }

    fn get_Targets(self: @Command, world: WorldStorage, player: Player) -> Array<Token> {
        let mut targets: Array<Token> = array![];
        for i in 0..self.tokens.len() {
            let token = self.tokens.at(i).clone();
            // Only consider Noun-type tokens
            if token.token_type != TokenType::Noun {
                continue;
            }
            // Only consider if the target is different from 0
            if token.target == 0 {
                continue;
            }

            targets.append(token.clone());
        };
        targets
    }
}

pub mod lexer {
    use super::super::entity::EntityTrait;
    use dojo::world::IWorldDispatcherTrait;
    use core::array::{ArrayTrait, ArrayImpl, Array};
    use super::{TokenType, Command, Token, CommandImpl};

    use dojo::{world::WorldStorage};

    use lore::{
        components::{player::{Player, PlayerImpl}}, //
        constants::errors::Error, //
        lib::{utils::ByteArrayTraitExt, dictionary::{get_dict_entry, initialize_dictionary}},
    };


    pub fn parse(
        message: ByteArray, world: WorldStorage, player: Player,
    ) -> Result<Command, Error> {
        initialize_dictionary(world);
        let words = message.clone().split_into_words();
        let tokens = match_tokens(world, words.clone());
        let mut command = Command {
            command_id: world.dispatcher.uuid().try_into().unwrap(),
            text: message,
            words,
            token_count: tokens.len().try_into().unwrap(),
            action_type: 0,
            tokens,
        };
        command = match_player_context(world, player, command);
        command = post_process_command(world, player, command);
        Result::Ok(command)
    }

    fn match_tokens(world: WorldStorage, words: Array<ByteArray>) -> Array<Token> {
        let mut tokens: Array<Token> = array![];
        for i in 0..words.len() {
            // iterate over the words in the string and find a dictionary match
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
            } else {
                println!("[Lexer]: {:?} : NO match ", words[i]);
            }
            tokens.append(token);
        };
        for t in 0..tokens.len() {
            println!("[Lexer]: {:?}", tokens[t]);
        };
        tokens
    }

    fn match_player_context(world: WorldStorage, player: Player, mut command: Command) -> Command {
        // get player for their context (room + room objects + inventory)
        let context = player.get_context(@world);
        let mut tokens = command.tokens.clone();
        for i in 0..command.tokens.len() {
            let mut token = command.tokens.at(i).clone();
            for item in context.clone() {
                let names = item.get_names();
                for name in names {
                    if token.text == name {
                        token.target = item.inst;
                        token.token_type = TokenType::Noun;
                        token.token_value = i.into();
                        println!("MATCH: {} : {:?}", name, token);
                        break;
                    }
                }
            };
            tokens.append(token);
        };
        // println!("tokens: {:?}", tokens);
        command
    }

    fn post_process_command(world: WorldStorage, player: Player, mut command: Command) -> Command {
        // here we do fancy stuff
        // when there is a preposition, can we assume the next token is a noun? we know more about
        // the context now and what objects we recognize. Do we need to figure out adjectives.
        println!("post_process_command: {:?}", command);
        let verbs = command.get_verbs(world, player);
        println!("PPC-verbs: {:?}", verbs);
        let nouns = command.get_nouns(world, player);
        println!("PPC-nouns: {:?}", nouns);
        let directions = command.get_directions(world, player);
        println!("PPC-directions: {:?}", directions);
        let targets = command.get_Targets(world, player);
        println!("PPC-targets: {:?}", targets);
        command
    }
}

#[cfg(test)]
mod tests {
    use super::lexer;
    use super::CommandImpl;
    use super::TokenType;
    use lore::{
        tests::helpers, lib::{level_test::create_test_level, a_lexer::{TokenTypeFelt252}},
        components::{player::{PlayerImpl, caller_as_player}}, lib::dictionary::{add_to_dictionary},
    };

    #[test]
    fn Lexer_test_prompt() {
        let (world, _, _, player_1, _) = helpers::setup_core();
        let promptText: ByteArray = "look, how illegal is it to call the door on a boat a lexer";
        println!("promptText: {:?}", promptText);
        create_test_level(world);
        let player = caller_as_player(world, player_1);
        player.move_to_room(world, 2826);
        let command = lexer::parse(promptText, world, player);
        println!("command: {:?}", command);
        // TODO: finish writing test
    // let prepositionToken: felt252 = TokenType::Preposition.into();
    // assert(command.tokens[1].token_value == prepositionToken, 'token value is 4');
    }

    #[test]
    fn test_get_verbs() {
        let (world, _, _, player_1, _) = helpers::setup_core();
        let prompt_text: ByteArray = "look at the magic circle";
        let expected_verb: ByteArray = "look"; // Correctly set verb as a ByteArray

        // Setup environment
        create_test_level(world);
        let player = caller_as_player(world, player_1);
        player.move_to_room(world, 2826);

        // Parse command
        let g_command = lexer::parse(prompt_text, world, player);
        assert!(g_command.is_ok(), "Command parsing should succeed");
        let command = g_command.unwrap(); // Safely unwrap since we assert it is Ok
        // Get verbs from the parsed command
        let verbs = command.get_verbs(world, player);
        println!("Verbs: {:?}", verbs);
        // Check the number of verbs found
        assert_eq!(verbs.len(), 1, "There should be exactly one verb");
        // Check if the first verb matches the expected verb ("look")
        assert_eq!(verbs[0].text, @expected_verb, "The verb should be 'look'");
    }

    #[test]
    fn test_get_nouns() {
        let (world, _, _, player_1, _) = helpers::setup_core();
        let prompt_text: ByteArray = "look at the ball";
        let expected_noun: ByteArray = "ball"; // Correctly set verb as a ByteArray

        // Setup environment
        create_test_level(world);
        let player = caller_as_player(world, player_1);
        player.move_to_room(world, 2826);
        let _ = add_to_dictionary(world, expected_noun.clone(), TokenType::Noun, 2826);

        // Parse command
        let g_command = lexer::parse(prompt_text, world, player);
        assert!(g_command.is_ok(), "Command parsing should succeed");
        let command = g_command.unwrap(); // Safely unwrap since we assert it is Ok
        // Get verbs from the parsed command
        let nouns = command.get_nouns(world, player);
        println!("Nouns: {:?}", nouns);
        // Check the number of verbs found
        assert_eq!(nouns.len(), 1, "There should be exactly one noun");
        // Check if the first verb matches the expected verb ("look")
        assert_eq!(nouns[0].text, @expected_noun, "The noun should be 'door'");
    }
}
