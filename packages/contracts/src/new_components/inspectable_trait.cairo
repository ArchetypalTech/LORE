use dojo::{model::ModelStorage, world::{WorldStorage, IWorldDispatcherTrait}};
use lore::{models::index::{Inspectable, DescriptionText}, lib::random};


#[generate_trait]
pub impl InspectableImpl of InspectableTrait {
    fn look_at(self: @Inspectable, world: WorldStorage) -> ByteArray {
        self.get_random_description(world)
    }

    fn get_random_description(self: @Inspectable, world: WorldStorage) -> ByteArray {
        if self.description.len() == 0 {
            return "";
        }
        let rng: u32 = random::random_u16(world.dispatcher.uuid().try_into().unwrap())
            .try_into()
            .unwrap();
        let description_len: u32 = self.description.len().try_into().unwrap();
        let entryRandom: u32 = (rng % description_len).try_into().unwrap();
        let key: u32 = self.description.at(entryRandom).clone();
        let descriptionText: DescriptionText = world.read_model((*self.inst, key));
        descriptionText.text
    }

    fn get_first_description(self: @Inspectable, world: WorldStorage) -> ByteArray {
        if self.description.len() == 0 {
            return "";
        }
        let key: u32 = self.description.at(0).clone();
        let descriptionText: DescriptionText = world.read_model((self.inst.clone(), key));
        descriptionText.text
    }

    fn get_specific_description(inspectable: @Inspectable, index: u32, world: WorldStorage) -> ByteArray {
        if inspectable.description.len() == 0 {
            return "";
        }
        let key: u32 = inspectable.description.at(index).clone();
        let descriptionText: DescriptionText = world.read_model((inspectable.inst.clone(), key));
        descriptionText.text
    }
}
