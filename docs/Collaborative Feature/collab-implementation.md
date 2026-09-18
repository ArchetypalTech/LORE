# Collaborative Trail Editing — Implementation

This document describes the contract-side implementation of the collaborative trail editing feature. For the original option analysis see [collab-proposals-flow.md](collab-proposals-flow.md).

---

## Why this approach

Trail tokens are ERC-721 NFTs. The owner of a trail token is the authoritative publisher of all content (entities + components) inside that trail. When a collaborator is invited, they need a way to propose changes without being able to publish content directly to the chain — because once data is on-chain it is live in the game immediately.

The chosen approach is **proposal event + owner publishes**:

1. The collaborator stages changes locally, then calls `submit_for_review` which emits a Dojo **event** (no storage written — nothing reaches the game world).
2. The trail owner reviews the proposal via Torii in `RemoteChangesPanel`, selects which items to include, and **publishes directly** using the normal `create_*` / `delete_*` functions (owner bypasses the approval gate).
3. The owner calls `signal_review_result` which writes a lightweight `CollabReviewResult` model that the collaborator receives via Torii.

Collaborators can **never** call `create_*` or `delete_*` directly on a trail they don't own — the gate is an unconditional `assert(false, NOT_APPROVED)`. This is simpler and cheaper than a two-phase commit design because it requires no intermediate approval storage.

---

## What was added to the contract

### 1. `CollabReviewResult` model — `models/collab_proposal.cairo`

```cairo
#[derive(Clone, Drop, Serde, Introspect)]
#[dojo::model]
pub struct CollabReviewResult {
    #[key] pub trail_id:       u128,
    #[key] pub proposer:       ContractAddress,
    pub published_count:       u32,
    pub skipped_count:         u32,
}
```

**Keys**: `(trail_id, proposer)` — one result record per collaborator per trail. Overwritten each time the owner calls `signal_review_result`.

**Why a MODEL not an event**: Dojo events go to Torii's `event_messages` table and require a separate Torii subscription. A model arrives through the existing `subscribeEntityQuery` already set up in `dojo.ts`, integrating naturally with the `dojoSync` pipeline in `editor.data.ts`. No additional subscription wiring needed.

**Three-state notification** (client-side, driven by `published_count` and `skipped_count`):
- `published_count > 0 && skipped_count == 0` → ✅ `toast.success("All your changes have been published.")`
- `published_count > 0 && skipped_count > 0` → ⚠️ `toast.info("…but N item(s) were not included.")`
- `published_count == 0` → ❌ rejection banner (staged changes preserved, collaborator can resubmit)

---

### 2. `CollabProposalEvent` — `models/collab_proposal.cairo`

```cairo
#[derive(Drop, Serde)]
#[dojo::event(historical: false)]
pub struct CollabProposalEvent {
    #[key] pub trail_id: u128,
    #[key] pub proposer: ContractAddress,
    // write proposals
    pub entities:             Array<Entity>,
    pub reactables:           Array<Reactable>,
    pub areas:                Array<Area>,
    pub exits:                Array<Exit>,
    pub hubs:                 Array<Hub>,
    pub description_texts:    Array<DescriptionText>,
    pub inventory_items:      Array<InventoryItem>,
    pub containers:           Array<Container>,
    pub trails:               Array<Trail>,
    pub triggers:             Array<Trigger>,
    pub conditions:           Array<Condition>,
    pub effects:              Array<Effect>,
    pub actions:              Array<Action>,
    pub parents:              Array<ParentToChildren>,
    pub children:             Array<ChildToParent>,
    // entity-level deletions
    pub deleted_entity_insts:          Array<felt252>,
    // component-level deletions — single-key types (flat list of inst values)
    pub deleted_reactable_insts:       Array<felt252>,
    pub deleted_area_insts:            Array<felt252>,
    pub deleted_exit_insts:            Array<felt252>,
    pub deleted_container_insts:       Array<felt252>,
    pub deleted_inventory_item_insts:  Array<felt252>,
    pub deleted_hub_insts:             Array<felt252>,
    pub deleted_trail_insts:           Array<felt252>,
    pub deleted_parent_insts:          Array<felt252>,
    pub deleted_child_insts:           Array<felt252>,
    // component-level deletions — multi-key types (flat [inst, key, ...] pairs)
    pub deleted_description_text_keys: Array<felt252>,
    pub deleted_trigger_keys:          Array<felt252>,
    pub deleted_condition_keys:        Array<felt252>,
    pub deleted_effect_keys:           Array<felt252>,
    pub deleted_action_keys:           Array<felt252>,
}
```

