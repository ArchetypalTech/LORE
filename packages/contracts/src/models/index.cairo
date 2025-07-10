use starknet::ContractAddress;

#[derive(Introspect, Drop, Copy, Serde)]
pub struct TokenGateConfig {
    pub erc721_address: ContractAddress,
    pub enabled: bool,
}

#[derive(Introspect, Drop, Serde)]
#[dojo::model]
pub struct SettingsMetadata {
    #[key]
    pub settings_id: u32,
    pub name: felt252,
    pub created_by: ContractAddress,
    pub created_at: u64,
}

#[derive(Introspect, Copy, Drop, Serde)]
#[dojo::model]
pub struct GameSettings {
    #[key]
    pub settings_id: u32,
    pub token_gate: TokenGateConfig,
}

#[derive(IntrospectPacked, Copy, Drop, Serde)]
#[dojo::model]
pub struct SettingsCounter {
    #[key]
    pub id: felt252,
    pub count: u32,
}
