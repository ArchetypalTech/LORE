use dojo::{world::WorldStorage, model::ModelStorage};
use lore::{
    types::command_type::{TokenType, IntoTokenTypeFelt252},
    lib::{
        utils::ByteArrayTraitExt,
    },
    constants::errors::Error,
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

#[generate_trait]
pub impl DictionaryImpl of DictionaryTrait {

    fn add_to_dictionary(
        ref self: WorldStorage, word: ByteArray, tokenType: TokenType, n_value: felt252,
    ) -> Result<(), Error> {
        if (word.clone().len() >= 31) {
            return Result::Err(Error::WordTooLong);
        }
        let dict_key: felt252 = word.clone().to_felt252_word().unwrap();
        let entry: Dict = Dict { dict_key, word, tokenType: tokenType, n_value };
        self.write_model(@entry);
        Result::Ok(())
    }

    fn get_dict_entry(self: @WorldStorage, word: ByteArray) -> Option<Dict> {
        let dict_key: felt252 = word.clone().to_felt252_word().unwrap();
        let entry: Dict = self.read_model(dict_key);
        if (entry.word == "") {
            return Option::None;
        }
        Option::Some(entry)
    }

    fn is_dictionary_initialized(self: @WorldStorage) -> bool {
        (self.get_dict_entry("intialized").is_some())
    }

    fn initialize_dictionary(ref self: WorldStorage) {
        self._init_dictionary();
        self._init_system_dictionary();
    }

    //
    // Internal
    //

    fn _init_dictionary(ref self: WorldStorage) {
        self.add_to_dictionary("check", TokenType::Verb, 1).unwrap();
        self.add_to_dictionary("climb", TokenType::Verb, 2).unwrap();
        self.add_to_dictionary("close", TokenType::Verb, 3).unwrap();
        self.add_to_dictionary("drop", TokenType::Verb, 4).unwrap();
        self.add_to_dictionary("drink", TokenType::Verb, 5).unwrap();
        self.add_to_dictionary("quaff", TokenType::Verb, 5).unwrap();
        self.add_to_dictionary("eat", TokenType::Verb, 6).unwrap();
        self.add_to_dictionary("consume", TokenType::Verb, 6).unwrap();
        self.add_to_dictionary("enter", TokenType::Verb, 7).unwrap();
        self.add_to_dictionary("in", TokenType::Verb, 7).unwrap();
        self.add_to_dictionary("examine", TokenType::Verb, 8).unwrap();
        self.add_to_dictionary("x", TokenType::Verb, 8).unwrap();
        self.add_to_dictionary("exit", TokenType::Verb, 9).unwrap();
        self.add_to_dictionary("out", TokenType::Verb, 9).unwrap();
        self.add_to_dictionary("feel", TokenType::Verb, 10).unwrap();
        self.add_to_dictionary("get", TokenType::Verb, 11).unwrap();
        self.add_to_dictionary("give", TokenType::Verb, 12).unwrap();
        self.add_to_dictionary("go", TokenType::Verb, 13).unwrap();
        self.add_to_dictionary("move", TokenType::Verb, 13).unwrap();
        self.add_to_dictionary("inventory", TokenType::Verb, 14).unwrap();
        self.add_to_dictionary("inv", TokenType::Verb, 14).unwrap();
        self.add_to_dictionary("i", TokenType::Verb, 14).unwrap();
        self.add_to_dictionary("is", TokenType::Verb, 15).unwrap();
        self.add_to_dictionary("listen", TokenType::Verb, 16).unwrap();
        self.add_to_dictionary("lock", TokenType::Verb, 17).unwrap();
        self.add_to_dictionary("look", TokenType::Verb, 18).unwrap();
        self.add_to_dictionary("l", TokenType::Verb, 18).unwrap();
        self.add_to_dictionary("open", TokenType::Verb, 19).unwrap();
        self.add_to_dictionary("pick", TokenType::Verb, 20).unwrap();
        self.add_to_dictionary("put", TokenType::Verb, 21).unwrap();
        self.add_to_dictionary("insert", TokenType::Verb, 21).unwrap();
        self.add_to_dictionary("read", TokenType::Verb, 22).unwrap();
        self.add_to_dictionary("smell", TokenType::Verb, 23).unwrap();
        self.add_to_dictionary("stare", TokenType::Verb, 24).unwrap();
        self.add_to_dictionary("take", TokenType::Verb, 25).unwrap();
        self.add_to_dictionary("taste", TokenType::Verb, 26).unwrap();
        self.add_to_dictionary("touch", TokenType::Verb, 27).unwrap();
        self.add_to_dictionary("unlock", TokenType::Verb, 28).unwrap();
        self.add_to_dictionary("use", TokenType::Verb, 29).unwrap();
        self.add_to_dictionary("activate", TokenType::Verb, 29).unwrap();
        self.add_to_dictionary("push", TokenType::Verb, 30).unwrap();
        self.add_to_dictionary("search", TokenType::Verb, 31).unwrap();
        self.add_to_dictionary("show", TokenType::Verb, 32).unwrap();
        self.add_to_dictionary("inspect", TokenType::Verb, 33).unwrap();
        self.add_to_dictionary("recruit", TokenType::Verb, 34).unwrap();
        self.add_to_dictionary("place", TokenType::Verb, 35).unwrap();
        self.add_to_dictionary("sell", TokenType::Verb, 36).unwrap();
        self.add_to_dictionary("buy", TokenType::Verb, 37).unwrap();
        self.add_to_dictionary("introduce", TokenType::Verb, 38).unwrap();
        self.add_to_dictionary("talk", TokenType::Verb, 39).unwrap();
        self.add_to_dictionary("play", TokenType::Verb, 40).unwrap();
        self.add_to_dictionary("validate", TokenType::Verb, 41).unwrap();
        self.add_to_dictionary("approach", TokenType::Verb, 42).unwrap();
        self.add_to_dictionary("praise", TokenType::Verb, 43).unwrap();
        self.add_to_dictionary("pin", TokenType::Verb, 44).unwrap();
        self.add_to_dictionary("hack", TokenType::Verb, 45).unwrap();
        self.add_to_dictionary("hang", TokenType::Verb, 46).unwrap();
        self.add_to_dictionary("feed", TokenType::Verb, 47).unwrap();
        self.add_to_dictionary("ring", TokenType::Verb, 48).unwrap();
        self.add_to_dictionary("test", TokenType::Verb, 49).unwrap();
        self.add_to_dictionary("free", TokenType::Verb, 50).unwrap();
        self.add_to_dictionary("leave", TokenType::Verb, 51).unwrap();
        self.add_to_dictionary("scan", TokenType::Verb, 52).unwrap();
        self.add_to_dictionary("present", TokenType::Verb, 53).unwrap();
        self.add_to_dictionary("make", TokenType::Verb, 54).unwrap();
        self.add_to_dictionary("rescue", TokenType::Verb, 55).unwrap();
        self.add_to_dictionary("sign", TokenType::Verb, 56).unwrap();
        self.add_to_dictionary("speak", TokenType::Verb, 39).unwrap();
        // directions
        self.add_to_dictionary("north", TokenType::Direction, 1).unwrap();
        self.add_to_dictionary("n", TokenType::Direction, 1).unwrap();
        self.add_to_dictionary("south", TokenType::Direction, 2).unwrap();
        self.add_to_dictionary("s", TokenType::Direction, 2).unwrap();
        self.add_to_dictionary("east", TokenType::Direction, 3).unwrap();
        self.add_to_dictionary("e", TokenType::Direction, 3).unwrap();
        self.add_to_dictionary("west", TokenType::Direction, 4).unwrap();
        self.add_to_dictionary("w", TokenType::Direction, 4).unwrap();
        self.add_to_dictionary("up", TokenType::Direction, 5).unwrap();
        self.add_to_dictionary("u", TokenType::Direction, 5).unwrap();
        self.add_to_dictionary("down", TokenType::Direction, 6).unwrap();
        self.add_to_dictionary("d", TokenType::Direction, 6).unwrap();
        self.add_to_dictionary("around", TokenType::Direction, 7).unwrap();
        self.add_to_dictionary("ahead", TokenType::Direction, 8).unwrap();
        self.add_to_dictionary("behind", TokenType::Direction, 8).unwrap();
        // adjectives
        self.add_to_dictionary("good", TokenType::Adjective, 1).unwrap();
        self.add_to_dictionary("bad", TokenType::Adjective, 2).unwrap();
        self.add_to_dictionary("happy", TokenType::Adjective, 3).unwrap();
        self.add_to_dictionary("sad", TokenType::Adjective, 4).unwrap();
        self.add_to_dictionary("beautiful", TokenType::Adjective, 5).unwrap();
        self.add_to_dictionary("ugly", TokenType::Adjective, 6).unwrap();
        self.add_to_dictionary("tall", TokenType::Adjective, 7).unwrap();
        self.add_to_dictionary("short", TokenType::Adjective, 8).unwrap();
        self.add_to_dictionary("fat", TokenType::Adjective, 9).unwrap();
        self.add_to_dictionary("thick", TokenType::Adjective, 10).unwrap();
        self.add_to_dictionary("thin", TokenType::Adjective, 11).unwrap();
        self.add_to_dictionary("big", TokenType::Adjective, 12).unwrap();
        self.add_to_dictionary("small", TokenType::Adjective, 13).unwrap();
        self.add_to_dictionary("long", TokenType::Adjective, 14).unwrap();
        self.add_to_dictionary("illegal", TokenType::Adjective, 14).unwrap();
        // articles
        self.add_to_dictionary("a", TokenType::Article, 1).unwrap();
        self.add_to_dictionary("an", TokenType::Article, 1).unwrap();
        self.add_to_dictionary("the", TokenType::Article, 1).unwrap();
        // prepositions
        self.add_to_dictionary("in", TokenType::Preposition, 1).unwrap();
        self.add_to_dictionary("on", TokenType::Preposition, 2).unwrap();
        self.add_to_dictionary("with", TokenType::Preposition, 3).unwrap();
        self.add_to_dictionary("at", TokenType::Preposition, 4).unwrap();
        self.add_to_dictionary("to", TokenType::Preposition, 5).unwrap();
        self.add_to_dictionary("into", TokenType::Preposition, 6).unwrap();
        self.add_to_dictionary("out", TokenType::Preposition, 7).unwrap();
        self.add_to_dictionary("from", TokenType::Preposition, 8).unwrap();
        self.add_to_dictionary("off", TokenType::Preposition, 9).unwrap();
        self.add_to_dictionary("for", TokenType::Preposition, 10).unwrap();
        self.add_to_dictionary("by", TokenType::Preposition, 11).unwrap();
        self.add_to_dictionary("of", TokenType::Preposition, 12).unwrap();
        // pronouns
        self.add_to_dictionary("it", TokenType::Pronoun, 1).unwrap();
        self.add_to_dictionary("them", TokenType::Pronoun, 2).unwrap();
        self.add_to_dictionary("me", TokenType::Pronoun, 3).unwrap();
        self.add_to_dictionary("you", TokenType::Pronoun, 4).unwrap();
        self.add_to_dictionary("he", TokenType::Pronoun, 5).unwrap();
        self.add_to_dictionary("she", TokenType::Pronoun, 6).unwrap();
        self.add_to_dictionary("him", TokenType::Pronoun, 7).unwrap();
        self.add_to_dictionary("her", TokenType::Pronoun, 8).unwrap();
        self.add_to_dictionary("this", TokenType::Pronoun, 9).unwrap();
        self.add_to_dictionary("that", TokenType::Pronoun, 8).unwrap();
        // quantifiers
        self.add_to_dictionary("all", TokenType::Quantifier, 256).unwrap();
        self.add_to_dictionary("one", TokenType::Quantifier, 1).unwrap();
        self.add_to_dictionary("1", TokenType::Quantifier, 1).unwrap();
        self.add_to_dictionary("two", TokenType::Quantifier, 2).unwrap();
        self.add_to_dictionary("2", TokenType::Quantifier, 2).unwrap();
        self.add_to_dictionary("three", TokenType::Quantifier, 3).unwrap();
        self.add_to_dictionary("3", TokenType::Quantifier, 3).unwrap();
        self.add_to_dictionary("four", TokenType::Quantifier, 4).unwrap();
        self.add_to_dictionary("4", TokenType::Quantifier, 4).unwrap();
        self.add_to_dictionary("five", TokenType::Quantifier, 5).unwrap();
        self.add_to_dictionary("5", TokenType::Quantifier, 5).unwrap();
        self.add_to_dictionary("six", TokenType::Quantifier, 6).unwrap();
        self.add_to_dictionary("6", TokenType::Quantifier, 6).unwrap();
        self.add_to_dictionary("seven", TokenType::Quantifier, 7).unwrap();
        self.add_to_dictionary("7", TokenType::Quantifier, 7).unwrap();
        self.add_to_dictionary("eight", TokenType::Quantifier, 8).unwrap();
        self.add_to_dictionary("8", TokenType::Quantifier, 8).unwrap();
        self.add_to_dictionary("nine", TokenType::Quantifier, 9).unwrap();
        self.add_to_dictionary("9", TokenType::Quantifier, 9).unwrap();
        self.add_to_dictionary("ten", TokenType::Quantifier, 10).unwrap();
        self.add_to_dictionary("10", TokenType::Quantifier, 10).unwrap();
        self.add_to_dictionary("more", TokenType::Quantifier, 255).unwrap();
        self.add_to_dictionary("less", TokenType::Quantifier, 255).unwrap();
        self.add_to_dictionary("most", TokenType::Quantifier, 255).unwrap();
        self.add_to_dictionary("least", TokenType::Quantifier, 255).unwrap();
        // nouns
        self.add_to_dictionary("noun", TokenType::Noun, 1).unwrap();
        self.add_to_dictionary("object", TokenType::Noun, 1).unwrap();
        self.add_to_dictionary("ball", TokenType::Noun, 1).unwrap();
        self.add_to_dictionary("bag", TokenType::Noun, 1).unwrap();
        self.add_to_dictionary("chest", TokenType::Noun, 1).unwrap();
        self.add_to_dictionary("ring", TokenType::Noun, 1).unwrap();
        self.add_to_dictionary("sword", TokenType::Noun, 1).unwrap();
        self.add_to_dictionary("player", TokenType::Noun, 1).unwrap();
        self.add_to_dictionary("trail", TokenType::Noun, 1).unwrap();
        // interrogatives
        self.add_to_dictionary("who", TokenType::Interrogative, 1).unwrap();
        self.add_to_dictionary("what", TokenType::Interrogative, 2).unwrap();
        self.add_to_dictionary("where", TokenType::Interrogative, 3).unwrap();
        self.add_to_dictionary("why", TokenType::Interrogative, 4).unwrap();
        self.add_to_dictionary("how", TokenType::Interrogative, 5).unwrap();
        // dictionary is initialized
        self.add_to_dictionary("intialized", TokenType::System, 1).unwrap();
    }

    fn _init_system_dictionary(ref self: WorldStorage) {
        self.add_to_dictionary("system_initialized", TokenType::System, 2).unwrap();
        self.add_to_dictionary("g_debug", TokenType::System, 2).unwrap();
        self.add_to_dictionary("g_command", TokenType::System, 2).unwrap();
        self.add_to_dictionary("g_move", TokenType::System, 2).unwrap();
        self.add_to_dictionary("g_init_dict", TokenType::System, 2).unwrap();
        self.add_to_dictionary("g_error", TokenType::System, 2).unwrap();
        self.add_to_dictionary("g_level", TokenType::System, 2).unwrap();
        self.add_to_dictionary("g_whereami", TokenType::System, 2).unwrap();
        self.add_to_dictionary("g_look", TokenType::System, 2).unwrap();
        self.add_to_dictionary("g_create_game", TokenType::System, 2).unwrap();
        self.add_to_dictionary("g_load_game", TokenType::System, 2).unwrap();
        self.add_to_dictionary("g_game_id", TokenType::System, 2).unwrap();
        self.add_to_dictionary("g_game_data", TokenType::System, 2).unwrap();
        self.add_to_dictionary("g_player", TokenType::System, 2).unwrap();
        self.add_to_dictionary("g_create_trail", TokenType::System, 2).unwrap();
        self.add_to_dictionary("g_actions", TokenType::System, 2).unwrap();
    }
}


#[cfg(test)]
mod tests {
    use lore::tests::helpers;
    use super::*;
    use lore::types::command_type::{TokenType, IntoTokenTypeFelt252};

    #[test]
    fn Dictionary_test_init() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let entry_1: Dict = sys.world.get_dict_entry("look").unwrap();
        let entry_2: Dict = sys.world.get_dict_entry("beautiful").unwrap();
        // println!("entry_1: {:?}", entry_1);
        // println!("entry_2: {:?}", entry_2);
        assert(entry_1.tokenType == TokenType::Verb, 'look is verb');
        assert(entry_2.tokenType == TokenType::Adjective, 'beautiful is adjective');
    }

    #[test]
    fn Dictionary_test_add_to_dictionary() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let _entry_1: Dict = sys.world.get_dict_entry("look").unwrap();
        sys.world.add_to_dictionary("something", TokenType::Verb, 1).unwrap();
        let entry_1: Dict = sys.world.get_dict_entry("something").unwrap();
        assert(entry_1.tokenType == TokenType::Verb, 'beautiful is verb');
        assert(entry_1.dict_key == 'something', 'dict_key is "beautiful"');
        assert(entry_1.word == "something", 'word is "beautiful"');
    }
}
