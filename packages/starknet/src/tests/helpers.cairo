use starknet::{ContractAddress, testing};
// use dojo::model::{ModelStorage, ModelStorageTest};
use dojo::world::{
    IWorldDispatcherTrait,
    WorldStorage,
    // WorldStorageTrait,
};
use dojo_cairo_test::{
    ContractDef, ContractDefTrait, NamespaceDef, TestResource, WorldStorageTestTrait,
    spawn_test_world,
};
pub use lore_sn::lib::{
    dns::{DnsTrait,
        IPermitTokenDispatcher, IPermitTokenDispatcherTrait
    },
    messaging::{IMessagingDispatcher},
};

pub fn impersonate(caller: ContractAddress) {
    starknet::testing::set_account_contract_address(caller);    // starknet::get_execution_info().tx_info.account_contract_address
    starknet::testing::set_contract_address(caller);            // starknet::get_execution_info().contract_address
}

pub fn appchain_contract() -> ContractAddress { 0x1234.try_into().unwrap() }
pub fn cartridge_contract() -> ContractAddress { 0x5678.try_into().unwrap() }

pub fn ZERO()      -> ContractAddress { 0x0.try_into().unwrap() }
pub fn OWNER()     -> ContractAddress { 0x111.try_into().unwrap() } // mock owner of duelists 1-2
pub fn OTHER()     -> ContractAddress { 0x222.try_into().unwrap() } // mock owner of duelists 3-4
pub fn ADMIN()     -> ContractAddress { 0x333.try_into().unwrap() } // mock owner of duelists 3-4
pub fn RECIPIENT() -> ContractAddress { 0x444.try_into().unwrap() }


#[derive(Copy, Drop)]
pub struct HelperSystems {
    pub world: WorldStorage,
    pub permit: IPermitTokenDispatcher,
    pub messaging: IMessagingDispatcher,
}

fn namespace_def() -> NamespaceDef {
    let ndef: NamespaceDef = NamespaceDef {
        namespace: "lore_sn",
        resources: [
            TestResource::Model(lore_sn::models::permit_config::m_PermitConfig::TEST_CLASS_HASH.into()),
            TestResource::Model(lore_sn::models::permit_token_info::m_PermitTokenInfo::TEST_CLASS_HASH.into()),
            TestResource::Model(lore_sn::models::permit_token_info::m_PermitType::TEST_CLASS_HASH.into()),
            TestResource::Contract(lore_sn::systems::permit_token::permit_token::TEST_CLASS_HASH.into()),
            TestResource::Contract(lore_sn::tests::messaging_mock::messaging_mock::TEST_CLASS_HASH.into()),
        ].span(),
    };
    (ndef)
}


pub fn setup_core() -> HelperSystems {
    let ndef: NamespaceDef = namespace_def();
    let mut world: WorldStorage = spawn_test_world(
        dojo::world::world::TEST_CLASS_HASH,
        [ndef].span(),
    );

    let permit: IPermitTokenDispatcher = world.permit_token_dispatcher();
    let messaging: IMessagingDispatcher = world.messaging_mock_dispatcher();

    let contract_defs: Span<ContractDef> = {
        [
            ContractDefTrait::new(@"lore_sn", @"permit_token")
                .with_writer_of([dojo::utils::bytearray_hash(@"lore_sn")].span())
                .with_init_calldata(array![
                    messaging.contract_address.into(),
                    appchain_contract().into(),
                    cartridge_contract().into()].span()),
        ].span()
    };

    world.sync_perms_and_inits(contract_defs);
    world.dispatcher.grant_owner(dojo::utils::bytearray_hash(@"lore_sn"), OWNER());
    world.dispatcher.grant_owner(lore_sn::lib::dns::SELECTORS::PERMIT_TOKEN, OWNER());

    testing::set_block_number(1);
    testing::set_block_timestamp(1);
    impersonate(OWNER());

    (HelperSystems {
        world,
        permit,
        messaging,
    })
}
