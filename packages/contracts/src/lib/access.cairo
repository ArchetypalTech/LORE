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
    fn set_is_editor(ref world: WorldStorage, account: ContractAddress, is_editor: bool) {
        (world.designer_dispatcher().set_editor(account, true))
    }
    fn is_admin(world: @WorldStorage, account: ContractAddress) -> bool {
        (world.designer_dispatcher().is_admin(account))
    }
    fn is_editor(world: @WorldStorage, account: ContractAddress) -> bool {
        (world.designer_dispatcher().is_editor(account))
    }
}
