#[derive(Copy, Drop, Debug, PartialEq)]
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
    TriggerNotMeetConditions,
    // Effects
    EffectFailed,
    EffectNotFound,
    ReadOnlyVariable,
    // PropertyResgistry
    NoPropertyRegistry,
    // Componets
    NoComponent,
    NoAreaComponent,
    NoExitComponent,
    NoInspectableComponent,
    NoInventoryItemComponent,
    NoContainerComponent,
    NoPlayerComponent,
}
