pub mod systems {
    pub mod designer;
    pub mod prompt;
    pub mod game_token;
    pub mod trail_token;
    pub mod actions_token;
}

pub mod constants {
    pub mod constants;
    pub mod errors;
    pub mod token_metadata;
}

pub mod lib {
    pub mod a_lexer;
    pub mod c_handler;
    pub mod access;
    pub mod random;
    pub mod utils;
    pub mod arrays;
    pub mod dns;
    pub mod trophies;
    pub mod level_test;
    pub mod errors_texts_output;
    pub mod variable_property_helper;
    // pub mod variable_property;
}

pub mod models {
    pub mod action;
    pub mod area;
    pub mod components;
    pub mod condition;
    pub mod container;
    pub mod description_text;
    pub mod dictionary;
    pub mod effect;
    pub mod entity;
    pub mod exit;
    pub mod game_instance;
    pub mod index;
    pub mod inventory_item;
    pub mod player;
    pub mod player_account;
    pub mod reactable;
    pub mod trigger;
    pub mod hub;
    pub mod game_token_info;
    pub mod trail_token_info;
    pub mod actions_config;
}

pub mod types {
    pub mod action_type;
    pub mod command_type;
    pub mod component_type;
    pub mod direction_type;
    pub mod property_type;
}

#[cfg(test)]
pub mod tests {
    pub mod designer_test;
    pub mod entity_test;
    pub mod game_token_test;
    pub mod trail_token_test;
    pub mod actions_token_test;
    pub mod helpers;
}
