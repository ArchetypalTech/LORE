use dojo::{
    world::{IWorldDispatcherTrait, WorldStorage},
    model::{ModelStorage},
};

use dojo_cairo_test::{
    ContractDef, ContractDefTrait, NamespaceDef, TestResource, WorldStorageTestTrait,
    spawn_test_world,
};

use lore::{
    systems::{
        designer::{designer, IDesignerDispatcher},
        prompt::{prompt, IPromptDispatcher},
        game_token::{game_token, IGameTokenDispatcher},
    },
    models,
    models::{
        entity::{Entity, EntityImpl},
        player::{PlayerStory, StoryLine},
    },
    types::{
        command_type::{IntoTokenTypeFelt252},
    },
    constants::{errors::{}},
    lib::{
        dictionary::{initialize_dictionary},
        utils::{ByteArrayTraitExt, SerializedAppend},
        dns::{DnsTrait},
    },
};


use starknet::{ContractAddress, testing};

pub fn set_caller(caller: ContractAddress) {
    starknet::testing::set_account_contract_address(caller);    // starknet::get_execution_info().tx_info.account_contract_address
    starknet::testing::set_contract_address(caller);            // starknet::get_execution_info().contract_address
}

pub fn ZERO()      -> ContractAddress { 0x0.try_into().unwrap() }
pub fn OWNER()     -> ContractAddress { 0x1.try_into().unwrap() } // mock owner of duelists 1-2
pub fn OTHER()     -> ContractAddress { 0x2.try_into().unwrap() } // mock owner of duelists 3-4
pub fn ADMIN()     -> ContractAddress { 0x3.try_into().unwrap() } // mock owner of duelists 3-4
pub fn RECIPIENT() -> ContractAddress { 0x4.try_into().unwrap() }



//-----------------------------------
// deploy test contrac
//

pub fn setup_core_initialized() -> (
    WorldStorage, IDesignerDispatcher, IPromptDispatcher, IGameTokenDispatcher, ContractAddress, ContractAddress,
) {
    let (world, designer, prompt, token, player_1, player_2) = setup_core();

    (world, designer, prompt, token, player_1, player_2)
}

fn namespace_def() -> NamespaceDef {
    let ndef = NamespaceDef {
        namespace: "lore",
        resources: [
            TestResource::Model(models::index::m_Dict::TEST_CLASS_HASH.into()),
            TestResource::Model(models::player::m_Player::TEST_CLASS_HASH.into()),
            TestResource::Model(models::player::m_PlayerStory::TEST_CLASS_HASH.into()),
            TestResource::Model(models::player::m_StoryLine::TEST_CLASS_HASH.into()),
            TestResource::Model(models::entity::m_Entity::TEST_CLASS_HASH.into()),
            TestResource::Model(models::reactable::m_Reactable::TEST_CLASS_HASH.into()),
            TestResource::Model(models::description_text::m_DescriptionText::TEST_CLASS_HASH.into()),
            TestResource::Model(models::area::m_Area::TEST_CLASS_HASH.into()),
            TestResource::Model(models::exit::m_Exit::TEST_CLASS_HASH.into()),
            TestResource::Model(models::container::m_Container::TEST_CLASS_HASH.into()),
            TestResource::Model(models::inventory_item::m_InventoryItem::TEST_CLASS_HASH.into()),
            TestResource::Model(models::entity::m_ParentToChildren::TEST_CLASS_HASH.into()),
            TestResource::Model(models::entity::m_ChildToParent::TEST_CLASS_HASH.into()),
            TestResource::Model(models::trigger::m_Trigger::TEST_CLASS_HASH.into()),
            TestResource::Model(models::trigger::m_TriggerIndex::TEST_CLASS_HASH.into()),
            TestResource::Model(models::trigger::m_TriggerExecuted::TEST_CLASS_HASH.into()),
            TestResource::Model(models::condition::m_Condition::TEST_CLASS_HASH.into()),
            TestResource::Model(models::index::m_PropertyRegistry::TEST_CLASS_HASH.into()),
            TestResource::Model(models::effect::m_Effect::TEST_CLASS_HASH.into()),
            TestResource::Model(models::action::m_Action::TEST_CLASS_HASH.into()),
            TestResource::Model(models::action::m_ActionExecuted::TEST_CLASS_HASH.into()),
            TestResource::Model(models::game_instance::m_GameInstanceMap::TEST_CLASS_HASH.into()),
            TestResource::Model(models::game_instance::m_GameInstanceKeyMap::TEST_CLASS_HASH.into()),
            // game_token
            TestResource::Model(models::admin::m_AccountPermissions::TEST_CLASS_HASH.into()),
            TestResource::Model(models::token_config::m_PlayerAccount::TEST_CLASS_HASH.into()),
            TestResource::Model(models::token_config::m_GameTokenInfo::TEST_CLASS_HASH.into()),
            TestResource::Event(models::token_config::e_GameCreatedEvent::TEST_CLASS_HASH.into()),
            // Arcade achievements
            TestResource::Event(achievement::events::index::e_TrophyCreation::TEST_CLASS_HASH.into()),
            TestResource::Event(achievement::events::index::e_TrophyProgression::TEST_CLASS_HASH.into()),
            // TestResource::Event(),
            TestResource::Contract(prompt::TEST_CLASS_HASH.into()),
            TestResource::Contract(designer::TEST_CLASS_HASH.into()),
            TestResource::Contract(game_token::TEST_CLASS_HASH.into()),
        ].span(),
    };

    ndef
}

