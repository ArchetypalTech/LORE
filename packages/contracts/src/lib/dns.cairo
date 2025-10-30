use core::num::traits::Zero;
use starknet::{ContractAddress, ClassHash};
use dojo::world::{WorldStorage, WorldStorageTrait};
use dojo::meta::interface::{
    IDeployedResourceDispatcher, IDeployedResourceDispatcherTrait,
    IDeployedResourceSafeDispatcher, IDeployedResourceSafeDispatcherTrait,
};

pub use lore::{
    systems::{
        designer::{IDesignerDispatcher, IDesignerDispatcherTrait},
        prompt::{IPromptDispatcher, IPromptDispatcherTrait},
        game_token::{IGameTokenDispatcher, IGameTokenDispatcherTrait},
        trail_token::{ITrailTokenDispatcher, ITrailTokenDispatcherTrait},
    },
    lib::{
        a_lexer::{ILexerLibraryDispatcher, ILexerDispatcherTrait},
        utils::{ByteArrayTrait},
    },
};

pub mod SELECTORS {
    // systems
    pub const PROMPT: felt252 = selector_from_tag!("lore-prompt");
    pub const DESIGNER: felt252 = selector_from_tag!("lore-designer");
    pub const GAME_TOKEN: felt252 = selector_from_tag!("lore-game_token");
    pub const TRAIL_TOKEN: felt252 = selector_from_tag!("lore-trail_token");
}

#[generate_trait]
pub impl DnsImpl of DnsTrait {
    #[inline(always)]
    fn find_contract_name(self: @WorldStorage, contract_address: ContractAddress) -> ByteArray {
        (IDeployedResourceDispatcher{contract_address}.dojo_name())
    }
    fn find_contract_address(self: @WorldStorage, contract_name: @ByteArray) -> ContractAddress {
        // let (contract_address, _) = self.dns(contract_name).unwrap(); // will panic if not found
        (self.dns_address(contract_name).unwrap_or(0x0.try_into().unwrap()))
    }
    fn find_library_address(self: @WorldStorage, library_name: @ByteArray, library_version: @ByteArray) -> ClassHash {
        let library_name: ByteArray = format!("{}_v{}", library_name, library_version);
        (self.dns_class_hash(@library_name).expect(library_name.to_felt252_word().unwrap_or('library not found')))
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
    #[inline(always)]
    fn trail_token_address(self: @WorldStorage) -> ContractAddress {
        (self.find_contract_address(@"trail_token"))
    }
    #[inline(always)]
    fn lexer_class_hash(self: @WorldStorage) -> ClassHash {
        (self.find_library_address(@"lexer", @"0_2_0"))
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
    #[inline(always)]
    fn trail_token_dispatcher(self: @WorldStorage) -> ITrailTokenDispatcher {
        (ITrailTokenDispatcher{ contract_address: self.trail_token_address() })
    }
    #[inline(always)]
    fn lexer_dispatcher(self: @WorldStorage) -> ILexerLibraryDispatcher {
        (ILexerLibraryDispatcher{ class_hash: self.lexer_class_hash() })
    }

    //--------------------------
    // address validators
    //
    #[feature("safe_dispatcher")]
    fn is_world_contract(self: @WorldStorage, contract_address: ContractAddress) -> bool {
        // try calling dojo_name() with safe dispatchers
        // https://book.cairo-lang.org/ch102-02-interacting-with-another-contract.html#handling-errors-with-safe-dispatchers
        let response: Result<ByteArray, Array<felt252>> = IDeployedResourceSafeDispatcher{contract_address}.dojo_name();
        (match response {
            // it is a dojo contract... check if it's in this world
            Result::Ok(contract_name) => (
                contract_address.is_non_zero() &&
                contract_address == self.find_contract_address(@contract_name)
            ),
            // failed to call dojo_name(), definitely not of this world
            Result::Err(_panic_reason) => (false),
        })
    }
}
