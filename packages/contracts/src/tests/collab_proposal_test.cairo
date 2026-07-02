use dojo::model::ModelStorage;

use lore::{
    models::{
        entity::Entity,
        area::Area,
        description_text::DescriptionText,
        collab_proposal::ApprovedProposal,
    },
    systems::designer::IDesignerDispatcherTrait,
    tests::{
        helpers::{OWNER, OTHER, RECIPIENT, set_caller, setup_core, HelperSystems},
        hub_test::tests::_mint_trail,
    },
};

// ─── Constants ───────────────────────────────────────────────────────────────

const ENTITY_A: felt252 = 0x0A01;   // exists from start; collaborator modifies its area
const ENTITY_B: felt252 = 0x0B01;   // exists from start; collaborator proposes deletion → owner rejects
const ENTITY_C: felt252 = 0x0C01;   // new entity; collaborator creates → owner approves

// ─── Helpers ─────────────────────────────────────────────────────────────────

fn make_empty_proposal(trail_id: u128, proposer: starknet::ContractAddress) -> ApprovedProposal {
    ApprovedProposal {
        trail_id,
        proposer,
        w_single_keys:       array![],
        w_description_texts: array![],
        w_multi_keys:        array![],
        d_single_keys:       array![],
        d_description_texts: array![],
        d_multi_keys:        array![],
    }
}

// OTHER() mints a trail, creates entity_A (area + description) and entity_B (area),
// then grants RECIPIENT() collaborator access. Returns the trail_id.
fn owner_setup(ref sys: HelperSystems) -> u128 {
    let (_entity_trail, trail, _exit) = _mint_trail(ref sys, OTHER());
    let trail_id: u128 = trail.trail_id;

    set_caller(OTHER());
    sys.designer.create_entity(array![
        Entity {
            inst: ENTITY_A,
            is_entity: true,
            trail_id,
            name: "Chamber A",
            alt_names: array![],
            actions_keys: array![],
            creator_address: OTHER(),
        },
        Entity {
            inst: ENTITY_B,
            is_entity: true,
            trail_id,
            name: "Passage B",
            alt_names: array![],
            actions_keys: array![],
            creator_address: OTHER(),
        },
    ]);
    sys.designer.create_area(array![
        Area { inst: ENTITY_A, is_area: true, is_spawn_point: false, preserve_children: false, progress_percentage: 10 },
        Area { inst: ENTITY_B, is_area: true, is_spawn_point: false, preserve_children: false, progress_percentage: 20 },
    ]);
    sys.designer.create_description_text(array![
        DescriptionText { inst: ENTITY_A, key: 1, text: "A dark stone chamber" },
    ]);

    // Grant RECIPIENT() collaborator access to this trail
    sys.designer.grant_access_to_trail(RECIPIENT(), trail_id, true);

    trail_id
}

// ─── Full Collaborative Flow ──────────────────────────────────────────────────

