# Collaborative Trail Editing — API Reference

This document is the authoritative reference for both the **Cairo contract API** and the **TypeScript client API** that implement the collaborative trail editing feature. For the rationale behind the design see [collab-implementation.md](collab-implementation.md).

---

## Table of contents

1. [Overview](#overview)
2. [Data types](#data-types)
   - [ApprovedProposal (Cairo model)](#approvedproposal-cairo-model)
   - [CollabProposalEvent (Cairo event)](#collabproposaleventslow-cairo-event)
   - [ApprovedProposal (TypeScript)](#approvedproposal-typescript)
   - [ChangeSet (TypeScript)](#changeset-typescript)
3. [Contract API — `IDesigner`](#contract-api--idesigner)
   - [Access control](#access-control)
   - [submit_for_review](#submit_for_review)
   - [approve_proposal](#approve_proposal)
   - [reject_proposal](#reject_proposal)
   - [Approval gate on create_* / delete_*](#approval-gate-on-create--delete-)
   - [Error codes](#error-codes)
4. [Client API — `publisher.ts`](#client-api--publisherts)
   - [submitForReview](#submitforreview)
   - [publishApproved](#publishapproved)
   - [publishConfigToContract](#publishconfigtocontract)
5. [Torii queries](#torii-queries)
6. [Component classification](#component-classification)
7. [Approval array encoding](#approval-array-encoding)

---

## Overview

The collab feature is a two-phase commit over Dojo events and models:

| Phase | Who | What | On-chain effect |
|---|---|---|---|
| 1. Submit | Collaborator | `submit_for_review` | Emits `CollabProposalEvent` — **zero storage written** |
| 2. Approve | Trail owner | `approve_proposal` | Writes `ApprovedProposal` model (inst IDs only) |
| 3. Publish | Collaborator | Normal `create_*` / `delete_*` | Full entity + component models written; contract checks approval gate |
| — | Trail owner | `reject_proposal` | Erases `ApprovedProposal`; no revert needed |

Trail owners bypass phases 1–2 entirely and call `create_*` / `delete_*` directly.

---

## Data types

### `ApprovedProposal` (Cairo model)

```cairo
// packages/contracts/src/models/collab_proposal.cairo

#[derive(Clone, Drop, Serde, Introspect)]
#[dojo::model]
pub struct ApprovedProposal {
    #[key] pub trail_id: u128,
    #[key] pub proposer: ContractAddress,

    // Writes — single-key components (Entity, Reactable, Area, Exit, Hub,
    //          InventoryItem, Container, Trail, ParentToChildren, ChildToParent)
    pub w_single_keys:       Array<felt252>,  // flat list of inst values

    // Writes — DescriptionText (keyed by inst + u32)
    pub w_description_texts: Array<felt252>,  // flat pairs [inst, key_as_felt252, ...]

    // Writes — multi-key components (Trigger, Condition, Effect, Action)
    pub w_multi_keys:        Array<felt252>,  // flat pairs [inst, key, ...]

    // Deletes — same bucket structure as writes
    pub d_single_keys:       Array<felt252>,
    pub d_description_texts: Array<felt252>,
    pub d_multi_keys:        Array<felt252>,
}
```

**Keys**: `(trail_id, proposer)` — one record per collaborator per trail. Writing a new `ApprovedProposal` for the same key pair overwrites the previous one. At most one pending approval per collaborator exists at any moment.

**Storage**: only `felt252` inst / key identifiers are stored — no component data. Cost is proportional to the number of approved items.

---

### `CollabProposalEvent` (Cairo event)

```cairo
// packages/contracts/src/models/collab_proposal.cairo

#[derive(Drop, Serde)]
#[dojo::event(historical: false)]
pub struct CollabProposalEvent {
    #[key] pub trail_id:  u128,
    #[key] pub proposer:  ContractAddress,

    // ── Write proposals ─────────────────────────────────────────────────────
    pub entities:          Array<Entity>,
    pub reactables:        Array<Reactable>,
    pub areas:             Array<Area>,
    pub exits:             Array<Exit>,
    pub hubs:              Array<Hub>,
    pub description_texts: Array<DescriptionText>,
    pub inventory_items:   Array<InventoryItem>,
    pub containers:        Array<Container>,
    pub trails:            Array<Trail>,
    pub triggers:          Array<Trigger>,
    pub conditions:        Array<Condition>,
    pub effects:           Array<Effect>,
    pub actions:           Array<Action>,
    pub parents:           Array<ParentToChildren>,
    pub children:          Array<ChildToParent>,

    // ── Entity-level deletions ───────────────────────────────────────────────
    pub deleted_entity_insts:          Array<felt252>,

    // ── Component-level deletions — single-key (flat inst list) ─────────────
    pub deleted_reactable_insts:       Array<felt252>,
    pub deleted_area_insts:            Array<felt252>,
    pub deleted_exit_insts:            Array<felt252>,
    pub deleted_container_insts:       Array<felt252>,
    pub deleted_inventory_item_insts:  Array<felt252>,
    pub deleted_hub_insts:             Array<felt252>,
    pub deleted_trail_insts:           Array<felt252>,
    pub deleted_parent_insts:          Array<felt252>,
    pub deleted_child_insts:           Array<felt252>,

    // ── Component-level deletions — multi-key (flat [inst, key, ...] pairs) ─
    pub deleted_description_text_keys: Array<felt252>,
    pub deleted_trigger_keys:          Array<felt252>,
    pub deleted_condition_keys:        Array<felt252>,
    pub deleted_effect_keys:           Array<felt252>,
    pub deleted_action_keys:           Array<felt252>,
}
```

**Storage**: none. The event is serialized into the Starknet transaction receipt and indexed by Torii in its off-chain `event_messages` table. `historical: false` means Torii keeps only the latest emission per `(trail_id, proposer)` key pair.

---

### `ApprovedProposal` (TypeScript)

Generated from the Cairo model by Dojo:

```typescript
// packages/client/src/lib/dojo_bindings/typescript/models.gen.ts

export interface ApprovedProposal {
    fieldOrder: string[];
    trail_id:          BigNumberish;
    proposer:          string;          // hex address
    w_single_keys:     BigNumberish[];
    w_description_texts: BigNumberish[];
    w_multi_keys:      BigNumberish[];
    d_single_keys:     BigNumberish[];
    d_description_texts: BigNumberish[];
    d_multi_keys:      BigNumberish[];
}
```

Torii delivers instances of this type via the SDK subscription. `publishApproved` consumes one instance.

---

### `ChangeSet` (TypeScript)

The unit of work in the local staging system:

```typescript
// packages/client/src/editor/lib/types.ts

export type ChangeSet = {
    type:   "update" | "delete";
    object: EditorCollection;   // the component data (or deletion target)
    inst:   BigNumberish;       // entity instance key
    key?:   BigNumberish;       // only set for multi-key component changes
};
```

`EditorCollection` is a partial map of component name → component data (with Cairo enums replaced by their string union equivalents). Both `submitForReview` and `publishApproved` consume `ChangeSet[]` arrays read from `EditorData().stagedChanges`.

---

## Contract API — `IDesigner`

Contract address: `LORE_CONFIG.contractAddresses.designer` (injected at build time).

### Access control

These functions must be called before a collaborator can submit:

```cairo
// Grant a collaborator access to a specific trail.
// Grants: ROLES::COLLABORATOR (passes _assert_caller_is_editor)
//       + trail_id.into() role (passes trail ownership check in create_entity)
// Caller must be trail owner or admin.
fn grant_access_to_trail(
    ref self: TContractState,
    account:  ContractAddress,
    trail_id: u128,
    granting: bool,             // false to revoke
)

// Grant access to a single entity (not trail-scoped).
// Caller must be admin.
fn grant_access_to_entity(
    ref self: TContractState,
    account: ContractAddress,
    inst:    felt252,
    granting: bool,
)

// Query helpers
fn is_admin(self: @TContractState, account: ContractAddress) -> bool
fn is_editor(self: @TContractState, account: ContractAddress) -> bool
fn has_role(self: @TContractState, role: felt252, account: ContractAddress) -> bool

// Grant admin / editor roles (existing admin only)
fn set_admin(ref self: TContractState, account: ContractAddress, is_admin: bool)
fn set_editor(ref self: TContractState, account: ContractAddress, is_editor: bool)
```

---

### `submit_for_review`

```cairo
fn submit_for_review(
    ref self: TContractState,
    trail_id: u128,

    // ── Write proposals (pass empty arrays for unchanged component types) ────
    entities:          Array<Entity>,
    reactables:        Array<Reactable>,
    areas:             Array<Area>,
    exits:             Array<Exit>,
    hubs:              Array<Hub>,
    description_texts: Array<DescriptionText>,
    inventory_items:   Array<InventoryItem>,
    containers:        Array<Container>,
    trails:            Array<Trail>,
    triggers:          Array<Trigger>,
    conditions:        Array<Condition>,
    effects:           Array<Effect>,
    actions:           Array<Action>,
    parents:           Array<ParentToChildren>,
    children:          Array<ChildToParent>,

    // ── Entity-level deletions ───────────────────────────────────────────────
    deleted_entity_insts:          Array<felt252>,

    // ── Component-level deletions — single-key ───────────────────────────────
    deleted_reactable_insts:       Array<felt252>,
    deleted_area_insts:            Array<felt252>,
    deleted_exit_insts:            Array<felt252>,
    deleted_container_insts:       Array<felt252>,
    deleted_inventory_item_insts:  Array<felt252>,
    deleted_hub_insts:             Array<felt252>,
    deleted_trail_insts:           Array<felt252>,
    deleted_parent_insts:          Array<felt252>,
    deleted_child_insts:           Array<felt252>,

    // ── Component-level deletions — multi-key (flat [inst, key, ...] pairs) ─
    deleted_description_text_keys: Array<felt252>,
    deleted_trigger_keys:          Array<felt252>,
    deleted_condition_keys:        Array<felt252>,
    deleted_effect_keys:           Array<felt252>,
    deleted_action_keys:           Array<felt252>,
)
```

**Caller**: collaborator (must hold `ROLES::COLLABORATOR` or `ROLES::EDITOR` / `ROLES::ADMIN`, and the `trail_id.into()` role).

**Effect**: emits one `CollabProposalEvent`. **No storage written.**

**Panics**:
- `NOT_EDITOR` — caller has no editor-level role at all
- `NOT_COLLABORATOR` — caller passes layer 1 but does not hold a role on this trail and is not the trail owner / admin

**Cost**: collaborator pays; gas scales with calldata size (total byte length of all arrays). Empty arrays each cost 1 felt252 (the length prefix 0). Recommended to only populate arrays that have actual changes.

---

### `approve_proposal`

```cairo
fn approve_proposal(ref self: TContractState, proposal: ApprovedProposal)
```

**Caller**: trail owner or admin.

**Effect**: writes `ApprovedProposal` model to World storage, keyed by `(proposal.trail_id, proposal.proposer)`. Any previous approval for the same key is overwritten.

**Panics**: `NOT_TRAIL_OWNER` — caller is not admin and does not own `proposal.trail_id`.

**Cost**: trail owner pays; cost scales with the number of inst/key values across the 6 arrays (typically tens of felt252 values — very cheap).

**Partial approval**: the owner can pass non-empty arrays for some component types and empty arrays for others. Empty `w_single_keys` means no single-key writes are approved; empty `d_single_keys` means no deletions are approved. The collaborator's subsequent `create_*` / `delete_*` calls will panic for unapproved items.

---

### `reject_proposal`

```cairo
fn reject_proposal(ref self: TContractState, trail_id: u128, proposer: ContractAddress)
```

**Caller**: trail owner or admin.

**Effect**: erases the `ApprovedProposal` model for `(trail_id, proposer)` from World storage. The `CollabProposalEvent` remains in Torii as a record of the original proposal.

**Panics**: `NOT_TRAIL_OWNER`.

**Cost**: trail owner pays; erasing a model is a trivial write.

**After rejection**: the collaborator receives no on-chain notification. The client detects rejection by watching the `ApprovedProposal` model disappear from Torii while staged changes remain (see `StagingPanel.tsx` rejection banner logic).

---

### Approval gate on `create_*` / `delete_*`

Every `create_*` and `delete_*` function applies the following gate **after** the base access-control checks pass:

```cairo
// Gate fires when all three are true:
if !owned.is_zero()                              // (1) not an admin
   && trail_id.is_non_zero()                     // (2) entity belongs to a trail
   && !world.is_owner_of_trail(trail_id, owned)  // (3) caller is not the trail owner
{
    let approval: ApprovedProposal = world.read_model((trail_id, owned));

    // Single-key component write (Entity, Area, Reactable, Exit, Hub, ...):
    assert(contains_inst(approval.w_single_keys.span(), o.inst), Errors::NOT_APPROVED);

    // DescriptionText write:
    assert(contains_pair(approval.w_description_texts.span(), o.inst, o.key.into()), Errors::NOT_APPROVED);

    // Multi-key write (Trigger, Condition, Effect, Action):
    assert(contains_pair(approval.w_multi_keys.span(), o.inst, o.key), Errors::NOT_APPROVED);

    // Single-key delete:
    assert(contains_inst(approval.d_single_keys.span(), inst), Errors::NOT_APPROVED);

    // DescriptionText delete:
    assert(contains_pair(approval.d_description_texts.span(), inst, key), Errors::NOT_APPROVED);

    // Multi-key delete:
    assert(contains_pair(approval.d_multi_keys.span(), inst, key), Errors::NOT_APPROVED);
}
```

The `contains_inst` and `contains_pair` free functions live in `collab_proposal.cairo`:

```cairo
pub fn contains_inst(mut list: Span<felt252>, inst: felt252) -> bool { ... }
pub fn contains_pair(mut list: Span<felt252>, inst: felt252, key: felt252) -> bool { ... }
```

**Important for new entities**: when calling `create_entity` for a new entity, the entity does not yet exist in storage, so the gate reads `trail_id` from `o.trail_id` (the field set by the collaborator), not from storage. The collaborator must set the correct `trail_id` on the entity struct.

---

### Error codes

| Constant | Value (felt252 short string) | Thrown by |
|---|---|---|
| `NOT_EDITOR` | `'DESIGNER: Not editor'` | `_assert_caller_is_editor` (first layer, all write/delete fns) |
| `NOT_YOUR_TRAIL` | `'DESIGNER: Not your trail'` | `create_entity`, component fns (second layer) |
| `NOT_APPROVED` | `'DESIGNER: Not approved'` | Approval gate (third layer) |
| `NOT_TRAIL_OWNER` | `'DESIGNER: Not trail owner'` | `approve_proposal`, `reject_proposal`, `grant_access_to_trail` |
| `NOT_COLLABORATOR` | `'DESIGNER: Not collaborator'` | `submit_for_review` |

---

## Client API — `publisher.ts`

File: `packages/client/src/editor/publisher.ts`

### `submitForReview`

```typescript
export const submitForReview = async (trailId: bigint): Promise<boolean>
```

Collects all staged changes for `trailId` from `EditorData().stagedChanges`, serializes them into the 30-parameter calldata for `submit_for_review`, and dispatches the transaction.

**Returns**: `true` on success, `false` if not connected, nothing staged, or the transaction fails.

**Effect**: calls `submit_for_review` on the designer contract. No models written. Shows a success toast on completion.

**Serialization**: each component type is serialized into its raw Cairo array format using the `build*Data` helpers (mirrors the `publish*` functions used for direct publishing). The complete calldata order is:

```
trail_id,
[entities], [reactables], [areas], [exits], [hubs],
[description_texts], [inventory_items], [containers], [trails],
[triggers], [conditions], [effects], [actions],
[parents], [children],
[deleted_entity_insts],
[deleted_reactable_insts], [deleted_area_insts], [deleted_exit_insts],
[deleted_container_insts], [deleted_inventory_item_insts],
[deleted_hub_insts], [deleted_trail_insts],
[deleted_parent_insts], [deleted_child_insts],
[deleted_description_text_keys], [deleted_trigger_keys],
[deleted_condition_keys], [deleted_effect_keys], [deleted_action_keys]
```

Each `[array]` is encoded as `[length, ...flat_items]` (Cairo array encoding). The `flatCairo` helper produces this format.

---

### `publishApproved`

```typescript
export const publishApproved = async (
    trailId:  bigint,
    approval: ApprovedProposal,
): Promise<boolean>
```

Publishes only the staged components that the trail owner approved, using the `ApprovedProposal` to filter. Bypasses the creator-address ownership check (the contract's approval gate enforces access instead).

**Returns**: `true` on success, `false` if nothing staged or the transaction fails.

**Effect**:
1. Reads `EditorData().stagedChanges` filtered to `trailId`.
2. Calls `buildFiltered` for each `ChangeSet` to keep only approved components.
3. Pass 1: publishes entity data (all components except relationships) for each approved update.
4. Pass 2: publishes relationships and processes approved deletes.
5. Removes published entries from `stagedChanges` and `changeSet`.
6. Removes the consumed `ApprovedProposal` from `EditorData().currentApprovals` (clears the "Approved by trail owner" banner).
7. Re-syncs published entities from Torii.

**`buildFiltered` logic** (per `ChangeSet`):

```typescript
// Selects approved components from one ChangeSet's object.
const buildFiltered = (
    singleList: bigint[],  // w_single_keys or d_single_keys
    descList:   bigint[],  // w_description_texts or d_description_texts
    multiList:  bigint[],  // w_multi_keys or d_multi_keys
): EditorCollection => {
    // Single-key components: inst must appear in singleList
    if (col.Entity     && containsInst(singleList, inst)) out.Entity = col.Entity;
    if (col.Area       && containsInst(singleList, inst)) out.Area   = col.Area;
    // ... Reactable, Exit, Hub, InventoryItem, Container, Trail,
    //     ParentToChildren, ChildToParent (same pattern)

    // DescriptionText: each (inst, key) pair checked against descList
    if (col.DescriptionText) {
        const ok = filterApprovedMulti(descList, col.DescriptionText);
        if (ok.length > 0) out.DescriptionText = ok;
    }

    // Multi-key: Trigger, Condition, Effect, Action — each (inst, key) checked against multiList
    applyMulti(col.Trigger,   "Trigger");
    applyMulti(col.Condition, "Condition");
    applyMulti(col.Effect,    "Effect");
    applyMulti(col.Action,    "Action");

    return out;
};
```

Uses `dSingle / dDesc / dMulti` for `delete` changes, `wSingle / wDesc / wMulti` for `update` changes.

**Membership helpers** (client-side mirrors of the Cairo contract functions):

```typescript
const containsInst = (list: bigint[], inst: bigint) =>
    list.some(x => x === inst);

const containsPair = (list: bigint[], inst: bigint, key: bigint) => {
    for (let i = 0; i + 1 < list.length; i += 2)
        if (list[i] === inst && list[i + 1] === key) return true;
    return false;
};
```

---

### `publishConfigToContract`

```typescript
export const publishConfigToContract = async (changes?: ChangeSet[]): Promise<boolean>
```

Trail owners and admins use this to publish staged changes directly (bypassing the review flow).

**Parameters**: if `changes` is provided, publishes exactly those changesets (used by per-entity Publish buttons). If omitted, publishes all staged changes for the active trail.

**Effect**:
- Pass 1: calls `create_*` functions for all entity data (non-relationship components) in order.
- Pass 2: calls `create_parent` / `create_child` for relationships, then `delete_*` for deletions.
- Cleans up `stagedChanges` / `changeSet` entries after each publish.
- Re-syncs published entities from Torii.

**Guard**: skips changes owned by another editor (non-admin callers) and shows a warning toast.

**Not for collaborators**: the `StagingPanel` disables the "Publish staged" button for collaborators who do not own the active trail (`!canPublishDirectly`). Collaborators must use `submitForReview` instead.

---

## Torii queries

### Subscribing to pending proposals (trail owner)

The owner queries `CollabProposalEvent` filtered by each owned `trail_id`:

```typescript
const query = new ToriiQueryBuilder<SchemaType>()
    .withLimit(100)
    .includeHashedKeys()
    .withClause(
        new ClauseBuilder<SchemaType>()
            .keys(
                ["lore-CollabProposalEvent"],
                [toHex(trailId), undefined],  // trail_id = mine, any proposer
            )
            .build()
    )
    .withEntityModels(["lore-CollabProposalEvent"]);

const result = await sdk.getEventMessages({ query });
const proposals = result?.getItems() ?? [];
```

### Subscribing to approvals (collaborator)

The collaborator subscribes to `ApprovedProposal` keyed by `(trailId, myAddress)`:

```typescript
const query = new ToriiQueryBuilder<SchemaType>()
    .withClause(
        new ClauseBuilder<SchemaType>()
            .keys(
                ["lore-ApprovedProposal"],
                [toHex(trailId), myAddress],
            )
            .build()
    )
    .withEntityModels(["lore-ApprovedProposal"]);
```

When a new `ApprovedProposal` arrives, `EditorData().currentApprovals` is updated, triggering the "Approved by trail owner" section in `StagingPanel`.

### Proposal state machine

| `CollabProposalEvent` in Torii | `ApprovedProposal` model | Displayed state |
|---|---|---|
| Yes | No | **Pending** — owner needs to review |
| Yes | Yes | **Approved** — collaborator can publish |
| No | No | Idle — nothing pending |
| No | Yes (stale) | Should not occur; approval erased on publish |

---

## Component classification

The approval arrays use three buckets. Every component falls into exactly one:

| Bucket | Array fields | Components |
|---|---|---|
| **Single-key** | `w_single_keys` / `d_single_keys` | `Entity`, `Reactable`, `Area`, `Exit`, `Hub`, `InventoryItem`, `Container`, `Trail`, `ParentToChildren`, `ChildToParent` |
| **DescriptionText** | `w_description_texts` / `d_description_texts` | `DescriptionText` (keyed by `inst` + `u32 key`) |
| **Multi-key** | `w_multi_keys` / `d_multi_keys` | `Trigger`, `Condition`, `Effect`, `Action` (keyed by `inst` + `felt252 key`) |

**Why DescriptionText is separate**: the owner must be able to approve structural changes (area bounds, reactable settings) while independently rejecting written content (description text). The three-bucket design captures this at the contract level without per-component arrays.

**Per-component granularity for single-key types**: the contract's `w_single_keys` list cannot distinguish "approve Area but not Entity" for the same inst — if an inst is present, all single-key writes for that inst are permitted. Finer granularity for single-key types is enforced **client-side** by `publishApproved`'s `buildFiltered`: only the components the owner checked in the UI are included in the actual `create_*` calls, even though the contract would permit all of them.

---

## Approval array encoding

### Single-key arrays (`w_single_keys`, `d_single_keys`)

Flat list of `felt252` inst values:

```cairo
// Approve writes for ENTITY_A and ENTITY_C
w_single_keys = array![ENTITY_A, ENTITY_C];

// Check in create_area / create_reactable / etc.
assert(contains_inst(approval.w_single_keys.span(), o.inst), Errors::NOT_APPROVED);
```

### DescriptionText arrays (`w_description_texts`, `d_description_texts`)

Flat consecutive pairs `[inst₁, key₁_as_felt252, inst₂, key₂_as_felt252, ...]`:

```cairo
// Approve DescriptionText (ENTITY_C, key=1) and (ENTITY_A, key=2)
w_description_texts = array![ENTITY_C, 1, ENTITY_A, 2];

// Check in create_description_text (note: u32 key cast to felt252)
assert(
    contains_pair(approval.w_description_texts.span(), o.inst, o.key.into()),
    Errors::NOT_APPROVED,
);
```

### Multi-key arrays (`w_multi_keys`, `d_multi_keys`)

Flat consecutive pairs `[inst₁, key₁, inst₂, key₂, ...]` (both `felt252`):

```cairo
// Approve Action (ENTITY_A, key=0xdeadbeef) and Trigger (ENTITY_C, key=0xcafe)
w_multi_keys = array![ENTITY_A, 0xdeadbeef, ENTITY_C, 0xcafe];

// Check in create_action / create_trigger / etc. (key stays felt252)
assert(
    contains_pair(approval.w_multi_keys.span(), o.inst, o.key),
    Errors::NOT_APPROVED,
);
```

### Deletion arrays

Deletion arrays follow the same encoding as their write counterparts:

```cairo
// Entity deletion (single-key bucket)
d_single_keys = array![ENTITY_B];

// DescriptionText deletion (inst + key pair)
d_description_texts = array![ENTITY_C, 2];

// Action deletion (inst + key pair)
d_multi_keys = array![ENTITY_A, 0xdeadbeef];
```

**Note**: entity deletions (`deleted_entity_insts`) are a subset of single-key deletions. Because deleting an entity implies deleting all its components, the client sends the entity's inst in `d_single_keys` when approving an entity deletion via `buildApprovedProposal`.
