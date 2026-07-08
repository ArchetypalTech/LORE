# Collaborative Trail Editing — Implementation

This document describes the contract-side implementation of the collaborative trail editing approval flow. For the original option analysis see [collab-proposals-flow.md](collab-proposals-flow.md).

---

## Why this approach

Trail tokens are ERC-721 NFTs. The owner of a trail token is the authoritative publisher of all content (entities + components) inside that trail. When a collaborator is invited, they need a way to propose changes without being able to publish content directly to the chain — because once data is on-chain it is live in the game immediately.

The chosen approach is a **two-phase commit with per-component-type granularity**:

1. The collaborator stages changes locally, then calls `submit_for_review` which emits a Dojo **event** (no storage written — nothing reaches the game world).
2. The trail owner reviews the proposal off-chain via Torii, then calls `approve_proposal` writing a lightweight `ApprovedProposal` model that lists exactly which component types they accept.
3. The collaborator calls the normal `create_*` / `delete_*` functions. The contract checks the approval list before each write and panics if the specific component was not approved.

This is Option B from the design document, extended with per-component-type approval lists instead of a flat `approved_insts[]` array. The extension was necessary because the owner must be able to say "I approve entity X's area and reactable but reject its description_text (the content is inappropriate)."

---

## What was added to the contract

### 1. `ApprovedProposal` model — `models/collab_proposal.cairo`

```cairo
#[derive(Clone, Drop, Serde, Introspect)]
#[dojo::model]
pub struct ApprovedProposal {
    #[key] pub trail_id: u128,
    #[key] pub proposer: ContractAddress,
    pub w_single_keys:       Array<felt252>,  // inst values for Entity, Area, Reactable, Exit, Hub, InventoryItem, Container, Trail, ParentToChildren, ChildToParent
    pub w_description_texts: Array<felt252>,  // flat pairs: [inst, key_as_felt252, ...]
    pub w_multi_keys:        Array<felt252>,  // flat pairs: [inst, key, ...] for Trigger, Condition, Effect, Action
    pub d_single_keys:       Array<felt252>,
    pub d_description_texts: Array<felt252>,
    pub d_multi_keys:        Array<felt252>,
}
```

**Keys**: `(trail_id, proposer)` — one approval record per collaborator per trail. The owner overwrites the same slot each time they call `approve_proposal`, so there is at most one pending approval per collaborator at any moment.

**Why 6 arrays instead of 30**: The critical ownership question is: can the trail owner approve structural components (area, reactable, exit) while independently rejecting textual content (description_text)? Three approval buckets per direction — single-key, description_texts, multi_keys — capture exactly that distinction while keeping storage cost minimal. A 30-array design (one per component type) would cost gas even on empty arrays; 6 arrays are always allocated, so the base cost is fixed and small regardless of what the collaborator proposed. Cross-entity granularity (e.g. approving ENTITY_A's area but not ENTITY_C's area) is expressed by which inst values appear inside the array.

**Per-component approval granularity — client vs contract**: The review UI lets the owner check or uncheck each individual component for each entity (Area, DescriptionText key 1, Action key 0, etc.). For `DescriptionText` and multi-key types (`Trigger`, `Condition`, `Effect`, `Action`), this per-item selection is enforced at the **contract level** via `contains_pair`. For single-key components (`Entity`, `Area`, `Reactable`, etc.), the contract uses a single flat `w_single_keys` list and cannot distinguish "approve Area but not Entity" for the same inst — if an inst is in `w_single_keys`, all single-key writes for that inst are permitted. This is enforced at the **client level** instead: `publishApproved`'s `buildFiltered` function only publishes the components that were actually checked by the owner, so the broader contract permission is never exploited.

**Who pays for this storage**: The trail owner, when calling `approve_proposal`. The storage cost is proportional to the number of inst/pair values stored (not the component data — just felt252 IDs). For typical approval sizes (tens of entities) this is negligible.

### 2. Single-key vs multi-key components

Components fall into two categories:

**Single-key** (`Entity`, `Reactable`, `Area`, `Exit`, `Hub`, `InventoryItem`, `Container`, `Trail`, `ParentToChildren`, `ChildToParent`): keyed only by `inst`. `w_single_keys` / `d_single_keys` store a flat list of `felt252` inst values. Membership is checked by `contains_inst`.

