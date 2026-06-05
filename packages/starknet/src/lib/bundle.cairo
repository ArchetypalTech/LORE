use bundle::types::item::ItemTrait as BundleItemTrait;
use bundle::types::metadata::MetadataTrait as BundleMetadataTrait;
use lore_sn::models::permit_metadata::{orug_metadata};

#[generate_trait]
pub impl BundleMetadata of MetadataTrait {
    #[inline]
    fn bundle(
        payment_tokens: Span<starknet::ContractAddress>,
        conditions: Span<ByteArray>,
    ) -> ByteArray {
        let item = BundleItemTrait::new(
            name: "Permit",
            description: "Permit",
            image_uri: orug_metadata::CONTRACT_IMAGE(),
        );
        let metadata = BundleMetadataTrait::new(
            name: "Permit",
            description: "Permit",
            image_uri: orug_metadata::CONTRACT_IMAGE(),
            items: array![item].span(),
            tokens: payment_tokens,
            conditions: conditions,
        );
        metadata.jsonify()
    }
}
