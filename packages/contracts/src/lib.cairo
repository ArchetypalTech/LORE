pub mod systems {
    pub mod designer;
    pub mod prompt;
}

pub mod components;

pub mod constants;

// Shinigami Architecture Layers
pub mod helpers;    // Layer 1: Pure utility functions
pub mod services;   // Layer 2: Business logic & world state integration
pub mod types;      // Layer 3: Entry points & routing
pub mod models;     // Layer 4: Enhanced entity & component modeling

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

#[cfg(test)]
pub mod tests {
    pub mod entity_test;
    pub mod helpers;
}
