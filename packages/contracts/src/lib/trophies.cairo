
#[derive(Copy, Drop, PartialEq)]
pub enum Trophy {
    None,               // 0
    FerryDeck,          // 1
    DockSide,           // 2
    TheFool,            // 3
    StagingGrounds,     // 4
    Marshes,            // 5
    Salts,              // 6
    Celestial,          // 7
    NewRuggin,          // 8
    ForkstoneVerge,     // 9
    BlackSpire,         // 10
    TCM,                // 11
    Usants,             // 12
    Crossroads,         // 13
    Ending1,            // 14
    Ending2,            // 15
    Ending3,            // 16
}

pub mod TROPHIES {
    // trophy count
    pub const COUNT: u8 = 16;
}

pub mod TROPHY_GROUP {
    pub const Trails: felt252 = 'Trails';
    pub const Endings: felt252 = 'Endings';
}


//------------------------------------------
// Traits
//
use starknet::{ContractAddress};
use dojo::world::{WorldStorage};
use achievement::{
    types::task::{Task as ArcadeTask, TaskTrait as ArcadeTaskTrait},
    store::{Store as ArcadeStore, StoreTrait as ArcadeStoreTrait},
};
use lore::{
    lib::{
        utils::ByteArrayTraitExt,
    },
};


#[generate_trait]
pub impl TrophyImpl of TrophyTrait {
    fn identifier(self: @Trophy) -> felt252 {
        match self {
            Trophy::None            => '',
            // TROPHY_GROUP::Trails
            Trophy::FerryDeck       => 'FerryDeck',
            Trophy::DockSide        => 'DockSide',
            Trophy::TheFool         => 'TheFool',
            Trophy::StagingGrounds  => 'StagingGrounds',
            Trophy::Marshes         => 'Marshes',
            Trophy::Salts           => 'Salts',
            Trophy::Celestial       => 'Celestial',
            Trophy::NewRuggin       => 'NewRuggin',
            Trophy::ForkstoneVerge  => 'ForkstoneVerge',
            Trophy::BlackSpire      => 'BlackSpire',
            Trophy::TCM             => 'TCM',
            Trophy::Usants          => 'Usants',
            Trophy::Crossroads      => 'Crossroads',
            // TROPHY_GROUP::Endings
            Trophy::Ending1         => 'Ending1',
            Trophy::Ending2         => 'Ending2',
            Trophy::Ending3         => 'Ending3',
        }
    }

    // The achievement group, it should be used to group achievements together
    fn group(self: @Trophy) -> felt252 {
        match self {
            Trophy::Ending1 |
            Trophy::Ending2 |
            Trophy::Ending3 => TROPHY_GROUP::Endings,
            _ => TROPHY_GROUP::Trails,
        }
    }

    // index inside the group
    fn index(self: @Trophy) -> u8 {
        match self {
            Trophy::None            => 0,
            // TROPHY_GROUP::Trails
            Trophy::FerryDeck       => 0,
            Trophy::DockSide        => 1,
            Trophy::TheFool         => 2,
            Trophy::StagingGrounds  => 3,
            Trophy::Marshes         => 4,
            Trophy::Salts           => 5,
            Trophy::Celestial       => 6,
            Trophy::NewRuggin       => 7,
            Trophy::ForkstoneVerge  => 8,
            Trophy::BlackSpire      => 9,
            Trophy::TCM             => 10,
            Trophy::Usants          => 11,
            Trophy::Crossroads      => 12,
            // TROPHY_GROUP::Endings
            Trophy::Ending1         => 0,
            Trophy::Ending2         => 1,
            Trophy::Ending3         => 2,
        }
    }

    fn title(self: @Trophy) -> felt252 {
        match self {
            Trophy::None            => 'None',
            // TROPHY_GROUP::Player
            Trophy::FerryDeck       => 'Ferry Deck',
            Trophy::DockSide        => 'Dock Side',
            Trophy::TheFool         => 'The Fool & Flitlock Tavern',
            Trophy::StagingGrounds  => 'Staging Grounds',
            Trophy::Marshes         => 'Marsh Clutch',
            Trophy::Salts           => 'Salt-Sheet Flats',
            Trophy::Celestial       => 'Celestial Relay',
            Trophy::NewRuggin       => 'New Ruggin Perimeter',
            Trophy::ForkstoneVerge  => 'Forkstone Verge',
            Trophy::BlackSpire      => 'Relay AR-3',
            Trophy::TCM             => 'TCM Spoke 12',
            Trophy::Usants          => 'Usants',
            Trophy::Crossroads      => 'Crossroads',
            // TROPHY_GROUP::Endings
            Trophy::Ending1         => 'Ending 1',
            Trophy::Ending2         => 'Ending 2',
            Trophy::Ending3         => 'Ending 3',
        }
    }

