use dojo::{world::WorldStorage, model::{ModelStorage}};
use starknet::ContractAddress;

#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct GameTokenInfo {
    #[key]
    pub game_id: u128,
    /// Properties ///
    pub minter_address: ContractAddress,
    pub seed: felt252,
    /// game progress indicators
    pub act_number: u8,
    pub room_name: ByteArray,
    pub progress: u8, // 0-100
    pub completed: bool,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event(historical:false)]
pub struct GameCreatedEvent {
    #[key]
    pub contract_address: ContractAddress,
    #[key]
    pub game_id: u128,
    /// Properties ///
    pub recipient: ContractAddress,
}

#[derive(Copy, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct PlayerAccount {
    #[key]
    pub address: ContractAddress,
    /// Properties ///
    pub current_game_id: u128,
}


//---------------------------------
// Model Traits
//
use lore::lib::dns::{DnsTrait, IGameTokenDispatcherTrait};
use lore::models::entity::{Entity};

#[generate_trait]
pub impl GameTokenInfoImpl of GameTokenInfoTrait {
    fn set_room(ref world: WorldStorage, game_id: u128, act_number: u8, room_inst: felt252) {
        let room_entity: Entity = world.read_model(room_inst);
        let mut game_info: GameTokenInfo = world.read_model(game_id);
        game_info.act_number = core::cmp::max(game_info.act_number, act_number);
        game_info.room_name = room_entity.name;
        world.write_model(@game_info);
        world.game_token_dispatcher().update_token_metadata(game_id.into());
    }
    fn set_progress(ref world: WorldStorage, game_id: u128, progress: u8) {
        let mut game_info: GameTokenInfo = world.read_model(game_id);
        game_info.progress = core::cmp::min(core::cmp::max(game_info.progress, progress), 100);
        game_info.completed = (game_info.progress == 100);
        world.write_model(@game_info);
        world.game_token_dispatcher().update_token_metadata(game_id.into());
    }
    fn is_completed(world: @WorldStorage, game_id: u128) -> bool {
        let game_info: GameTokenInfo = world.read_model(game_id);
        (game_info.completed)
    }
}

#[generate_trait]
pub impl PlayerAccountImpl of PlayerAccountTrait {
    fn current_game_id(world: @WorldStorage, address: ContractAddress) -> u128 {
        let account: PlayerAccount = world.read_model(address);
        (account.current_game_id)
    }
    fn switch_game_id(ref world: WorldStorage, address: ContractAddress, game_id: u128) {
        let mut account: PlayerAccount = world.read_model(address);
        if (account.current_game_id != game_id && game_id != 0) {
            account.current_game_id = game_id;
            world.write_model(@account);
        }
    }
}




#[cfg(test)]
mod tests {
    use dojo::{model::ModelStorage};
    use super::*;
    use lore::{
        tests::helpers,
    };

    #[test]
    fn test_game_token_info_edit() {
        let (mut world, _, _, _, _, _) = helpers::setup_core();
        // create room entities
        let room_entity_1: @Entity = @helpers::create_new_entity(1, "Room 1");
        let room_entity_2: @Entity = @helpers::create_new_entity(2, "Room 2");
        world.write_model(room_entity_1);
        world.write_model(room_entity_2);
        //
        // set room
        let game_id: u128 = 123;
        GameTokenInfoTrait::set_room(ref world, game_id, 1, *room_entity_1.inst);
        let token_info: GameTokenInfo = world.read_model(game_id);
        assert_eq!(token_info.act_number, 1, "set room");
        assert_eq!(token_info.room_name, room_entity_1.name.clone(), "set room");
        assert_eq!(token_info.progress, 0, "set room");
        assert_eq!(token_info.completed, false, "set room");
        //  
        // new act
        GameTokenInfoTrait::set_room(ref world, game_id, 2, *room_entity_2.inst);
        let token_info: GameTokenInfo = world.read_model(game_id);
        assert_eq!(token_info.act_number, 2, "new act");
        assert_eq!(token_info.room_name, room_entity_2.name.clone(), "new act");
        //
        // back one room
        GameTokenInfoTrait::set_room(ref world, game_id, 1, *room_entity_1.inst);
        let token_info: GameTokenInfo = world.read_model(game_id);
        assert_eq!(token_info.act_number, 2, "back one room");
        assert_eq!(token_info.room_name, room_entity_1.name.clone(), "back one room");
        //
        // progress 50
        GameTokenInfoTrait::set_progress(ref world, game_id, 50);
        let token_info: GameTokenInfo = world.read_model(game_id);
        assert_eq!(token_info.progress, 50, "progress 50");
        assert_eq!(token_info.completed, false, "progress 50");
        assert!(!GameTokenInfoTrait::is_completed(@world, game_id), "progress 50");
        //
        // progress 10 (will not reduce progress)
        GameTokenInfoTrait::set_progress(ref world, game_id, 10);
        let token_info: GameTokenInfo = world.read_model(game_id);
        assert_eq!(token_info.progress, 50, "progress 10");
        assert_eq!(token_info.completed, false, "progress 10");
        assert!(!GameTokenInfoTrait::is_completed(@world, game_id), "progress 10");
        //
        // progress 200 (will set progress to max 100)
        GameTokenInfoTrait::set_progress(ref world, game_id, 200);
        let token_info: GameTokenInfo = world.read_model(game_id);
        assert_eq!(token_info.progress, 100, "progress 200");
        assert_eq!(token_info.completed, true, "progress 200");
        assert!(GameTokenInfoTrait::is_completed(@world, game_id), "progress 200");
        //
        // progress 90 (will not reduce progress)
        GameTokenInfoTrait::set_progress(ref world, game_id, 90);
        let token_info: GameTokenInfo = world.read_model(game_id);
        assert_eq!(token_info.progress, 100, "progress 90");
        assert_eq!(token_info.completed, true, "progress 90");
        assert!(GameTokenInfoTrait::is_completed(@world, game_id), "progress 90");
    }
}
