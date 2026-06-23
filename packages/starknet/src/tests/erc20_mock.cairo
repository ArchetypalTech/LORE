#[starknet::interface]
pub trait ITestERC20<T> {
    fn approve(ref self: T, spender: starknet::ContractAddress, amount: u256) -> bool;
    fn balance_of(self: @T, account: starknet::ContractAddress) -> u256;
}

// minimal ERC20 used as a mock payment token in tests
#[starknet::contract]
pub mod erc20_mock {
    use openzeppelin_token::erc20::{DefaultConfig, ERC20Component, ERC20HooksEmptyImpl};
    use starknet::ContractAddress;

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);

    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;

    #[storage]
    pub struct Storage {
        #[substorage(v0)]
        pub erc20: ERC20Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState, recipient: ContractAddress, initial_supply: u256) {
        self.erc20.initializer("MockUSDC", "mUSDC");
        self.erc20.mint(recipient, initial_supply);
    }
}
