use dojo::{world::WorldStorage, model::{Model, ModelStorage}};
use lore::models::components::{Instance};
use lore::lib::utils::{HashImpl};


pub trait GameTrait<M> {
    fn game_inst(inst: felt252, game_id: u128) -> felt252;
    fn read_game_model(self: @WorldStorage, inst: felt252, game_id: u128) -> M;
    fn write_game_model(ref self: WorldStorage, model: @M, game_id: u128);
}

pub impl GameImpl<M, +Drop<M>, +Clone<M>, +Model<M>, +Instance<M>> of GameTrait<M> {

    // generates a game entity instance ID
    //  * @param {felt252} inst - The LORE instance ID
    //  * @param {felt252} game_id - The game token ID
    //  * @returns {felt252} - The game instance ID, or inst if game_id is zero
    fn game_inst(inst: felt252, game_id: u128) -> felt252 {
        if (inst != 0 && game_id != 0) {
            let values: Span<felt252> = array![inst, game_id.into()].span();
            (HashImpl::hash_values(values))
        } else {
            (inst)
        }
    }

    // reads a game instance model, if it exists
    fn read_game_model(self: @WorldStorage, inst: felt252, game_id: u128) -> M {
        let game_inst: felt252 = Self::game_inst(inst, game_id);
        (if Instance::<M>::has_component(self, game_inst) {
            // read the game instance model
            let mut result: M = self.read_model(game_inst);
            // keep the original inst key
            result.set_inst(inst);
            (result)
        } else {
            (self.read_model(inst))
        })
    }
    
    // writes a game instance model
    fn write_game_model(ref self: WorldStorage, model: @M, game_id: u128) {
        if game_id != 0 {
            // generate game instance key
            let game_inst: felt252 = Self::game_inst(model.inst(), game_id);
            // clone model using game instance key
            let mut game_model: M = model.clone();
            game_model.set_inst(game_inst);
            // write model
            self.write_model(@game_model);
        } else {
            self.write_model(model);
        }
    }
}
