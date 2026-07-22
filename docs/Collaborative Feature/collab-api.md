# Collaborative Trail Editing — API Reference

This document is the authoritative reference for both the **Cairo contract API** and the **TypeScript client API** that implement the collaborative trail editing feature. For the rationale behind the design see [collab-implementation.md](collab-implementation.md).

---

## Table of contents

1. [Overview](#overview)
2. [Data types](#data-types)
   - [CollabReviewResult (Cairo model)](#collabrevid-result-cairo-model)
   - [CollabProposalEvent (Cairo event)](#collabproposaleventslow-cairo-event)
   - [CollabReviewResult (TypeScript)](#collabrevid-result-typescript)
   - [ChangeSet (TypeScript)](#changeset-typescript)
3. [Contract API — `IDesigner`](#contract-api--idesigner)
   - [Access control](#access-control)
   - [submit_for_review](#submit_for_review)
   - [signal_review_result](#signal_review_result)
   - [Approval gate on create_* / delete_*](#approval-gate-on-create--delete-)
   - [Error codes](#error-codes)
4. [Client API — `publisher.ts`](#client-api--publisherts)
   - [submitForReview](#submitforreview)
   - [publishFromProposal](#publishfromproposal)
   - [signalReviewResult](#signalreviewresult)
   - [publishConfigToContract](#publishconfigtocontract)
5. [Torii queries](#torii-queries)
6. [Component classification](#component-classification)

---

## Overview

The collab feature is a proposal-based flow where the **trail owner publishes approved content** on behalf of the collaborator:

| Phase | Who | What | On-chain effect |
|---|---|---|---|
| 1. Submit | Collaborator | `submit_for_review` | Emits `CollabProposalEvent` — **zero storage written** |
| 2. Publish | Trail owner | `publishFromProposal` (client) → `create_*` / `delete_*` | Full entity + component models written |
| 3. Signal | Trail owner | `signal_review_result` | Writes `CollabReviewResult` model (counts only) |
| — | Collaborator | Receives `CollabReviewResult` via Torii | Toast notification / rejection banner |

Trail owners bypass phase 1 entirely and call `create_*` / `delete_*` directly. Collaborators can **never** call `create_*` / `delete_*` on a trail they don't own.

---

## Data types

### `CollabReviewResult` (Cairo model)

```cairo
// packages/contracts/src/models/collab_proposal.cairo

#[derive(Clone, Drop, Serde, Introspect)]
#[dojo::model]
pub struct CollabReviewResult {
    #[key] pub trail_id:       u128,
    #[key] pub proposer:       ContractAddress,
    pub published_count:       u32,
    pub skipped_count:         u32,
}
```

**Keys**: `(trail_id, proposer)` — one record per collaborator per trail. Writing a new `CollabReviewResult` for the same key pair overwrites the previous one.

**Storage**: minimal — 2 u32 counts plus keys. Cost is negligible.

**Delivery**: arrives through the existing `subscribeEntityQuery` in `dojo.ts` (same channel as regular model updates) — no separate event subscription needed.

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

### `CollabReviewResult` (TypeScript)

Generated from the Cairo model by Dojo:

```typescript
// packages/client/src/lib/dojo_bindings/typescript/models.gen.ts

export interface CollabReviewResult {
    fieldOrder: string[];
    trail_id:        BigNumberish;
    proposer:        string;      // hex address
    published_count: number;
    skipped_count:   number;
}
```

Torii delivers instances of this type via the entity subscription. `StagingPanel` watches it to show toast notifications or the rejection banner.

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

`EditorCollection` is a partial map of component name → component data. `submitForReview` consumes `ChangeSet[]` arrays read from `EditorData().stagedChanges`.

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

**Restriction**: `deleted_entity_insts` must be empty for non-owner callers. Collaborators can propose component-level deletions but not entity-level deletions.

**Panics**:
- `NOT_EDITOR` — caller has no editor-level role at all
- `NOT_COLLABORATOR` — caller passes layer 1 but does not hold a role on this trail and is not the trail owner / admin
- `NOT_TRAIL_OWNER` — caller is a collaborator and passed a non-empty `deleted_entity_insts`

**Cost**: collaborator pays; gas scales with calldata size. Recommended to only populate arrays that have actual changes.

---

### `signal_review_result`

```cairo
fn signal_review_result(
    ref self: TContractState,
    trail_id:        u128,
    proposer:        ContractAddress,
    published_count: u32,
    skipped_count:   u32,
)
```

**Caller**: trail owner or admin.

**Effect**: writes `CollabReviewResult` model to World storage, keyed by `(trail_id, proposer)`. Any previous result for the same key is overwritten.

**Panics**: `NOT_TRAIL_OWNER` — caller is not admin and does not own `trail_id`.

**Cost**: trail owner pays; trivial (2 u32 fields).

**When to call**: after calling `publishFromProposal` (or after deciding to skip all items). The owner passes the exact counts returned by `publishFromProposal` to give the collaborator an accurate notification.

**Full rejection**: call with `published_count = 0` and `skipped_count = total proposal items`. The collaborator receives the rejection banner and their staged changes are preserved.

---

### Approval gate on `create_*` / `delete_*`

Every `create_*` and `delete_*` function applies the following gate **after** the base access-control checks pass:

```cairo
// Gate fires when all three are true:
if !owned.is_zero()                              // (1) not an admin
   && trail_id.is_non_zero()                     // (2) entity belongs to a trail
   && !world.is_owner_of_trail(trail_id, owned)  // (3) caller is not the trail owner
{
    assert(false, Errors::NOT_APPROVED);  // unconditional — collaborators never write directly
}
```

There is no approval list to look up. The check is purely: **if you are a non-owner collaborator, you cannot write**. The trail owner is expected to call these functions directly when publishing a collaborator's proposal.

**`creator_address` for new entities**: when the owner publishes a new entity (one that doesn't yet exist on-chain), they pass the collaborator's address as `creator_address` in the `Entity` struct. The contract uses this value for new entities and ignores it for existing ones (always preserving the stored creator).

```cairo
// Inside create_entity — creator resolution
if stored_entity.creator_address.is_zero() {
    // new entity: use passed value if non-zero, otherwise use caller
    entity.creator_address = if o.creator_address.is_non_zero() {
        o.creator_address
    } else {
        owned
    };
} else {
    // existing entity: always preserve stored creator
    entity.creator_address = stored_entity.creator_address;
}
```

---

### Error codes

| Constant | Value (felt252 short string) | Thrown by |
|---|---|---|
| `NOT_EDITOR` | `'DESIGNER: Not editor'` | `_assert_caller_is_editor` (first layer, all write/delete fns) |
| `NOT_YOUR_TRAIL` | `'DESIGNER: Not your trail'` | `create_entity`, component fns (second layer) |
| `NOT_APPROVED` | `'DESIGNER: Not approved'` | Approval gate (third layer — unconditional for non-owners) |
| `NOT_TRAIL_OWNER` | `'DESIGNER: Not trail owner'` | `signal_review_result`, `grant_access_to_trail`, `submit_for_review` (entity deletion) |
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

**Serialization**: each component type is serialized into its raw Cairo array format. The complete calldata order is:

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

Each `[array]` is encoded as `[length, ...flat_items]` (Cairo array encoding).

---

### `publishFromProposal`

```typescript
export const publishFromProposal = async (
    proposal: CollabProposalEvent,
    selected: Set<string>,
): Promise<{ publishedCount: number; skippedCount: number }>
```

Called by the trail owner after reviewing the proposal. Publishes only the items whose keys appear in `selected`, then returns the counts for `signal_review_result`.

**Parameters**:
- `proposal` — the `CollabProposalEvent` received from Torii
- `selected` — set of selection keys (see format below)

**Returns**: `{ publishedCount, skippedCount }` where `publishedCount + skippedCount = totalSelectableKeys`.

**Effect**:
1. Builds lookup maps for all proposal items (entity by inst, components by inst, multi-key components by inst+key).
2. Builds the full list of selectable keys from the proposal.
3. Pass 1: publishes entity data for all selected `w:` keys — for each new entity, passes the proposer's address as `creatorAddress`.
4. Pass 2: publishes relationships (`ParentToChildren` / `ChildToParent`) and executes deletions for `d:` keys.
5. Returns `{ publishedCount, skippedCount }`.

**Selection key format**:

| Key format | Meaning |
|---|---|
| `w:${inst}:${comp}` | Write a single-key component (Entity, Area, Reactable, etc.) |
| `w:${inst}:${comp}:${key}` | Write a multi-key component (DescriptionText, Trigger, Condition, Effect, Action) |
| `d:${inst}:${comp}` | Delete a single-key component |
| `d:${inst}:${comp}:${key}` | Delete a multi-key component |

`RemoteChangesPanel` builds these keys via `buildSelectableKeys(proposal)` and stores the owner's selection in a `Set<string>`.

---

### `signalReviewResult`

```typescript
export const signalReviewResult = async (
    trailId:        bigint,
    proposer:       string,
    publishedCount: number,
    skippedCount:   number,
): Promise<void>
```

Thin re-export wrapping `SystemCalls.signalReviewResult`. Called by the owner after `publishFromProposal` completes.

**Effect**: calls `signal_review_result` on the designer contract, writing `CollabReviewResult` for the given `(trailId, proposer)` pair.

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

**Not for collaborators**: the `StagingPanel` disables the "Publish staged" button for collaborators who do not own the active trail. Collaborators must use `submitForReview` instead.

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

### Receiving review results (collaborator)

`CollabReviewResult` is a Dojo **model**, not an event. It arrives through the existing entity subscription in `dojo.ts` alongside all other model updates — no separate query needed:

```typescript
// dojo.ts — withEntityModels subscription (excerpt)
.withEntityModels([
    "lore-Entity",
    // ... other models ...
    "lore-CollabReviewResult",    // ← added to existing subscription
])
```

In `editor.data.ts`, the `dojoSync` handler extracts it:

```typescript
const reviewResult = (obj as any).CollabReviewResult as CollabReviewResult | undefined;
if (reviewResult?.trail_id !== undefined) {
    set({ reviewResult });
    return;
}
```

`StagingPanel` then reads `reviewResult` from `useEditorData()` and applies the three-state notification logic.

### Proposal state

| `CollabProposalEvent` in Torii | `CollabReviewResult` for proposer | State |
|---|---|---|
| Yes | No (or stale) | **Pending** — owner needs to review and publish |
| Yes | Yes (recent, `published_count > 0`) | **Published** — result delivered |
| Yes | Yes (`published_count == 0`) | **Rejected** — result delivered, B can resubmit |
| No | No | Idle — nothing pending |

---

## Component classification

For the purposes of `publishFromProposal` selection keys, components fall into two categories:

| Category | Selection key format | Components |
|---|---|---|
| **Single-key** | `w:${inst}:${comp}` / `d:${inst}:${comp}` | `Entity`, `Reactable`, `Area`, `Exit`, `Hub`, `InventoryItem`, `Container`, `Trail`, `ParentToChildren`, `ChildToParent` |
| **Multi-key** | `w:${inst}:${comp}:${key}` / `d:${inst}:${comp}:${key}` | `DescriptionText` (u32 key), `Trigger`, `Condition`, `Effect`, `Action` (felt252 key) |

This classification determines the key format used in the selection `Set<string>` and how `publishFromProposal` looks up items in the proposal lookup maps.
