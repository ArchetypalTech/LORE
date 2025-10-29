use dojo::{world::WorldStorage, model::ModelStorage};
use lore::{
    models::index::Dict, types::command_type::{TokenType, IntoTokenTypeFelt252},
    constants::errors::Error, lib::{c_handler::{init_system_dictionary}, utils::ByteArrayTraitExt},
};
use core::result::{Result, ResultTrait};

pub fn add_to_dictionary(
    mut world: WorldStorage, word: ByteArray, tokenType: TokenType, n_value: felt252,
) -> Result<(), Error> {
    if (word.clone().len() >= 31) {
        return Result::Err(Error::WordTooLong);
    }
    let dict_key: felt252 = word.clone().to_felt252_word().unwrap();
    let entry: Dict = Dict { dict_key, word, tokenType: tokenType, n_value };
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
    add_to_dictionary(world, "check", TokenType::Verb, 1).unwrap();
    add_to_dictionary(world, "climb", TokenType::Verb, 2).unwrap();
    add_to_dictionary(world, "close", TokenType::Verb, 3).unwrap();
    add_to_dictionary(world, "drop", TokenType::Verb, 4).unwrap();
    add_to_dictionary(world, "drink", TokenType::Verb, 5).unwrap();
    add_to_dictionary(world, "quaff", TokenType::Verb, 5).unwrap();
    add_to_dictionary(world, "eat", TokenType::Verb, 6).unwrap();
    add_to_dictionary(world, "consume", TokenType::Verb, 6).unwrap();
    add_to_dictionary(world, "enter", TokenType::Verb, 7).unwrap();
    add_to_dictionary(world, "in", TokenType::Verb, 7).unwrap();
    add_to_dictionary(world, "examine", TokenType::Verb, 8).unwrap();
    add_to_dictionary(world, "x", TokenType::Verb, 8).unwrap();
    add_to_dictionary(world, "exit", TokenType::Verb, 9).unwrap();
    add_to_dictionary(world, "out", TokenType::Verb, 9).unwrap();
    add_to_dictionary(world, "feel", TokenType::Verb, 10).unwrap();
    add_to_dictionary(world, "get", TokenType::Verb, 11).unwrap();
    add_to_dictionary(world, "give", TokenType::Verb, 12).unwrap();
    add_to_dictionary(world, "go", TokenType::Verb, 13).unwrap();
    add_to_dictionary(world, "move", TokenType::Verb, 13).unwrap();
    add_to_dictionary(world, "inventory", TokenType::Verb, 14).unwrap();
    add_to_dictionary(world, "inv", TokenType::Verb, 14).unwrap();
    add_to_dictionary(world, "i", TokenType::Verb, 14).unwrap();
    add_to_dictionary(world, "is", TokenType::Verb, 15).unwrap();
    add_to_dictionary(world, "listen", TokenType::Verb, 16).unwrap();
    add_to_dictionary(world, "lock", TokenType::Verb, 17).unwrap();
    add_to_dictionary(world, "look", TokenType::Verb, 18).unwrap();
    add_to_dictionary(world, "l", TokenType::Verb, 18).unwrap();
    add_to_dictionary(world, "open", TokenType::Verb, 19).unwrap();
    add_to_dictionary(world, "pick", TokenType::Verb, 20).unwrap();
    add_to_dictionary(world, "put", TokenType::Verb, 21).unwrap();
    add_to_dictionary(world, "insert", TokenType::Verb, 21).unwrap();
    add_to_dictionary(world, "read", TokenType::Verb, 22).unwrap();
    add_to_dictionary(world, "smell", TokenType::Verb, 23).unwrap();
    add_to_dictionary(world, "stare", TokenType::Verb, 24).unwrap();
    add_to_dictionary(world, "take", TokenType::Verb, 25).unwrap();
    add_to_dictionary(world, "taste", TokenType::Verb, 26).unwrap();
    add_to_dictionary(world, "touch", TokenType::Verb, 27).unwrap();
    add_to_dictionary(world, "unlock", TokenType::Verb, 28).unwrap();
    add_to_dictionary(world, "use", TokenType::Verb, 29).unwrap();
    add_to_dictionary(world, "activate", TokenType::Verb, 29).unwrap();
    add_to_dictionary(world, "push", TokenType::Verb, 30).unwrap();
    add_to_dictionary(world, "search", TokenType::Verb, 31).unwrap();
    add_to_dictionary(world, "show", TokenType::Verb, 32).unwrap();
    add_to_dictionary(world, "inspect", TokenType::Verb, 33).unwrap();
    add_to_dictionary(world, "recruit", TokenType::Verb, 34).unwrap();
    add_to_dictionary(world, "place", TokenType::Verb, 35).unwrap();
    add_to_dictionary(world, "sell", TokenType::Verb, 36).unwrap();
    add_to_dictionary(world, "buy", TokenType::Verb, 37).unwrap();
    add_to_dictionary(world, "introduce", TokenType::Verb, 38).unwrap();
    add_to_dictionary(world, "talk", TokenType::Verb, 39).unwrap();
    add_to_dictionary(world, "play", TokenType::Verb, 40).unwrap();
    add_to_dictionary(world, "validate", TokenType::Verb, 41).unwrap();
    add_to_dictionary(world, "approach", TokenType::Verb, 42).unwrap();
    add_to_dictionary(world, "praise", TokenType::Verb, 43).unwrap();
    add_to_dictionary(world, "pin", TokenType::Verb, 44).unwrap();
    add_to_dictionary(world, "hack", TokenType::Verb, 45).unwrap();
    add_to_dictionary(world, "hang", TokenType::Verb, 46).unwrap();
    add_to_dictionary(world, "feed", TokenType::Verb, 47).unwrap();
    add_to_dictionary(world, "ring", TokenType::Verb, 48).unwrap();
    add_to_dictionary(world, "test", TokenType::Verb, 49).unwrap();
    add_to_dictionary(world, "free", TokenType::Verb, 50).unwrap();
    add_to_dictionary(world, "leave", TokenType::Verb, 51).unwrap();
    add_to_dictionary(world, "scan", TokenType::Verb, 52).unwrap();
    add_to_dictionary(world, "present", TokenType::Verb, 53).unwrap();
    add_to_dictionary(world, "make", TokenType::Verb, 54).unwrap();
    add_to_dictionary(world, "rescue", TokenType::Verb, 55).unwrap();
    add_to_dictionary(world, "sign", TokenType::Verb, 56).unwrap();
    add_to_dictionary(world, "speak", TokenType::Verb, 39).unwrap();

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
    add_to_dictionary(world, "bag", TokenType::Noun, 1).unwrap();
    add_to_dictionary(world, "chest", TokenType::Noun, 1).unwrap();
    add_to_dictionary(world, "ring", TokenType::Noun, 1).unwrap();
    add_to_dictionary(world, "sword", TokenType::Noun, 1).unwrap();
    add_to_dictionary(world, "player", TokenType::Noun, 1).unwrap();
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
    use lore::types::command_type::{TokenType, IntoTokenTypeFelt252};

    #[test]
    fn Dictionary_test_init() {
        let (world, _, _, _, _, _) = helpers::setup_core();
        let entry_1 = get_dict_entry(world, "look").unwrap();
        let entry_2 = get_dict_entry(world, "beautiful").unwrap();
        // println!("entry_1: {:?}", entry_1);
        // println!("entry_2: {:?}", entry_2);
        assert(entry_1.tokenType == TokenType::Verb, 'look is verb');
        assert(entry_2.tokenType == TokenType::Adjective, 'beautiful is adjective');
    }

    #[test]
    fn Dictionary_test_add_to_dictionary() {
        let (world, _, _, _, _, _) = helpers::setup_core();
        add_to_dictionary(world, "something", TokenType::Verb, 1).unwrap();
        let entry_1 = get_dict_entry(world, "something").unwrap();
        assert(entry_1.tokenType == TokenType::Verb, 'beautiful is verb');
        assert(entry_1.dict_key == 'something', 'dict_key is "beautiful"');
        assert(entry_1.word == "something", 'word is "beautiful"');
    }
}
