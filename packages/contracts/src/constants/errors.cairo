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
    NotInTheSameTrail,
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
    // Exit
    NameNotMatch,
    DirectionNotMatch,
    Unenterable,
    // Reactable
    FailToReactTo,
    NoTarget,
    // Container
    NotOpen,
    ContainerFull,
    CantStore,
    NoPersonalContainer,
    NoContainer,
    // Inventory Item
    CantBePicked,
    CantBeStored,
    AlreadyStored,
    NotStored,
    // Player
    NoRoom,
    NotYourGame,
    NotEditor,
    InsufficientActionsBalance,
}