**`DescriptionText`** (separate bucket): keyed by `(inst, u32 key)`. `w_description_texts` / `d_description_texts` store flat consecutive pairs `[inst1, key1_as_felt252, inst2, key2_as_felt252, ...]`. Kept in its own array so the owner can approve structural components while independently rejecting written text. Membership is checked by `contains_pair` with `o.key.into()` for the u32→felt252 conversion.

**Multi-key** (`Trigger`, `Condition`, `Effect`, `Action`): keyed by `(inst, felt252 key)`. `w_multi_keys` / `d_multi_keys` store flat consecutive pairs `[inst1, key1, inst2, key2, ...]`. Membership is checked by `contains_pair`.

```cairo
// Approve description_text (ENTITY_C, key=1) and (ENTITY_A, key=2)
approval.w_description_texts = array![ENTITY_C, 1, ENTITY_A, 2];

// Inside create_description_text — per-item check
assert(
    contains_pair(approval.w_description_texts.span(), o.inst, o.key.into()),
    Errors::NOT_APPROVED
);

// Approve area and reactable for ENTITY_A and ENTITY_C (single-key, all go in w_single_keys)
approval.w_single_keys = array![ENTITY_A, ENTITY_C];

// Inside create_area — per-item check
assert(contains_inst(approval.w_single_keys.span(), o.inst), Errors::NOT_APPROVED);
```

The two helper functions live as public free functions in `collab_proposal.cairo` and are imported by `designer.cairo`:

```cairo
pub fn contains_inst(mut list: Span<felt252>, inst: felt252) -> bool { ... }
pub fn contains_pair(mut list: Span<felt252>, inst: felt252, key: felt252) -> bool { ... }
```

### 3. `CollabProposalEvent` — `models/collab_proposal.cairo`

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

The 14 `deleted_*` arrays exist solely to carry the full deletion proposal to the review panel. The `ApprovedProposal` model does not need new fields for component deletions — the existing `d_single_keys` / `d_description_texts` / `d_multi_keys` buckets already gate every `delete_*` entrypoint. Splitting deletions by component type in the event lets the owner see and approve/reject each deletion individually in the client UI without changing the contract approval model.

**Why an event, not a model**: A Dojo `event` writes nothing to World contract storage. The data is serialized into the transaction receipt, and Torii picks it up and stores it in its own off-chain database. Until the owner approves and the collaborator publishes, **zero entity or component data exists on-chain**. Nothing enters the game world during the review phase.

`historical: false` means Torii retains only the **latest submission per (trail_id, proposer) pair**. If the collaborator revises their proposal and resubmits, the old one is replaced in Torii automatically.

### 4. Three new system functions — `systems/designer.cairo`

#### `submit_for_review`

```
Caller: collaborator (must have trail_id role or be trail owner/admin)
Effect: emits CollabProposalEvent — no model writes
Cost:   collaborator pays (event-only transaction, cheap)
```

Checks that the caller has been granted access to the specified trail (`has_role(trail_id.into(), caller)`) or is the trail owner or an admin. Panics with `NOT_COLLABORATOR` otherwise.

After the check, calls `world.emit_event(@CollabProposalEvent { ... })`. Nothing is written to storage. The call accepts all 30 arrays: the 16 write arrays (entities, components, relationships), one entity-level deletion array, nine single-key component deletion arrays, and four multi-key component deletion arrays (flat `[inst, key, ...]` pairs).

Trail owners see the "Submit for review" button in the staging panel as disabled with a tooltip — they publish directly and never need to submit for review.

#### `approve_proposal`

```
Caller: trail owner or admin
Effect: writes ApprovedProposal model to World storage
Cost:   trail owner pays (lightweight — inst IDs only, no component data)
```

The caller constructs the full `ApprovedProposal` struct specifying exactly which component types and which specific insts/pairs are approved. The contract validates trail ownership and writes the struct directly. The owner has full flexibility: approve all, approve a subset, or call with all-empty arrays to record a "nothing approved" state.

```cairo
fn approve_proposal(ref self: ContractState, proposal: ApprovedProposal) {
    let caller = starknet::get_caller_address();
    assert(self.is_admin(caller) || world.is_owner_of_trail(proposal.trail_id, caller),
           Errors::NOT_TRAIL_OWNER);
    world.write_model(@proposal);
}
```

