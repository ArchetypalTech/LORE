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
        designer::{IDesignerDispatcher},
        prompt::{IPromptDispatcher},
        game_token::{IGameTokenDispatcher},
        trail_token::{ITrailTokenDispatcher},
    },
    models,
    models::{
        entity::{Entity, EntityImpl},
        player::{PlayerStory, StoryLine},
        dictionary::{DictionaryTrait},
    },
    types::{
        command_type::{IntoTokenTypeFelt252},
    },
    constants::{errors::{}},
    lib::{
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

pub const PLAYER_1: ContractAddress = 0x69.try_into().unwrap(); // 105
pub const PLAYER_2: ContractAddress = 0x42.try_into().unwrap(); // 66

#[derive(Copy, Drop)]
pub struct HelperSystems {
    pub world:WorldStorage,
    pub designer:IDesignerDispatcher,
    pub prompt:IPromptDispatcher,
    pub game_token:IGameTokenDispatcher,
    pub trail_token:ITrailTokenDispatcher,
}

//-----------------------------------
// deploy test contrac
//

fn namespace_def() -> NamespaceDef {
    let ndef: NamespaceDef = NamespaceDef {
        namespace: "lore",
        resources: [
            TestResource::Model(models::dictionary::m_Dict::TEST_CLASS_HASH.into()),
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
            TestResource::Model(models::game_token_info::m_PlayerGame::TEST_CLASS_HASH.into()),
            TestResource::Model(models::game_token_info::m_GameTokenInfo::TEST_CLASS_HASH.into()),
            TestResource::Event(models::game_token_info::e_GameCreatedEvent::TEST_CLASS_HASH.into()),
            // trail_token
            TestResource::Model(models::trail_token_info::m_TrailTokenInfo::TEST_CLASS_HASH.into()),
            TestResource::Model(models::trail_token_info::m_TrailProgress::TEST_CLASS_HASH.into()),
            TestResource::Event(models::trail_token_info::e_TrailCreatedEvent::TEST_CLASS_HASH.into()),
            // Arcade achievements
            TestResource::Event(achievement::events::index::e_TrophyCreation::TEST_CLASS_HASH.into()),
            TestResource::Event(achievement::events::index::e_TrophyProgression::TEST_CLASS_HASH.into()),
            // Systems
            TestResource::Contract(lore::systems::designer::designer::TEST_CLASS_HASH.into()),
            TestResource::Contract(lore::systems::prompt::prompt::TEST_CLASS_HASH.into()),
            TestResource::Contract(lore::systems::game_token::game_token::TEST_CLASS_HASH.into()),
            TestResource::Contract(lore::systems::trail_token::trail_token::TEST_CLASS_HASH.into()),
            TestResource::Library((lore::lib::a_lexer::lexer::TEST_CLASS_HASH.into(), @"lexer", @"0_2_0")),
        ].span(),
    };
    (ndef)
}

fn core_contract_defs() -> Span<ContractDef> {
    let mut game_token_init_calldata: Array<felt252> = array![];
    let admin_accounts: Span<felt252> = array![ADMIN().into()].span();
    game_token_init_calldata.append_serde(admin_accounts);
    [
        ContractDefTrait::new(@"lore", @"designer")
            .with_writer_of([dojo::utils::bytearray_hash(@"lore")].span())
            .with_init_calldata(game_token_init_calldata.span()),
        ContractDefTrait::new(@"lore", @"prompt")
            .with_writer_of([dojo::utils::bytearray_hash(@"lore"),].span()),
        ContractDefTrait::new(@"lore", @"game_token")
            .with_writer_of([dojo::utils::bytearray_hash(@"lore"),].span())
            .with_init_calldata(array![].span()),
        ContractDefTrait::new(@"lore", @"trail_token")
            .with_writer_of([dojo::utils::bytearray_hash(@"lore"),].span())
            .with_init_calldata(array![].span()),
    ].span()
}


pub fn setup_core() -> HelperSystems {
    set_caller(OWNER());

    let mut world: WorldStorage = spawn_test_world(
        dojo::world::world::TEST_CLASS_HASH.into(),
        [namespace_def()].span(),
    );

    world.sync_perms_and_inits(core_contract_defs());

    world.dispatcher.grant_owner(dojo::utils::bytearray_hash(@"lore"), OWNER());
    world.dispatcher.grant_owner(selector_from_tag!("lore-designer"), OWNER());
    world.dispatcher.grant_owner(selector_from_tag!("lore-prompt"), OWNER());
    world.dispatcher.grant_owner(selector_from_tag!("lore-game_token"), OWNER());

    let designer: IDesignerDispatcher = IDesignerDispatcher { contract_address: world.designer_address() };
    let prompt: IPromptDispatcher = IPromptDispatcher { contract_address: world.prompt_address() };
    let game_token: IGameTokenDispatcher = IGameTokenDispatcher { contract_address: world.game_token_address() };
    let trail_token: ITrailTokenDispatcher = ITrailTokenDispatcher { contract_address: world.trail_token_address() };

    // FIXME: Setup permissions
    world.dispatcher.grant_writer(selector_from_tag!("lore-Dict"), world.prompt_address());

    // world.grant_writer(selector_from_tag!("pixelaw-AppName"), core_actions_address);
    // world.grant_writer(selector_from_tag!("pixelaw-CoreActionsAddress"), core_actions_address);
    // world.grant_writer(selector_from_tag!("pixelaw-Pixel"), core_actions_address);
    // world.grant_writer(selector_from_tag!("pixelaw-RTree"), core_actions_address);
    // world.grant_writer(selector_from_tag!("pixelaw-Area"), core_actions_address);

    testing::set_block_number(1);
    testing::set_block_timestamp(1);

    // burn entity 0 value
    EntityImpl::create_entity(ref world, "entity_0");

    DictionaryTrait::initialize_dictionary(ref world);

    (HelperSystems {
        world,
        designer,
        prompt,
        game_token,
        trail_token,
    })
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
        story_id: 1,
        trail_id: 1,
        name,
        alt_names: array![],
        actions_keys: array![],
        creator_address: starknet::get_caller_address(),
    })
}
