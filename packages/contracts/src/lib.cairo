pub mod systems {
    pub mod designer;
    pub mod prompt;
}

pub mod components;

pub mod constants;

pub mod lib {
    pub mod a_lexer;
    pub mod dictionary;
    pub mod c_handler;
    pub mod entity;
    pub mod random;
    pub mod relations;
    pub mod utils;
    pub mod level_test;
    pub mod trigger;
    pub mod condition;
    pub mod variable_property;
    pub mod variable_property_helper;
    pub mod effect;
    pub mod actions;
}

pub mod models {
    pub mod index;
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
    pub mod entity_test;
    pub mod helpers;
}
