use dojo::{world::WorldStorage, model::ModelStorage};
use lore::{
    constants::errors::Error,
    lib::{
        c_handler::{init_system_dictionary}, a_lexer::{TokenType, TokenTypeFelt252},
        utils::ByteArrayTraitExt,
    },
};
use core::result::{Result, ResultTrait};

#[derive(Clone, Drop, Serde, Introspect, Debug)]
#[dojo::model]
pub struct Dict {
    #[key]
    pub dict_key: felt252,
    pub word: ByteArray,
    pub tokenType: TokenType,
    pub n_value: felt252,
}

pub fn add_to_dictionary(
    mut world: WorldStorage, word: ByteArray, tokenType: TokenType, n_value: felt252,
) -> Result<(), Error> {
    if (word.clone().len() >= 31) {
        return Result::Err(Error::WordTooLong);
    }
    let dict_key: felt252 = word.clone().to_felt252_word().unwrap();
    let entry = Dict { dict_key, word, tokenType: tokenType, n_value };
    world.write_model(@entry);
    Result::Ok(())
}

pub fn get_dict_entry(world: WorldStorage, word: ByteArray) -> Option<Dict> {
    let dict_key: felt252 = word.clone().to_felt252_word().unwrap();
    let entry: Dict = world.read_model(dict_key);
    if (entry.word == "") {
        return Option::None;
    }
    Option::Some(entry)
}

pub fn initialize_dictionary(world: WorldStorage) {
    if get_dict_entry(world, "intialized").is_none() {
        init_dictionary(world);
        init_system_dictionary(world);
    }
}

