pub mod systems {
    pub mod designer;
    pub mod prompt;
}

pub mod components;

pub mod constants;

pub mod lib {
    pub mod a_lexer;
    pub mod dictionary;
    pub mod entity;
    pub mod random;
    pub mod relations;
    pub mod utils;
    pub mod level_test;
}

#[cfg(test)]
pub mod tests {
    pub mod helpers;
}
