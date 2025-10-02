use core::num::traits::Zero;
use dojo::{world::WorldStorage, model::{Model, ModelStorage}};
use lore::lib::utils::{HashImpl};

// game instance mapping, for client discovery
#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct GameInstanceMap {
    #[key]
    pub game_id: u128,
    #[key]
    pub inst: felt252,
    /// game instance key for [inst] in game [game_id]
    pub game_inst: felt252,
}

// game instance mapping, for client discovery
#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct GameInstanceKeyMap {
    #[key]
    pub game_id: u128,
    #[key]
    pub inst: felt252,
    #[key]
    pub key: u32,
    /// game instance key for [inst, key] in game [game_id]
    pub game_inst: felt252,
}


//---------------------------------
// Traits
//

// for models with keys: (inst)
pub trait Instance<M, +Drop<M>, +Model<M>> {
    // return a models instance key
    fn inst(self: @M) -> felt252;
    // used by GameModelImpl only
    fn set_inst(ref self: M, new_inst: felt252);
    // validate if a component is initialized
    fn is_component(self: @M) -> bool;
    // validate if an entity contains this component with key: (inst)
    fn has_component(self: @WorldStorage, inst: felt252) -> bool;
}

// for models with keys: (inst, key)
pub trait InstanceKey<M, +Drop<M>, +Model<M>> {
    // return a models instance key
    fn inst(self: @M) -> felt252;
    // return a models key
    fn key(self: @M) -> u32;
    // used by GameModelImpl only
    fn set_inst(ref self: M, new_inst: felt252);
}

// for models with keys: (inst)
pub trait GameModelTrait<M> {
    // get the mapped game instance for the given, or 0 if not mapped
    fn get_mapped_game_inst(self: @WorldStorage, inst: felt252, game_id: u128) -> felt252;
    // verify if a game instance has its own version of a component
    fn has_game_model(self: @WorldStorage, inst: felt252, game_id: u128) -> bool;
    // read a game instance component, or the original
    fn read_game_model(self: @WorldStorage, inst: felt252, game_id: u128) -> M;
    // write a game instance component. next read operations will read the game instance version
    fn write_game_model(ref self: WorldStorage, model: @M, game_id: u128);
    // reset a game instance component. next read operatinos will read the original version
    fn reset_game_model(ref self: WorldStorage, inst: felt252, game_id: u128);
    // fn write_game_member<T, +Serde<T>, +Drop<T>>(ref self: WorldStorage, model: @M, field_selector: felt252, value: T, game_id: u128);
}

// for models with keys: (inst, key)
pub trait GameModelKeyTrait<M> {
    // get the mapped game instance for the given, or 0 if not mapped
    fn get_mapped_game_inst(self: @WorldStorage, inst: felt252, key: u32, game_id: u128) -> felt252;
    // read a game instance component, or the original
    fn read_game_model_key(self: @WorldStorage, inst: felt252, key: u32, game_id: u128) -> M;
    // write a game instance component. next read operations will read the game instance version
    fn write_game_model_key(ref self: WorldStorage, model: @M, game_id: u128);
}


//---------------------------------
// Implementations
//

#[generate_trait]
pub impl GameInstImpl of GameInstTrait {
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
}

pub impl GameModelImpl<M, +Drop<M>, +Clone<M>, +Model<M>, +Instance<M>> of GameModelTrait<M> {
    fn get_mapped_game_inst(self: @WorldStorage, inst: felt252, game_id: u128) -> felt252 {
        (self.read_member(Model::<GameInstanceMap>::ptr_from_keys((game_id, inst),), selector!("game_inst")))
    }

    fn has_game_model(self: @WorldStorage, inst: felt252, game_id: u128) -> bool {
        let game_inst: felt252 = GameInstImpl::game_inst(inst, game_id);
        (Instance::<M>::has_component(self, game_inst))
    }
    
