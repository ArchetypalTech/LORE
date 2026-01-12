use core::num::traits::{Zero};
use starknet::ContractAddress;
use dojo::world::{WorldStorage, IWorldDispatcherTrait};

//---------------------------------
// L2/L3 constants
// must always be in sync
//

pub mod APPCHAIN {
    // initial config
    pub const STARTER_PACK_ACTIONS_COUNT: u32 = 20;
    pub const CREATOR_REWARD_ACTIONS_COUNT: u32 = 20;

    pub mod MESSAGE_TYPES {
        pub const MINT_PERMIT_REWARDS: felt252 = 'MINT_PERMIT_REWARDS';
    }

    pub mod PERMIT_TYPES {
        pub const STARTER_PACK: felt252 = 'STARTER_PACK';
        pub const CREATOR_REWARD: felt252 = 'CREATOR_REWARD';
        pub const FREE_REWARD: felt252 = 'FREE_REWARD';
    }
}

//---------------------------------
// Events
//

#[derive(Clone, Drop, Serde)]
#[dojo::event(historical:false)]
pub struct AppchainMessageEvent {
    #[key]
    pub uuid: u32,
    /// Properties ///
    pub caller_address: ContractAddress,
    pub from_address: ContractAddress,
    pub to_address: ContractAddress,
    pub block_number: u64,
    pub block_timestamp: u64,
    pub message_type: felt252,
    pub payload: Array<felt252>,
}

#[derive(Clone, Drop)]
pub struct MintPermitRewardsPayload {
    pub uuid: u32,
    pub message_type: felt252,
    pub permit_type: felt252,
    pub recipient: ContractAddress,
    pub actions_count: u32,
}


//---------------------------------
// L3 Traits
//
#[generate_trait]
pub impl AppchainEventImpl of AppchainEventTrait {

    fn pack_mint_permit_rewards_event(ref self: WorldStorage,
        permit_type: felt252,
        recipient: ContractAddress,
        actions_count: u32,
    ) -> AppchainMessageEvent {
        assert(actions_count.is_non_zero(), 'APPCHAIN: Invalid actions count');
        assert(permit_type.is_non_zero(), 'APPCHAIN: Invalid permit type');
        assert(recipient.is_non_zero(), 'APPCHAIN: Invalid recipient');
        let mut values: Span<felt252> = array![
            permit_type.into(),
            recipient.into(),
            actions_count.into(),
        ].span();
        (self._pack_message_event(APPCHAIN::MESSAGE_TYPES::MINT_PERMIT_REWARDS, values))
    }

    // Internal functions
    fn _pack_message_event(ref self: WorldStorage,
        message_type: felt252,
        values: Span<felt252>,
    ) -> AppchainMessageEvent {
        let uuid: u32 = self.dispatcher.uuid();
        let mut payload: Array<felt252> = array![
            uuid.into(),
            message_type,
        ];
        for i in 0..values.len() {
            payload.append(*values.at(i));
        }
        (AppchainMessageEvent {
            uuid,
            caller_address: starknet::get_caller_address(),
            from_address: starknet::get_contract_address(),
            to_address: 0x0.try_into().unwrap(),
            block_number: starknet::get_block_number(),
            block_timestamp: starknet::get_block_timestamp(),
            message_type,
            payload,
        })
    }
}


//---------------------------------
// L2 Traits
//
#[generate_trait]
pub impl AppchainPayloadImpl of AppchainPayloadTrait {
    fn unpack_mint_permit_rewards_payload(ref self: WorldStorage,
        payload: Span<felt252>,
    ) -> MintPermitRewardsPayload {
        let uuid: u32 = (*payload.at(0)).try_into().unwrap();
        let message_type: felt252 = *payload.at(1);
        let permit_type: felt252 = *payload.at(2);
        let recipient: ContractAddress = (*payload.at(3)).try_into().unwrap();
        let actions_count: u32 = (*payload.at(4)).try_into().unwrap();
        assert(message_type == APPCHAIN::MESSAGE_TYPES::MINT_PERMIT_REWARDS, 'APPCHAIN: Invalid message type');
        (MintPermitRewardsPayload {
            uuid,
            message_type,
            permit_type,
            recipient,
            actions_count,
        })
    }
}