    fn description(self: @Trophy) -> ByteArray {
        match self {
            Trophy::None            => "I need context.",
            // TROPHY_GROUP::Trails
            Trophy::FerryDeck       => "You wake to the accelerating chocks of an overworked but reliable engine being put into reverse...",
            Trophy::DockSide        => "The dock is a concrete slab sweating salt and bureaucratic disdain...",
            Trophy::TheFool         => "Patrons huddle in cliques - trail-hardened strangers with eyes that dart like sparrows...",
            Trophy::StagingGrounds  => "Past the tavern's alley, the town thins into a stripped industrial edge-a no-man's-land of pallets...",
            Trophy::Marshes         => "The marsh heaves in slow breaths...",
            Trophy::Salts           => "Past the tavern's alley, the town thins into a stripped industrial edge-a no-man's-land of pallets...",
            Trophy::Celestial       => "After entering and going through the canyon, you find yourself at a Relay...",
            Trophy::NewRuggin       => "Sheds in a maze, fences like handwriting, a smell of printer heat...",
            Trophy::ForkstoneVerge  => "A road sign in two halves scratched by a patient knife...",
            Trophy::BlackSpire      => "Deep inside the cavern system stands a silent relay post...",
            Trophy::TCM             => "Concrete flares into a stem with plates like insect armor...",
            Trophy::Usants          => "Painted lines, mirrored glass, voices modulated to neutral...",
            Trophy::Crossroads      => "The Crossroads is the staging area for user generated content...",
            // TROPHY_GROUP::Endings
            Trophy::Ending1         => "Ending 1...",
            Trophy::Ending2         => "Ending 2...",
            Trophy::Ending3         => "Ending 3...",
        }
    }

    fn task_description(self: @Trophy) -> ByteArray {
        match self {
            Trophy::None                => "Huhhh...",
            // TROPHY_GROUP::Trails
            Trophy::FerryDeck       => "Start your journey at the Ferry Deck",
            Trophy::DockSide        => "Reach the Dock Side",
            Trophy::TheFool         => "Reach the Fool & Flitlock Tavern",
            Trophy::StagingGrounds  => "Reach the Staging Grounds",
            Trophy::Marshes         => "Reach the Marsh Clutch",
            Trophy::Salts           => "Reach the Salt-Sheet Flats",
            Trophy::Celestial       => "Reach the Celestial Relay",
            Trophy::NewRuggin       => "Reach the New Ruggin Perimeter",
            Trophy::ForkstoneVerge  => "Reach the Forkstone Verge",
            Trophy::BlackSpire      => "Reach the Relay AR-3",
            Trophy::TCM             => "Reach the TCM Spoke 12",
            Trophy::Usants          => "Reach Usants",
            Trophy::Crossroads      => "Reach the Crossroads",
            // TROPHY_GROUP::Endings
            Trophy::Ending1         => "Reach the Ending 1",
            Trophy::Ending2         => "Reach the Ending 2",
            Trophy::Ending3         => "Reach the Ending 3",
        }
    }

    // from: https://fontawesome.com/icons
    fn icon(self: @Trophy) -> felt252 {
        match self {
            Trophy::None            => 'fa-circle-question',
            // TROPHY_GROUP::Trails
            Trophy::FerryDeck       => 'fa-ferry',
            Trophy::DockSide        => 'fa-anchor',
            Trophy::TheFool         => 'fa-wine-bottle',
            Trophy::StagingGrounds  => 'fa-wagon-covered',
            Trophy::Marshes         => 'fa-hill-rockslide',
            Trophy::Salts           => 'fa-horizontal-rule',
            Trophy::Celestial       => 'fa-house-tree',
            Trophy::NewRuggin       => 'fa-bell-concierge',
            Trophy::ForkstoneVerge  => 'fa-sign-post',
            Trophy::BlackSpire      => 'fa-dungeon',
            Trophy::TCM             => 'fa-location-question',
            Trophy::Usants          => 'fa-barcode',
            Trophy::Crossroads      => 'fa-signs-post',
            // TROPHY_GROUP::Endings
            Trophy::Ending1         => 'fa-flag',
            Trophy::Ending2         => 'fa-flag-swallowtail',
            Trophy::Ending3         => 'fa-flag-pennant',
        }
    }