    fn read_game_model(self: @WorldStorage, inst: felt252, game_id: u128) -> M {
        let game_inst: felt252 = GameInstImpl::game_inst(inst, game_id);
        (if Instance::<M>::has_component(self, game_inst) {
            // read the game instance model
            let mut result: M = self.read_model(game_inst);
            // keep the original inst key
            // println!("+ read_game_model {}:{:x}:{:x}", game_id, inst, game_inst);
            result.set_inst(inst);
            (result)
        } else {
            // println!("+ read_model ZERO:{:x}", inst);
            (self.read_model(inst))
        })
    }
    
    fn write_game_model(ref self: WorldStorage, model: @M, game_id: u128) {
        if game_id.is_non_zero() {
            // generate game instance key
            let game_inst: felt252 = GameInstImpl::game_inst(model.inst(), game_id);
            // create game instance mapping for easy client discovery
            if !Instance::<M>::has_component(@self, game_inst) {
                self.write_model(@GameInstanceMap {
                    game_id,
                    inst: model.inst(),
                    game_inst,
                });
            }
            // clone model using game instance key
            let mut game_model: M = model.clone();
            game_model.set_inst(game_inst);
            // write model
            // println!("+ write_game_model {}:{:x}:{:x}", game_id, model.inst(), game_inst);
            self.write_model(@game_model);
        } else {
            // println!("+ write_model ZERO:{:x}", model.inst());
            self.write_model(model);
        }
    }

    fn reset_game_model(ref self: WorldStorage, inst: felt252, game_id: u128) {
        let game_inst: felt252 = Self::get_mapped_game_inst(@self, inst, game_id);
        if game_inst.is_non_zero() {
            // read the original model
            let mut model: M = self.read_model(inst);
            // overwrite the game instance
            model.set_inst(game_inst);
            self.write_model(@model);
        }
    }
}

pub impl GameModelKeyImpl<M, +Drop<M>, +Clone<M>, +Model<M>, +InstanceKey<M>> of GameModelKeyTrait<M> {
    // get the mapped game_inst for the given (inst, key)
    // if non zero, means game_id has its own version of this model
    fn get_mapped_game_inst(self: @WorldStorage, inst: felt252, key: u32, game_id: u128) -> felt252 {
        (self.read_member(Model::<GameInstanceKeyMap>::ptr_from_keys((game_id, inst, key),), selector!("game_inst")))
    }

    fn read_game_model_key(self: @WorldStorage, inst: felt252, key: u32, game_id: u128) -> M {
        let game_inst: felt252 = Self::get_mapped_game_inst(self, inst, key, game_id);
        (if game_inst.is_non_zero() {
            // read the game instance model
            let mut result: M = self.read_model((game_inst, key),);
            // keep the original inst key
            // println!("+ read_game_model_key {}:({:x},{}):{:x}", game_id, inst, key, game_inst);
            result.set_inst(inst);
            (result)
        } else {
            // println!("+ read_model_key ZERO:({:x},{})", inst, key);
            (self.read_model((inst, key),))
        })
    }
    
    fn write_game_model_key(ref self: WorldStorage, model: @M, game_id: u128) {
        if game_id.is_non_zero() {
            let mut game_inst: felt252 = Self::get_mapped_game_inst(@self, model.inst(), model.key(), game_id);
            // create game instance mapping for easy client discovery
            if game_inst.is_zero() {
                game_inst = GameInstImpl::game_inst(model.inst(), game_id);
                self.write_model(@GameInstanceKeyMap {
                    game_id,
                    inst: model.inst(),
                    key: model.key(),
                    game_inst,
                });
            }
            // clone model using game instance key
            let mut game_model: M = model.clone();
            game_model.set_inst(game_inst);
            // write model
            // println!("+ write_game_model_key {}:({:x},{}):{:x}", game_id, model.inst(), model.key(), game_inst);
            self.write_model(@game_model);
        } else {
            // println!("+ write_model_key ZERO:({:x},{})", model.inst(), model.key());
            self.write_model(model);
        }
    }
}
