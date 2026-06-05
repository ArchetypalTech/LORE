// use dojo::{world::WorldStorage, model::{ModelStorage}};
// use starknet::ContractAddress;

//
// Per-token configuration
//

#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct PermitTokenInfo {
    #[key]
    pub permit_id: u128,
    /// Properties ///
    pub permit_type: felt252,   // from APPCHAIN::PERMIT_TYPES
    pub is_used: bool,          // minted actions in L3
    pub trail_name: ByteArray,  // trail that generated this permit (unused)
}

#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct PermitType {
    #[key]
    pub permit_type: felt252,
    /// Properties ///
    pub actions_count: u32,
}



//---------------------------------
// Model Traits
//
use dojo::{
    world::WorldStorage,
    model::{ModelStorage, Model},
    // event::EventStorage,
};

#[generate_trait]
pub impl PermitTokenInfoImpl of PermitTokenInfoTrait {
    fn set_is_used(ref self: WorldStorage, permit_id: u128) {
        self.write_member(Model::<PermitTokenInfo>::ptr_from_keys(permit_id), selector!("is_used"), true);
    }
}
