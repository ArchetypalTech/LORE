// Here you can find the command, token structs and token types.

#[derive(Clone, Drop, Serde, Debug, Introspect, DojoStore, Default)]
pub struct Command {
    #[key]
    pub command_id: felt252, // Unique ID of this command
    /// Full command text
    pub text: ByteArray,
    /// Command splited into words
    pub words: Array<ByteArray>,
    /// Number of tokens in the command
    pub token_count: u8,
    /// Type of action (using ActionType enum as u8)
    pub action_type: u8,
    /// Array of tokens in the command
    pub tokens: Array<Token>,
}

#[derive(Clone, Drop, Serde, Debug, Introspect, DojoStore, Default)]
pub struct Token {
    /// Token position in the command
    pub position: u32,
    /// The token text as ByteArray
    pub text: ByteArray,
    /// Type of token (using TokenType enum as u8)
    pub token_type: TokenType,
    /// Value of token (ie directionId, obj inst)
    pub token_value: felt252,
    /// Target object (inst for token)
    pub target: felt252,
}


#[derive(Copy, Drop, Serde, Debug, Introspect, PartialEq, DojoStore, Default)]
pub enum TokenType {
    #[default]
    Unknown,
    Verb, // go, take, drop, look, inventory, spawn
    Direction, // north, south, east, west
    Article, // the, a
    Preposition, // in, on, at, to
    Pronoun, // they, it, me, you
    Adjective, // good, bad, happy, sad
    Noun, // noun, object
    Quantifier, // number, quantity
    Interrogative, // who, what, where, why, how
    System,
}

// Implementation into Felt252 //

pub impl IntoTokenTypeFelt252 of core::traits::Into<TokenType, felt252> {
    #[inline]
    fn into(self: TokenType) -> felt252 {
        match self {
            TokenType::Unknown => 0,
            TokenType::Verb => 1,
            TokenType::Direction => 2,
            TokenType::Article => 3,
            TokenType::Preposition => 4,
            TokenType::Pronoun => 5,
            TokenType::Adjective => 6,
            TokenType::Noun => 7,
            TokenType::Quantifier => 8,
            TokenType::Interrogative => 9,
            TokenType::System => 10,
        }
    }
}

// Implementation into TokenType //
pub impl IntoFelt252TokenType of core::traits::Into<felt252, TokenType> {
    #[inline]
    fn into(self: felt252) -> TokenType {
        match self {
            0 => TokenType::Unknown,
            1 => TokenType::Verb,
            2 => TokenType::Direction,
            3 => TokenType::Article,
            4 => TokenType::Preposition,
            5 => TokenType::Pronoun,
            6 => TokenType::Adjective,
            7 => TokenType::Noun,
            8 => TokenType::Quantifier,
            9 => TokenType::Interrogative,
            10 => TokenType::System,
            _ => TokenType::Unknown,
        }
    }
}

// convert type to ByteArray for debugging
pub impl IntoTokenTypeByteArray of core::traits::Into<TokenType, ByteArray> {
    #[inline]
    fn into(self: TokenType) -> ByteArray {
        match self {
            TokenType::Unknown => "Unknown",
            TokenType::Verb => "Verb",
            TokenType::Direction => "Direction",
            TokenType::Article => "Article",
            TokenType::Preposition => "Preposition",
            TokenType::Pronoun => "Pronoun",
            TokenType::Adjective => "Adjective",
            TokenType::Noun => "Noun",
            TokenType::Quantifier => "Quantifier",
            TokenType::Interrogative => "Interrogative",
            TokenType::System => "System",
        }
    }
}


#[generate_trait]
pub impl CommandImpl of CommandTrait {
    fn is_system_command(self: @Command) -> bool {
        let mut is_system_command: bool = false;
        for token in self.clone().tokens {
            if token.token_type == TokenType::System {
                is_system_command = true;
                break;
            }
        };
        is_system_command
    }
    //get_targets() -> Array<Entity>
    // let list = command.get_targets();
    // let amount = list.len();

    fn get_verbs(self: @Command) -> Span<Token> {
        let mut verbs: Array<Token> = array![];
        for i in 0..self.tokens.len() {
            let token: Token = self.tokens.at(i).clone();

            // Only proceed if it's a verb
            if token.token_type != TokenType::Verb {
                continue;
            }
            verbs.append(token.clone());
        };
        (verbs.span())
    }

    fn get_nouns(self: @Command) -> Span<Token> {
        let mut nouns: Array<Token> = array![];
        for i in 0..self.tokens.len() {
            let token: Token = self.tokens.at(i).clone();

            // Only consider tokens labeled as Noun
            if token.token_type != TokenType::Noun {
                continue;
            }
            nouns.append(token.clone());
        };
        (nouns.span())
    }

    fn get_directions(self: @Command) -> Span<Token> {
        let mut directions: Array<Token> = array![];
        for i in 0..self.tokens.len() {
            let token: Token = self.tokens.at(i).clone();

            // Only consider direction-type tokens
            if token.token_type != TokenType::Direction {
                continue;
            }
            directions.append(token.clone());
        };
        (directions.span())
    }

    fn get_Targets(self: @Command) -> Span<Token> {
        let mut targets: Array<Token> = array![];
        for i in 0..self.tokens.len() {
            let token: Token = self.tokens.at(i).clone();
            // Only consider Noun-type tokens
            if token.token_type != TokenType::Noun {
                continue;
            }
            // Only consider if the target is different from 0
            if token.target != 0 {
                continue;
            }

            targets.append(token.clone());
        };
        (targets.span())
    }

    fn pretty_print(self: @Command) {
        // println!("Command: {:?}", self);
        for _token in self.tokens.clone() { // println!("{:?}: {:?}", token.text, token);
        };
    }
}

