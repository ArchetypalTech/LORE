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
    pub room_name: ByteArray,
    pub act_number: u8,
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
use lore::models::{
    entity::{Entity},
    area::{Area, AreaComponent},
};

#[generate_trait]
pub impl GameTokenInfoImpl of GameTokenInfoTrait {
    fn set_room(ref world: WorldStorage, game_id: u128, room_inst: felt252) {
        // read room entity
        let room_entity: Entity = world.read_model(room_inst);
        let area: Option<Area> = AreaComponent::get_component(@world, room_inst, game_id);
        // update token info
        let mut game_info: GameTokenInfo = world.read_model(game_id);
        game_info.room_name = room_entity.name;
        match area {
            Option::Some(area) => {
                let act_number: u8 =
                    if (area.progress_percentage < 33) {1}
                    else if (area.progress_percentage < 66) {2}
                    else {3};
                game_info.act_number = core::cmp::max(game_info.act_number, act_number);
                game_info.progress = core::cmp::min(core::cmp::max(game_info.progress, area.progress_percentage), 100);
                game_info.completed = (game_info.progress == 100);
            },
            Option::None => {
                game_info.act_number = 0;
                game_info.progress = 0;
                game_info.completed = false;
            }
        };
        world.write_model(@game_info);
        world.game_token_dispatcher().update_token_metadata(game_id.into());
    }
    fn has_finished_game(world: @WorldStorage, game_id: u128) -> bool {
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
        let room_entity_3: @Entity = @helpers::create_new_entity(3, "Room 3");
        world.write_model(room_entity_1);
        world.write_model(room_entity_2);
        world.write_model(room_entity_3);
        let mut area_1: Area = AreaComponent::add_component(ref world, *room_entity_1.inst);
        let mut area_2: Area = AreaComponent::add_component(ref world, *room_entity_2.inst);
        let mut area_3: Area = AreaComponent::add_component(ref world, *room_entity_3.inst);
        area_1.progress_percentage = 10;
        area_2.progress_percentage = 50;
        area_3.progress_percentage = 100;
        world.write_model(@area_1);
        world.write_model(@area_2);
        world.write_model(@area_3);
        //
        // set room
        let game_id: u128 = 123;
        GameTokenInfoTrait::set_room(ref world, game_id, *room_entity_1.inst);
        let token_info: GameTokenInfo = world.read_model(game_id);
        assert_eq!(token_info.room_name, room_entity_1.name.clone(), "set room");
        assert_eq!(token_info.act_number, 1, "set room");
        assert_eq!(token_info.progress, 10, "set room");
        assert_eq!(token_info.completed, false, "set room");
        assert!(!GameTokenInfoTrait::has_finished_game(@world, game_id), "set room");
        //  
        // new act
        GameTokenInfoTrait::set_room(ref world, game_id, *room_entity_2.inst);
        let token_info: GameTokenInfo = world.read_model(game_id);
        assert_eq!(token_info.room_name, room_entity_2.name.clone(), "new act");
        assert_eq!(token_info.act_number, 2, "new act");
        assert_eq!(token_info.progress, 50, "new act");
        assert_eq!(token_info.completed, false, "new act");
        assert!(!GameTokenInfoTrait::has_finished_game(@world, game_id), "new act");
        //
        // back one room
        GameTokenInfoTrait::set_room(ref world, game_id, *room_entity_1.inst);
        let token_info: GameTokenInfo = world.read_model(game_id);
        assert_eq!(token_info.room_name, room_entity_1.name.clone(), "back one room");
        assert_eq!(token_info.act_number, 2, "back one room");
        assert_eq!(token_info.progress, 50, "back one room");
        assert_eq!(token_info.completed, false, "back one room");
        assert!(!GameTokenInfoTrait::has_finished_game(@world, game_id), "back one room");
        //
        // finish...
        GameTokenInfoTrait::set_room(ref world, game_id, *room_entity_3.inst);
        let token_info: GameTokenInfo = world.read_model(game_id);
        assert_eq!(token_info.room_name, room_entity_3.name.clone(), "finished");
        assert_eq!(token_info.act_number, 3, "finished");
        assert_eq!(token_info.progress, 100, "finished");
        assert_eq!(token_info.completed, true, "finished");
        assert!(GameTokenInfoTrait::has_finished_game(@world, game_id), "finished");
    }
}
