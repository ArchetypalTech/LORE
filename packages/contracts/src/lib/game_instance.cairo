use dojo::{world::WorldStorage, model::{Model, ModelStorage}};
use lore::lib::utils::{HashImpl};


pub trait GameTrait<M> {
    fn game_inst(inst: felt252, game_id: felt252) -> felt252;
    fn read_game_inst(self: @WorldStorage, inst: felt252, game_id: felt252) -> M;
    fn write_game_inst(ref self: WorldStorage, model: @M, game_id: felt252);
}

pub impl GameImpl<M, +Model<M>, +Drop<M>> of GameTrait<M> {

    // generates a game entity instance ID
    //  * @param {felt252} inst - The LORE instance ID
    //  * @param {felt252} game_id - The game token ID
    //  * @returns {felt252} - The game instance ID, or inst if game_id is zero
    fn game_inst(inst: felt252, game_id: felt252) -> felt252 {
        if (inst != 0 && game_id != 0) {
            let values: Span<felt252> = array![inst, game_id].span();
            (HashImpl::hash_values(values))
        } else {
            (inst)
        }
    }

    // reads a game instance model with keys (inst)
    fn read_game_inst(self: @WorldStorage, inst: felt252, game_id: felt252) -> M {
        let keys: felt252 = inst;
        (self.read_model(keys))
    }
    
    // writes a game instance model
    fn write_game_inst(ref self: WorldStorage, model: @M, game_id: felt252) {
        self.write_model(model);
    }
}
