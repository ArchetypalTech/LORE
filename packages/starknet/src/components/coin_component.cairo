use starknet::{ContractAddress};

#[starknet::interface]
pub trait ICoinComponentInternal<TState> {
    fn initialize(ref self: TState,
        minter_address: ContractAddress,
        faucet_amount: u128,
    );
    fn can_mint(self: @TState, recipient: ContractAddress) -> bool;
    fn assert_caller_is_minter(self: @TState) -> ContractAddress;
    fn mint(ref self: TState, recipient: ContractAddress, amount: u256);
    fn faucet(ref self: TState, recipient: ContractAddress);
}

#[starknet::component]
pub mod CoinComponent {
    use core::num::traits::Zero;
    use starknet::{ContractAddress};
    use dojo::contract::components::world_provider::{IWorldProvider};
    use dojo::{
        model::ModelStorage,
        world::WorldStorage,
        // event::EventStorage,
    };
    
    use openzeppelin_token::erc20::{
        ERC20Component,
        ERC20Component::{InternalImpl as ERC20InternalImpl},
    };

    use lore_sn::components::coin_config::{
        CoinConfig,
    };
    use lore_sn::lib::dns::{DnsTrait};

    #[storage]
    pub struct Storage {}

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    pub enum Event {}

    pub mod Errors {
        pub const CALLER_IS_NOT_MINTER: felt252 = 'COIN: caller is not minter';
        pub const FAUCET_UNAVAILABLE: felt252   = 'COIN: faucet unavailable';
    }


    //-----------------------------------------
    // Internal
    //
    pub impl CoinComponentInternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        +IWorldProvider<TContractState>,
        +ERC20Component::ERC20HooksTrait<TContractState>,
        impl ERC20: ERC20Component::HasComponent<TContractState>,
        +Drop<TContractState>,
    > of super::ICoinComponentInternal<ComponentState<TContractState>> {
        fn initialize(ref self: ComponentState<TContractState>,
            minter_address: ContractAddress,
            faucet_amount: u128,
        ) {
            let mut world: WorldStorage = DnsTrait::world_storage(self.get_contract().world_dispatcher(), @"lore_sn");
            let coin_config: CoinConfig = CoinConfig {
                coin_address: starknet::get_contract_address(),
                minter_address,
                faucet_amount,
            };
            world.write_model(@coin_config);
        }

        fn can_mint(self: @ComponentState<TContractState>,
            recipient: ContractAddress,
        ) -> bool {
            let mut world: WorldStorage = DnsTrait::world_storage(self.get_contract().world_dispatcher(), @"lore_sn");
            let coin_config: CoinConfig = world.read_model(starknet::get_contract_address());
            (
                coin_config.minter_address.is_zero() ||      // anyone can mint
                recipient == coin_config.minter_address // caller is minter contract
            )
        }

        fn assert_caller_is_minter(self: @ComponentState<TContractState>) -> ContractAddress {
            let caller: ContractAddress = starknet::get_caller_address();
            assert(self.can_mint(caller), Errors::CALLER_IS_NOT_MINTER);
            (caller)
        }

        // if public, wrap in the contract
        fn mint(ref self: ComponentState<TContractState>,
            recipient: ContractAddress,
            amount: u256,
        ) {
            self.assert_caller_is_minter();
            let mut erc20 = get_dep_component_mut!(ref self, ERC20);
            erc20.mint(recipient, amount);
        }

        // if public, wrap in the contract
        fn faucet(ref self: ComponentState<TContractState>,
            recipient: ContractAddress,
        ) {
            let mut world: WorldStorage = DnsTrait::world_storage(self.get_contract().world_dispatcher(), @"lore_sn");
            let coin_config: CoinConfig = world.read_model(starknet::get_contract_address());
            assert(coin_config.faucet_amount > 0, Errors::FAUCET_UNAVAILABLE);

            // let erc20 = get_dep_component!(self, ERC20);
            let mut erc20 = get_dep_component_mut!(ref self, ERC20);
            erc20.mint(recipient, coin_config.faucet_amount.into());
        }
    }

}
