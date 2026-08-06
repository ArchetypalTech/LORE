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
- **`command.get_targets()`** (`types/command_type.cairo:182`) already resolves a command's noun(s) to their target `Entity` inst(s). "use door" → one target. "give token to officer" → two. This is the hook for multi-object splitting.

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

Earlier contributors keep out-earning later ones **even at the same collaborator count** — every new join reweights the whole pool, and being present for more of those reweightings compounds. This asymmetry is deliberate (confirmed) and is the reason the on-chain accounting below can't just divide the pool evenly per collaborator.

### On-chain accounting: settle-on-join

Two decisions shape this:

1. **Accrue + claim**, not synchronous transfer — every action just increments an internal balance; parties call `claim()` when they want to withdraw. Necessary because a single command could otherwise trigger a handful of ERC-20 transfers on the hot path.
2. **Future-only reweighting** — a new collaborator changes the split applied to revenue *from that point forward*. Balances a collaborator has already earned (even if unclaimed) are never retroactively shrunk by someone else joining later.

Naively replaying the recursion on every single action (or writing to every collaborator's balance on every action) is unbounded — an entity with many edits would make every future "use door" cost more gas than the last. The fix is the same accumulator pattern staking-reward contracts use (Synthetix / MasterChef "reward-per-share"), split into a cheap hot path and a rare, bounded-by-that-entity's-own-size cold path:

**Owner / creator** — `owner(n)` / `creator(n)` are pure closed-form functions of `n` alone (no history dependency). Credit them directly into the existing `ActionsReward` ledger every action. O(1), no accumulator needed.

**Collaborator pool** — needs one accumulator per entity plus one slot record per collaborator (parallel to the existing `collaborators: Array<ContractAddress>`, one record per array slot, including duplicate slots for repeat contributors):

| Storage | Scope | Fields |
|---|---|---|
| Entity pool state | per entity | `pool_index: u256` (fixed-point, 1e18), `total_weight: u256` |
| Collaborator slot | per array index | `weight: u256`, `checkpoint: u256`, `claimable: u256` |

| Operation | Frequency | Cost | What happens |
|---|---|---|---|
| **Charge a fee** | every action | **O(1)**, independent of collaborator count | `pool_index += pool_amt / total_weight`. One write. No per-collaborator touch. |
| **`add_collaborator`** | one per join (rare) | O(n) in *that entity's own* collaborator count only | For every existing slot: settle `claimable_k += weight_k × (pool_index − checkpoint_k)` — this locks in everything earned so far, so it can never be touched again (satisfies "future-only"). Then recompute every slot's weight for the new generation: `weight_k(n_new) = 0.5 × weight_k(n_old) + 1/n_new` (new slot gets `1/n_new`), reset `pool_index = 0`, recompute `total_weight`. |
| **`claim()`** | collaborator-initiated (pull) | O(slots that address holds for that entity) | Settle any not-yet-settled slots the same way, sum, pay out via the existing `claim_rewards`/`send_rewards` path, zero the claimable. |

The O(n) work only ever happens on a join — a rare, owner/admin-gated event — never on the hot path of a player typing a command. This is exactly the recursive percentage table above, reproduced exactly at read time; the O(n) cost of "everyone's weight shifts when someone joins" gets paid once, at join time, instead of being re-paid on every action against that entity.

### Multi-object actions

For commands with more than one target ("put the book in the bag", "give token to officer"), resolve `command.get_targets()` in `prompt.cairo` before charging, apply a weight table across the targets (default: flat 50/50 — a "give X to Y" verb reasonably weighting the recipient higher than the item is a real product call, not something to hardcode blindly), and run **each target's slice independently** through the owner/creator/pool split above, using that target entity's own `n`, `trail_id`, and `creator_address`. A single-target command is the `n=1` degenerate case of the same code path — no special-casing needed.

### Defaults chosen without a separate round-trip

- Fixed-point precision: 1e18, matching the codebase's existing `CONST::ETH_TO_WEI` convention.
- Multi-object default weight: flat 50/50 until per-action-type weighting is worth building.
- Rounding dust from `pool_amt / total_weight` division: absorbed into `pool_index` precision loss, negligible at 1e18 scale — not worth a separate sweep mechanism initially.

### Open work — not yet built

- [ ] `EntityRevenue`-style model(s): per-entity `pool_index`/`total_weight`, per-slot `weight`/`checkpoint`/`claimable`.
- [ ] Rewrite `add_collaborator` to perform the settle-then-reweight step (currently just appends — see Part 1).
- [ ] Extend `charge_player_actions` (or add a sibling entrypoint) to split `actions_amount` across target entities and credit owner/creator/pool per entity, instead of 100% to the trail owner.
- [ ] Wire `command.get_targets()` through `prompt.cairo` so the charge call knows which entity/entities to credit, not just the player's trail.
- [ ] `claim()` entrypoint (or extend `claim_rewards`) for collaborators to settle + withdraw their per-entity slot balances.
- [ ] Tests: the recursive formula (verify the worked n=3 table above), settle-on-join correctness (a claim before vs. after a new join should differ only in *future* accrual, never past), multi-object weight split.

### Key files (Part 2)

| File | Role |
|---|---|
| `packages/contracts/src/systems/actions_token.cairo` | `charge_player_actions` — where the fee currently goes 100% to trail owner; `ActionsReward` claim ledger to extend |
| `packages/contracts/src/systems/prompt.cairo` | Call site — needs to pass target entity/entities instead of only `trail_id` |
| `packages/contracts/src/models/actions_config.cairo` | `ActionsConfig`/`ActionsReward` models |
| `packages/contracts/src/types/command_type.cairo` | `Command::get_targets()` — multi-object resolution |
| `packages/contracts/src/models/entity.cairo` | `creator_address` / `collaborators` — inputs to the split |
| `packages/contracts/src/systems/designer.cairo` | `add_collaborator` — needs the settle-then-reweight rewrite |
