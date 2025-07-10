use dojo::world::{WorldStorage, IWorldDispatcherTrait};
use lore::{models::index::Inspectable, lib::random};


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
        let description = self.description.at(rng % self.description.len()).clone();
        description
    }

    fn get_first_description(self: @Inspectable, world: WorldStorage) -> ByteArray {
        if self.description.len() == 0 {
            return "";
        }
        let description = self.description.at(0).clone();
        description
    }

    fn get_specific_description(inspectabe: @Inspectable, index: u32) -> ByteArray {
        if inspectabe.description.len() == 0 {
            return "";
        }
        let description = inspectabe.description.at(index).clone();
        description
    }
}
