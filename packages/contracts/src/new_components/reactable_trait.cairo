use dojo::{model::ModelStorage, world::{WorldStorage, IWorldDispatcherTrait}};
use lore::{
    models::{
        index::{DescriptionText},
        reactable::{Reactable, get_action_token}
    },
    types::{
        component_type::{ReactableActions},
        command_type::Command,
    },
    lib::random,
};


#[generate_trait]
pub impl ReactableImpl of ReactableTrait {
    fn get_random_description(
        self: @Reactable, command: @Command, world: WorldStorage,
    ) -> ByteArray {
        let (action, _token) = get_action_token(self, world, command).unwrap();
        match action.action_fn {
            ReactableActions::ReadRandomDescription => {
                let (idx1, idx2): (u32, u32) = action.entrypoints.try_into().unwrap();
                if self.description.len() == 0 || idx1 > idx2 {
                    return "";
                }
                let range_len = idx2 - idx1 + 1;
                let rng: u32 = random::random_u16(world.dispatcher.uuid().try_into().unwrap())
                    .try_into()
                    .unwrap();

                let random_idx = idx1 + (rng % range_len);
                if random_idx >= self.description.len().try_into().unwrap() {
                    return ""; // avoid out-of-bounds access
                }
                let key: u32 = self.description.at(random_idx).clone();
                let descriptionText: DescriptionText = world.read_model((*self.inst, key));
                descriptionText.text
            },
            _ => "",
        }
    }

    fn get_first_description(self: @Reactable, world: WorldStorage) -> ByteArray {
        if self.description.len() == 0 {
            return "";
        }
        let key: u32 = self.description.at(0).clone();
        let descriptionText: DescriptionText = world.read_model((self.inst.clone(), key));
        descriptionText.text
    }

    fn get_specific_description(
        reactable: @Reactable, index: u32, world: WorldStorage,
    ) -> ByteArray {
        if reactable.description.len() == 0 {
            return "";
        }
        let key: u32 = reactable.description.at(index).clone();
        let descriptionText: DescriptionText = world.read_model((reactable.inst.clone(), key));
        descriptionText.text
    }
}
