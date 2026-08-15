# Monetization — Revenue Distribution Between Owner, Creator & Collaborators

This document covers the feature end-to-end: **both parts are shipped** — collaborator tracking (Part 1) and the actual revenue split on player actions (Part 2), the latter feature-gated behind `ActionsConfig.revenue_split_enabled` (default `false`) pending a soak-test/rollout decision. Full step-by-step build record, including the real final code and lessons learned mid-implementation, is in [revenue-distribution-implementation-plan.md](revenue-distribution-implementation-plan.md).

---

## The idea in one paragraph

Every entity (door, officer, token, ...) in the world has a `creator_address` (who first authored it) and a `collaborators` list (who has since modified it). When a player spends an action-fee interacting with that entity, the fee splits between the **trail owner** (hosts the content), the **creator** (authored the object), and any **collaborators** (touched it since) — instead of the pre-Part-2 behavior, where 100% went to the trail owner. Part 1 builds the bookkeeping (who touched what). Part 2 implements how the money actually splits and accrues on-chain, live behind a feature flag.

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

## Part 2 — Revenue distribution formula (shipped, feature-gated)

### The money path this hooks into

Not new infrastructure — it extends a fee mechanism that was already live:

- **`packages/contracts/src/systems/actions_token.cairo`** — `actions_token` is a soulbound ERC-20 ("O'Ruggin Trail Actions") that players spend to act. `charge_player_actions` is where a fee gets collected on every successful command.
- **Before Part 2**, it credited 100% to the trail owner unconditionally, with a literal `// TODO: share with creator` marking the gap. **Now**, it takes a `targets: Array<felt252>` parameter (resolved entity insts) — empty targets preserve the old 100%-to-owner behavior exactly (object-less commands like "look"); non-empty targets run the split formula below, once per target. See [revenue-distribution-implementation-plan.md](revenue-distribution-implementation-plan.md) for the exact shipped code.
- **`packages/contracts/src/systems/prompt.cairo`** is the call site. It reads `ActionsConfig.revenue_split_enabled` and only resolves/passes real targets when the flag is on — while off (the current default), it passes an empty array regardless of what the command resolved, so behavior stays byte-for-byte identical to before Part 2 until the flag is explicitly flipped.
- **`ActionsReward`** (`models/actions_config.cairo`) is the existing claimable-balance ledger, keyed by address, paid out via `claim_rewards` / `send_rewards` — unchanged by Part 2, just written to more often (once per recipient per targeted action instead of once for the owner). Full claim mechanics in [How the revenue gets claimed](#how-the-revenue-gets-claimed) below.
- **`command.get_nouns()`** (`types/command_type.cairo:154`) is the hook for multi-object splitting — every noun token in the command, each with `.target` already resolved to an `Entity` inst by the parser. "use door" → one noun. "give token to officer" → two. Wrapped in `Command::get_action_targets()` (`types/command_type.cairo`), which filters to only the resolved (nonzero-target) nouns. (Correction, kept for history: an earlier version of this doc cited `get_targets()` for this — that function actually does the opposite, returning noun tokens whose target is still **unresolved**, presumably for error-reporting. `get_nouns()` is the right source.)

### How the revenue gets claimed

Owner, creator, and every collaborator go through the **same** path once credited — nothing new needed for Part 2, since it's the same ledger `charge_player_actions` already writes to today for the trail owner. It's a few hops, spanning two packages:

**1. Credit lands in `ActionsReward`** (`models/actions_config.cairo:21-27`) — `set_actions_collected_on_content(address, amount)` increments `collected_actions_amount` for that address, a running total in the same "actions" currency the player spent, keyed only by address (not per-entity). Part 2 calls this once for the owner, once for the creator, and once per collaborator, per targeted action — where today it's called once, for the owner only.

**2. Not directly withdrawable — it's a batched claim** (`actions_token.cairo:375-385`) — `claimable = collected_actions_amount - claimed_actions_amount` converts to a **whole-batch reward count**: `rewards_count = (claimable / ETH_TO_WEI) / trail_reward_actions_count`. `trail_reward_actions_count` defaults to 20 (`CREATOR_REWARD_ACTIONS_COUNT`, `constants/appchain.cairo:13`, admin-settable via `set_trail_reward_actions_count`). A party needs at least 20 whole "actions" worth of accrued credit before they can claim anything at all — under the flat-split formula this plan adopts, a collaborator on a lightly-used entity (or one of many collaborators splitting a thin pool) could sit at zero claimable for a long time.

**3. `claim_rewards(rewards_count)`** (`actions_token.cairo:215-232`) — caller-facing; anyone with a nonzero claimable balance calls this for themselves. It marks that many actions as `claimed_actions_amount` (so they can't be claimed twice), then sends a cross-chain message via `send_message_to_l1_syscall` (`_send_message`, `actions_token.cairo:415`) to `actions_config.sn_contract`, requesting `rewards_count` `CREATOR_REWARD`-type permits be minted for the caller. This appchain contract's job ends here — nothing is paid out yet.

**4. The message lands on Starknet, in a different package** — `packages/starknet/src/systems/permit_token.cairo`'s `consume_message` mints an actual ERC-721 "permit" token (`PermitTokenInfo`) to the recipient. This is a real, tradeable NFT (royalties, `max_supply`, built on `nft_combo`'s `ERC721ComboComponent`) — at this point the reward is a holdable asset, not just a ledger number.

**5. The permit can be "used"** (`permit_token.cairo`, `_use_permit`) — marks it consumed and mints actions back onto the L3/appchain side for whoever holds it. So the round trip is: spend actions → collect credit in `ActionsReward` → batch-claim into an NFT permit → optionally redeem that permit back into more spendable actions (or hold/trade the NFT itself).

There is also `send_rewards` (`actions_token.cairo:281-294`) — owner-of-contract-only, a manual promo/airdrop tool for sending `FREE_REWARD`-type permits. Not part of the normal creator/collaborator flow; nobody calls it for themselves.

**Nothing about this changes for Part 2.** The claim path doesn't know or care *why* an address has a balance — crediting three-plus addresses instead of one per action is the only change; everything downstream of `set_actions_collected_on_content` is untouched.

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

**Two guardrails on `add_collaborator`** (full detail in the implementation plan's Phase 2): a trail owner naming their own second wallet as a "collaborator" would otherwise let them double-dip into the pool at the real creator's expense — e.g. at `n=0→1`, owner's true take goes from 50% to 62.5% for free. One line (`assert(account != owner, ...)`) blocks the naive version of that; it doesn't stop a fresh unlinked wallet, which is a named, accepted trust assumption rather than a solved problem. A `MAX_COLLABORATORS` cap also bounds the collaborator-crediting loop in `charge_player_actions`, since — under this flat-split design — that loop runs on *every action* against the entity, not just at join time, so it bounds what every player pays per command, not just what the owner pays once.

### Multi-object actions

For commands with more than one target ("put the book in the bag", "give token to officer"), resolve `command.get_nouns()` in `prompt.cairo` before charging (each noun's `.target` is already a resolved entity inst), split `actions_amount` flat across the targets (a "give X to Y" verb reasonably weighting the recipient higher than the item is a real product call for later, not hardcoded here), and run **each target's slice independently** through the owner/creator/collaborator split, using that target entity's own `n`, `trail_id`, and `creator_address`. A single-target command is the degenerate one-target case of the same code path — no special-casing needed.

### Worked examples: real commands over a playthrough

Both examples use the formula that actually ships (flat split across collaborators, not the join-order-weighted table above — see [On-chain accounting: superseded by a simpler design](#on-chain-accounting-superseded-by-a-simpler-design)), with `action_cost_amount` at its default of 1 action per command.

**One important framing point before the numbers**: `ActionsReward` accrues *cumulatively across every player who ever plays that trail*, not per playthrough. A single player's 5–10 uses of an object in one session is a tiny slice of what that object earns over its lifetime — the totals below are per-playthrough contributions toward a much larger running total, not a ceiling on what anyone eventually earns.

#### Ex1 — single object, "use gangplank" — owner, creator, 2 collaborators (n=2)

One target, so the full action fee goes to this one entity — no cross-object split first.

```
decay = 0.5² = 0.25
owner  = creator = 1 × (1 + 0.25) / 4 = 0.3125   → 31.25% each
pool   = 1 − 0.3125 − 0.3125 = 0.375             → 37.5%
each collaborator = 0.375 / 2 = 0.1875           → 18.75% each
```

| Party | Share per use | After 5 uses | After 10 uses |
|---|---|---|---|
| Owner | 31.25% (0.3125 actions) | 1.5625 actions | 3.125 actions |
| Creator | 31.25% (0.3125 actions) | 1.5625 actions | 3.125 actions |
| Collaborator 1 | 18.75% (0.1875 actions) | 0.9375 actions | 1.875 actions |
| Collaborator 2 | 18.75% (0.1875 actions) | 0.9375 actions | 1.875 actions |

None of this reaches the 20-action claim batch (see [How the revenue gets claimed](#how-the-revenue-gets-claimed)) from one playthrough alone — at this rate, the gangplank needs **64 total uses across all players** before its owner or creator can claim even one reward batch, and **107 total uses** before either collaborator can. Every additional collaborator on the same entity would push that further out, since the pool keeps splitting further while owner/creator's floor (25% base each) never shrinks below `0.25 × 1 = 25%` of every use.

#### Ex2 — two objects, "show id to officer" — officer has owner, creator, 3 collaborators (n=3)

Two targets, so the fee splits flat 50/50 across "id" and "officer" *before* either object's own owner/creator/collaborator split runs. Numbers below are for the **officer** side only (the side specified); "id" goes through the identical mechanic independently, using its own entity's `creator_address`/`collaborators`/trail owner (not given here, so not worked).

```
per_target (officer's half) = 0.5 actions
decay = 0.5³ = 0.125
owner  = creator = 0.5 × (1 + 0.125) / 4 = 0.140625   → 28.125% of officer's half, 14.0625% of the full fee
pool   = 0.5 − 0.140625 − 0.140625 = 0.21875          → 43.75% of officer's half, 21.875% of the full fee
each of 3 collaborators = 0.21875 / 3 ≈ 0.072917      → 14.583% of officer's half, ≈7.29% of the full fee
```

| Party (officer's cut only) | Share per use (% of full fee) | After 2 uses | After 3 uses |
|---|---|---|---|
| Owner | 14.0625% (0.140625 actions) | 0.28125 actions | 0.421875 actions |
| Creator | 14.0625% (0.140625 actions) | 0.28125 actions | 0.421875 actions |
| Collaborator 1 | ≈7.29% (0.072917 actions) | 0.145833 actions | 0.21875 actions |
| Collaborator 2 | ≈7.29% (0.072917 actions) | 0.145833 actions | 0.21875 actions |
| Collaborator 3 | ≈7.29% (0.072917 actions) | 0.145833 actions | 0.21875 actions |

Splitting across two objects roughly halves everyone's per-use take on the officer side compared to Ex1's single-object case, on top of the pool already being divided three ways instead of two — the claim threshold moves out accordingly: **143 total uses** of this exact two-object command before the officer's owner/creator can claim, **275 total uses** before any one of its three collaborators can. Low-traffic multi-object interactions like this are the slowest-accruing case in the model — worth keeping in mind when judging whether a given collaborator's cut is meaningful in practice versus mostly symbolic.

### Defaults chosen without a separate round-trip

- Fixed-point precision: 1e18, matching the codebase's existing `CONST::ETH_TO_WEI` convention.
- Multi-object default weight: flat split across however many targets a command resolves.
- Rounding dust from integer division: negligible at 1e18/action-cost scale — not worth a separate sweep mechanism.

### Status — shipped, behind a flag

All of Phases 1–3 in [revenue-distribution-implementation-plan.md](revenue-distribution-implementation-plan.md) are implemented and tested (9 passing tests in `packages/contracts/src/tests/actions_revenue_test.cairo`, including two that drive a real `"read paper"` command through the full lexer/dictionary/reactable pipeline, not synthetic input). `ActionsConfig.revenue_split_enabled` defaults to `false`, so none of this affects production payouts until an admin explicitly calls `set_revenue_split_enabled(true)`. See the implementation plan for the exact final code, the full test list, and a "Lessons from implementation" section covering the non-obvious issues hit along the way (Cairo type inference, Dojo WRITER-role requirements in tests, `game_id` assumptions, gas cost of naive test setups).

### Key files (Part 2)

| File | Role |
|---|---|
| `packages/contracts/src/systems/actions_token.cairo` | `charge_player_actions` — split formula; `set_revenue_split_enabled` admin entrypoint |
| `packages/contracts/src/systems/prompt.cairo` | Reads `ActionsConfig.revenue_split_enabled`, conditionally resolves and passes target entities |
| `packages/contracts/src/models/actions_config.cairo` | `ActionsConfig` (+ `revenue_split_enabled` field) / `ActionsReward` models |
| `packages/contracts/src/types/command_type.cairo` | `Command::get_nouns()` / `get_action_targets()` — multi-object resolution |
| `packages/contracts/src/models/entity.cairo` | `creator_address` / `collaborators` — inputs to the split |
| `packages/contracts/src/systems/designer.cairo` | `add_collaborator` — sybil guard + `MAX_COLLABORATORS` cap |
| `packages/starknet/src/systems/permit_token.cairo` | L2 side of the claim path — mints the `CREATOR_REWARD` NFT permit `claim_rewards` requests, and redeems it back into actions via `_use_permit` |
| `packages/contracts/src/tests/actions_revenue_test.cairo` | All Part 2 tests, including the full-pipeline ones |
