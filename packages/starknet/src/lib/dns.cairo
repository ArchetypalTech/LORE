use starknet::{ContractAddress};
use core::num::traits::Zero;
use dojo::world::{WorldStorage, WorldStorageTrait, IWorldDispatcher};
use dojo::meta::interface::{
    IDeployedResourceDispatcher, IDeployedResourceDispatcherTrait,
    IDeployedResourceSafeDispatcher, IDeployedResourceSafeDispatcherTrait,
};

pub use lore_sn::systems::{
    permit_token::{IPermitTokenDispatcher, IPermitTokenDispatcherTrait},
    setup::{ISetupDispatcher, ISetupDispatcherTrait},
};

// piltover messaging interface
// use piltover::messaging::interface::{IMessagingDispatcher, IMessagingDispatcherTrait};
pub use lore_sn::lib::messaging::{IMessagingDispatcher, IMessagingDispatcherTrait};

pub mod SELECTORS {
    // systems
    pub const SETUP: felt252 = selector_from_tag!("lore_sn-setup");
    pub const PERMIT_TOKEN: felt252 = selector_from_tag!("lore_sn-permit_token");
    pub const MESSAGING_MOCK: felt252 = selector_from_tag!("lore_sn-messaging_mock");
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

    // Create a Store from a dispatcher
    // https://github.com/dojoengine/dojo/blob/main/crates/dojo/core/src/contract/components/world_provider.cairo
    // https://github.com/dojoengine/dojo/blob/main/crates/dojo/core/src/world/storage.cairo
    #[inline(always)]
    fn world_storage(dispatcher: IWorldDispatcher, namespace: @ByteArray) -> WorldStorage {
        (WorldStorageTrait::new(dispatcher, namespace))
    }

    //--------------------------
    // system addresses
    //
    #[inline(always)]
    fn setup_address(self: @WorldStorage) -> ContractAddress {
        (self.find_contract_address(@"setup"))
    }
    #[inline(always)]
    fn permit_token_address(self: @WorldStorage) -> ContractAddress {
        (self.find_contract_address(@"permit_token"))
    }
    #[inline(always)]
    fn messaging_mock_address(self: @WorldStorage) -> ContractAddress {
        (self.find_contract_address(@"messaging_mock"))
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
    #[inline(always)]
    fn caller_is_world_contract(self: @WorldStorage) -> bool {
        (self.is_world_contract(starknet::get_caller_address()))
    }

    //--------------------------
    // dispatchers
    //
    #[inline(always)]
    fn setup_dispatcher(self: @WorldStorage) -> ISetupDispatcher {
        (ISetupDispatcher{ contract_address: self.setup_address() })
    }
    #[inline(always)]
    fn permit_token_dispatcher(self: @WorldStorage) -> IPermitTokenDispatcher {
        (IPermitTokenDispatcher{ contract_address: self.permit_token_address() })
    }
    #[inline(always)]
    fn messaging_mock_dispatcher(self: @WorldStorage) -> IMessagingDispatcher {
        (IMessagingDispatcher{ contract_address: self.messaging_mock_address() })
    }

}
