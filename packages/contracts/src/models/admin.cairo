use dojo::{world::WorldStorage, model::{ModelStorage}};
use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct AccountPermissions {
    #[key]
    pub account_address: ContractAddress,
    /// Properties ///
    /// admins can edit core game and play any game
    pub is_admin: bool,
    /// editors are players who completed the game
    /// with limited editing permissions (their own rooms only)
    pub is_editor: bool,
}


//---------------------------------
// Model Traits
//

#[generate_trait]
pub impl AccountPermissionsImpl of AccountPermissionsTrait {
    fn set_is_admin(ref world: WorldStorage, account_address: ContractAddress, is_admin: bool) {
        let mut config: AccountPermissions = world.read_model(account_address);
        config.is_admin = is_admin;
        world.write_model(@config);
    }
    fn set_is_editor(ref world: WorldStorage, account_address: ContractAddress, is_editor: bool) {
        let mut config: AccountPermissions = world.read_model(account_address);
        config.is_editor = is_editor;
        world.write_model(@config);
    }
    fn is_admin(world: @WorldStorage, account_address: ContractAddress) -> bool {
        let config: AccountPermissions = world.read_model(account_address);
        (config.is_admin)
    }
    fn is_editor(world: @WorldStorage, account_address: ContractAddress) -> bool {
        let config: AccountPermissions = world.read_model(account_address);
        (config.is_admin || config.is_editor)
    }
}
