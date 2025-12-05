use starknet::{ContractAddress};
use lore_sn::lib::messaging::{MessageHash, Nonce};

#[starknet::interface]
pub trait IMessagingMock<T> {
    fn send_message_to_appchain(
        ref self: T, to_address: ContractAddress, selector: felt252, payload: Span<felt252>,
    ) -> (MessageHash, Nonce);
    fn consume_message_from_appchain(
        ref self: T, from_address: ContractAddress, payload: Span<felt252>,
    ) -> MessageHash;
}

#[dojo::contract]
pub mod messaging_mock {
    use starknet::{ContractAddress};
    use lore_sn::lib::messaging::{MessageHash, Nonce};

    #[abi(embed_v0)]
    impl MessagingMockImpl of super::IMessagingMock<ContractState> {
        fn send_message_to_appchain(
            ref self: ContractState, to_address: ContractAddress, selector: felt252, payload: Span<felt252>,
        ) -> (MessageHash, Nonce) {
            (0, 0)
        }

        fn consume_message_from_appchain(
            ref self: ContractState, from_address: ContractAddress, payload: Span<felt252>,
        ) -> MessageHash {
            0
        }
    }
}
