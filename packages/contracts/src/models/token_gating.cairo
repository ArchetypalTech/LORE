use starknet::ContractAddress;
pub use lore::models::index::TokenGateConfig;

#[generate_trait]
pub impl TokenGateConfigImpl of TokenGateConfigTrait {
    #[inline]
    fn new(erc721_address: ContractAddress, enabled: bool) -> TokenGateConfig {
        TokenGateConfig { erc721_address: erc721_address, enabled: enabled }
    }

    #[inline]
    fn flip_enabled(ref self: TokenGateConfig) {
        self.enabled = !self.enabled;
    }

    #[inline]
    fn set_gate_address(ref self: TokenGateConfig, erc721_address: ContractAddress) {
        self.erc721_address = erc721_address;
    }
}