pub fn init_dictionary(world: WorldStorage) {
    add_to_dictionary(world, "look", TokenType::Verb, 1).unwrap();
    add_to_dictionary(world, "l", TokenType::Verb, 1).unwrap();
    add_to_dictionary(world, "stare", TokenType::Verb, 1).unwrap();
    add_to_dictionary(world, "examine", TokenType::Verb, 1).unwrap();
    add_to_dictionary(world, "x", TokenType::Verb, 1).unwrap();
    add_to_dictionary(world, "take", TokenType::Verb, 1).unwrap();
    add_to_dictionary(world, "get", TokenType::Verb, 1).unwrap();
    add_to_dictionary(world, "drop", TokenType::Verb, 1).unwrap();
    add_to_dictionary(world, "inventory", TokenType::Verb, 1).unwrap();
    add_to_dictionary(world, "inv", TokenType::Verb, 1).unwrap();
    add_to_dictionary(world, "i", TokenType::Verb, 1).unwrap();
    add_to_dictionary(world, "go", TokenType::Verb, 1).unwrap();
    add_to_dictionary(world, "open", TokenType::Verb, 1).unwrap();
    add_to_dictionary(world, "close", TokenType::Verb, 1).unwrap();
    add_to_dictionary(world, "put", TokenType::Verb, 1).unwrap();
    add_to_dictionary(world, "give", TokenType::Verb, 1).unwrap();
    add_to_dictionary(world, "eat", TokenType::Verb, 1).unwrap();
    add_to_dictionary(world, "drink", TokenType::Verb, 1).unwrap();
    add_to_dictionary(world, "is", TokenType::Verb, 1).unwrap();
    add_to_dictionary(world, "use", TokenType::Verb, 1).unwrap();
    add_to_dictionary(world, "enter", TokenType::Verb, 1).unwrap();
    add_to_dictionary(world, "climb", TokenType::Verb, 1).unwrap();
    add_to_dictionary(world, "pickup", TokenType::Verb, 1).unwrap();

    // directions
    add_to_dictionary(world, "north", TokenType::Direction, 1).unwrap();
    add_to_dictionary(world, "n", TokenType::Direction, 1).unwrap();
    add_to_dictionary(world, "south", TokenType::Direction, 2).unwrap();
    add_to_dictionary(world, "s", TokenType::Direction, 2).unwrap();
    add_to_dictionary(world, "east", TokenType::Direction, 3).unwrap();
    add_to_dictionary(world, "e", TokenType::Direction, 3).unwrap();
    add_to_dictionary(world, "west", TokenType::Direction, 4).unwrap();
    add_to_dictionary(world, "w", TokenType::Direction, 4).unwrap();
    add_to_dictionary(world, "up", TokenType::Direction, 5).unwrap();
    add_to_dictionary(world, "u", TokenType::Direction, 5).unwrap();
    add_to_dictionary(world, "down", TokenType::Direction, 6).unwrap();
    add_to_dictionary(world, "d", TokenType::Direction, 6).unwrap();
    add_to_dictionary(world, "around", TokenType::Direction, 7).unwrap();
    add_to_dictionary(world, "ahead", TokenType::Direction, 8).unwrap();
    add_to_dictionary(world, "behind", TokenType::Direction, 8).unwrap();
    // adjectives
    add_to_dictionary(world, "good", TokenType::Adjective, 1).unwrap();
    add_to_dictionary(world, "bad", TokenType::Adjective, 2).unwrap();
    add_to_dictionary(world, "happy", TokenType::Adjective, 3).unwrap();
    add_to_dictionary(world, "sad", TokenType::Adjective, 4).unwrap();
    add_to_dictionary(world, "beautiful", TokenType::Adjective, 5).unwrap();
    add_to_dictionary(world, "ugly", TokenType::Adjective, 6).unwrap();
    add_to_dictionary(world, "tall", TokenType::Adjective, 7).unwrap();
    add_to_dictionary(world, "short", TokenType::Adjective, 8).unwrap();
    add_to_dictionary(world, "fat", TokenType::Adjective, 9).unwrap();
    add_to_dictionary(world, "thick", TokenType::Adjective, 10).unwrap();
    add_to_dictionary(world, "thin", TokenType::Adjective, 11).unwrap();
    add_to_dictionary(world, "big", TokenType::Adjective, 12).unwrap();
    add_to_dictionary(world, "small", TokenType::Adjective, 13).unwrap();
    add_to_dictionary(world, "long", TokenType::Adjective, 14).unwrap();
    add_to_dictionary(world, "illegal", TokenType::Adjective, 14).unwrap();
    // articles
    add_to_dictionary(world, "a", TokenType::Article, 1).unwrap();
    add_to_dictionary(world, "an", TokenType::Article, 1).unwrap();
    add_to_dictionary(world, "the", TokenType::Article, 1).unwrap();
    // prepositions
    add_to_dictionary(world, "in", TokenType::Preposition, 1).unwrap();
    add_to_dictionary(world, "on", TokenType::Preposition, 2).unwrap();
    add_to_dictionary(world, "with", TokenType::Preposition, 3).unwrap();
    add_to_dictionary(world, "at", TokenType::Preposition, 4).unwrap();
    add_to_dictionary(world, "to", TokenType::Preposition, 5).unwrap();
    add_to_dictionary(world, "into", TokenType::Preposition, 6).unwrap();
    add_to_dictionary(world, "out", TokenType::Preposition, 7).unwrap();
    add_to_dictionary(world, "from", TokenType::Preposition, 8).unwrap();
    add_to_dictionary(world, "off", TokenType::Preposition, 9).unwrap();
    add_to_dictionary(world, "for", TokenType::Preposition, 10).unwrap();
    add_to_dictionary(world, "by", TokenType::Preposition, 11).unwrap();
    add_to_dictionary(world, "of", TokenType::Preposition, 12).unwrap();
    // pronouns
    add_to_dictionary(world, "it", TokenType::Pronoun, 1).unwrap();
    add_to_dictionary(world, "them", TokenType::Pronoun, 2).unwrap();
    add_to_dictionary(world, "me", TokenType::Pronoun, 3).unwrap();
    add_to_dictionary(world, "you", TokenType::Pronoun, 4).unwrap();
    add_to_dictionary(world, "he", TokenType::Pronoun, 5).unwrap();
    add_to_dictionary(world, "she", TokenType::Pronoun, 6).unwrap();
    add_to_dictionary(world, "him", TokenType::Pronoun, 7).unwrap();
    add_to_dictionary(world, "her", TokenType::Pronoun, 8).unwrap();
    add_to_dictionary(world, "this", TokenType::Pronoun, 9).unwrap();
    add_to_dictionary(world, "that", TokenType::Pronoun, 8).unwrap();
    // quantifiers
    add_to_dictionary(world, "all", TokenType::Quantifier, 256).unwrap();
    add_to_dictionary(world, "one", TokenType::Quantifier, 1).unwrap();
    add_to_dictionary(world, "1", TokenType::Quantifier, 1).unwrap();
    add_to_dictionary(world, "two", TokenType::Quantifier, 2).unwrap();
    add_to_dictionary(world, "2", TokenType::Quantifier, 2).unwrap();
    add_to_dictionary(world, "three", TokenType::Quantifier, 3).unwrap();
    add_to_dictionary(world, "3", TokenType::Quantifier, 3).unwrap();
    add_to_dictionary(world, "four", TokenType::Quantifier, 4).unwrap();
    add_to_dictionary(world, "4", TokenType::Quantifier, 4).unwrap();
    add_to_dictionary(world, "five", TokenType::Quantifier, 5).unwrap();
    add_to_dictionary(world, "5", TokenType::Quantifier, 5).unwrap();
    add_to_dictionary(world, "six", TokenType::Quantifier, 6).unwrap();
    add_to_dictionary(world, "6", TokenType::Quantifier, 6).unwrap();
    add_to_dictionary(world, "seven", TokenType::Quantifier, 7).unwrap();
    add_to_dictionary(world, "7", TokenType::Quantifier, 7).unwrap();
    add_to_dictionary(world, "eight", TokenType::Quantifier, 8).unwrap();
    add_to_dictionary(world, "8", TokenType::Quantifier, 8).unwrap();
    add_to_dictionary(world, "nine", TokenType::Quantifier, 9).unwrap();
    add_to_dictionary(world, "9", TokenType::Quantifier, 9).unwrap();
    add_to_dictionary(world, "ten", TokenType::Quantifier, 10).unwrap();
    add_to_dictionary(world, "10", TokenType::Quantifier, 10).unwrap();
    add_to_dictionary(world, "more", TokenType::Quantifier, 255).unwrap();
    add_to_dictionary(world, "less", TokenType::Quantifier, 255).unwrap();
    add_to_dictionary(world, "most", TokenType::Quantifier, 255).unwrap();
    add_to_dictionary(world, "least", TokenType::Quantifier, 255).unwrap();
    // nouns
    add_to_dictionary(world, "noun", TokenType::Noun, 1).unwrap();
    add_to_dictionary(world, "object", TokenType::Noun, 1).unwrap();
    add_to_dictionary(world, "ball", TokenType::Noun, 1).unwrap();
    // interrogatives
    add_to_dictionary(world, "who", TokenType::Interrogative, 1).unwrap();
    add_to_dictionary(world, "what", TokenType::Interrogative, 2).unwrap();
    add_to_dictionary(world, "where", TokenType::Interrogative, 3).unwrap();
    add_to_dictionary(world, "why", TokenType::Interrogative, 4).unwrap();
    add_to_dictionary(world, "how", TokenType::Interrogative, 5).unwrap();

    // dictionary is initialized
    add_to_dictionary(world, "intialized", TokenType::System, 1).unwrap();
}


#[cfg(test)]
mod tests {
    use lore::tests::helpers;
    use super::*;
    use lore::lib::a_lexer::{TokenType, TokenTypeFelt252};

    #[test]
    fn Dictionary_test_init() {
        let (world, _, _, _, _) = helpers::setup_core();
        let entry_1 = get_dict_entry(world, "look").unwrap();
        let entry_2 = get_dict_entry(world, "beautiful").unwrap();
        println!("entry_1: {:?}", entry_1);
        println!("entry_2: {:?}", entry_2);
        assert(entry_1.tokenType == TokenType::Verb, 'look is verb');
        assert(entry_2.tokenType == TokenType::Adjective, 'beautiful is adjective');
    }

    #[test]
    fn Dictionary_test_add_to_dictionary() {
        let (world, _, _, _, _) = helpers::setup_core();
        add_to_dictionary(world, "something", TokenType::Verb, 1).unwrap();
        let entry_1 = get_dict_entry(world, "something").unwrap();
        assert(entry_1.tokenType == TokenType::Verb, 'beautiful is verb');
        assert(entry_1.dict_key == 'something', 'dict_key is "beautiful"');
        assert(entry_1.word == "something", 'word is "beautiful"');
    }
}