The 14 `deleted_*` arrays carry per-component deletion proposals so the review panel can show the owner exactly which individual components are being removed.

**Why an event, not a model**: A Dojo `event` writes nothing to World contract storage. The data is serialized into the transaction receipt, and Torii picks it up and stores it in its own off-chain database. Until the owner publishes, **zero entity or component data exists on-chain**.

`historical: false` means Torii retains only the **latest submission per (trail_id, proposer) pair**. If the collaborator revises their proposal and resubmits, the old one is replaced in Torii automatically.

**Entity-level deletions**: `deleted_entity_insts` can only be proposed by trail owners and admins. `submit_for_review` enforces this:

```cairo
assert(
    is_trail_owner || is_admin || deleted_entity_insts.len() == 0,
    Errors::NOT_TRAIL_OWNER
);
```

Collaborators may propose component-level deletions but cannot propose deleting the entity itself.

---

### 3. Two system functions — `systems/designer.cairo`

#### `submit_for_review`

```
Caller: collaborator (must have trail_id role or be trail owner/admin)
Effect: emits CollabProposalEvent — no model writes
Cost:   collaborator pays (event-only transaction, cheap)
```

Checks that the caller has been granted access to the specified trail (`has_role(trail_id.into(), caller)`) or is the trail owner or an admin. Panics with `NOT_COLLABORATOR` otherwise.

After the check, calls `world.emit_event(@CollabProposalEvent { ... })`. Nothing is written to storage. The call accepts all 30 arrays: the 16 write arrays (entities, components, relationships), one entity-level deletion array, nine single-key component deletion arrays, and four multi-key component deletion arrays.

Trail owners see the "Submit for review" button in the staging panel as disabled with a tooltip — they publish directly and never need to submit for review.

#### `signal_review_result`

```
Caller: trail owner or admin
Effect: writes CollabReviewResult model to World storage
Cost:   trail owner pays (trivial — 2 u32 fields + keys)
```

Called by the owner after publishing (or deciding to skip entirely). Writes the `CollabReviewResult` model with the counts of published vs skipped items. The collaborator receives this via the existing entity subscription in Torii.

```cairo
fn signal_review_result(
    ref self: ContractState,
    trail_id:        u128,
    proposer:        ContractAddress,
    published_count: u32,
    skipped_count:   u32,
) {
    let caller = starknet::get_caller_address();
    assert(
        self.is_admin(caller) || world.is_owner_of_trail(trail_id, caller),
        Errors::NOT_TRAIL_OWNER
    );
    world.write_model(@CollabReviewResult { trail_id, proposer, published_count, skipped_count });
}
```

---

### 4. Simplified approval gate on every write and delete function

Every `create_*` and `delete_*` function in `designer.cairo` has an inline gate. The gate fires only when **all three conditions are true**:

```cairo
if !owned.is_zero()                                 // (1) caller is not an admin
   && trail_id.is_non_zero()                        // (2) entity belongs to a trail
   && !world.is_owner_of_trail(trail_id, owned)     // (3) caller does not own the trail
{
    assert(false, Errors::NOT_APPROVED);  // collaborators can never write directly
}
```