#### `reject_proposal`

```
Caller: trail owner or admin
Effect: erases the ApprovedProposal model from storage
Cost:   trail owner pays (trivial — erase one model)
```

Removes the `ApprovedProposal` for the given `(trail_id, proposer)` pair. The collaborator's submitted event remains in Torii (as a historical record) but the on-chain gate is cleared. The collaborator cannot publish any component after a rejection.

### 5. Approval gate on every write and delete function

Every `create_*` and `delete_*` function in `designer.cairo` gained an inline approval gate. The gate fires only when **all three conditions are true**:

```cairo
if !owned.is_zero()                                 // (1) caller is not an admin
   && trail_id.is_non_zero()                        // (2) entity belongs to a trail
   && !world.is_owner_of_trail(trail_id, owned)     // (3) caller does not own the trail
{
    let approval: ApprovedProposal = world.read_model((trail_id, owned));
    assert(contains_inst(approval.w_single_keys.span(), o.inst), Errors::NOT_APPROVED);
}
```

- Condition (1): `owned` is the return value of `_assert_caller_is_editor()`, which returns `0x0` for admins and `caller_address` for everyone else. Admins bypass the gate entirely.
- Condition (2): entities without a trail (trail_id = 0) are core world entities; collaborators cannot touch those at all (earlier checks prevent it).
- Condition (3): the trail owner writes freely — no approval needed on their own trail.

For `DescriptionText`, `contains_pair` is used with the `u32` key cast to `felt252`:

```cairo
// create_description_text
assert(
    contains_pair(approval.w_description_texts.span(), o.inst, o.key.into()),
    Errors::NOT_APPROVED
);
```

For `Trigger` / `Condition` / `Effect` / `Action`, `contains_pair` is used with the native `felt252` key:

```cairo
// create_trigger / create_condition / etc.
assert(
    contains_pair(approval.w_multi_keys.span(), o.inst, o.key),
    Errors::NOT_APPROVED
);
```

The gate applies to both write (`create_*`) and delete (`delete_*`) paths, using `w_single_keys` / `w_description_texts` / `w_multi_keys` for writes and the corresponding `d_*` arrays for deletes.

**Important for new entities**: when a collaborator calls `create_entity`, the entity does not yet exist in storage. The gate uses `o.trail_id` (the field the collaborator sets on the struct) rather than `world.get_entity_trail_id(o.inst)` (which would return 0). The collaborator must set the correct `trail_id` on the entity, and that trail_id must appear in the `ApprovedProposal` for the gate to pass.

For component writes after `create_entity`, the entity exists in storage, so `world.get_entity_trail_id(o.inst)` returns the real trail_id and the gate works normally.

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

[Torii delivers event]
[review panel shows diff]

approve_proposal(proposal) ────────────────────────────────────────────► ApprovedProposal model written
 where proposal.w_single_keys = [ENTITY_C, ENTITY_A, ENTITY_C]          (trail_id, proposer) key
       proposal.w_description_texts = [ENTITY_C, 1]                     cheap: inst IDs only
       proposal.d_single_keys = []  (entity_B deletion rejected)

[Torii delivers ApprovedProposal]
                                     create_area([area_A_modified])  ──► gate checks w_single_keys → ENTITY_A in list → OK
                                     create_entity([entity_C])        ──► gate checks w_single_keys → ENTITY_C in list → OK
                                     create_area([area_C])            ──► gate checks w_single_keys → ENTITY_C in list → OK
                                     create_desc_text([desc_C])       ──► gate checks w_description_texts → (ENTITY_C,1) pair in list → OK
                                     delete_entity([entity_B])        ──► gate checks d_single_keys → ENTITY_B NOT in list → PANIC
