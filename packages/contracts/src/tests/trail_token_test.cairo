#[cfg(test)]
mod tests {
    use starknet::ContractAddress;
    use dojo::{
        // world::{WorldStorage},
        model::{ModelStorage},
    };
    use lore::{
        systems::{
            trail_token::{ITrailTokenDispatcherTrait},
            designer::{IDesignerDispatcherTrait},
            // prompt::{IPromptDispatcherTrait},
        },
        models::{
            trail_token_info::{TrailTokenInfo},
        },
        lib::{
            // access::{AccessTrait},
        },
        constants::token_metadata::{trail_metadata},
        tests::{
            helpers,
            helpers::{OWNER, OTHER, ADMIN},
        },
    };

    fn _mint_token(ref sys: helpers::HelperSystems, recipient: ContractAddress) {
        helpers::set_caller(recipient);
        sys.trail_token.create_trail(recipient);
    }

    #[test]
    fn test_token_initialized() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        println!("TOKEN NAME: [{}]", sys.trail_token.name());
        println!("TOKEN SYMBOL: [{}]", sys.trail_token.symbol());
        assert_ne!(sys.trail_token.name(), "", "empty name");
        assert_ne!(sys.trail_token.symbol(), "", "empty symbol");
        assert_eq!(sys.trail_token.name(), trail_metadata::TOKEN_NAME(), "wrong name");
        assert_eq!(sys.trail_token.symbol(), trail_metadata::TOKEN_SYMBOL(), "wrong symbol");
    }

    #[test]
    fn test_token_token_uri() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        _mint_token(ref sys, OWNER());
        let uri: ByteArray = sys.trail_token.token_uri(1);
        assert_gt!(uri.len(), 1000, "token_uri.len()");
        println!("TOKEN URI: [{}]", uri);
    }


    //-----------------------------------
    // admin functions
    //

    #[test]
    fn test_token_set_minting_paused() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        helpers::set_caller(OWNER());
        assert_eq!(sys.trail_token.is_minting_paused(), false, "default");
        sys.trail_token.set_minting_paused(true);
        assert_eq!(sys.trail_token.is_minting_paused(), true, "set_minting_paused(true)");
        sys.trail_token.set_minting_paused(false);
        assert_eq!(sys.trail_token.is_minting_paused(), false, "set_minting_paused(false)");
    }

    #[test]
    #[should_panic(expected: ('ERC721Combo: minting is paused','ENTRYPOINT_FAILED'))]
    fn test_token_set_minting_paused_mint() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        helpers::set_caller(OWNER());
        sys.trail_token.set_minting_paused(true);
        assert_eq!(sys.trail_token.is_minting_paused(), true, "set_minting_paused(true)");
        _mint_token(ref sys, OWNER());
    }

    #[test]
    #[should_panic(expected: ('TRAIL: Invalid caller','ENTRYPOINT_FAILED'))]
    fn test_token_set_minting_paused_not_admin() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        helpers::set_caller(OTHER());
        sys.trail_token.set_minting_paused(true);
    }


    //-----------------------------------
    // minting
    //

    #[test]
    fn test_token_mint() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();

        //
        // owner can mint...
        _mint_token(ref sys, OWNER());
        assert_eq!(sys.trail_token.total_supply(), 1, "total_supply()");
        assert_eq!(sys.trail_token.owner_of(1), OWNER(), "owner_of()");
        assert_eq!(sys.trail_token.balance_of(OWNER()), 1, "balance_of()");
        let token_info_1: TrailTokenInfo = sys.world.read_model(1);
        assert_ne!(token_info_1.seed, 0, "token_info.seed");

        //
        // admins can mint...
        _mint_token(ref sys, ADMIN());
        assert_eq!(sys.trail_token.total_supply(), 2, "total_supply()");
        assert_eq!(sys.trail_token.owner_of(2), ADMIN(), "owner_of(2)");
        assert_eq!(sys.trail_token.balance_of(ADMIN()), 1, "balance_of())");
        let token_info_2: TrailTokenInfo = sys.world.read_model(2);
        assert_ne!(token_info_2.seed, 0, "token_info.seed");
        assert_ne!(token_info_2.seed, token_info_1.seed, "token_info.seed");

        //
        // editors can mint...
        sys.designer.set_editor(OTHER(), true);
        _mint_token(ref sys, OTHER());
        _mint_token(ref sys, OTHER());
        assert_eq!(sys.trail_token.total_supply(), 4, "total_supply()");
        assert_eq!(sys.trail_token.owner_of(3), OTHER(), "owner_of()");
        assert_eq!(sys.trail_token.owner_of(4), OTHER(), "owner_of()");
        assert_eq!(sys.trail_token.balance_of(OTHER()), 2, "balance_of()");
        let token_info_3: TrailTokenInfo = sys.world.read_model(3);
        let token_info_4: TrailTokenInfo = sys.world.read_model(4);
        assert_ne!(token_info_3.seed, 0, "token_info.seed");
        assert_ne!(token_info_4.seed, 0, "token_info.seed");
        assert_ne!(token_info_3.seed, token_info_1.seed, "token_info.seed");
        assert_ne!(token_info_3.seed, token_info_2.seed, "token_info.seed");
        assert_ne!(token_info_4.seed, token_info_1.seed, "token_info.seed");
        assert_ne!(token_info_4.seed, token_info_2.seed, "token_info.seed");
        assert_ne!(token_info_4.seed, token_info_3.seed, "token_info.seed");
    }

    #[test]
    #[should_panic(expected: ('TRAIL: Not editor','ENTRYPOINT_FAILED'))]
    fn test_token_set_minting_not_editor() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        _mint_token(ref sys, OTHER());
    }

}