// Scenario:
// 1. Owner (OTHER) publishes two entities with components and grants collaborator access.
// 2. Collaborator (RECIPIENT) proposes: modify entity_A's area, create entity_C with
//    area + description, delete entity_B.
// 3. Owner approves area_A modification + entity_C creation but NOT entity_B deletion.
// 4. Collaborator publishes all approved changes -they all succeed.
// 5. entity_B remains intact because its deletion was not approved.
#[test]
fn test_collab_full_flow_approved_changes() {
    let mut sys = setup_core();
    let trail_id: u128 = owner_setup(ref sys);

    // Collaborator prepares proposed changes
    let modified_area_a = Area {
        inst: ENTITY_A,
        is_area: true,
        is_spawn_point: false,
        preserve_children: false,
        progress_percentage: 75,
    };
    let new_entity_c = Entity {
        inst: ENTITY_C,
        is_entity: true,
        trail_id,
        name: "Hall C",
        alt_names: array![],
        actions_keys: array![],
        creator_address: RECIPIENT(),
    };
    let new_area_c = Area {
        inst: ENTITY_C,
        is_area: true,
        is_spawn_point: false,
        preserve_children: false,
        progress_percentage: 30,
    };
    let new_desc_c = DescriptionText { inst: ENTITY_C, key: 1, text: "A grand hall" };

    // Step 2 -collaborator submits for review (emits event, no storage writes)
    set_caller(RECIPIENT());
    sys.designer.submit_for_review(
        trail_id,
        array![new_entity_c.clone()],                          // new entity
        array![],                                              // reactables
        array![modified_area_a.clone(), new_area_c.clone()],  // modified + new area
        array![],                                              // exits
        array![],                                              // hubs
        array![new_desc_c.clone()],                           // new description_text
        array![],                                              // inventory_items
        array![],                                              // containers
        array![],                                              // trails
        array![],                                              // triggers
        array![],                                              // conditions
        array![],                                              // effects
        array![],                                              // actions
        array![],                                              // parents
        array![],                                              // children
        array![ENTITY_B],                                     // proposed deletions
    );

    // Step 3 -owner approves modification + creation; entity_B deletion intentionally omitted
    set_caller(OTHER());
    let mut approval = make_empty_proposal(trail_id, RECIPIENT());
    // ENTITY_C (new entity) + ENTITY_A and ENTITY_C (area writes) all go in w_single_keys
    approval.w_single_keys       = array![ENTITY_C, ENTITY_A, ENTITY_C];
    // flat pairs [inst, key_as_felt252, ...] for DescriptionText
    approval.w_description_texts = array![ENTITY_C, 1];
    // d_single_keys left empty -entity_B deletion is rejected
    sys.designer.approve_proposal(approval);

    // Step 4 -collaborator publishes each approved change

    set_caller(RECIPIENT());

    // Publish modified area_A -ENTITY_A is in w_single_keys → succeeds
    sys.designer.create_area(array![modified_area_a]);
    let stored_area_a: Area = sys.world.read_model(ENTITY_A);
    assert_eq!(stored_area_a.progress_percentage, 75, "area_A should be updated to 75");

    // Publish new entity_C -ENTITY_C is in w_single_keys → succeeds
    sys.designer.create_entity(array![new_entity_c]);
    let stored_entity_c: Entity = sys.world.read_model(ENTITY_C);
    assert!(stored_entity_c.is_entity, "entity_C should be created");
    assert_eq!(stored_entity_c.name, "Hall C", "entity_C name mismatch");
    assert_eq!(stored_entity_c.trail_id, trail_id, "entity_C should belong to the trail");

    // Publish new area_C (entity_C now exists in storage) -ENTITY_C in w_single_keys → succeeds
    sys.designer.create_area(array![new_area_c]);
    let stored_area_c: Area = sys.world.read_model(ENTITY_C);
    assert!(stored_area_c.is_area, "area_C should be created");
    assert_eq!(stored_area_c.progress_percentage, 30, "area_C progress mismatch");

    // Publish description_text for entity_C -(ENTITY_C, 1) pair in w_description_texts → succeeds
    sys.designer.create_description_text(array![new_desc_c]);
    let stored_desc_c: DescriptionText = sys.world.read_model((ENTITY_C, 1_u32));
    assert_eq!(stored_desc_c.text, "A grand hall", "desc_C text mismatch");

    // Step 5 -entity_B untouched; its deletion was not approved
    let entity_b: Entity = sys.world.read_model(ENTITY_B);
    assert!(entity_b.is_entity, "entity_B should still exist -deletion was rejected");
    let area_b: Area = sys.world.read_model(ENTITY_B);
    assert!(area_b.is_area, "area_B should still exist");
}

