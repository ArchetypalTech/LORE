use dojo::{
    world::WorldStorage,
    // model::{ModelStorage},
};
use starknet::ContractAddress;

#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct TrailTokenInfo {
    #[key]
    pub trail_id: u128,
    /// Properties ///
    pub minter_address: ContractAddress,
    pub seed: felt252,
    /// trail location
    pub hub_inst: felt252,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event(historical:false)]
pub struct TrailCreatedEvent {
    #[key]
    pub contract_address: ContractAddress,
    #[key]
    pub trail_id: u128,
    /// Properties ///
    pub recipient: ContractAddress,
}



//---------------------------------
// Model Traits
//
// use lore::lib::dns::{DnsTrait, ITrailTokenDispatcherTrait};
// use lore::models::{
//     entity::{Entity},
//     area::{Area, AreaComponent},
//     player::{Player, PlayerImpl},
// };
// use lore::lib::{
//     access::{AccessTrait},
//     trophies::{Trophy, TrophyProgressTrait},
// };

#[generate_trait]
pub impl TrailTokenInfoImpl of TrailTokenInfoTrait {
    fn set_hub(ref world: WorldStorage, trail_id: u128, hub_inst: felt252) {
        // // read room entity
        // let room_entity: Entity = world.read_model(room_inst);
        // let area: Option<Area> = AreaComponent::get_component(@world, room_inst, game_id);
        // // update token info
        // let mut game_info: GameTokenInfo = world.read_model(game_id);
        // game_info.room_name = room_entity.name;
        // match area {
        //     Option::Some(area) => {
        //         // emit achievement
        //         let trophy: Trophy = TrophyProgressTrait::on_enter_room(@world, room_inst);
        //         // find change in act
        //         let act_number: u8 =
        //             if (trophy == Trophy::Marshes) {2}
        //             else if (trophy == Trophy::ForkstoneVerge) {3}
        //             else {1};
        //         // update token info
        //         game_info.act_number = core::cmp::max(game_info.act_number, act_number);
        //         game_info.progress = core::cmp::min(core::cmp::max(game_info.progress, area.progress_percentage), 100);
        //         let completed: bool = (game_info.progress == 100);
        //         if (completed && !game_info.completed) {
        //             // completed for the first time: owner becomes editor
        //             let owner: ContractAddress = world.game_token_dispatcher().owner_of(game_id.into());
        //             AccessTrait::set_is_editor(ref world, owner, true);
        //         }
        //         game_info.completed = completed;
        //     },
        //     Option::None => {
        //         game_info.act_number = 0;
        //         game_info.progress = 0;
        //         game_info.completed = false;
        //     }
        // };
        // world.write_model(@game_info);
        // world.game_token_dispatcher().update_token_metadata(game_id.into());
    }
}


// #[cfg(test)]
// mod tests {
//     use dojo::{model::ModelStorage};
//     use super::*;
//     use lore::{
//         tests::helpers,
//         systems::prompt::{IPromptDispatcherTrait},
//         models::player::{PlayerImpl},
//     };

//     #[test]
//     fn test_game_token_info_edit() {
//     }
// }