```

The collaborator can publish the approved components in any order. The `ApprovedProposal` model remains in storage until the owner calls `reject_proposal` (which erases it) or overwrites it with a new `approve_proposal` call.

---

## Who pays for what

| Action | Caller | Storage written | Cost |
|---|---|---|---|
| `grant_access_to_trail` | Trail owner | Role grant (small) | Trail owner — one-time per collaborator |
| `submit_for_review` | Collaborator | None (event only) | Collaborator — cheap; cost scales with calldata size |
| `approve_proposal` | Trail owner | `ApprovedProposal` (inst IDs only) | Trail owner — cheap; cost scales with number of approved insts |
| `reject_proposal` | Trail owner | Erases `ApprovedProposal` | Trail owner — trivial |
| `create_*` / `delete_*` (publish) | Collaborator | Full component models | Collaborator — normal write cost, same as any publisher |

The design is intentional: the collaborator pays for their own content. The trail owner only pays for the lightweight approval record, not for the actual entity/component data.

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

`grant_access_to_trail` also grants the `trail_id.into()` role to the invitee, so `has_trail_role` is true for collaborators. This check prevents an editor from writing into a trail they were never invited to.

For component functions (`create_area`, etc.), `_assert_can_edit_entity` performs an equivalent check using `world.can_edit_trail(inst, owned)` or `has_role(trail_id.into(), owned)`.

### Layer 3 — Approval gate (collab-specific)

After passing layers 1 and 2, the inline approval gate fires for any caller who is not the trail owner and not an admin. Without a valid `ApprovedProposal` containing the specific inst/pair, the transaction panics with `NOT_APPROVED`.

This is the layer that enforces the two-phase commit. No amount of role-granting bypasses it — only an `ApprovedProposal` model written by the trail owner or an admin does.

---

## Client-side review UI

### Proposal review panel (`RemoteChangesPanel.tsx`)

The `ProposalCard` component presents each pending proposal with per-component approval checkboxes:

- **Entity header**: a tri-state checkbox (checked / indeterminate / unchecked) selects or deselects all components for that entity at once.
- **Expanded view**: each component gets its own row — `Area`, `DescriptionText · key 1`, `Action · key 0`, etc. — with a checkbox and a field-level diff (old value → new value, or green "new" for additions). Deselected rows are dimmed but remain visible so the owner can see what they are rejecting.
- **Component deletion rows**: each deleted component appears as a red strikethrough row within the same expanded view. Multi-key deletions (e.g. `− DescriptionText · key 2`) each get their own checkbox.
- **Entity-level deletions** (`deleted_entity_insts`) are listed in a separate "Deletions" section below the entity rows.
- **Approve button**: labelled "Approve (N)" where N is the count of currently selected component items. Disabled when nothing is selected.

`buildApprovedProposal` constructs the `ApprovedProposal` from the selection:
- `w_single_keys`: insts that have at least one checked single-key component.
- `w_description_texts` / `w_multi_keys`: flat `[inst, key, ...]` pairs for every checked DescriptionText / multi-key item.
- `d_single_keys` / `d_description_texts` / `d_multi_keys`: same pattern for checked deletion items.

### Staging panel (`StagingPanel.tsx`)

- **Component labels**: both unstaged and staged rows show the component name(s) being changed. Multi-key components include the key value (e.g. `DescriptionText (key 1)`, `Action (key 0)`).
- **Submit for review**: disabled for trail owners (who publish directly) with a tooltip explaining why. Collaborators who do not own the trail see it as active whenever there are staged changes.

---

## Key files

| File | Role |
|---|---|
| `packages/contracts/src/models/collab_proposal.cairo` | `ApprovedProposal` model, `CollabProposalEvent` event (30 arrays), `contains_inst`, `contains_pair` |
| `packages/contracts/src/systems/designer.cairo` | `submit_for_review` (30 params), `approve_proposal`, `reject_proposal`, approval gates on all write/delete functions |
| `packages/contracts/src/tests/collab_proposal_test.cairo` | Full flow tests covering approval, rejection, and access control |
| `packages/contracts/src/tests/helpers.cairo` | `m_ApprovedProposal` and `e_CollabProposalEvent` registered in `namespace_def()` |
| `packages/contracts/src/lib.cairo` | `collab_proposal` module declared under `models` and `tests` |
| `packages/client/src/editor/components/RemoteChangesPanel.tsx` | Per-component proposal review UI, `buildInstMap`, `buildApprovedProposal`, `buildSelectableKeys` |
| `packages/client/src/editor/components/StagingPanel.tsx` | Staging/unstaging UI, `Submit for review` (disabled for owners), component label with key display |
| `packages/client/src/editor/publisher.ts` | `submitForReview` (serializes all 30 arrays), `publishApproved` with `buildFiltered` per-component enforcement |
