use dojo::{world::{IWorldDispatcherTrait, WorldStorage, WorldStorageTrait}};

use dojo_cairo_test::{
    ContractDef, ContractDefTrait, NamespaceDef, TestResource, WorldStorageTestTrait,
    spawn_test_world,
};

use lore::{
    systems::{ //
        designer::{designer, IDesignerDispatcher}, //
        prompt::{prompt, IPromptDispatcher} //
    },
    components::{ //
        area::{m_Area}, // 
        inspectable::{m_Inspectable}, //
        player::{m_Player, m_PlayerStory} //
    },
    constants::{errors::{}},
    lib::{
        entity::{m_Entity}, //
        a_lexer::{TokenTypeFelt252}, //
        dictionary::{m_Dict, init_dictionary}, //
        utils::{ByteArrayTraitExt},
    },
};


use starknet::{ContractAddress, contract_address_const};

pub fn set_caller(caller: ContractAddress) {
    starknet::testing::set_account_contract_address(caller);
    starknet::testing::set_contract_address(caller);
}

pub fn ZERO_ADDRESS() -> ContractAddress {
    contract_address_const::<0x0>()
}

pub fn setup_core_initialized() -> (
    WorldStorage, IDesignerDispatcher, IPromptDispatcher, ContractAddress, ContractAddress,
) {
    let (world, designer, prompt, player_1, player_2) = setup_core();

    (world, designer, prompt, player_1, player_2)
}

fn namespace_def() -> NamespaceDef {
    let ndef = NamespaceDef {
        namespace: "lore",
        resources: [
            TestResource::Model(m_Dict::TEST_CLASS_HASH),
            TestResource::Model(m_Player::TEST_CLASS_HASH),
            TestResource::Model(m_PlayerStory::TEST_CLASS_HASH),
            TestResource::Model(m_Entity::TEST_CLASS_HASH),
            TestResource::Model(m_Inspectable::TEST_CLASS_HASH),
            TestResource::Model(m_Area::TEST_CLASS_HASH),
            // TestResource::Event(),
            TestResource::Contract(prompt::TEST_CLASS_HASH),
            TestResource::Contract(designer::TEST_CLASS_HASH),
        ]
            .span(),
    };

    ndef
}

fn core_contract_defs() -> Span<ContractDef> {
    [
        ContractDefTrait::new(@"lore", @"designer")
            .with_writer_of([dojo::utils::bytearray_hash(@"lore")].span()),
        ContractDefTrait::new(@"lore", @"prompt")
            .with_writer_of([dojo::utils::bytearray_hash(@"lore")].span()),
    ]
        .span()
}


pub fn setup_core() -> (
    WorldStorage, IDesignerDispatcher, IPromptDispatcher, ContractAddress, ContractAddress,
) {
    let mut world = spawn_test_world([namespace_def()].span());

    world.sync_perms_and_inits(core_contract_defs());

    let (designer_address, _) = world.dns(@"designer").unwrap();
    let (prompt_address, _) = world.dns(@"prompt").unwrap();
    let designer = IDesignerDispatcher { contract_address: designer_address };
    let prompt = IPromptDispatcher { contract_address: prompt_address };

    // FIXME: Setup permissions
    // world.dispatcher.grant_writer(selector_from_tag!("pixelaw-App"), core_actions_address);
    // world.grant_writer(selector_from_tag!("pixelaw-AppName"), core_actions_address);
    // world.grant_writer(selector_from_tag!("pixelaw-CoreActionsAddress"), core_actions_address);
    // world.grant_writer(selector_from_tag!("pixelaw-Pixel"), core_actions_address);
    // world.grant_writer(selector_from_tag!("pixelaw-RTree"), core_actions_address);
    // world.grant_writer(selector_from_tag!("pixelaw-Area"), core_actions_address);

    // Setup players
    let player_1 = contract_address_const::<0x69>();
    let player_2 = contract_address_const::<0x42>();

    init_dictionary(world);

    (world, designer, prompt, player_1, player_2)
}


pub fn update_test_world(ref world: WorldStorage, namespaces_defs: Span<NamespaceDef>) {
    for ns in namespaces_defs {
        let namespace = ns.namespace.clone();

        // TODO make this failsafe
        // world.dispatcher.register_namespace(namespace.clone());

        for r in ns.resources.clone() {
            match r {
                TestResource::Event(ch) => {
                    world.dispatcher.register_event(namespace.clone(), (*ch).try_into().unwrap());
                },
                TestResource::Model(ch) => {
                    world.dispatcher.register_model(namespace.clone(), (*ch).try_into().unwrap());
                },
                TestResource::Contract(ch) => {
                    world
                        .dispatcher
                        .register_contract(*ch, namespace.clone(), (*ch).try_into().unwrap());
                },
                TestResource::Library((
                    _ch, _name, _version,
                )) => { // FIXME somehow cannot call "register_library", for later fix when we're using
                // libraries world
                //     .register_library(
                //         namespace.clone(),
                //         (*ch).try_into().unwrap(),
                //         (*name).clone(),
                //         (*version).clone(),
                //     );
                },
            }
        }
    };
}

pub fn drop_all_events(address: ContractAddress) {
    loop {
        match starknet::testing::pop_log_raw(address) {
            core::option::Option::Some(_) => {},
            core::option::Option::None => { break; },
        };
    }
}
