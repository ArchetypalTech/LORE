use starknet::{ContractAddress, ClassHash};
use dojo::world::{WorldStorage, WorldStorageTrait};

pub use lore::{
    systems::{
    game_token::{IGameTokenDispatcher, IGameTokenDispatcherTrait},
    prompt::{IPromptDispatcher, IPromptDispatcherTrait},
    designer::{IDesignerDispatcher, IDesignerDispatcherTrait},
    },
    lib::{
        a_lexer::{ILexerLibraryDispatcher, ILexerDispatcherTrait},
    }
};

pub mod SELECTORS {
    // systems
    pub const PROMPT: felt252 = selector_from_tag!("lore-prompt");
    pub const DESIGNER: felt252 = selector_from_tag!("lore-designer");
    pub const GAME_TOKEN: felt252 = selector_from_tag!("lore-game_token");
}

#[generate_trait]
pub impl DnsImpl of DnsTrait {
    fn find_contract_address(self: @WorldStorage, contract_name: @ByteArray) -> ContractAddress {
        // let (contract_address, _) = self.dns(contract_name).unwrap(); // will panic if not found
        (self.dns_address(contract_name).unwrap_or(0x0.try_into().unwrap()))
    }

    //--------------------------
    // system addresses
    //
    #[inline(always)]
    fn prompt_address(self: @WorldStorage) -> ContractAddress {
        (self.find_contract_address(@"prompt"))
    }
    #[inline(always)]
    fn designer_address(self: @WorldStorage) -> ContractAddress {
        (self.find_contract_address(@"designer"))
    }
    #[inline(always)]
    fn game_token_address(self: @WorldStorage) -> ContractAddress {
        (self.find_contract_address(@"game_token"))
    }

    //--------------------------
    // dispatchers
    //
    #[inline(always)]
    fn prompt_dispatcher(self: @WorldStorage) -> IPromptDispatcher {
        (IPromptDispatcher{ contract_address: self.prompt_address() })
    }
    #[inline(always)]
    fn designer_dispatcher(self: @WorldStorage) -> IDesignerDispatcher {
        (IDesignerDispatcher{ contract_address: self.designer_address() })
    }
    #[inline(always)]
    fn game_token_dispatcher(self: @WorldStorage) -> IGameTokenDispatcher {
        (IGameTokenDispatcher{ contract_address: self.game_token_address() })
    }

    //--------------------------
    // library dispatchers
    //
    fn lexer_dispatcher(self: @WorldStorage) -> ILexerLibraryDispatcher {
        let (_, class_hash): (ContractAddress, ClassHash) = self.dns(@"lexer_v0_2_0").expect('lexer library not found');
        (ILexerLibraryDispatcher{ class_hash })
    }
}


