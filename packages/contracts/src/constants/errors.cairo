#[derive(Copy, Drop, Debug)]
pub enum Error {
    // Utils
    WordTooLong,
    // Lexer
    LexerFailed,
    // Actions
    ActionFailed,
    // World
    EntityNotFound,
    // Dictionary
    NoDictionaryMatch,
    None,
}
