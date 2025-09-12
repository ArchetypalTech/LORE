use starknet::ContractAddress;
use dojo::{model::ModelStorage};
use lore::{
    systems::{
        game_token::{IGameTokenDispatcher, IGameTokenDispatcherTrait},
    },
    models::{
        token_config::{ContractConfig, GameTokenInfo, PlayerAccount},
    },
    constants::{token as constants},
    tests::{
        helpers,
        helpers::{OWNER, OTHER, RECIPIENT},
    },
};

#[cfg(test)]
mod tests {
    use super::*;

    fn _mint_token(token: IGameTokenDispatcher, recipient: ContractAddress) {
        helpers::set_caller(recipient);
        token.create_game(recipient);
    }

    #[test]
    fn test_token_initialized() {
        let (mut world, _, _, token, _, _) = helpers::setup_core();

        println!("TOKEN NAME: [{}]", token.name());
        println!("TOKEN SYMBOL: [{}]", token.symbol());
        assert_ne!(token.name(), "", "empty name");
        assert_ne!(token.symbol(), "", "empty symbol");
        assert_eq!(token.name(), constants::TOKEN_NAME(), "wrong name");
        assert_eq!(token.symbol(), constants::TOKEN_SYMBOL(), "wrong symbol");

        let contract_config: ContractConfig = world.read_model(token.contract_address);
        assert_eq!(contract_config.admin_address, OWNER(), "wrong admin address");
    }

    #[test]
    fn test_token_mint() {
        let (mut world, _, _, token, _, _) = helpers::setup_core();

        _mint_token(token, OWNER());
        assert_eq!(token.total_supply(), 1, "total_supply()");
        assert_eq!(token.owner_of(1), OWNER(), "owner_of()");
        assert_eq!(token.balance_of(OWNER()), 1, "balance_of()");
        let token_info_1: GameTokenInfo = world.read_model(1);
        assert_ne!(token_info_1.seed, 0, "token_info.seed");
        assert_eq!(token_info_1.act_number, 1, "token_info.act_number");
        assert_eq!(token_info_1.progress, 0, "token_info.progress");
        assert_eq!(token_info_1.completed, false, "token_info.completed");
        let account: PlayerAccount = world.read_model(OWNER());
        assert_eq!(account.current_game_id, 1, "account.current_game_id");

        _mint_token(token, OTHER());
        assert_eq!(token.total_supply(), 2, "total_supply()");
        assert_eq!(token.owner_of(2), OTHER(), "owner_of(2)");
        assert_eq!(token.balance_of(OTHER()), 1, "balance_of())");
        let token_info_2: GameTokenInfo = world.read_model(2);
        assert_ne!(token_info_2.seed, 0, "token_info.seed");
        assert_ne!(token_info_2.seed, token_info_1.seed, "token_info.seed");
        assert_eq!(token_info_2.act_number, 1, "token_info.act_number");
        assert_eq!(token_info_2.progress, 0, "token_info.progress");
        assert_eq!(token_info_2.completed, false, "token_info.completed");
        let account: PlayerAccount = world.read_model(OTHER());
        assert_eq!(account.current_game_id, 2, "account.current_game_id");

        _mint_token(token, OWNER());
        assert_eq!(token.total_supply(), 3, "total_supply()");
        assert_eq!(token.owner_of(3), OWNER(), "owner_of()");
        assert_eq!(token.balance_of(OWNER()), 2, "balance_of()");
        let token_info_3: GameTokenInfo = world.read_model(3);
        assert_ne!(token_info_3.seed, token_info_1.seed, "token_info.seed");
        assert_ne!(token_info_3.seed, token_info_2.seed, "token_info.seed");
        assert_ne!(token_info_3.seed, 0, "token_info.seed");
        assert_eq!(token_info_3.act_number, 1, "token_info.act_number");
        assert_eq!(token_info_3.progress, 0, "token_info.progress");
        assert_eq!(token_info_3.completed, false, "token_info.completed");
        let account: PlayerAccount = world.read_model(OWNER());
        assert_eq!(account.current_game_id, 3, "account.current_game_id");
    }

    #[test]
    fn test_token_set_paused() {
        let (_, _, _, token, _, _) = helpers::setup_core();
        helpers::set_caller(OWNER());
        assert_eq!(token.is_minting_paused(), false, "default");
        token.set_paused(true);
        assert_eq!(token.is_minting_paused(), true, "set_paused(true)");
        token.set_paused(false);
        assert_eq!(token.is_minting_paused(), false, "set_paused(false)");
    }

    #[test]
    #[should_panic(expected: ('ERC721Combo: minting is paused','ENTRYPOINT_FAILED'))]
    fn test_token_set_paused_mint() {
        let (_, _, _, token, _, _) = helpers::setup_core();
        helpers::set_caller(OWNER());
        token.set_paused(true);
        assert_eq!(token.is_minting_paused(), true, "set_paused(true)");
        _mint_token(token, OWNER());
    }

    #[test]
    #[should_panic(expected: ('ORUG: caller is not admin','ENTRYPOINT_FAILED'))]
    fn test_token_set_paused_not_admin() {
        let (_, _, _, token, _, _) = helpers::setup_core();
        helpers::set_caller(OTHER());
        token.set_paused(true);
    }

    #[test]
    fn test_token_set_admin() {
        let (mut world, _, _, token, _, _) = helpers::setup_core();
        // OWNER set admin to OTHER
        helpers::set_caller(OWNER());
        token.set_admin(OTHER());
        let contract_config: ContractConfig = world.read_model(token.contract_address);
        assert_eq!(contract_config.admin_address, OTHER(), "wrong admin address");
        // OTHER set admin to RECIPIENT
        helpers::set_caller(OTHER());
        token.set_admin(RECIPIENT());
        let contract_config: ContractConfig = world.read_model(token.contract_address);
        assert_eq!(contract_config.admin_address, RECIPIENT(), "wrong admin address");
    }

    #[test]
    #[should_panic(expected: ('ORUG: caller is not admin','ENTRYPOINT_FAILED'))]
    fn test_token_set_admin_not_admin() {
        let (_, _, _, token, _, _) = helpers::setup_core();
        helpers::set_caller(OTHER());
        token.set_admin(RECIPIENT());
    }


}
