use core::option::{OptionTraitImpl};

#[starknet::interface]
pub trait IPrompt<T> {
    fn prompt(ref self: T, cmd: ByteArray);
}

#[dojo::contract]
pub mod prompt {
    use super::{IPrompt};
    use starknet::{get_caller_address};
    use dojo::{world::{WorldStorage}};
    use lore::components::{player::{PlayerImpl, caller_as_player}};
    use lore::lib::{a_lexer::{lexer}, random::{random_text}, c_handler::{handle_command} //
    // dictionary::{init_dictionary},
    };

    #[constructor]
    fn constructor(
        ref self: ContractState,
    ) { // TODO:  Panicked with ("Contract `prompt` does NOT have WRITER role on model (or its
    // namespace) `Dict`", 0x454e545259504f494e545f4641494c4544 ('ENTRYPOINT_FAILED'),
    // 0x434f4e5354525543544f525f4641494c4544 ('CONSTRUCTOR_FAILED'), caused in helper, need to fix
    // test permissions let mut world: WorldStorage = self.world(@"lore");
    // init_dictionary(world);
    }

    #[abi(embed_v0)]
    pub impl PromptImpl of IPrompt<ContractState> {
        fn prompt(ref self: ContractState, cmd: ByteArray) {
            let mut world: WorldStorage = self.world(@"lore");
            let player = caller_as_player(world, get_caller_address());

            player.add_command_text(world, cmd.clone());
            match (lexer::parse(cmd, world, player)) {
                Result::Ok(result) => {
                    let res = handle_command(result, world, player);
                    if !res.is_ok() {
                        player.say(world, random_text(world, random_error()));
                    }
                },
                Result::Err(_r) => { player.say(world, random_text(world, random_error())); },
            }
        }
    }

    pub fn random_intro() -> Array<ByteArray> {
        array![
            "Hello, yeah",
            "It's still just very bright here",
            "Yeah, you're still here",
            "Not sure what's happening yet",
            "Looks like a void for now",
        ]
    }

    pub fn random_error() -> Array<ByteArray> {
        array![
            "I don't know what that means",
            "Nope",
            "Can you repeat that?",
            "I'm at a loss",
            "You're not helping",
            "I can't imagine",
        ]
    }
}