fn core_contract_defs() -> Span<ContractDef> {
    let mut game_token_init_calldata: Array<felt252> = array![];
    let admin_accounts: Span<felt252> = array![ADMIN().into()].span();
    game_token_init_calldata.append_serde(admin_accounts);
    [
        ContractDefTrait::new(@"lore", @"designer")
            .with_writer_of([dojo::utils::bytearray_hash(@"lore")].span())
            .with_init_calldata(array![].span()),
        ContractDefTrait::new(@"lore", @"prompt")
            .with_writer_of([dojo::utils::bytearray_hash(@"lore"),].span()),
        ContractDefTrait::new(@"lore", @"game_token")
            .with_writer_of([dojo::utils::bytearray_hash(@"lore"),].span())
            .with_init_calldata(game_token_init_calldata.span()),
    ].span()
}


pub fn setup_core() -> (
    WorldStorage, IDesignerDispatcher, IPromptDispatcher, IGameTokenDispatcher, ContractAddress, ContractAddress,
) {
    set_caller(OWNER());

    let mut world = spawn_test_world(
        dojo::world::world::TEST_CLASS_HASH.into(),
        [namespace_def()].span(),
    );

    world.sync_perms_and_inits(core_contract_defs());

    world.dispatcher.grant_owner(dojo::utils::bytearray_hash(@"lore"), OWNER());
    world.dispatcher.grant_owner(selector_from_tag!("lore-designer"), OWNER());
    world.dispatcher.grant_owner(selector_from_tag!("lore-prompt"), OWNER());
    world.dispatcher.grant_owner(selector_from_tag!("lore-game_token"), OWNER());

    let designer = IDesignerDispatcher { contract_address: world.designer_address() };
    let prompt = IPromptDispatcher { contract_address: world.prompt_address() };
    let game_token = IGameTokenDispatcher { contract_address: world.game_token_address() };

    // FIXME: Setup permissions
    world.dispatcher.grant_writer(selector_from_tag!("lore-Dict"), world.prompt_address());

    // world.grant_writer(selector_from_tag!("pixelaw-AppName"), core_actions_address);
    // world.grant_writer(selector_from_tag!("pixelaw-CoreActionsAddress"), core_actions_address);
    // world.grant_writer(selector_from_tag!("pixelaw-Pixel"), core_actions_address);
    // world.grant_writer(selector_from_tag!("pixelaw-RTree"), core_actions_address);
    // world.grant_writer(selector_from_tag!("pixelaw-Area"), core_actions_address);

    testing::set_block_number(1);
    testing::set_block_timestamp(1);

    // Setup players
    let player_1 = 0x69.try_into().unwrap(); // 105
    let player_2 = 0x42.try_into().unwrap(); // 66

    // burn entity 0 value
    EntityImpl::create_entity(ref world, "entity_0");

    initialize_dictionary(world);

    (world, designer, prompt, game_token, player_1, player_2)
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
                        .register_contract((*ch).try_into().unwrap(), namespace.clone(), (*ch).try_into().unwrap());
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


//
// misc functions
//

pub fn player_story_len(world: @WorldStorage, game_id: u128) -> u32 {
    let story: PlayerStory = world.read_model(game_id);
    (story.story_line)
}
pub fn player_story_last_line(world: @WorldStorage, game_id: u128) -> ByteArray {
    let story: PlayerStory = world.read_model(game_id);
    let story_line: StoryLine = world.read_model((game_id, story.story_line),);
    (story_line.line)
}
pub fn print_player_story_last_line(world: @WorldStorage, game_id: u128) {
    println!("___output: {:?}", player_story_last_line(world, game_id));
}

pub fn create_new_entity(inst: felt252, name: ByteArray) -> Entity {
    (Entity {
        inst,
        is_entity: true,
        name,
        alt_names: array![],
        actions_keys: array![],
        creator_address: starknet::get_caller_address(),
    })
}