// Collaborator tries to delete entity_B even though the owner's ApprovedProposal
// does not include it in d_single_keys -should panic.
#[test]
#[should_panic(expected: ('DESIGNER: Not approved', 'ENTRYPOINT_FAILED'))]
fn test_collab_delete_rejected_panics() {
    let mut sys = setup_core();
    let trail_id: u128 = owner_setup(ref sys);

    set_caller(RECIPIENT());
    sys.designer.submit_for_review(
        trail_id,
        array![], array![], array![], array![], array![],
        array![], array![], array![], array![], array![],
        array![], array![], array![], array![], array![],
        array![ENTITY_B],   // proposes deletion of entity_B
    );

    // Owner approves only an area modification -entity_B deletion NOT included
    set_caller(OTHER());
    let mut approval = make_empty_proposal(trail_id, RECIPIENT());
    approval.w_single_keys = array![ENTITY_A];
    sys.designer.approve_proposal(approval);

    // Collaborator tries to delete entity_B → panic: NOT_APPROVED
    set_caller(RECIPIENT());
    sys.designer.delete_entity(array![ENTITY_B]);
}

// ─── Access Control Edge Cases ────────────────────────────────────────────────

// A user with no trail role at all cannot submit for review.
#[test]
#[should_panic(expected: ('DESIGNER: Not collaborator', 'ENTRYPOINT_FAILED'))]
fn test_submit_for_review_by_stranger_panics() {
    let mut sys = setup_core();
    // Mint trail for OTHER() but do NOT grant RECIPIENT() any access
    let (_entity_trail, trail, _exit) = _mint_trail(ref sys, OTHER());
    let trail_id: u128 = trail.trail_id;

    set_caller(RECIPIENT());
    sys.designer.submit_for_review(
        trail_id,
        array![], array![], array![], array![], array![],
        array![], array![], array![], array![], array![],
        array![], array![], array![], array![], array![],
        array![],
    );
}

// A collaborator cannot call approve_proposal -only the trail owner or admin can.
#[test]
#[should_panic(expected: ('DESIGNER: Not trail owner', 'ENTRYPOINT_FAILED'))]
fn test_approve_by_collaborator_panics() {
    let mut sys = setup_core();
    let trail_id: u128 = owner_setup(ref sys);

    let proposal = make_empty_proposal(trail_id, RECIPIENT());
    set_caller(RECIPIENT());
    sys.designer.approve_proposal(proposal);
}

// Without any approve_proposal call, a collaborator cannot write components.
#[test]
#[should_panic(expected: ('DESIGNER: Not approved', 'ENTRYPOINT_FAILED'))]
fn test_collab_write_without_approval_panics() {
    let mut sys = setup_core();
    let _trail_id: u128 = owner_setup(ref sys);

    set_caller(RECIPIENT());
    sys.designer.create_area(array![Area {
        inst: ENTITY_A,
        is_area: true,
        is_spawn_point: false,
        preserve_children: false,
        progress_percentage: 99,
    }]);
}

// The trail owner never needs an ApprovedProposal -can write freely.
#[test]
fn test_trail_owner_bypasses_approval_gate() {
    let mut sys = setup_core();
    let _trail_id: u128 = owner_setup(ref sys);

    set_caller(OTHER());
    sys.designer.create_area(array![Area {
        inst: ENTITY_A,
        is_area: true,
        is_spawn_point: false,
        preserve_children: false,
        progress_percentage: 55,
    }]);
    let stored: Area = sys.world.read_model(ENTITY_A);
    assert_eq!(stored.progress_percentage, 55, "trail owner can update freely");
}

// Admin (OWNER) also bypasses all gates.
#[test]
fn test_admin_bypasses_approval_gate() {
    let mut sys = setup_core();
    let _trail_id: u128 = owner_setup(ref sys);

    set_caller(OWNER());
    sys.designer.create_area(array![Area {
        inst: ENTITY_A,
        is_area: true,
        is_spawn_point: false,
        preserve_children: false,
        progress_percentage: 42,
    }]);
    let stored: Area = sys.world.read_model(ENTITY_A);
    assert_eq!(stored.progress_percentage, 42, "admin can update freely");
}
