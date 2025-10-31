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

#[generate_trait]
pub impl AccessImpl of AccessTrait {
    fn set_player_is_editor(ref self: WorldStorage, account: ContractAddress, is_editor: bool) {
        (self.designer_dispatcher().set_editor(account, true))
    }
    fn is_player_admin(self: @WorldStorage, account: ContractAddress) -> bool {
        (self.designer_dispatcher().is_admin(account))
    }
    fn is_player_editor(self: @WorldStorage, account: ContractAddress) -> bool {
        (self.designer_dispatcher().is_editor(account))
    }
}
