#[derive(Copy, Drop, Debug)]
pub enum Error {
    // Utils
    Unimplemented,
    // Lexer
    WordTooLong,
    LexerFailed,
    // Commands
    TestError,
    ActionFailed,
    NotSystemAction,
    // World
    EntityNotFound,
    // Dictionary
    NoDictionaryMatch,
    None,
    // Triggers
    TriggerNotFound,
    NameTooLong,
    FailedToUpdateTriggerIndex,
    FailedToRemoveTriggerIndex,
    // Effects
    EffectFailed,
    EffectNotFound,
}
