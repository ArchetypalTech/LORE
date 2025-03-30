use dojo::{world::{WorldStorage, IWorldDispatcherTrait}};

use origami_random::dice::{DiceTrait};

#[inline]
pub fn random_u8(seed: felt252) -> u8 {
    let result: u8 = (random_u16(seed) % 255_u16).try_into().unwrap();
    result
}

#[inline]
pub fn random_u16(seed: felt252) -> u16 {
    let mut dice = DiceTrait::new(255, seed);
    let var_1: u16 = dice.roll().into();
    let var_2: u16 = dice.roll().into();
    let result: u16 = (var_1 * 42_u16 + var_2).into();
    result
}

#[inline]
pub fn random_text(world: WorldStorage, texts: Array<ByteArray>) -> ByteArray {
    let rng: u32 = random_u16(world.dispatcher.uuid().try_into().unwrap()).try_into().unwrap();
    let description = texts.at(rng % texts.len()).clone();
    description
}

#[cfg(test)]
mod tests {
    use dojo::world::IWorldDispatcherTrait;
    use lore::tests::helpers;
    use super::random_u8;
    use super::random_u16;

    #[test]
    fn Random_test_random_u8() {
        let (world, _, _, _, _) = helpers::setup_core();
        let mut num = array![];
        for _ in 0..10_u8 {
            let seed: felt252 = world.dispatcher.uuid().try_into().unwrap();
            let result: u8 = random_u8(seed);
            num.append(result);
        };
        println!("rnd_u8: {:?}", num);
    }

    #[test]
    fn Random_test_random_u16() {
        let (world, _, _, _, _) = helpers::setup_core();
        let mut num = array![];
        for _ in 0..10_u8 {
            let seed: felt252 = world.dispatcher.uuid().try_into().unwrap();
            let result: u16 = random_u16(seed);
            num.append(result);
        };
        println!("rnd_u16: {:?}", num);
    }
}
