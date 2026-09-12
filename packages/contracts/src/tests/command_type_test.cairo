use lore::types::command_type::{Command, CommandImpl, CommandType, Token, TokenType};

fn make_token(text: ByteArray, token_type: TokenType, target: felt252) -> Token {
    Token {
        position: 0,
        text,
        token_type,
        token_value: 0,
        target,
    }
}

fn make_command(tokens: Array<Token>) -> Command {
    Command {
        command_id: 1,
        text: "",
        words: array![],
        token_count: tokens.len().try_into().unwrap(),
        action_type: 0,
        tokens,
        command_type: CommandType::Action,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_get_action_targets_single_noun() {
        // "use door" -> one resolved target
        let door_inst: felt252 = 111;
        let command: Command = make_command(
            array![
                make_token("use", TokenType::Verb, 0),
                make_token("door", TokenType::Noun, door_inst),
            ],
        );

        let targets: Array<felt252> = command.get_action_targets();
        assert(targets.len() == 1, 'expected 1 target');
        assert(*targets.at(0) == door_inst, 'wrong target inst');
    }

    #[test]
    fn test_get_action_targets_two_nouns() {
        // "give token to officer" -> two resolved targets, in token order
        let token_inst: felt252 = 222;
        let officer_inst: felt252 = 333;
        let command: Command = make_command(
            array![
                make_token("give", TokenType::Verb, 0),
                make_token("token", TokenType::Noun, token_inst),
                make_token("to", TokenType::Preposition, 0),
                make_token("officer", TokenType::Noun, officer_inst),
            ],
        );

        let targets: Array<felt252> = command.get_action_targets();
        assert(targets.len() == 2, 'expected 2 targets');
        assert(*targets.at(0) == token_inst, 'wrong first target');
        assert(*targets.at(1) == officer_inst, 'wrong second target');
    }

    #[test]
    fn test_get_action_targets_no_noun() {
        // "look" -> no noun tokens at all -> empty array
        let command: Command = make_command(array![make_token("look", TokenType::Verb, 0)]);

        let targets: Array<felt252> = command.get_action_targets();
        assert(targets.len() == 0, 'expected no targets');
    }

    #[test]
    fn test_get_action_targets_skips_unresolved_noun() {
        // A noun the lexer couldn't resolve to an entity (target still 0) must not
        // be treated as a revenue-split target.
        let command: Command = make_command(
            array![
                make_token("look", TokenType::Verb, 0),
                make_token("at", TokenType::Preposition, 0),
                make_token("bird", TokenType::Noun, 0), // unresolved
            ],
        );

        let targets: Array<felt252> = command.get_action_targets();
        assert(targets.len() == 0, 'unresolved noun not skipped');
    }

    #[test]
    fn test_get_action_targets_mixed_resolved_and_unresolved() {
        // Only the resolved noun should come back.
        let known_inst: felt252 = 444;
        let command: Command = make_command(
            array![
                make_token("give", TokenType::Verb, 0),
                make_token("bird", TokenType::Noun, 0), // unresolved
                make_token("to", TokenType::Preposition, 0),
                make_token("officer", TokenType::Noun, known_inst),
            ],
        );

        let targets: Array<felt252> = command.get_action_targets();
        assert(targets.len() == 1, 'expected 1 resolved target');
        assert(*targets.at(0) == known_inst, 'wrong resolved target');
    }
}