- Condition (1): `owned` is the return value of `_assert_caller_is_editor()`, which returns `0x0` for admins and `caller_address` for everyone else. Admins bypass the gate entirely.
- Condition (2): entities without a trail (`trail_id = 0`) are core world entities; collaborators cannot touch those at all.
- Condition (3): the trail owner writes freely — no gate on their own trail.

The gate is unconditional — there is no approval list to consult. If you are a non-owner collaborator, the call panics. The owner must be the one calling `create_*` / `delete_*` to publish proposal content.

---

## The full flow

```
Trail owner (OTHER)                  Collaborator (RECIPIENT)             Chain
───────────────────                  ────────────────────────             ─────

grant_access_to_trail()   ────────►  RECIPIENT gets:
                                      • trail_id role (for submit)
                                      • COLLABORATOR role (for is_editor)

                                     [stage changes locally in editor]

                                     submit_for_review(trail_id, ...) ──► CollabProposalEvent emitted
                                                                          (Torii receives it, no models written)

[Torii delivers CollabProposalEvent]
[review panel shows diff]
[owner selects items to publish]

create_entity([entity_C]) ─────────────────────────────────────────────► entity_C written
 (passes creator_address=RECIPIENT)                                        creator_address = RECIPIENT ✓
create_area([area_A_modified])  ────────────────────────────────────────► area_A written
create_area([area_C])     ─────────────────────────────────────────────► area_C written
 (entity_B deletion was deselected by owner — skipped)

signal_review_result(     ─────────────────────────────────────────────► CollabReviewResult written
  trail_id, RECIPIENT,                                                     { published_count: 3,
  published_count=3,                                                         skipped_count: 1 }
  skipped_count=1)

[Torii delivers CollabReviewResult]
                                     ⚠️ toast.info("3 published, 1 skipped")
```

---

## Who pays for what

| Action | Caller | Storage written | Cost |
|---|---|---|---|
| `grant_access_to_trail` | Trail owner | Role grant (small) | Trail owner — one-time per collaborator |
| `submit_for_review` | Collaborator | None (event only) | Collaborator — cheap; cost scales with calldata size |
| `create_*` / `delete_*` (publish) | Trail owner | Full component models | Trail owner — normal write cost |
| `signal_review_result` | Trail owner | `CollabReviewResult` (2 u32 fields) | Trail owner — trivial |

The collaborator pays only for their cheap proposal submission. The trail owner pays for the actual content writes.

---

## Access control layers

Three independent layers prevent unauthorized writes:

### Layer 1 — `_assert_caller_is_editor`

Every write/delete function calls this first. It returns `0x0` for admins (full access) and the caller's address for anyone holding `ROLES::EDITOR`, `ROLES::ADMIN`, or `ROLES::COLLABORATOR`. It panics with `NOT_EDITOR` for everyone else.

`grant_access_to_trail` grants `ROLES::COLLABORATOR` to the invitee, so they pass this check.

### Layer 2 — Trail ownership / role check

Inside `create_entity`, a second check fires:

```cairo
let has_trail_role = o.trail_id.is_non_zero()
    && self.accesscontrol.has_role(o.trail_id.into(), owned);
assert(owned.is_zero() || is_owner_of_trail || has_trail_role, NOT_YOUR_TRAIL);
```

`grant_access_to_trail` also grants the `trail_id.into()` role to the invitee, so `has_trail_role` is true for collaborators. This prevents an editor from writing into a trail they were never invited to.

For component functions (`create_area`, etc.), `_assert_can_edit_entity` performs an equivalent check using `world.can_edit_trail(inst, owned)` or `has_role(trail_id.into(), owned)`.

### Layer 3 — Unconditional collaborator gate

After passing layers 1 and 2, any caller who is not the trail owner and not an admin triggers `assert(false, NOT_APPROVED)`. No role assignment bypasses this — only being the trail owner or admin allows direct writes. Collaborators must always go through `submit_for_review`.

---

## Client-side review UI

### Proposal review panel (`RemoteChangesPanel.tsx`)

The `ProposalCard` component presents each pending proposal with per-component selection:

- **Entity header**: a tri-state checkbox (checked / indeterminate / unchecked) selects or deselects all components for that entity at once.
- **Expanded view**: each component gets its own row — `Area`, `DescriptionText · key 1`, `Action · key 0`, etc. — with a checkbox and a field-level diff (old value → new value, or green "new" for additions). Deselected rows are dimmed but remain visible so the owner can see what they are skipping.
- **Component deletion rows**: each deleted component appears as a red strikethrough row within the same expanded view.
- **Entity-level deletions** (`deleted_entity_insts`) are listed in a separate "Deletions" section below the entity rows.
- **Publish button**: labelled "Publish selected (N)" where N is the count of currently selected items. Disabled when nothing is selected.

**Selection key format** used by `buildSelectableKeys` and `publishFromProposal`:
- `w:${inst}:${comp}` — write a single-key component
- `w:${inst}:${comp}:${key}` — write a multi-key component (DescriptionText, Trigger, etc.)
- `d:${inst}:${comp}` — delete a single-key component
- `d:${inst}:${comp}:${key}` — delete a multi-key component

`publishFromProposal(proposal, selected)` takes the `CollabProposalEvent` and the `Set<string>` of selected keys, publishes only the selected items (calling `create_*` / `delete_*` as the owner), and returns `{ publishedCount, skippedCount }`. The owner then calls `signalReviewResult(trailId, proposer, publishedCount, skippedCount)`.

**`creator_address` for new entities**: `publishFromProposal` passes `proposer` as the `creatorAddress` argument when calling `publishEntity` for entities that do not yet exist in the world. The `publishEntity` function sets this as `creator_address` in the entity struct, and the contract uses it (non-zero check).

### Staging panel (`StagingPanel.tsx`)

- **Submit for review**: disabled for trail owners (who publish directly) with a tooltip explaining why. Collaborators see it as active whenever there are staged changes.
- **Three-state notification**: watches `reviewResult` from `EditorData`; fires a toast or sets the rejection banner based on `published_count` / `skipped_count`.
- **Rejection banner**: shown when `published_count === 0`; auto-dismissed when staged changes are cleared; has a manual Dismiss button.

---

## Key files

| File | Role |
|---|---|
| `packages/contracts/src/models/collab_proposal.cairo` | `CollabReviewResult` model, `CollabProposalEvent` event (30 arrays) |
| `packages/contracts/src/systems/designer.cairo` | `submit_for_review` (30 params), `signal_review_result`, unconditional `NOT_APPROVED` gate on all write/delete functions |
| `packages/contracts/src/tests/collab_proposal_test.cairo` | Full flow tests covering owner publishes, partial publish, rejection, and access control |
| `packages/contracts/src/tests/helpers.cairo` | `m_CollabReviewResult` and `e_CollabProposalEvent` registered in `namespace_def()` |
| `packages/client/src/lib/dojo_bindings/typescript/models.gen.ts` | `CollabReviewResult` TypeScript interface and schema |
| `packages/client/src/lib/dojo_bindings/typescript/contracts.gen.ts` | `signalReviewResult` / `buildSignalReviewResultCalldata` entrypoints |
| `packages/client/src/editor/components/RemoteChangesPanel.tsx` | Per-component proposal review UI, `buildSelectableKeys`, `handlePublish` → `publishFromProposal` + `signalReviewResult` |
| `packages/client/src/editor/components/StagingPanel.tsx` | Staging/unstaging UI, `Submit for review` (disabled for owners), three-state `reviewResult` notification |
| `packages/client/src/editor/publisher.ts` | `submitForReview` (serializes all 30 arrays), `publishFromProposal` (owner publishes selected items), `signalReviewResult` re-export |
| `packages/client/src/editor/data/editor.data.ts` | `reviewResult` state, `dojoSync` integration for `CollabReviewResult` |
| `packages/client/src/lib/stores/wallet.store.ts` | Cartridge Controller policies: `submit_for_review`, `signal_review_result` |
