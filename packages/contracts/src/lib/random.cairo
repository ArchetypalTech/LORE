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

#[cfg(test)]
mod tests {
    use dojo::world::IWorldDispatcherTrait;
    use lore::tests::helpers;
    use super::random_u8;
    use super::random_u16;

    #[test]
    fn Random_test_random_u8() {
        let (world, _, _, _, _) = helpers::setup_core();
        for _ in 0..10_u8 {
            let seed: felt252 = world.dispatcher.uuid().try_into().unwrap();
            let result: u8 = random_u8(seed);
            println!("rnd_u8: {:?}", result);
        }
    }

    #[test]
    fn Random_test_random_u16() {
        let (world, _, _, _, _) = helpers::setup_core();
        for _ in 0..10_u8 {
            let seed: felt252 = world.dispatcher.uuid().try_into().unwrap();
            let result: u16 = random_u16(seed);
            println!("rnd_u16: {:?}", result);
        }
    }
}
