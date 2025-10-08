// use dojo::{world::{WorldStorage}, model::{ModelStorage, Model}};
use lore::{
    models::{
        game_instance::{InstanceKey, GameModelImpl},
    },
};

#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct DescriptionText {
    /// Unique identifier from the Entity it is attached to
    #[key]
    pub inst: felt252,
    /// Unique identifier of the description
    #[key]
    pub key: u32,
    /// Description text
    pub text: ByteArray,
}


//---------------------------------
// Component
//
pub impl DescriptionTextInstance of InstanceKey<DescriptionText> {
    #[inline(always)]
    fn inst(self: @DescriptionText) -> felt252 {
        (*self.inst)
    }
    #[inline(always)]
    fn key(self: @DescriptionText) -> u32 {
        (*self.key)
    }
    #[inline(always)]
    fn set_inst(ref self: DescriptionText, new_inst: felt252) {
        self.inst = new_inst;
    }
}





#[cfg(test)]
mod tests {
    use super::*;
    use dojo::{model::ModelStorage, world::WorldStorage};
    use lore::{
        tests::helpers,
        models::{
            entity::{EntityImpl},
            game_instance::{GameModelKeyImpl},
        },
    };

    fn _create_desc(ref world: WorldStorage, inst: felt252, key: u32, text: ByteArray) -> DescriptionText {
        let desc: DescriptionText = DescriptionText { inst, key, text };
        world.write_model(@desc);
        (desc)
    }

    fn _assert_desc_models(world: @WorldStorage, inst: felt252, key: u32, game_id: u128, text: @ByteArray, game_text: @ByteArray, prefix: ByteArray) {
        let comp_inst: DescriptionText = world.read_model((inst, key),);
        let comp_game: DescriptionText = world.read_game_model_key(inst, key, game_id);
        assert_eq!(@comp_inst.text, text, "[{}] comp_inst.text", prefix);
        assert_eq!(@comp_game.text, game_text, "[{}] comp_game.text", prefix);
    }

    #[test]
    fn test_description_text_game_inst() {
        let (mut world, _, _, _, _, _) = helpers::setup_core();
        //
        // create area
        let desc_1_0: DescriptionText = _create_desc(ref world, 111, 0, "desc_1_0");
        let desc_1_1: DescriptionText = _create_desc(ref world, 111, 1, "desc_1_1");
        let desc_1_2: DescriptionText = _create_desc(ref world, 111, 2, "desc_1_2");
        let desc_2_0: DescriptionText = _create_desc(ref world, 222, 0, "desc_2_0");
        let desc_2_1: DescriptionText = _create_desc(ref world, 222, 1, "desc_2_1");
        // validate InstanceKey
        assert_eq!(desc_1_0.inst(), desc_1_0.inst);
        assert_eq!(desc_1_1.inst(), desc_1_1.inst);
        assert_eq!(desc_1_2.inst(), desc_1_2.inst);
        assert_eq!(desc_2_0.inst(), desc_2_0.inst);
        assert_eq!(desc_2_1.inst(), desc_2_1.inst);
        assert_eq!(desc_1_0.key(), desc_1_0.key);
        assert_eq!(desc_1_1.key(), desc_1_1.key);
        assert_eq!(desc_1_2.key(), desc_1_2.key);
        assert_eq!(desc_2_0.key(), desc_2_0.key);
        assert_eq!(desc_2_1.key(), desc_2_1.key);
        //
        // read game inst version, same as inst
        let game_id: u128 = 888;
        _assert_desc_models(@world, desc_1_0.inst, desc_1_0.key, game_id, @desc_1_0.text, @desc_1_0.text, "baseline desc_1_0");
        _assert_desc_models(@world, desc_1_1.inst, desc_1_1.key, game_id, @desc_1_1.text, @desc_1_1.text, "baseline desc_1_1");
        _assert_desc_models(@world, desc_1_2.inst, desc_1_2.key, game_id, @desc_1_2.text, @desc_1_2.text, "baseline desc_1_2");
        _assert_desc_models(@world, desc_2_0.inst, desc_2_0.key, game_id, @desc_2_0.text, @desc_2_0.text, "baseline desc_2_0");
        _assert_desc_models(@world, desc_2_1.inst, desc_2_1.key, game_id, @desc_2_1.text, @desc_2_1.text, "baseline desc_2_1");
        //
        // save game inst version
        let mut new_desc_1_0: DescriptionText = desc_1_0.clone();
        let mut new_desc_1_1: DescriptionText = desc_1_1.clone();
        let mut new_desc_1_2: DescriptionText = desc_1_2.clone();
        let mut new_desc_2_0: DescriptionText = desc_2_0.clone();
        let mut new_desc_2_1: DescriptionText = desc_2_1.clone();
        new_desc_1_0.text = "new_desc_1_0";
        new_desc_1_1.text = "new_desc_1_1";
        new_desc_1_2.text = "new_desc_1_2";
        new_desc_2_0.text = "new_desc_2_0";
        new_desc_2_1.text = "new_desc_2_1";
        world.write_game_model_key(@new_desc_1_0, game_id);
        world.write_game_model_key(@new_desc_1_1, game_id);
        world.write_game_model_key(@new_desc_1_2, game_id);
        world.write_game_model_key(@new_desc_2_0, game_id);
        world.write_game_model_key(@new_desc_2_1, game_id);
        // game inst version
        _assert_desc_models(@world, desc_1_0.inst, desc_1_0.key, game_id, @desc_1_0.text, @new_desc_1_0.text, "game desc_1_0");
        _assert_desc_models(@world, desc_1_1.inst, desc_1_1.key, game_id, @desc_1_1.text, @new_desc_1_1.text, "game desc_1_1");
        _assert_desc_models(@world, desc_1_2.inst, desc_1_2.key, game_id, @desc_1_2.text, @new_desc_1_2.text, "game desc_1_2");
        _assert_desc_models(@world, desc_2_0.inst, desc_2_0.key, game_id, @desc_2_0.text, @new_desc_2_0.text, "game desc_2_0");
        _assert_desc_models(@world, desc_2_1.inst, desc_2_1.key, game_id, @desc_2_1.text, @new_desc_2_1.text, "game desc_2_1");
        // other games are preserved
        _assert_desc_models(@world, desc_1_0.inst, desc_1_0.key, game_id+1, @desc_1_0.text, @desc_1_0.text, "other desc_1_0");
        _assert_desc_models(@world, desc_1_1.inst, desc_1_1.key, game_id+1, @desc_1_1.text, @desc_1_1.text, "other desc_1_1");
        _assert_desc_models(@world, desc_1_2.inst, desc_1_2.key, game_id+1, @desc_1_2.text, @desc_1_2.text, "other desc_1_2");
        _assert_desc_models(@world, desc_2_0.inst, desc_2_0.key, game_id+1, @desc_2_0.text, @desc_2_0.text, "other desc_2_0");
        _assert_desc_models(@world, desc_2_1.inst, desc_2_1.key, game_id+1, @desc_2_1.text, @desc_2_1.text, "other desc_2_1");
    }

}
