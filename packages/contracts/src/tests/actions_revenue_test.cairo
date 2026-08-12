// Phase 2 tests for docs/Monetization/revenue-distribution-implementation-plan.md —
// charge_player_actions' owner/creator/collaborator revenue split, and the two guard
// lines added to add_collaborator.
//
// charge_player_actions is called directly (via the protected dispatcher, with the
// caller mocked to a real world contract to satisfy _assert_caller_is_world_contract —
// same pattern as test_transfer_from_prompt_contract in actions_token_test.cairo)
// rather than through a full "use gangplank" text command. The lexer/dictionary/
// reactable/action_map pipeline that would resolve such a sentence into a Command with
// a resolved noun target is unchanged by this plan (Phase 1 only added a pure helper on
// top of it, already tested in command_type_test.cairo) — exercising it again here would
// mean rebuilding that whole pipeline in the test just to reach the two lines charge_player_actions
// actually changed. Calling the entrypoint directly with a hand-built targets array
// exercises the exact same code, and the exact same access-control gate, with far less
// incidental setup.

use starknet::ContractAddress;
use core::num::traits::Zero;
use dojo::model::ModelStorage;
use lore::{
    models::{
        entity::Entity,
        actions_config::ActionsReward,
    },
    systems::designer::IDesignerDispatcherTrait,
    systems::actions_token::{IActionsTokenDispatcherTrait, IActionsTokenProtectedDispatcherTrait},
    lib::dns::DnsTrait,
    tests::{
        helpers::{OWNER, OTHER, RECIPIENT, PLAYER_1, set_caller, setup_core, HelperSystems},
        hub_test::tests::_mint_trail,
    },
};

const PRECISION: u128 = 1_000_000_000_000_000_000;

const GANGPLANK: felt252 = 0x0F01;
const OFFICER: felt252 = 0x0F02;
const ID_CARD: felt252 = 0x0F03;

fn COLLAB_1() -> ContractAddress { 0x111.try_into().unwrap() }
fn COLLAB_2() -> ContractAddress { 0x222.try_into().unwrap() }
fn COLLAB_3() -> ContractAddress { 0x333.try_into().unwrap() }
fn TRAIL_B_OWNER() -> ContractAddress { 0x444.try_into().unwrap() }
fn ID_CREATOR() -> ContractAddress { 0x555.try_into().unwrap() }

// Creates `inst` inside `trail_id`, called by the trail owner OTHER(), with
// creator_address set explicitly — mirrors how publishFromProposal attributes a new
// entity's creator_address regardless of who the publishing caller is (Part 1).
fn _create_object(ref sys: HelperSystems, inst: felt252, trail_id: u128, creator: ContractAddress, owner: ContractAddress) {
    set_caller(owner);
    sys.designer.create_entity(array![
        Entity {
            inst, is_entity: true, trail_id, name: "test object",
            alt_names: array![], actions_keys: array![],
            creator_address: creator,
            collaborators: array![],
        },
    ]);
}

fn _collected(ref sys: HelperSystems, address: ContractAddress) -> u128 {
    let reward: ActionsReward = sys.world.read_model(address);
    (reward.collected_actions_amount)
}

// charge_player_actions burns from the player's real actions_token balance — mint some
// first, or the burn underflows with 'ERC20: insufficient balance'.
fn _fund_player(ref sys: HelperSystems, player: ContractAddress, actions_count: u32) {
    set_caller(OWNER());
    sys.actions.mint_to(player, actions_count);
}

