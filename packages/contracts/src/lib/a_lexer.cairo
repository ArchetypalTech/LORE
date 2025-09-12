use core::array::{ArrayTrait, ArrayImpl, Array};

use lore::{
    models::player::PlayerImpl,
    types::command_type::{Command, Token, TokenType},
};


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

    fn get_verbs(self: @Command) -> Span<Token> {
        let mut verbs: Array<Token> = array![];
        for i in 0..self.tokens.len() {
            let token = self.tokens.at(i).clone();

            // Only proceed if it's a verb
            if token.token_type != TokenType::Verb {
                continue;
            }
            verbs.append(token.clone());
        };
        (verbs.span())
    }

    fn get_nouns(self: @Command) -> Span<Token> {
        let mut nouns: Array<Token> = array![];
        for i in 0..self.tokens.len() {
            let token = self.tokens.at(i).clone();

            // Only consider tokens labeled as Noun
            if token.token_type != TokenType::Noun {
                continue;
            }
            nouns.append(token.clone());
        };
        (nouns.span())
    }

    fn get_directions(self: @Command) -> Span<Token> {
        let mut directions: Array<Token> = array![];
        for i in 0..self.tokens.len() {
            let token = self.tokens.at(i).clone();

            // Only consider direction-type tokens
            if token.token_type != TokenType::Direction {
                continue;
            }
            directions.append(token.clone());
        };
        (directions.span())
    }

    fn get_Targets(self: @Command) -> Span<Token> {
        let mut targets: Array<Token> = array![];
        for i in 0..self.tokens.len() {
            let token = self.tokens.at(i).clone();
            // Only consider Noun-type tokens
            if token.token_type != TokenType::Noun {
                continue;
            }
            // Only consider if the target is different from 0
            if token.target != 0 {
                continue;
            }

            targets.append(token.clone());
        };
        (targets.span())
    }

    fn pretty_print(self: @Command) {
        // println!("Command: {:?}", self);
        for _token in self.tokens.clone() { // println!("{:?}: {:?}", token.text, token);
        };
    }
}

pub mod lexer {
    use super::CommandTrait;
    use dojo::world::IWorldDispatcherTrait;
    use core::array::{ArrayTrait, ArrayImpl, Array};
    use super::{CommandImpl};

    use dojo::{world::WorldStorage};

    use lore::{
        models::{
            entity::{EntityImpl},
            player::{Player, PlayerImpl},
        },
        types::command_type::{Command, Token, TokenType},
        constants::errors::Error,
        lib::{
            utils::{ByteArrayTraitExt, ClousureTraitImp},
            dictionary::{get_dict_entry, initialize_dictionary},
        },
    };


    pub fn parse(
        message: ByteArray, world: WorldStorage, player: Player, game_id: u128,
    ) -> Result<Command, Error> {
        initialize_dictionary(world);
        let words = message.split_into_words();
        let lowercased = lowercase(words.clone());
        let tokens = match_tokens(world, lowercased);
        let mut command = Command {
            command_id: world.dispatcher.uuid().try_into().unwrap(),
            text: message,
            words,
            token_count: tokens.len().try_into().unwrap(),
            action_type: 0,
            tokens,
            game_id,
        };
        command = match_player_context(world, player, command);
        command = post_process_command(world, player, command);
        command.pretty_print();
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
            }
            tokens.append(token);
        };
        tokens
    }

    fn match_player_context(world: WorldStorage, player: Player, mut command: Command) -> Command {
        // get player for their context (room + room objects + inventory)
        let context = player.get_full_context(@world, command.game_id);
        let mut newTokens: Array<Token> = array![];
        for i in 0..command.tokens.len() {
            let mut token = command.tokens.at(i).clone();
            for item in context.clone() {
                let names = item.get_names();
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
        let _verbs = command.get_verbs();
        let _nouns = command.get_nouns();
        let _directions = command.get_directions();
        let _targets = command.get_Targets();
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
    use super::lexer;
    use super::CommandImpl;
    use lore::{
        models::player::{PlayerImpl},
        types::command_type::{TokenType, IntoTokenTypeFelt252},
        tests::helpers,
        lib::{
            level_test::create_test_level,
            dictionary::{add_to_dictionary},
        },
    };

    #[test]
    fn Lexer_test_prompt() {
        let (mut world, _, _, _, player_1, _) = helpers::setup_core();
        let promptText: ByteArray = "look, how illegal is it to call the door on a boat a lexer";
        // println!("promptText: {:?}", promptText);
        create_test_level(ref world);
        let game_id: u128 = 0;
        let player = PlayerImpl::caller_as_player(ref world, player_1, game_id);
        player.move_to_room(ref world, 2826, game_id);
        let _command = lexer::parse(promptText, world, player, game_id);
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
        let player = PlayerImpl::caller_as_player(ref world, player_1, game_id);
        player.move_to_room(ref world, 2826, game_id);

        // Parse command
        let g_command = lexer::parse(prompt_text, world, player, game_id);
        assert!(g_command.is_ok(), "Command parsing should succeed");
        let command = g_command.unwrap(); // Safely unwrap since we assert it is Ok
        // Get verbs from the parsed command
        let verbs = command.get_verbs();
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
        let player = PlayerImpl::caller_as_player(ref world, player_1, game_id);
        player.move_to_room(ref world, 2826, game_id);
        let _ = add_to_dictionary(world, expected_noun.clone(), TokenType::Noun, 2826);

        // Parse command
        let g_command = lexer::parse(prompt_text, world, player, game_id);
        assert!(g_command.is_ok(), "Command parsing should succeed");
        let command = g_command.unwrap(); // Safely unwrap since we assert it is Ok
        // Get verbs from the parsed command
        let nouns = command.get_nouns();
        // println!("Nouns: {:?}", nouns);
        // Check the number of verbs found
        assert_eq!(nouns.len(), 1, "There should be exactly one noun");
        // Check if the first verb matches the expected verb ("look")
        assert_eq!(nouns[0].text, @expected_noun, "The noun should be 'door'");
    }
}
