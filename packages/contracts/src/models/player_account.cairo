use dojo::{world::WorldStorage, model::{ModelStorage}};
use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct PlayerAccount {
    #[key]
    pub player_address: ContractAddress,
    /// Properties ///
    pub current_game_id: u128,
}


//---------------------------------
// Model Traits
//

#[generate_trait]
pub impl PlayerAccountImpl of PlayerAccountTrait {
    fn current_game_id(world: @WorldStorage, player_address: ContractAddress) -> u128 {
        let player_game: PlayerAccount = world.read_model(player_address);
        (player_game.current_game_id)
    }
    fn switch_game_id(ref world: WorldStorage, player_address: ContractAddress, game_id: u128) {
        let mut player_game: PlayerAccount = world.read_model(player_address);
        if (player_game.current_game_id != game_id && game_id != 0) {
            player_game.current_game_id = game_id;
            world.write_model(@player_game);
        }
    }
}
