use dojo::model::ModelStorage;

use lore::{
    models::{
        entity::Entity,
        area::Area,
        description_text::DescriptionText,
        collab_proposal::CollabReviewResult,
    },
    systems::designer::IDesignerDispatcherTrait,
    tests::{
        helpers::{OWNER, OTHER, RECIPIENT, set_caller, setup_core, HelperSystems},
        hub_test::tests::_mint_trail,
    },
};

// ─── Constants ───────────────────────────────────────────────────────────────

const ENTITY_A: felt252 = 0x0A01;   // exists from start; owner publishes modified area
const ENTITY_B: felt252 = 0x0B01;   // exists from start; entity deletion skipped (owner decides)
const ENTITY_C: felt252 = 0x0C01;   // new entity proposed by collaborator; owner publishes

// ─── Setup helper ─────────────────────────────────────────────────────────────

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
            collaborators: array![],
        },
        Entity {
            inst: ENTITY_B,
            is_entity: true,
            trail_id,
            name: "Passage B",
            alt_names: array![],
            actions_keys: array![],
            creator_address: OTHER(),
            collaborators: array![],
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

// Shared submit helper — RECIPIENT() proposes: modify area_A, create entity_C + area_C + desc_C.
fn collab_submit(ref sys: HelperSystems, trail_id: u128) {
    set_caller(RECIPIENT());
    sys.designer.submit_for_review(
        trail_id,
        array![Entity { inst: ENTITY_C, is_entity: true, trail_id, name: "Hall C", alt_names: array![], actions_keys: array![], creator_address: RECIPIENT(), collaborators: array![] }],
        array![],                                                // reactables
        array![
            Area { inst: ENTITY_A, is_area: true, is_spawn_point: false, preserve_children: false, progress_percentage: 75 },
            Area { inst: ENTITY_C, is_area: true, is_spawn_point: false, preserve_children: false, progress_percentage: 30 },
        ],
        array![], array![],                                       // exits, hubs
        array![DescriptionText { inst: ENTITY_C, key: 1, text: "A grand hall" }],
        array![], array![], array![],                             // inventory_items, containers, trails
        array![], array![], array![], array![],                   // triggers, conditions, effects, actions
        array![], array![],                                       // parents, children
        array![],                                                 // deleted_entity_insts (empty — collaborator cannot propose entity deletions)
        array![], array![], array![], array![], array![],         // deleted: reactable, area, exit, container, inventory_item
        array![], array![], array![], array![],                   // deleted: hub, trail, parent, child
        array![], array![], array![], array![], array![],         // deleted keys: desc_text, trigger, condition, effect, action
    );
}

// ─── Full flow: owner publishes on behalf of collaborator ─────────────────────

// Scenario:
// 1. Owner creates entity_A + entity_B, grants RECIPIENT() access.
// 2. Collaborator submits proposal: modify area_A, create entity_C + area_C + desc_C.
// 3. Owner publishes all proposed changes directly (calling create_* from their own wallet).
//    entity_C gets creator_address = RECIPIENT() because the owner passes it in the struct.
// 4. Owner signals result: published_count=4, skipped_count=0.
// 5. Verify all components on chain; CollabReviewResult model written.
#[test]
fn test_collab_owner_publishes_full_proposal() {
    let mut sys = setup_core();
    let trail_id: u128 = owner_setup(ref sys);
    collab_submit(ref sys, trail_id);

    // Owner publishes on behalf of collaborator
    set_caller(OTHER());

    // New entity — pass RECIPIENT() as creator_address so the collaborator is recorded as creator
    sys.designer.create_entity(array![
        Entity { inst: ENTITY_C, is_entity: true, trail_id, name: "Hall C", alt_names: array![], actions_keys: array![], creator_address: RECIPIENT(), collaborators: array![] },
    ]);
    let stored_c: Entity = sys.world.read_model(ENTITY_C);
    assert!(stored_c.is_entity, "entity_C should be created");
    assert_eq!(stored_c.creator_address, RECIPIENT(), "entity_C creator should be RECIPIENT");

    // Modified area_A
    sys.designer.create_area(array![
        Area { inst: ENTITY_A, is_area: true, is_spawn_point: false, preserve_children: false, progress_percentage: 75 },
    ]);
    let stored_area_a: Area = sys.world.read_model(ENTITY_A);
    assert_eq!(stored_area_a.progress_percentage, 75, "area_A should be updated");

    // area_C
    sys.designer.create_area(array![
        Area { inst: ENTITY_C, is_area: true, is_spawn_point: false, preserve_children: false, progress_percentage: 30 },
    ]);

    // desc_C
    sys.designer.create_description_text(array![
        DescriptionText { inst: ENTITY_C, key: 1, text: "A grand hall" },
    ]);
    let stored_desc_c: DescriptionText = sys.world.read_model((ENTITY_C, 1_u32));
    assert_eq!(stored_desc_c.text, "A grand hall", "desc_C text mismatch");

    // Signal result — all 4 items published, 0 skipped
    sys.designer.signal_review_result(trail_id, RECIPIENT(), 4, 0);
    let result: CollabReviewResult = sys.world.read_model((trail_id, RECIPIENT()));
    assert_eq!(result.published_count, 4, "published_count should be 4");
    assert_eq!(result.skipped_count, 0, "skipped_count should be 0");
}

// Scenario: owner publishes only the area modification, skips entity_C creation.
// Signal reflects partial publish; entity_B and entity_C untouched.
#[test]
fn test_collab_owner_publishes_partial_proposal() {
    let mut sys = setup_core();
    let trail_id: u128 = owner_setup(ref sys);
    collab_submit(ref sys, trail_id);

    set_caller(OTHER());

    // Owner only publishes the area_A modification
    sys.designer.create_area(array![
        Area { inst: ENTITY_A, is_area: true, is_spawn_point: false, preserve_children: false, progress_percentage: 75 },
    ]);

    // Signal partial result: 1 published, 3 skipped
    sys.designer.signal_review_result(trail_id, RECIPIENT(), 1, 3);
    let result: CollabReviewResult = sys.world.read_model((trail_id, RECIPIENT()));
    assert_eq!(result.published_count, 1, "published_count should be 1");
    assert_eq!(result.skipped_count, 3, "skipped_count should be 3");

    // entity_C should not exist
    let entity_c: Entity = sys.world.read_model(ENTITY_C);
    assert!(!entity_c.is_entity, "entity_C should not have been created");
}

// Scenario: owner rejects entirely — signals published_count=0, skipped_count=total.
#[test]
fn test_collab_owner_signals_rejection() {
    let mut sys = setup_core();
    let trail_id: u128 = owner_setup(ref sys);
    collab_submit(ref sys, trail_id);

    set_caller(OTHER());
    sys.designer.signal_review_result(trail_id, RECIPIENT(), 0, 4);
    let result: CollabReviewResult = sys.world.read_model((trail_id, RECIPIENT()));
    assert_eq!(result.published_count, 0, "published_count should be 0 for rejection");
    assert_eq!(result.skipped_count, 4, "skipped_count should be 4 for full rejection");
}

// ─── Access control: collaborators cannot write directly to trail entities ────

// A collaborator who has been granted trail access cannot call create_area directly.
// They must go through submit_for_review; the owner publishes.
#[test]
#[should_panic(expected: ('DESIGNER: Not approved', 'ENTRYPOINT_FAILED'))]
fn test_collab_cannot_write_directly() {
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

// A collaborator cannot delete a component directly on a trail entity.
#[test]
#[should_panic(expected: ('DESIGNER: Not approved', 'ENTRYPOINT_FAILED'))]
fn test_collab_cannot_delete_component_directly() {
    let mut sys = setup_core();
    let _trail_id: u128 = owner_setup(ref sys);

    set_caller(RECIPIENT());
    sys.designer.delete_area(array![ENTITY_A]);
}

// A collaborator cannot delete an entity directly.
#[test]
#[should_panic(expected: ('DESIGNER: Not approved', 'ENTRYPOINT_FAILED'))]
fn test_collab_cannot_delete_entity_directly() {
    let mut sys = setup_core();
    let _trail_id: u128 = owner_setup(ref sys);

    set_caller(RECIPIENT());
    sys.designer.delete_entity(array![ENTITY_B]);
}

// A collaborator cannot include entity deletions in their proposal.
#[test]
#[should_panic(expected: ('DESIGNER: Not trail owner', 'ENTRYPOINT_FAILED'))]
fn test_collab_cannot_propose_entity_deletion() {
    let mut sys = setup_core();
    let trail_id: u128 = owner_setup(ref sys);

    set_caller(RECIPIENT());
    sys.designer.submit_for_review(
        trail_id,
        array![], array![], array![], array![], array![],
        array![], array![], array![], array![], array![],
        array![], array![], array![], array![], array![],
        array![ENTITY_B],                                         // collaborator tries to propose entity deletion
        array![], array![], array![], array![], array![],
        array![], array![], array![], array![],
        array![], array![], array![], array![], array![],
    );
}

// A stranger (no trail role) cannot call submit_for_review.
#[test]
#[should_panic(expected: ('DESIGNER: Not collaborator', 'ENTRYPOINT_FAILED'))]
fn test_submit_for_review_by_stranger_panics() {
    let mut sys = setup_core();
    let (_entity_trail, trail, _exit) = _mint_trail(ref sys, OTHER());
    let trail_id: u128 = trail.trail_id;

    set_caller(RECIPIENT());
    sys.designer.submit_for_review(
        trail_id,
        array![], array![], array![], array![], array![],
        array![], array![], array![], array![], array![],
        array![], array![], array![], array![], array![],
        array![],
        array![], array![], array![], array![], array![],
        array![], array![], array![], array![],
        array![], array![], array![], array![], array![],
    );
}

// Only the trail owner or admin can call signal_review_result.
#[test]
#[should_panic(expected: ('DESIGNER: Not trail owner', 'ENTRYPOINT_FAILED'))]
fn test_signal_review_result_by_non_owner_panics() {
    let mut sys = setup_core();
    let trail_id: u128 = owner_setup(ref sys);
    collab_submit(ref sys, trail_id);

    set_caller(RECIPIENT());
    sys.designer.signal_review_result(trail_id, RECIPIENT(), 4, 0);
}

// ─── Owner and admin bypass the gate ─────────────────────────────────────────

// The trail owner never needs to go through review — can write freely.
#[test]
fn test_trail_owner_bypasses_gate() {
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

// Admin also bypasses all gates.
#[test]
fn test_admin_bypasses_gate() {
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
