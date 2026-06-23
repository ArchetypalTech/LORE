use super::dns::DnsTrait;
use starknet::{ContractAddress};
use dojo::world::WorldStorage;
use bundle::types::item::ItemTrait as BundleItemTrait;
use bundle::types::metadata::MetadataTrait as BundleMetadataTrait;
use lore_sn::appchain::appchain::{APPCHAIN, PermitTypeTrait};
use lore_sn::lib::constants::{orug_metadata, usdc_address, CONST};

// pre-register 10 bundles to reserve sequential ids (1-10)
pub const BUNDLE_COUNT: u32 = 10;

#[derive(Copy, Drop)]
pub enum BundleId {
    #[default]
    None,           // 0
    StandardPermit, // 1
}
pub impl IntoU32BundleId of core::traits::Into<u32, BundleId> {
    fn into(self: u32) -> BundleId {
        match self {
            0  => BundleId::None,
            1  => BundleId::StandardPermit,
            _  => BundleId::None,
        }
    }
}

#[derive(Drop)]
pub struct BundleDescriptor {
    pub name: ByteArray,
    pub description: ByteArray,
    pub image_uri: ByteArray,
    pub referral_percentage: u8,
    pub reissuable: bool,
    pub price: u256,
    pub payment_token: ContractAddress,
    pub payment_receiver: ContractAddress,
    pub allower: ContractAddress,
    // metadata
    pub payment_tokens: Span<starknet::ContractAddress>,
    pub conditions: Span<ByteArray>,
}

#[generate_trait]
pub impl BundleIdImpl of BundleIdTrait {
    // convert bundle_id to APPCHAIN::PERMIT_TYPES
    fn to_permit_type(self: BundleId) -> felt252 {
        match self {
            BundleId::StandardPermit => APPCHAIN::PERMIT_TYPES::PERMIT_BUNDLE,
            BundleId::None => 0,
        }
    }

    // convert bundle_id to BundleDescriptor
    // bundle_id from 0 to 9
    fn to_bundle_descriptor(self: BundleId, world: @WorldStorage) -> Option<BundleDescriptor> {
        let permit_type: felt252 = self.to_permit_type();
        let actions_count: u32 = permit_type.actions_count();
        match self {
            BundleId::StandardPermit => Option::Some(BundleDescriptor {
                name: "O'Ruggin Trail Permit",
                description: format!("Contains {} actions.", actions_count),
                image_uri: orug_metadata::CONTRACT_IMAGE(),
                referral_percentage: 0,
                reissuable: true,
                price: CONST::USDC_TO_WEI, // 1 USDC
                payment_token: usdc_address(),
                payment_receiver: world.setup_address(),
                allower: 0.try_into().unwrap(),
                payment_tokens: array![usdc_address()].span(),
                conditions: array![].span(),
            }),
            BundleId::None => Option::None,
        }
    }
}

#[generate_trait]
pub impl BundleDescriptorImpl of BundleDescriptorTrait {
    // build permit metadata for bundle
    fn to_bundle_metadata(self: @BundleDescriptor) -> ByteArray {
        let item = BundleItemTrait::new(
            name: self.name.clone(),
            description: self.description.clone(),
            image_uri: self.image_uri.clone(),
        );
        let metadata = BundleMetadataTrait::new(
            name: self.name.clone(),
            description: self.description.clone(),
            image_uri: self.image_uri.clone(),
            items: array![item].span(),
            tokens: *self.payment_tokens,
            conditions: *self.conditions,
        );
        metadata.jsonify()
    }
}
