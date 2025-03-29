// inspired by Inform 6 grammar
#[derive(Debug, Clone, PartialEq, Hash)]
pub enum Action {
    None,
    // Movement
    Go,
    Enter,
    Exit,
    GetOff,
    JumpOver,
    
    // Looking
    Look,
    Examine,
    Search,
    LookUnder,
    LookIn,
    
    // Inventory
    Inventory,
    Take,
    Drop,
    Put,
    PutOn,
    Insert,
    Remove,
    Empty,
    EmptyInto,
    
    // Manipulation
    Open,
    Close,
    Unlock,
    Lock,
    SwitchOn,
    SwitchOff,
    Turn,
    Push,
    Pull,
    
    // Object interaction
    Eat,
    Drink,
    Wear,
    Disrobe,
    Touch,
    Taste,
    Smell,
    Listen,
    Rub,
    Throw,
    Give,
    Show,
    
    // Communication
    Talk,
    Ask,
    Tell,
    Answer,
    
    // System commands
    Quit,
    Restart,
    Restore,
    Save,
    Script,
    Unscript,
    Score,
    Version,
    Help,
    
    // Meta commands
    Verbose,
    Brief,
    Superbrief,
    Pronouns,
    NotifyOn,
    NotifyOff,
    
    // Other
    Wait,
    Sleep,
    Wake,
    WakeOther,
    Attack,
    Burn,
    Buy,
    Climb,
    Cut,
    Dig,
    Fill,
    Jump,
    JumpIn,
    JumpOn,
    Kiss,
    Pray,
    Sing,
    Squeeze,
    Swim,
    Swing,
    Tie,
    Transfer,
    
    // Special
    Mild,
    Strong,
    Sorry,
    Think,
    Yes,
    No,
}

impl ActionImpl of Action {
    /// Get the Action from a verb string
    pub fn from_verb(verb: ByteArray) -> Option<Self> {
        match verb.to_lowercase().as_str() {
            // Movement
            "go" | "walk" | "run" => Some(Action::Go),
            "enter" | "cross" => Some(Action::Enter),
            "exit" | "out" | "outside" => Some(Action::Exit),
            "leave" => Some(Action::Exit),
            "get off" => Some(Action::GetOff),
            "jump over" => Some(Action::JumpOver),
            
            // Looking
            "look" | "l" => Some(Action::Look),
            "examine" | "x" | "check" | "describe" | "watch" => Some(Action::Examine),
            "search" => Some(Action::Search),
            "look under" => Some(Action::LookUnder),
            "look in" | "look into" | "look inside" => Some(Action::LookIn),
            
            // Inventory
            "inventory" | "inv" | "i" => Some(Action::Inventory),
            "take" | "get" | "pick" | "pick up" | "carry" | "hold" => Some(Action::Take),
            "drop" | "discard" => Some(Action::Drop),
            "put" => Some(Action::Put),
            "put on" => Some(Action::PutOn),
            "insert" => Some(Action::Insert),
            "remove" => Some(Action::Remove),
            "empty" => Some(Action::Empty),
            "empty into" => Some(Action::EmptyInto),
            
            // Manipulation
            "open" | "uncover" | "undo" | "unwrap" => Some(Action::Open),
            "close" | "cover" | "shut" => Some(Action::Close),
            "unlock" => Some(Action::Unlock),
            "lock" => Some(Action::Lock),
            "switch on" | "turn on" => Some(Action::SwitchOn),
            "switch off" | "turn off" => Some(Action::SwitchOff),
            "turn" | "rotate" | "screw" | "twist" | "unscrew" => Some(Action::Turn),
            "push" | "clear" | "move" | "press" | "shift" => Some(Action::Push),
            "pull" | "drag" => Some(Action::Pull),
            
            // Object interaction
            "eat" => Some(Action::Eat),
            "drink" | "sip" | "swallow" => Some(Action::Drink),
            "wear" | "don" => Some(Action::Wear),
            "disrobe" | "doff" | "shed" => Some(Action::Disrobe),
            "touch" | "feel" | "fondle" | "grope" => Some(Action::Touch),
            "taste" => Some(Action::Taste),
            "smell" | "sniff" => Some(Action::Smell),
            "listen" | "hear" => Some(Action::Listen),
            "rub" | "clean" | "dust" | "polish" | "scrub" | "shine" | "sweep" | "wipe" => Some(Action::Rub),
            "throw" => Some(Action::Throw),
            "give" | "feed" | "offer" | "pay" => Some(Action::Give),
            "show" | "display" | "present" => Some(Action::Show),
            
            // Communication
            "talk" => Some(Action::Talk),
            "ask" => Some(Action::Ask),
            "tell" => Some(Action::Tell),
            "answer" | "say" | "shout" | "speak" => Some(Action::Answer),
            
            // System commands
            "quit" | "q" | "die" => Some(Action::Quit),
            "restart" => Some(Action::Restart),
            "restore" => Some(Action::Restore),
            "save" => Some(Action::Save),
            "script" | "transcript" => Some(Action::Script),
            "noscript" | "unscript" => Some(Action::Unscript),
            "score" => Some(Action::Score),
            "version" => Some(Action::Version),
            "help" | "hint" | "hints" => Some(Action::Help),
            
            // Meta commands
            "verbose" | "long" => Some(Action::Verbose),
            "brief" => Some(Action::Brief),
            "superbrief" | "short" => Some(Action::Superbrief),
            "pronouns" | "nouns" => Some(Action::Pronouns),
            "notify on" => Some(Action::NotifyOn),
            "notify off" => Some(Action::NotifyOff),
            
            // Other
            "wait" | "z" => Some(Action::Wait),
            "sleep" | "nap" => Some(Action::Sleep),
            "wake" | "awake" | "awaken" => Some(Action::Wake),
            "wake up" => Some(Action::WakeOther),
            "attack" | "break" | "crack" | "destroy" | "fight" | "hit" | "kill" |
            "murder" | "punch" | "smash" | "thump" | "torture" | "wreck" => Some(Action::Attack),
            "burn" | "light" => Some(Action::Burn),
            "buy" | "purchase" => Some(Action::Buy),
            "climb" | "scale" => Some(Action::Climb),
            "cut" | "chop" | "prune" | "slice" => Some(Action::Cut),
            "dig" => Some(Action::Dig),
            "fill" => Some(Action::Fill),
            "jump" | "hop" | "skip" => Some(Action::Jump),
            "jump in" => Some(Action::JumpIn),
            "jump on" => Some(Action::JumpOn),
            "kiss" | "embrace" | "hug" => Some(Action::Kiss),
            "pray" => Some(Action::Pray),
            "sing" => Some(Action::Sing),
            "squeeze" | "squash" => Some(Action::Squeeze),
            "swim" | "dive" => Some(Action::Swim),
            "swing" => Some(Action::Swing),
            "tie" | "attach" | "connect" | "fasten" | "fix" => Some(Action::Tie),
            "transfer" => Some(Action::Transfer),
            
            // Special
            "bother" | "curses" | "darn" | "drat" => Some(Action::Mild),
            "shit" | "damn" | "fuck" | "sod" => Some(Action::Strong),
            "sorry" => Some(Action::Sorry),
            "think" => Some(Action::Think),
            "yes" | "y" => Some(Action::Yes),
            "no" | "n" => Some(Action::No),
            
            _ => None,
        }
    }
}