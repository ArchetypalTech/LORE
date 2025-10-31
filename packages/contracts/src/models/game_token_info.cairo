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
}

#[derive(Copy, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct PlayerGame {
    #[key]
    pub player_address: ContractAddress,
    /// Properties ///
    pub current_game_id: u128,
}


//---------------------------------
// events
//
#[derive(Copy, Drop, Serde)]
#[dojo::event(historical:false)]
pub struct GameCreatedEvent {
    #[key]
    pub game_id: u128,
    /// Properties ///
    pub recipient: ContractAddress,
}


//---------------------------------
// Model Traits
//
use lore::lib::dns::{DnsTrait, IGameTokenDispatcherTrait};
use lore::models::{
    entity::{Entity},
    area::{Area, AreaComponent},
    player::{Player, PlayerImpl},
    trail_token_info::{TrailProgressTrait, MAIN_TRAIL_ID},
};
use lore::lib::{
    access::{AccessTrait},
    trophies::{Trophy, TrophyProgressTrait},
};

#[generate_trait]
pub impl GameTokenInfoImpl of GameTokenInfoTrait {
    fn set_room(ref world: WorldStorage, game_id: u128, room_inst: felt252) {
        // read room entity
        let room_entity: Entity = world.read_model(room_inst);
        let area: Option<Area> = AreaComponent::get_component(@world, room_inst, game_id);
        // update token info
        let mut game_info: GameTokenInfo = world.read_model(game_id);
        if let Option::Some(area) = area {
            // emit achievement
            let trophy: Trophy = TrophyProgressTrait::on_enter_room(@world, room_inst);
            // find change in act
            let act_number: u8 =
                if (trophy == Trophy::Marshes) {2}
                else if (trophy == Trophy::ForkstoneVerge) {3}
                else {1};
            // update token info
            game_info.room_name = room_entity.name;
            game_info.act_number = core::cmp::max(game_info.act_number, act_number);
            // update progress
            let completed_now: bool = world.set_trail_progress(game_id, MAIN_TRAIL_ID, area.progress_percentage);
            if (completed_now) {
                // completed for the first time: owner becomes editor
                let owner: ContractAddress = world.game_token_dispatcher().owner_of(game_id.into());
                world.set_player_is_editor(owner, true);
            }
            // store!
            world.write_model(@game_info);
            world.game_token_dispatcher().update_token_metadata(game_id.into());
        };
    }
    fn current_game_progress(self: @WorldStorage, game_id: u128) -> u8 {
        (self.current_trail_progress(game_id, MAIN_TRAIL_ID))
    }
    fn has_finished_game(self: @WorldStorage, game_id: u128) -> bool {
        (self.has_finished_trail(game_id, MAIN_TRAIL_ID))
    }
    fn is_dead(world: @WorldStorage, game_id: u128) -> bool {
        let player: Option<Player> = PlayerImpl::get_player(world, game_id);
        match player {
            Option::Some(player) => {(player.is_dead)},
            Option::None => {(false)},
        }
    }
}

#[generate_trait]
pub impl PlayerGameImpl of PlayerGameTrait {
    fn current_game_id(world: @WorldStorage, player_address: ContractAddress) -> u128 {
        let player_game: PlayerGame = world.read_model(player_address);
        (player_game.current_game_id)
    }
    fn switch_game_id(ref world: WorldStorage, player_address: ContractAddress, game_id: u128) {
        let mut player_game: PlayerGame = world.read_model(player_address);
        if (player_game.current_game_id != game_id && game_id != 0) {
            player_game.current_game_id = game_id;
            world.write_model(@player_game);
        }
    }
}




#[cfg(test)]
mod tests {
    use dojo::{model::ModelStorage};
    use super::*;
    use lore::{
        tests::helpers,
        systems::prompt::{IPromptDispatcherTrait},
        models::player::{PlayerImpl},
    };

    #[test]
    fn test_game_token_info_edit() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        PlayerImpl::caller_as_player(ref sys.world, helpers::PLAYER_1, 0);
        // create room entities
        let room_entity_1: @Entity = @helpers::create_new_entity(1, "Room 1");
        let room_entity_2: @Entity = @helpers::create_new_entity(0x03a419a814c431cc29706ccc4dcfbbb9c952cc96d2f9719d62ab8163b0f5bb52, "Room 2");
        let room_entity_3: @Entity = @helpers::create_new_entity(0x032454cde156173c1f4ee9a89e4a3a97a9a81bc2f5237b81728af955569c85bb, "Room 3");
        sys.world.write_model(room_entity_1);
        sys.world.write_model(room_entity_2);
        sys.world.write_model(room_entity_3);
        let mut area_1: Area = AreaComponent::add_component(ref sys.world, *room_entity_1.inst);
        let mut area_2: Area = AreaComponent::add_component(ref sys.world, *room_entity_2.inst);
        let mut area_3: Area = AreaComponent::add_component(ref sys.world, *room_entity_3.inst);
        area_1.progress_percentage = 10;
        area_2.progress_percentage = 50;
        area_3.progress_percentage = 100;
        sys.world.write_model(@area_1);
        sys.world.write_model(@area_2);
        sys.world.write_model(@area_3);
        //
        // mint game
        helpers::set_caller(helpers::PLAYER_1);
        sys.prompt.prompt("", Option::None);
        let game_id: u128 = 1;
        //
        // set room
        helpers::set_caller(helpers::OWNER());
        GameTokenInfoTrait::set_room(ref sys.world, game_id, *room_entity_1.inst);
        let token_info: GameTokenInfo = sys.world.read_model(game_id);
        assert_eq!(token_info.room_name, room_entity_1.name.clone(), "set room");
        assert_eq!(token_info.act_number, 1, "set room");
        assert_eq!(sys.world.current_game_progress(game_id), 10, "set room");
        assert!(!sys.world.has_finished_game(game_id), "set room");
        //
        // new act
        GameTokenInfoTrait::set_room(ref sys.world, game_id, *room_entity_2.inst);
        let token_info: GameTokenInfo = sys.world.read_model(game_id);
        assert_eq!(token_info.room_name, room_entity_2.name.clone(), "new act");
        assert_eq!(token_info.act_number, 2, "new act");
        assert_eq!(sys.world.current_game_progress(game_id), 50, "new act");
        assert!(!sys.world.has_finished_game(game_id), "new act");
        //
        // back one room
        GameTokenInfoTrait::set_room(ref sys.world, game_id, *room_entity_1.inst);
        let token_info: GameTokenInfo = sys.world.read_model(game_id);
        assert_eq!(token_info.room_name, room_entity_1.name.clone(), "back one room");
        assert_eq!(token_info.act_number, 2, "back one room");
        assert_eq!(sys.world.current_game_progress(game_id), 50, "back one room");
        assert!(!sys.world.has_finished_game(game_id), "back one room");
        //
        // finish...
        GameTokenInfoTrait::set_room(ref sys.world, game_id, *room_entity_3.inst);
        let token_info: GameTokenInfo = sys.world.read_model(game_id);
        assert_eq!(token_info.room_name, room_entity_3.name.clone(), "finished");
        assert_eq!(token_info.act_number, 3, "finished");
        assert_eq!(sys.world.current_game_progress(game_id), 100, "finished");
        assert!(sys.world.has_finished_game(game_id), "finished");
    }
}
