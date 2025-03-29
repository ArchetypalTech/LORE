use core::option::{OptionTraitImpl};

#[starknet::interface]
pub trait IPrompt<T> {
    fn prompt(ref self: T, cmd: ByteArray);
}

#[dojo::contract]
pub mod prompt {
    use super::{IPrompt};
    use starknet::{get_caller_address};
    use dojo::{world::{WorldStorage, IWorldDispatcherTrait}};
    use lore::components::{player::{PlayerImpl, caller_as_player}};
    use lore::lib::a_lexer::{lexer};
    use lore::lib::random;

    #[abi(embed_v0)]
    pub impl PromptImpl of IPrompt<ContractState> {
        fn prompt(ref self: ContractState, cmd: ByteArray) {
            let mut world: WorldStorage = self.world(@"lore");
            let player = caller_as_player(world, get_caller_address());

            player.add_command_text(world, cmd.clone());
            match (lexer::parse(cmd, world, player)) {
                Result::Ok(result) => {
                    println!("result: {:?}", result);
                    player.say(world, random_intro_text(world))
                },
                Result::Err(_r) => { player.say(world, "I don't know what that means"); },
            }
        }
    }

    pub fn random_intro_text(world: WorldStorage) -> ByteArray {
        let randomIntroText: Array<ByteArray> = array![
            "Hello, yeah",
            "It's still just very bright here",
            "Yeah, you're still here",
            "Not sure what's happening yet",
            "Looks like a void for now",
        ];
        let rng: u32 = random::random_u16(world.dispatcher.uuid().try_into().unwrap())
            .try_into()
            .unwrap();
        let description = randomIntroText.at(rng % randomIntroText.len()).clone();
        description
    }
}