    fn points(self: @Trophy) -> u16 {
        match self {
            Trophy::None            => 0,
            // TROPHY_GROUP::Trails
            Trophy::FerryDeck       => 10,
            Trophy::DockSide        => 10,
            Trophy::TheFool         => 10,
            Trophy::StagingGrounds  => 10,
            Trophy::Marshes         => 10,
            Trophy::Salts           => 10,
            Trophy::Celestial       => 10,
            Trophy::NewRuggin       => 10,
            Trophy::ForkstoneVerge  => 10,
            Trophy::BlackSpire      => 10,
            Trophy::TCM             => 10,
            Trophy::Usants          => 10,
            Trophy::Crossroads      => 10,
            // TROPHY_GROUP::Endings
            Trophy::Ending1         => 100,
            Trophy::Ending2         => 100,
            Trophy::Ending3         => 100,
        }
    }

    fn from_room_inst(self: felt252) -> Trophy {
        if (self == 0x03300f5cdb0c4fb0281ccf00344beb3e79907e3c217f94dba02d8ef86ee1f2fc) {(Trophy::FerryDeck)}
        else if (self == 0x014d77a7b0faec26ae6a60c0f4d2322eb4b9405b5b644f9ad0887883e987fb43) {(Trophy::DockSide)}
        else if (self == 0x017625e5157fd410506cfcd655515651daf49d4a2b6da6ee351ffc011e0234c4) {(Trophy::TheFool)}
        else if (self == 0x03be4e404aa7fe9739467b455362babc3b8b32fc2a6b2eedc1b3a39f51e57272) {(Trophy::StagingGrounds)}
        else if (self == 0x03a419a814c431cc29706ccc4dcfbbb9c952cc96d2f9719d62ab8163b0f5bb52) {(Trophy::Marshes)} // start of Act 2
        else if (self == 0x01ac0212df270aaa32a64cb967ccda8886ae8937ace1f47fc70d390d6bc4f48c) {(Trophy::Salts)}
        else if (self == 0x038281211e4318c639d79e0637a7998e41a4abc993cc0d35aa1394bf85d1b5be) {(Trophy::Celestial)}
        else if (self == 0x023cac799dfbb07f1b2d1ebae31766c85c145cffb79d4b93b49a7a02f654d7a4) {(Trophy::NewRuggin)}
        else if (self == 0x032454cde156173c1f4ee9a89e4a3a97a9a81bc2f5237b81728af955569c85bb) {(Trophy::ForkstoneVerge)} // start of Act 3
        else if (self == 0x009337a3d78bcef8fd1123bc0b86c2bf3ce4447d06a6f9b0473622bbe0673485) {(Trophy::BlackSpire)}
        else if (self == 0x00149baaaf49ef617134213413abf7c3ea81dc112eebcc9afa413cf279e45768) {(Trophy::TCM)}
        else if (self == 0x011dfa59613087381d51de9ac0b38512d5657321b591f3a1706b05fa28f18300) {(Trophy::Usants)}
        else if (self == 0x00e0c2c6ce0cdff92c8e857cbde8b7e1ff75cabd59d015389e90aef0a033a976) {(Trophy::Crossroads)}
        else if (self == 0x11111111111) {(Trophy::Ending1)}
        else if (self == 0x22222222222) {(Trophy::Ending2)}
        else if (self == 0x33333333333) {(Trophy::Ending3)}
        else {(Trophy::None)}
    }

    fn hidden(self: @Trophy) -> bool {
        match self {
            Trophy::Ending1 => true,
            Trophy::Ending2 => true,
            Trophy::Ending3 => true,
            _ => false,
        }
    }

    #[inline(always)]
    fn start(self: @Trophy) -> u64 {
        (0)
    }

    #[inline(always)]
    fn end(self: @Trophy) -> u64 {
        (0)
    }

    fn task_count(self: @Trophy) -> u128 {
        match self {
            Trophy::None            => 0,
            // TROPHY_GROUP::Trails
            Trophy::FerryDeck       => 1,
            Trophy::DockSide        => 1,
            Trophy::TheFool         => 1,
            Trophy::StagingGrounds  => 1,
            Trophy::Marshes         => 1,
            Trophy::Salts           => 1,
            Trophy::Celestial       => 1,
            Trophy::NewRuggin       => 1,
            Trophy::ForkstoneVerge  => 1,
            Trophy::BlackSpire      => 1,
            Trophy::TCM             => 1,
            Trophy::Usants          => 1,
            Trophy::Crossroads      => 1,
            // TROPHY_GROUP::Endings
            Trophy::Ending1         => 1,
            Trophy::Ending2         => 1,
            Trophy::Ending3         => 1,
        }
    }

    fn tasks(self: @Trophy) -> Span<ArcadeTask> {
        let task: ArcadeTask = ArcadeTaskTrait::new(
            self.identifier(),
            self.task_count(),
            self.task_description(),
        );
        ([task].span())
    }

    #[inline(always)]
    fn data(self: @Trophy) -> ByteArray {
        ("")
    }