//-----------------------------------
// charge_player_actions — revenue split
//

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_charge_single_target_flat_split_n2() {
        // GANGPLANK: trail owner OTHER(), creator RECIPIENT(), 2 collaborators.
        // "use gangplank" -> one target, full action fee goes to it.
        let mut sys: HelperSystems = setup_core();
        let (_entity_trail, trail, _exit) = _mint_trail(ref sys, OTHER());
        let trail_id: u128 = trail.trail_id;
        _create_object(ref sys, GANGPLANK, trail_id, RECIPIENT(), OTHER());

        set_caller(OTHER()); // trail owner
        sys.designer.add_collaborator(GANGPLANK, COLLAB_1());
        sys.designer.add_collaborator(GANGPLANK, COLLAB_2());

        let actions_amount: u128 = PRECISION; // 1 action
        // Baseline, not zero: _mint_trail() above already ran a prompt() as OTHER(),
        // which mints OTHER()'s initial free actions as a side effect unrelated to this
        // test — compare deltas against this baseline rather than an absolute value.
        let supply_before: u256 = sys.actions.total_supply();
        _fund_player(ref sys, PLAYER_1, 10);
        assert_eq!(sys.actions.balance_of(PLAYER_1), 10_u256 * PRECISION.into(), "balance before charge");
        set_caller(sys.prompt.contract_address); // mock world-contract caller
        sys.world.actions_token_protected_dispatcher().charge_player_actions(
            PLAYER_1, array![GANGPLANK], trail_id, actions_amount, 1,
        );

        // Closed-form at n=2: owner = creator = 0.3125, each collaborator = 0.1875 —
        // see docs/Monetization/monetization-revenue-distribution.md worked examples.
        assert_eq!(_collected(ref sys, OTHER()), 312500000000000000, "owner share");
        assert_eq!(_collected(ref sys, RECIPIENT()), 312500000000000000, "creator share");
        assert_eq!(_collected(ref sys, COLLAB_1()), 187500000000000000, "collaborator 1 share");
        assert_eq!(_collected(ref sys, COLLAB_2()), 187500000000000000, "collaborator 2 share");
        // conservation: nothing lost or fabricated (n=2 divides evenly, exact)
        assert_eq!(
            _collected(ref sys, OTHER()) + _collected(ref sys, RECIPIENT())
                + _collected(ref sys, COLLAB_1()) + _collected(ref sys, COLLAB_2()),
            actions_amount,
            "conservation",
        );
        // the burn side (pre-existing behavior) still fires exactly once, for the full
        // actions_amount, regardless of how many parties the fee split across.
        assert_eq!(sys.actions.balance_of(PLAYER_1), 9_u256 * PRECISION.into(), "balance after charge");
        assert_eq!(sys.actions.total_supply(), supply_before + 9_u256 * PRECISION.into(), "total_supply after charge");
    }

    #[test]
    fn test_charge_two_targets_independent_entities() {
        // ID_CARD: separate trail, separate owner/creator, 0 collaborators.
        // OFFICER: trail owner OTHER(), creator RECIPIENT(), 3 collaborators.
        // "give id to officer" -> two targets, fee splits flat 50/50 across them first,
        // then each target's half splits independently by its own entity's data.
        let mut sys: HelperSystems = setup_core();

        let (_entity_trail_a, trail_a, _exit_a) = _mint_trail(ref sys, OTHER());
        let trail_id_a: u128 = trail_a.trail_id;
        _create_object(ref sys, OFFICER, trail_id_a, RECIPIENT(), OTHER());
        set_caller(OTHER());
        sys.designer.add_collaborator(OFFICER, COLLAB_1());
        sys.designer.add_collaborator(OFFICER, COLLAB_2());
        sys.designer.add_collaborator(OFFICER, COLLAB_3());

        let (_entity_trail_b, trail_b, _exit_b) = _mint_trail(ref sys, TRAIL_B_OWNER());
        let trail_id_b: u128 = trail_b.trail_id;
        _create_object(ref sys, ID_CARD, trail_id_b, ID_CREATOR(), TRAIL_B_OWNER());

        let actions_amount: u128 = PRECISION; // 1 action, split 50/50 across 2 targets
        _fund_player(ref sys, PLAYER_1, 10);
        set_caller(sys.prompt.contract_address);
        sys.world.actions_token_protected_dispatcher().charge_player_actions(
            PLAYER_1, array![ID_CARD, OFFICER], trail_id_a, actions_amount, 1,
        );

        // ID_CARD half (5e17, n=0): owner = creator = 0.25e18 exactly, no collaborators.
        assert_eq!(_collected(ref sys, TRAIL_B_OWNER()), 250000000000000000, "id_card owner share");
        assert_eq!(_collected(ref sys, ID_CREATOR()), 250000000000000000, "id_card creator share");

        // OFFICER half (5e17, n=3): owner = creator = 0.140625e18, each collaborator ~0.0729e18.
        assert_eq!(_collected(ref sys, OTHER()), 140625000000000000, "officer owner share");
        assert_eq!(_collected(ref sys, RECIPIENT()), 140625000000000000, "officer creator share");
        assert_eq!(_collected(ref sys, COLLAB_1()), 72916666666666666, "officer collaborator 1 share");
        assert_eq!(_collected(ref sys, COLLAB_2()), 72916666666666666, "officer collaborator 2 share");
        assert_eq!(_collected(ref sys, COLLAB_3()), 72916666666666666, "officer collaborator 3 share");

        // Trails are fully independent: OTHER() (officer's owner) collected nothing from
        // id_card's half, and TRAIL_B_OWNER() collected nothing from officer's half.
        // (Already implied above since each address's total equals only its own side's
        // share — no cross-contamination to separately assert.)
    }

    #[test]
    fn test_charge_no_target_falls_back_to_trail_owner() {
        // Regression: a command with no resolvable noun target ("look", "go north")
        // must charge 100% to the trail owner, byte-for-byte today's behavior.
        let mut sys: HelperSystems = setup_core();
        let (_entity_trail, trail, _exit) = _mint_trail(ref sys, OTHER());
        let trail_id: u128 = trail.trail_id;

        let actions_amount: u128 = PRECISION;
        _fund_player(ref sys, PLAYER_1, 10);
        set_caller(sys.prompt.contract_address);
        sys.world.actions_token_protected_dispatcher().charge_player_actions(
            PLAYER_1, array![], trail_id, actions_amount, 1,
        );

        assert_eq!(_collected(ref sys, OTHER()), actions_amount, "100% to trail owner");
        assert_eq!(sys.actions.balance_of(PLAYER_1), 9_u256 * PRECISION.into(), "balance after charge");
    }

    #[test]
    fn test_charge_no_target_zero_trail_id_credits_nobody() {
        // A player in a core/global area (trail_id == 0) issuing an object-less command
        // must not panic calling owner_of(0) — nobody gets credited, matching the
        // existing (pre-Phase-2) guard in the no-target branch.
        let mut sys: HelperSystems = setup_core();
        let actions_amount: u128 = PRECISION;
        _fund_player(ref sys, PLAYER_1, 10);
        set_caller(sys.prompt.contract_address);
        sys.world.actions_token_protected_dispatcher().charge_player_actions(
            PLAYER_1, array![], 0, actions_amount, 1,
        );
        // no assertion beyond "did not panic" — there is no owner to check
    }

    //-----------------------------------
    // add_collaborator guards
    //

    #[test]
    #[should_panic(expected: ('DESIGNER: Invalid collaborator', 'ENTRYPOINT_FAILED'))]
    fn test_add_collaborator_blocks_owner_self_add() {
        let mut sys: HelperSystems = setup_core();
        let (_entity_trail, trail, _exit) = _mint_trail(ref sys, OTHER());
        let trail_id: u128 = trail.trail_id;
        _create_object(ref sys, GANGPLANK, trail_id, RECIPIENT(), OTHER());

        set_caller(OTHER());
        sys.designer.add_collaborator(GANGPLANK, OTHER()); // owner naming themselves
    }

    #[test]
    #[should_panic(expected: ('DESIGNER: Too many collabs', 'ENTRYPOINT_FAILED'))]
    fn test_add_collaborator_max_cap() {
        let mut sys: HelperSystems = setup_core();
        let (_entity_trail, trail, _exit) = _mint_trail(ref sys, OTHER());
        let trail_id: u128 = trail.trail_id;
        _create_object(ref sys, GANGPLANK, trail_id, RECIPIENT(), OTHER());

        // MAX_COLLABORATORS = 200 (designer.cairo). Pre-fill 199 collaborators directly
        // via a single model write instead of 199 real add_collaborator calls — same
        // end state (add_collaborator has no side effect beyond the array append), far
        // cheaper than paying full entrypoint dispatch cost 199 times over.
        let mut collaborators: Array<ContractAddress> = array![];
        let mut i: u32 = 0;
        while i < 199 {
            let addr_felt: felt252 = 0x10000 + i.into();
            collaborators.append(addr_felt.try_into().unwrap());
            i += 1;
        };
        // Direct world writes need WRITER on the Entity model — granted to OWNER() (the
        // namespace owner, setup_core()) but not to OTHER(), who _create_object() left
        // as the active caller. Switch to OWNER() for the raw write, then back to
        // OTHER() (the trail owner) for the real add_collaborator calls below.
        set_caller(OWNER());
        let mut entity: Entity = sys.world.read_model(GANGPLANK);
        entity.collaborators = collaborators;
        sys.world.write_model(@entity);

        set_caller(OTHER());
        // 200th collaborator (len 199 < 200 cap) — must succeed.
        let addr_200_felt: felt252 = 0x10000 + 199;
        let addr_200: ContractAddress = addr_200_felt.try_into().unwrap();
        sys.designer.add_collaborator(GANGPLANK, addr_200);

        // 201st (len now 200, 200 < 200 is false) — must revert.
        let addr_201_felt: felt252 = 0x10000 + 200;
        let addr_201: ContractAddress = addr_201_felt.try_into().unwrap();
        sys.designer.add_collaborator(GANGPLANK, addr_201);
    }

    //-----------------------------------
    // Formula conservation invariant — mirrors charge_player_actions' arithmetic
    // directly (not the full entrypoint — Tests above already cover that at n=2/n=3/n=0)
    // to sweep many collaborator counts cheaply and confirm rounding never creates value
    // and never loses more than n+1 wei-units per target (see the shortfall bound below).
    //

    fn _formula_shares(per_target: u128, n: u32) -> (u128, u128, u128) {
        let mut decay: u128 = PRECISION;
        let mut k: u32 = 0;
        while k < n {
            decay = decay / 2;
            k += 1;
        };
        // Each .into() target is pinned via an explicit typed binding — Cairo can't infer
        // u256 across the chained expression (mirrors actions_token.cairo's same fix).
        let per_target_u256: u256 = per_target.into();
        let numer_u256: u256 = (PRECISION + decay).into();
        let denom_u256: u256 = (4 * PRECISION).into();
        let owner_share: u128 = (per_target_u256 * numer_u256 / denom_u256)
            .try_into()
            .unwrap();
        let creator_share: u128 = owner_share;
        let each: u128 = if n.is_non_zero() {
            (per_target - owner_share - creator_share) / n.into()
        } else {
            0
        };
        (owner_share, creator_share, each)
    }

    #[test]
    fn test_formula_conservation_across_collaborator_counts() {
        let mut per_target_index: u32 = 0;
        let per_targets: Array<u128> = array![
            1_000_000_000_000_000_000, // 1 action, round
            777_777_777_777_777_777,   // odd amount, exercises rounding edges
        ];
        while per_target_index < per_targets.len() {
            let per_target: u128 = *per_targets.at(per_target_index);
            let mut n: u32 = 0;
            while n <= 200 { // MAX_COLLABORATORS
                let (owner_share, creator_share, each): (u128, u128, u128) = _formula_shares(per_target, n);
                let n_u128: u128 = n.into();
                let distributed: u128 = owner_share + creator_share + each * n_u128;
                // never fabricates value
                assert(distributed <= per_target, 'distributed exceeds per_target');
                // Never loses more than n+1 wei-units to rounding: up to n-1 from the
                // n-way collaborator split (pool // n), plus up to 1 more from the
                // owner/creator division itself (per_target*(...)/(4*PRECISION) floors
                // independently of n — e.g. at n=0 with an odd per_target, owner+creator
                // alone is 1 wei short of per_target, before any collaborator is involved).
                assert(per_target <= distributed + n_u128 + 1, 'shortfall exceeds bound');
                n += 1;
            };
            per_target_index += 1;
        };
    }
}
