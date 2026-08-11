# Monetization — Revenue Distribution Between Owner, Creator & Collaborators

This document covers the feature end-to-end: what's **shipped** (collaborator tracking — Part 1), and what's a **proposal awaiting implementation** (splitting actual action revenue between trail owner, entity creator, and collaborators — Part 2).

---

## The idea in one paragraph

Every entity (door, officer, token, ...) in the world has a `creator_address` (who first authored it) and now a `collaborators` list (who has since modified it). When a player spends an action-fee interacting with that entity, the fee should split between the **trail owner** (hosts the content), the **creator** (authored the object), and any **collaborators** (touched it since) — instead of the current behavior, where 100% goes to the trail owner. Part 1 builds the bookkeeping (who touched what). Part 2 proposes how the money actually splits and accrues on-chain.

---

## Part 1 — Collaborator tracking (shipped)

### Why this shape

An entity's `creator_address` was already tracked (`entity.cairo`). Revenue-sharing needs a second list: everyone else who has since modified that entity, because a collaborator can:

- **Create** a new entity → they become `creator_address` (existing behavior, untouched).
- **Modify** an existing entity → their address should be appended to `collaborators`, whether that entity was created by the trail owner, by them, or by a third party — including modifying an entity they themselves created (confirmed: creator_address and collaborators can both list the same address; no dedup — every modifying publish appends, so `collaborators.len()` doubles as a contribution count, which Part 2's formula depends on).

This only matters at the point where content actually becomes canon: when the trail owner **publishes** a collaborator's proposal (see [collab-implementation.md](../Collaborative%20Feature/collab-implementation.md) for the propose/review/publish flow this builds on). A collaborator can stage and submit many entities across many proposals — every one of them, once published, must credit that collaborator on every entity it touched.

### What changed

**1. `models/entity.cairo`** — new field, positioned between `creator_address` and `alt_names` (struct field order matters — it's part of the Cairo calldata ABI):

```cairo
pub struct Entity {
    ...
    pub creator_address: ContractAddress,
    pub collaborators: Array<ContractAddress>,   // new
    pub alt_names: Array<ByteArray>,
    ...
}
```

Every existing `Entity { ... }` struct literal in the contracts (`EntityTrait::create_trail_entity`, `lib/level_test.cairo`'s two hardcoded test rooms) had to add `collaborators: array![]` — Cairo struct literals are exhaustive, so the compiler catches every call site.

**2. `systems/designer.cairo` — `add_collaborator` entrypoint**

```cairo
fn add_collaborator(ref self: ContractState, inst: felt252, account: ContractAddress) {
    let caller: ContractAddress = starknet::get_caller_address();
    let mut world: WorldStorage = self.world_default();
    let trail_id: u128 = world.get_entity_trail_id(inst);
    let is_trail_owner: bool = world.is_owner_of_trail(trail_id, caller);
    assert(self.is_admin(caller) || is_trail_owner, Errors::NOT_TRAIL_OWNER);
    let mut entity: Entity = world.read_model(inst);
    entity.collaborators.append(account);
    world.write_model(@entity);
}
```

Restricted to the entity's trail owner or an admin — mirrors the existing `signal_review_result` gate — so an arbitrary address can't inflate its own (or anyone's) revenue share by calling this directly. No dedup, appends unconditionally (see decision above).


**3. Client-side wiring — `packages/client/src/editor/publisher.ts`**

Two things were needed here, one of them an unrelated but blocking bug found along the way:

- **Bug fix**: `publishEntity` / `buildEntityData` build the `create_entity` calldata as a plain positional array. Since Cairo serializes structs positionally, adding `collaborators` to the struct without adding it to these arrays would silently shift every field after it (`alt_names`, `actions_keys`) — corrupting every entity write. Fixed by inserting a `resolveCollaborators(inst)` call at the right position in both functions.

  ```ts
  const resolveCollaborators = (inst: BigNumberish): bigint[] => {
      const synced = EditorData().getEntity(inst, true);   // on-chain (syncPool) state
      return (synced?.Entity?.collaborators ?? []).map((a) => num.toBigInt(a));
  };
  ```

  This always resends the **synced on-chain** collaborators list rather than whatever's in the local editable copy, because `create_entity` has no merge semantics — it overwrites the full struct. Without this, an unrelated field edit (e.g. renaming an entity) would silently wipe out every collaborator credit that entity had accrued. New entities (not yet synced) resolve to `[]`.

- **Collaborator crediting — `publishFromProposal`, Pass 3**: after the existing two passes (entity/component data, then relationships + deletions), a third pass walks every entity `inst` that had at least one **write** (not deletion) selected by the owner. If that entity already existed before this proposal (i.e. it wasn't created by this same publish — new entities already got the proposer as `creator_address` in Pass 1, no separate credit needed), it calls the new entrypoint:

  ```ts
  for (const inst of modifiedInsts) {
      if (isNewEntity(inst)) continue;
      await SystemCalls.addCollaborator(inst, proposal.proposer);
  }
  ```

  `proposal.proposer` comes straight from the `CollabProposalEvent` (set by the contract to `get_caller_address()` when the collaborator called `submit_for_review`) — the same event object the review panel already displays and that `publishFromProposal` already consumes for `creator_address` attribution.

**4. `packages/client/src/lib/systemCalls.ts`** — new `addCollaborator(inst, account)` function, dispatched directly (not through `dispatchDesignerCall`, which assumes the entrypoint's `args` serialize as a single `Array<T>` parameter's contents — `add_collaborator` takes two independent scalar params, so it needs its own `CallData.compile([inst, account])` call, same pattern as `signalReviewResult` / `grantAccessToTrail`).

### Key files (Part 1)

| File | Role |
|---|---|
| `packages/contracts/src/models/entity.cairo` | `collaborators: Array<ContractAddress>` field on `Entity` |
| `packages/contracts/src/systems/designer.cairo` | `add_collaborator` entrypoint, owner/admin-gated |
| `packages/contracts/src/lib/level_test.cairo` | Test fixtures updated for the new struct field |
| `packages/client/src/editor/publisher.ts` | `resolveCollaborators`, calldata fix in `publishEntity`/`buildEntityData`, Pass 3 in `publishFromProposal` |
| `packages/client/src/lib/systemCalls.ts` | `SystemCalls.addCollaborator` |

---

## Part 2 — Revenue distribution formula (proposal, not yet implemented)

### The existing money path

This isn't new infrastructure — it hooks into a fee mechanism that's already live:

- **`packages/contracts/src/systems/actions_token.cairo`** — `actions_token` is a soulbound ERC-20 ("O'Ruggin Trail Actions") that players spend to act. `charge_player_actions` (lines 318–334) is where a fee gets collected on every successful command.
- Today it credits **100% to the trail owner**:
  ```cairo
  fn charge_player_actions(ref self: ContractState, player_address: ContractAddress, trail_id: u128, actions_amount: u128, game_id: u128) {
      ...
      if (trail_id.is_non_zero()) {
          let owner: ContractAddress = world.trail_token_dispatcher().owner_of(trail_id.into());
          world.set_actions_collected_on_content(owner, actions_amount);
      }
      // TODO: share with creator
      // TODO: not from ADMIN
      world.spent_actions(player_address, actions_amount, game_id);
      self.erc20.burn(player_address, actions_amount.into());
  }
  ```
  The `// TODO: share with creator` at line 328 is the exact gap this proposal fills.
- **`packages/contracts/src/systems/prompt.cairo`** (lines 69–74) is the call site. It currently derives `trail_id` from the *player's own location*, not from the command's target object — there's no per-entity granularity yet, only per-trail.
- **`ActionsReward`** (`models/actions_config.cairo`) is the existing claimable-balance ledger, currently keyed by a single address (the trail owner), paid out via `claim_rewards` / `send_rewards`. This is the accrue-and-claim half already built — Part 2 reuses it rather than inventing a parallel payout system.
- **`command.get_nouns()`** (`types/command_type.cairo:154`) is the hook for multi-object splitting — every noun token in the command, each with `.target` already resolved to an `Entity` inst by the parser. "use door" → one noun. "give token to officer" → two. (Correction: an earlier version of this doc cited `get_targets()` at line 182 for this — that function actually does the opposite, returning noun tokens whose target is still **unresolved**, presumably for error-reporting. `get_nouns()` is the right source.)

### The split formula

**Fixed base**: owner 25%, creator 25%, always — regardless of collaborator count.

**The remaining 50%** ("the pool") splits recursively every time a new collaborator is credited. Each pool-split event divides the current pool in half:
- **Half A** — redistributes the *entire previous pool distribution*, scaled to half its size (owner and creator keep getting a shrinking cut of the pool on top of their fixed base; existing collaborators keep a shrinking cut too).
- **Half B** — a fresh 25%-of-total split evenly across the collaborators known at that point.

As a recursion (fractions of 1.0):

```
base(owner) = base(creator) = 0.25
pool(0)  = { owner: 0.25, creator: 0.25 }                          # no collaborators: pool folds back to owner+creator
pool(n)  = 0.5 × pool(n-1)  +  { 0.25 split evenly across n collaborators }
total(n) = base + pool(n)
```

Closed form (owner = creator by symmetry; `n` = size of `collaborators`, i.e. total contribution *events*, not unique addresses — consistent with Part 1's "always append, no dedup"):

```
owner(n) = creator(n) = 0.25 × (1 + 0.5ⁿ)
contributor_k(n)      = 0.25 × Σ_{m=k}^{n} 0.5^(n-m) / m        (k = 1-indexed join order)
```

Worked example, n=3:

| party | share |
|---|---|
| owner | 28.125% |
| creator | 28.125% |
| contributor 1 (joined first) | 20.83% |
| contributor 2 | 14.58% |
| contributor 3 (joined last) | 8.33% |

Earlier contributors keep out-earning later ones **even at the same collaborator count** — every new join reweights the whole pool, and being present for more of those reweightings compounds. This asymmetry was the original design goal — see the note below on what actually shipped.

### On-chain accounting: superseded by a simpler design

An earlier version of this section specified a settle-on-join accumulator (`EntityRevenuePool` + per-collaborator `weight`/`checkpoint` state, an accumulator index, a `claim()`-style entrypoint) to reproduce the join-order-weighted formula above in O(1) per action. After review, that was judged to be over-engineering it — real storage, a state-management surface, and a settle step, for a feature that doesn't strictly need persisted state.

**What actually shipped instead** (full detail in [revenue-distribution-implementation-plan.md](revenue-distribution-implementation-plan.md)): no new models, no settle step. `charge_player_actions` computes and credits owner, creator, and every current collaborator directly into the existing `ActionsReward` ledger, in one pass, every action — the only claim path is the `claim_rewards`/`send_rewards` flow that already existed. The trade-off: the collaborator pool splits **flat and even** across current collaborators rather than by join order, because reproducing the join-order weighting above with zero stored state would cost O(n²) per action (a join-history sum for every collaborator, every command) — not viable on the hot path. Owner/creator's `0.25 × (1 + 0.5ⁿ)` formula is unaffected either way; it was already a pure function of `n`.

The worked n=3 table above (28.125% / 28.125% / 20.83% / 14.58% / 8.33%) describes the *original* join-order-weighted goal. What ships instead gives owner/creator the same 28.125%/28.125%, and splits the remaining 43.75% **evenly** — 14.58% to each of the three collaborators, not front-loaded by join order. If join-order weighting turns out to matter later, the accumulator design is the way to get it back; it needs the state this version deliberately avoids.

### Multi-object actions

For commands with more than one target ("put the book in the bag", "give token to officer"), resolve `command.get_nouns()` in `prompt.cairo` before charging (each noun's `.target` is already a resolved entity inst), split `actions_amount` flat across the targets (a "give X to Y" verb reasonably weighting the recipient higher than the item is a real product call for later, not hardcoded here), and run **each target's slice independently** through the owner/creator/collaborator split, using that target entity's own `n`, `trail_id`, and `creator_address`. A single-target command is the degenerate one-target case of the same code path — no special-casing needed.

### Defaults chosen without a separate round-trip

- Fixed-point precision: 1e18, matching the codebase's existing `CONST::ETH_TO_WEI` convention.
- Multi-object default weight: flat split across however many targets a command resolves.
- Rounding dust from integer division: negligible at 1e18/action-cost scale — not worth a separate sweep mechanism.

### Open work — not yet built

See [revenue-distribution-implementation-plan.md](revenue-distribution-implementation-plan.md) for the current, phased, step-by-step checklist — it supersedes the list that used to live here.

### Key files (Part 2)

| File | Role |
|---|---|
| `packages/contracts/src/systems/actions_token.cairo` | `charge_player_actions` — where the fee currently goes 100% to trail owner |
| `packages/contracts/src/systems/prompt.cairo` | Call site — needs to pass resolved target entity/entities instead of only `trail_id` |
| `packages/contracts/src/models/actions_config.cairo` | `ActionsConfig`/`ActionsReward` models |
| `packages/contracts/src/types/command_type.cairo` | `Command::get_nouns()` — multi-object resolution |
| `packages/contracts/src/models/entity.cairo` | `creator_address` / `collaborators` — inputs to the split |
| `packages/contracts/src/systems/designer.cairo` | `add_collaborator` — two small guard-line additions, see implementation plan |
