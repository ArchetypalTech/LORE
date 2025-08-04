#[derive(Serde, Clone, Drop, Debug, PartialEq, Introspect)]
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
    OnceUseOnly,
    // Conditions
    ConditionFailed,
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
    NoReactableComponent,
    NoInventoryItemComponent,
    NoContainerComponent,
    NoPlayerComponent,
    // Entity
    NoTargetEntity,
}
