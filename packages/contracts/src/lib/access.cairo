use dojo::{
    world::WorldStorage,
    // model::{ModelStorage},
};
use starknet::ContractAddress;
use lore::lib::dns::{DnsTrait, IDesignerDispatcherTrait};

pub mod ROLES {
    pub const ADMIN: felt252 = 'ROLE_ADMIN';
    pub const EDITOR: felt252 = 'ROLE_EDITOR';
}

// Emitted events for easy client-side tracking
#[derive(Copy, Drop, Serde)]
#[dojo::event(historical:false)]
pub struct AccessGrantedEvent {
    #[key]
    pub address: ContractAddress,
    #[key]
    pub role: felt252,
    /// Properties ///
    pub granted: bool,
}

#[generate_trait]
pub impl AccessImpl of AccessTrait {
    fn is_player_admin(self: @WorldStorage, account: ContractAddress) -> bool {
        (self.designer_dispatcher().is_admin(account))
    }
    fn is_player_editor(self: @WorldStorage, account: ContractAddress) -> bool {
        (self.designer_dispatcher().is_editor(account))
    }
    fn set_player_is_editor(ref self: WorldStorage, account: ContractAddress, is_editor: bool) {
        (self.designer_dispatcher().set_editor(account, is_editor))
    }
    fn grant_access_to_entity(ref self: WorldStorage, account: ContractAddress, inst: felt252, granting: bool) {
        (self.designer_dispatcher().grant_access_to_entity(account, inst, granting))
    }
}