    // send a progress event to the arcade store
    // https://github.com/cartridge-gg/arcade/blob/main/packages/achievement/src/components/achievable.cairo#L99-L112
    // https://github.com/cartridge-gg/arcade/blob/main/packages/achievement/src/store.cairo#L59-L63
    fn progress(self: @Trophy, store: @ArcadeStore, player_address: ContractAddress, count: u128) {
// println!("___progress: {} {}", self, self.identifier());
        (*store).progress(
            player_address.into(),
            self.identifier(),
            count,
            starknet::get_block_timestamp(),
        );
    }
}


//----------------------------
// Converters
//

pub impl IntoTrophyU8 of core::traits::Into<Trophy, u8> {
    fn into(self: Trophy) -> u8 {
        match self {
            Trophy::None            => 0,
            // TROPHY_GROUP::Trails
            Trophy::FerryDeck       => 1,
            Trophy::DockSide        => 2,
            Trophy::TheFool         => 3,
            Trophy::StagingGrounds  => 4,
            Trophy::Marshes         => 5,
            Trophy::Salts           => 6,
            Trophy::Celestial       => 7,
            Trophy::NewRuggin       => 8,
            Trophy::ForkstoneVerge  => 9,
            Trophy::BlackSpire      => 10,
            Trophy::TCM             => 11,
            Trophy::Usants          => 12,
            Trophy::Crossroads      => 13,
            // TROPHY_GROUP::Endings
            Trophy::Ending1         => 14,
            Trophy::Ending2         => 15,
            Trophy::Ending3         => 16,
        }
    }
}

pub impl IntoU8Trophy of core::traits::Into<u8, Trophy> {
    fn into(self: u8) -> Trophy {
        let card: felt252 = self.into();
        match card {
            0  => Trophy::None,
            // TROPHY_GROUP::Trails
            1  => Trophy::FerryDeck,
            2  => Trophy::DockSide,
            3  => Trophy::TheFool,
            4  => Trophy::StagingGrounds,
            5  => Trophy::Marshes,
            6  => Trophy::Salts,
            7  => Trophy::Celestial,
            8  => Trophy::NewRuggin,
            9  => Trophy::ForkstoneVerge,
            10 => Trophy::BlackSpire,
            11 => Trophy::TCM,
            12 => Trophy::Usants,
            13 => Trophy::Crossroads,
            // TROPHY_GROUP::Endings
            14 => Trophy::Ending1,
            15 => Trophy::Ending2,
            16 => Trophy::Ending3,
            // invalids
            _  => Trophy::None,
        }
    }
}

// for println! format! (core::fmt::Display<>) assert! (core::fmt::Debug<>)
pub impl TrophyDisplay of core::fmt::Display<Trophy> {
    fn fmt(self: @Trophy, ref f: core::fmt::Formatter) -> Result<(), core::fmt::Error> {
        let result: ByteArray = ByteArrayTraitExt::byte_array_from_felt252(self.identifier());
        f.buffer.append(@result);
        Result::Ok(())
    }
}
pub impl TrophyDebug of core::fmt::Debug<Trophy> {
    fn fmt(self: @Trophy, ref f: core::fmt::Formatter) -> Result<(), core::fmt::Error> {
        let result: ByteArray = ByteArrayTraitExt::byte_array_from_felt252(self.identifier());
        f.buffer.append(@result);
        Result::Ok(())
    }
}





//------------------------------------------
// Trophy distribution
//

#[generate_trait]
pub impl TrophyProgressImpl of TrophyProgressTrait {
    // Duel has a winner
    fn on_enter_room(world: @WorldStorage, inst: felt252) -> Trophy {
        let store: @ArcadeStore = @ArcadeStoreTrait::new(*world);
        let trophy: Trophy = inst.from_room_inst();
        if (trophy != Trophy::None) {
            trophy.progress(store, starknet::get_caller_address(), 1);
        }
        (trophy)
    }
}



//----------------------------------------
// Unit  tests
//
#[cfg(test)]
mod unit {
    use super::{Trophy, TROPHIES};

    #[test]
    fn test_trophy_identifiers() {
        // invalid
        let mut last_trophy: Trophy = Trophy::None;
        let mut i: u8 = 1;
        while (i <= TROPHIES::COUNT) {
            let trophy: Trophy = i.into();
            assert_ne!(Trophy::None, trophy, "({}) is None", i);
            assert_ne!(last_trophy, trophy, "({}) == ({}): trophy", i, last_trophy);
            let ii: u8 = trophy.into();
            assert_eq!(i, ii, "({}) != ({}): trophy", i, ii);
            last_trophy = trophy;
            i += 1;
        };
        // // end of trophies
        // let trophy: Trophy = (TROPHY_ID::COUNT+1).into();
        // assert_eq!(Trophy::None, trophy, "bad TROPHY_ID::COUNT");
    }
}
