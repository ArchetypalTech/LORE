use dojo::{world::WorldStorage, model::{ModelStorage}};
use starknet::{ContractAddress};
use lore::models::player::{PlayerStory};

#[derive(Copy, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct PlayerAccount {
    #[key]
    pub player_address: ContractAddress,
    /// Properties ///
    pub timestamp_joined: u64,
    pub timestamp_free_actions_claimed: u64,
    /// track claims
    pub minted_actions_count: u32,  // total actions minted
    pub purchase_count: u32,        // total L2 permits used
    pub subscription_count: u32,    // total subscriptions used
    /// game state
    pub current_game_id: u128,
}

#[derive(Copy, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct PlayerBalances {
    #[key]
    pub player_address: ContractAddress,
    /// Properties ///
    pub free_actions_balance: u128,
    pub paid_actions_balance: u128,
    pub sub_actions_balance: u128,
}

#[derive(Copy, Drop, Serde, Debug, PartialEq)]
pub enum ActionsSource {
    Unknown,
    FreeClaimed,
    Airdrop,
    Purchase,
    Subscription,
    ActionsClaimed,
}



//---------------------------------
// Model Traits
//
use core::num::traits::Zero;
use lore::models::{
    actions_config::{ActionsConfig, ActionsConfigTrait},
};
use lore::constants::constants::{CONST};

#[generate_trait]
pub impl PlayerAccountImpl of PlayerAccountTrait {
    fn current_game_id(world: @WorldStorage, player_address: ContractAddress) -> u128 {
        let player_game: PlayerAccount = world.read_model(player_address);
        (player_game.current_game_id)
    }
    fn switch_game_id(ref world: WorldStorage, player_address: ContractAddress, game_id: u128) {
        let mut player_game: PlayerAccount = world.read_model(player_address);
        if (player_game.current_game_id != game_id && game_id != 0) {
            player_game.current_game_id = game_id;
            world.write_model(@player_game);
        }
    }

    // called when a player mints actions
    fn minted_actions(ref self: WorldStorage, player_address: ContractAddress, actions_count: u32, source: ActionsSource) -> bool {
        let mut player_game: PlayerAccount = self.read_model(player_address);
        // initialize new player
        let is_new_player: bool = (player_game.timestamp_joined == 0);
        if (is_new_player) {
            player_game.timestamp_joined = starknet::get_block_timestamp();
        }
        // validate source
        let mut player_balances: PlayerBalances = self.read_model(player_address);
        let actions_amount: u128 = (actions_count.into() * CONST::ETH_TO_WEI.low);
        match source {
            ActionsSource::FreeClaimed => {
                player_game.timestamp_free_actions_claimed = starknet::get_block_timestamp();
                player_balances.free_actions_balance += actions_amount;
            },
            ActionsSource::Purchase => {
                player_game.purchase_count += 1;
                player_balances.paid_actions_balance += actions_amount;
            },
            ActionsSource::Subscription => {
                player_game.subscription_count += 1;
                player_balances.sub_actions_balance += actions_amount;
            },
            ActionsSource::Airdrop |
            ActionsSource::ActionsClaimed => {
                player_balances.paid_actions_balance += actions_amount;
            },
            ActionsSource::Unknown => {
                assert(false, 'ACTIONS: Invalid source');
            },
        }
        // increment actions count
        player_game.minted_actions_count += actions_count;
        self.write_model(@player_game);
        self.write_model(@player_balances);
        // returns true if new player
        (is_new_player)
    }

    // called when a player spends actions
    fn spent_actions(ref self: WorldStorage, player_address: ContractAddress, actions_amount: u128, game_id: u128) {
        let mut player_balances: PlayerBalances = self.read_model(player_address);
        let mut due_amount: u128 = actions_amount;
        let mut playerStory: PlayerStory = self.read_model(game_id);
        if player_balances.free_actions_balance.is_non_zero() {
            let amount: u128 = core::cmp::min(player_balances.free_actions_balance, due_amount);
            player_balances.free_actions_balance -= amount;
            due_amount -= amount;
            playerStory.free_actions_count += amount;
        }
        if due_amount.is_non_zero() && player_balances.sub_actions_balance.is_non_zero() {
            let amount: u128 = core::cmp::min(player_balances.sub_actions_balance, due_amount);
            player_balances.sub_actions_balance -= amount;
            due_amount -= amount;
            playerStory.sub_actions_count += amount;
        }
        if due_amount.is_non_zero() && player_balances.paid_actions_balance.is_non_zero() {
            let amount: u128 = core::cmp::min(player_balances.paid_actions_balance, due_amount);
            player_balances.paid_actions_balance -= amount;
            due_amount -= amount;
            playerStory.paid_actions_count += amount;
        }
        self.write_model(@player_balances);
    }

    // free actions
    fn get_free_actions_count(self: @WorldStorage, player_address: ContractAddress) -> u32 {
        let player_game: PlayerAccount = self.read_model(player_address);
        let actions_config: ActionsConfig = self.get_actions_config();
        if (player_game.timestamp_joined.is_zero()) {
            // new players get an initial set of free actions
            (actions_config.initial_free_actions_count)
        } else if (player_game.minted_actions_count > actions_config.max_free_actions_count) {
            // have acquired more than the initial free actions
            let elapsed_since_last_claim: u64 = (starknet::get_block_timestamp() - player_game.timestamp_free_actions_claimed);
            (core::cmp::min(
                (elapsed_since_last_claim / actions_config.free_action_claim_interval).try_into().unwrap(),
                actions_config.max_free_actions_count,
            ))
        } else {
            (0) // must acquire some actions first
        }
    }
}
