# Revenue Distribution — Implementation Plan

Step-by-step plan for building Part 2 of [monetization-revenue-distribution.md](monetization-revenue-distribution.md) (the split formula and settle-on-join accounting are defined there — this document is the "how to actually build it," in order, with concrete structs/signatures). Each phase is independently landable and testable before moving to the next; nothing here should be built out of order because later phases depend on earlier ones compiling and being tested first.

---

## Phase 0 — Land and verify Part 1

Everything downstream reads `Entity.collaborators` and calls the current `add_collaborator`. Before extending it, confirm it actually compiles and behaves as designed — this was written but the verification build got interrupted mid-session.

- [X] `sozo build` in `packages/contracts`. Fix any errors from the `add_collaborator` owner/admin gate (`designer.cairo`).
- [X] Add a Cairo test (`packages/contracts/src/tests/`, follow the pattern in `collab_proposal_test.cairo`): a non-owner, non-admin caller invoking `add_collaborator` reverts with `NOT_TRAIL_OWNER`; the trail owner and an admin both succeed.
- [X] Regenerate TS bindings (`models.gen.ts` / `contracts.gen.ts`) if the build changed the ABI, and confirm the client (`publisher.ts` Pass 3) still round-trips against a local devnet — publish a collaborator proposal on a test trail, confirm `collaborators` grows.

**Exit criteria**: full local flow (submit proposal → owner publishes → `collaborators` array updated) verified end-to-end on devnet.

---

## Phase 1 — New models: `EntityRevenuePool` + `CollaboratorSlot`

Two new models, not one — this is a correction from the first draft, which stored per-slot weights as arrays inside a single model. Dojo rewrites a model's entire array field on every `write_model` call, so "settle just these two slots" would have cost the same as "settle all fifty," defeating the entire point of Phase 3's cheap standalone claim path. Composite-keyed models let each slot be read/written independently — see [Gas, Hashing & Security](#gas-hashing--security) below for the full reasoning.

**New file: `packages/contracts/src/models/entity_revenue.cairo`**

```cairo
use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, Introspect)]
#[dojo::model]
pub struct EntityRevenuePool {
    #[key]
    pub inst: felt252,
    /// Fixed-point (1e18) reward-per-weight accumulator. Monotonically
    /// increasing — never decreases, never resets.
    pub pool_index: u128,
    /// Fixed-point (1e18) = 0.5^n, where n = collaborators.len(). Halved on
    /// every add_collaborator call. Lets owner/creator shares be computed
    /// in O(1) without recomputing a power on the hot (charge) path.
    pub decay: u128,
    /// Sum of all current slot weights — the divisor for pool_index increments.
    /// Zero when there are no collaborators yet (n == 0).
    pub total_weight: u128,
}

#[derive(Copy, Drop, Serde, Introspect)]
#[dojo::model]
pub struct CollaboratorSlot {
    #[key]
    pub inst: felt252,
    #[key]
    pub slot_index: u32,       // == index into Entity.collaborators
    pub weight: u128,
    pub checkpoint: u128,      // pool_index snapshot at last settle
}
```

- `u128`, not `u256` — matches the existing convention (`ActionsConfig.action_cost_amount`, `ActionsReward.collected_actions_amount` are both `u128`) and roughly halves storage cost per field. Headroom: `pool_index` grows by `pool_share × PRECISION / total_weight` per charged action — with `PRECISION = 1e18` and realistic per-action amounts on the same order, that's ~1e18 per action against `u128::MAX ≈ 3.4e38`, room for ~10^20 actions before overflow. Not a practical concern, but the multiplication that computes each increment must be done carefully — see the mulDiv note below.
- `PRECISION: u128 = 1_000_000_000_000_000_000` — same numeric value as `CONST::ETH_TO_WEI` (`constants/constants.cairo:42`), but that constant is typed `u256` for ERC-20 amounts, so don't import it directly; declare a `u128` sibling in this module (or add one next to it in `constants.cairo` if other code ends up needing it too).
- `decay` starts at `PRECISION` (n=0 → 0.5⁰ = 1.0). `pool_index`/`total_weight` start at 0.
- `CollaboratorSlot` is written once at join time (Phase 2) and touched only by settlement (Phase 2's bulk settle, or Phase 3's targeted settle) — the charge path (Phase 4) only ever writes `EntityRevenuePool.pool_index`, never a `CollaboratorSlot`.
- Add a trait (`EntityRevenuePoolTrait`, same file) with `get_or_init(world, inst) -> EntityRevenuePool` for the "give me this entity's pool, zeroed if it doesn't exist yet" case every other phase needs.

**Registration** (required for every new model — same pattern as `CollabReviewResult`):
- `packages/contracts/src/tests/helpers.cairo` — add both `TestResource::Model(models::entity_revenue::m_EntityRevenuePool::TEST_CLASS_HASH.into())` and the equivalent `m_CollaboratorSlot::TEST_CLASS_HASH.into())` to `namespace_def()` (see line 105 for the `CollabReviewResult` precedent).
- `packages/contracts/src/lib.cairo` (or wherever `models::` module is declared) — add `pub mod entity_revenue;`.

**Exit criteria**: both models compile, register, and `get_or_init` returns a correctly-zeroed pool for an entity that's never had one. Add a small test confirming this.

---

## Phase 2 — Rewrite `add_collaborator`: settle-then-reweight

This is the only place `EntityRevenuePool` gets touched with O(n) cost — bounded by that one entity's own collaborator count, and only on a join (rare, owner/admin-gated), never on the action hot path.

**Modify `packages/contracts/src/systems/designer.cairo`** — `add_collaborator` keeps its existing signature (from Part 1), but its body changes, and the access gate gains one more check:

```cairo
const MAX_COLLABORATORS: u32 = 200; // bounds worst-case gas — see Gas section below

fn add_collaborator(ref self: ContractState, inst: felt252, account: ContractAddress) {
    let caller: ContractAddress = starknet::get_caller_address();
    let mut world: WorldStorage = self.world_default();
    let trail_id: u128 = world.get_entity_trail_id(inst);
    let owner: ContractAddress = world.trail_token_dispatcher().owner_of(trail_id.into());
    assert(self.is_admin(caller) || caller == owner, Errors::NOT_TRAIL_OWNER);
    assert(account != owner, Errors::INVALID_COLLABORATOR); // blocks the naive self-add — see Gas/Security section

    let mut entity: Entity = world.read_model(inst);
    let n_old: u32 = entity.collaborators.len();
    assert(n_old < MAX_COLLABORATORS, Errors::TOO_MANY_COLLABORATORS);
    let mut pool: EntityRevenuePool = world.get_or_init_revenue_pool(inst);

    // Settle every existing slot at the CURRENT pool_index (locks in everything
    // earned so far — future-only reweighting), then reweight it for the new
    // generation, in one pass: one read + one write per existing slot.
    let n_new: u128 = (n_old + 1).into();
    let mut new_total_weight: u128 = 0;
    let mut i: u32 = 0;
    while i < n_old {
        let mut slot: CollaboratorSlot = world.read_model((inst, i));
        let delta: u128 = pool.pool_index - slot.checkpoint; // pool_index only ever grows — see invariant note
        if delta.is_non_zero() {
            let owed: u256 = u256 { low: slot.weight, high: 0 } * u256 { low: delta, high: 0 }
                / u256 { low: PRECISION, high: 0 };
            world.set_actions_collected_on_content(*entity.collaborators.at(i), owed.try_into().unwrap());
        }
        slot.weight = slot.weight / 2 + PRECISION / n_new;
        slot.checkpoint = pool.pool_index;
        world.write_model(@slot);
        new_total_weight += slot.weight;
        i += 1;
    }

    // New slot for the joining collaborator.
    let new_slot = CollaboratorSlot { inst, slot_index: n_old, weight: PRECISION / n_new, checkpoint: pool.pool_index };
    world.write_model(@new_slot);
    new_total_weight += new_slot.weight;

    entity.collaborators.append(account);
    world.write_model(@entity);

    pool.total_weight = new_total_weight; // summed exactly during the loop above, not derived via total_weight/2 + PRECISION
    pool.decay = pool.decay / 2;
    world.write_model(@pool);
}
```

- **Widened multiply**: `weight × delta` is computed by casting both `u128` operands up to `u256` before multiplying, then dividing, then narrowing the result back down with `.try_into().unwrap()`. Multiplying two `u128` values directly can overflow `u128` well before the mathematically correct result would — this is the standard "mulDiv" pattern from fixed-point math libraries (the exact class of bug behind more than one real DeFi exploit), and it applies everywhere this doc multiplies a weight/share by a delta/amount before dividing (Phase 3, Phase 4 below too).
- `total_weight` is summed exactly during the loop that's already touching every slot, rather than derived from the closed-form shortcut `total_weight/2 + PRECISION` — summing is exact and costs nothing extra (the loop is already O(n)), whereas the shortcut would compound rounding drift from repeated `PRECISION/n` truncation across many joins.
- `assert(account != owner, ...)` blocks the single most naive form of a real economic attack (an owner adding their own address as a "collaborator" to double-dip into the pool at the creator's expense) but does **not** stop a determined owner from using a fresh, unlinked address instead — see [Gas, Hashing & Security](#gas-hashing--security) for the actual mitigation options.

- [ ] Implement exactly as above (this version, unlike the first draft, is directly translatable to real Cairo — no array-mutation caveats left to resolve).
- [ ] Unit test: create an entity, call `add_collaborator` three times with three different addresses, assert `CollaboratorSlot.weight`/`EntityRevenuePool.total_weight`/`.decay` match the closed-form table in the Part 2 doc (n=1: contributor1's weight == `total_weight` == `PRECISION`; n=2: contributor1's weight is double contributor2's; n=3: weights are in ratio 20.83 : 14.58 : 8.33).
- [ ] Unit test: settlement into `ActionsReward` — charge some `pool_index` between joins (Phase 4 needed for a full integration test here; until then, manually set `pool.pool_index` in the test to isolate this phase).
- [ ] Unit test: the `MAX_COLLABORATORS` cap reverts on the 201st `add_collaborator` call for a single entity.
- [ ] Unit test: `add_collaborator(inst, owner_address)` reverts with `INVALID_COLLABORATOR`.

**Exit criteria**: three sequential joins on a test entity reproduce the exact percentages in the Part 2 doc's worked n=3 table (within fixed-point rounding tolerance).

---

## Phase 3 — Settle/claim entrypoint for stand-alone claims

Collaborators need a way to realize earnings **without** waiting for the next join (which might never happen again on a popular, stable entity).

**Add to `designer.cairo`** (`IDesigner`/`IDesignerPublic` + impl, same pattern as `add_collaborator`):

```cairo
fn settle_collaborator_slots(ref self: TContractState, inst: felt252, slot_indices: Array<u32>);
```

- Permissionless (any caller) — the payout destination is fixed by whichever address is stored at that slot, not by the caller, so there's no way to redirect funds by calling this for someone else. This means the trail owner, an off-chain relayer, or the collaborator themselves can all pay the gas to flush earnings into `ActionsReward`.
- Body: for each `slot_index` in `slot_indices`, first `assert(slot_index < entity.collaborators.len(), Errors::INVALID_SLOT)` — bound-check explicitly rather than relying on the fact that reading a nonexistent `CollaboratorSlot` would harmlessly return a zeroed default (`weight=0` → `owed=0`). Explicit bounds give a clear revert instead of a silent no-op, which matters for a caller debugging why nothing happened. Then the same settle step as Phase 2's loop (compute `owed` via the widened `u256` mulDiv, credit via `set_actions_collected_on_content`, bump checkpoint) — but only for the requested indices, not all of them, so cost is genuinely O(len(slot_indices)) now that slots are composite-keyed models rather than array elements.
- Duplicate indices in the same call are safe and idempotent: the first occurrence advances that slot's checkpoint to the current `pool_index`, so a second occurrence in the same call computes `delta == 0` → `owed == 0`. No double-credit risk, no need to de-duplicate the input array defensively.
- Client already knows which slot indices belong to which address (it's watching `Entity.collaborators` via Torii sync) — no on-chain "find my slots" lookup needed, consistent with how the rest of the client/contract split already works (client resolves indices, contract validates/executes).
- After settlement, the existing `claim_rewards`/`send_rewards` flow in `actions_token.cairo` (unchanged) is what actually turns `ActionsReward.collected_actions_amount` into a withdrawable/claimable reward — this entrypoint only moves money from "pending in the pool" to "sitting in the existing ledger," it does not itself pay anyone.

- [ ] Implement `settle_collaborator_slots`.
- [ ] Test: settle before vs. after a subsequent join — confirm the pre-join settled amount is untouched by the later join's reweighting (this is the "future-only" guarantee from the Part 2 doc; the test that proves it).
- [ ] Test: settling the same slot twice in a row with no new action revenue in between is a no-op (checkpoint already caught up, `owed == 0`).
- [ ] Test: an out-of-range `slot_index` reverts with `INVALID_SLOT` rather than silently no-op-ing.
- [ ] Test: settling `[3, 3, 3]` (duplicate indices) in one call credits the same total as settling `[3]` once — confirms idempotency.

**Exit criteria**: a collaborator can realize their earnings at any time without needing the entity to get a new join first.

---

## Phase 4 — Wire the charge path: multi-target resolution + per-entity split

This is where real money starts flowing through the new logic instead of 100% to the trail owner. Land Phases 1–3 and their tests first — this phase is where a mistake actually costs someone money.

**4a. `packages/contracts/src/types/command_type.cairo`** — no changes needed; `Command::get_targets()` (line 182) already returns resolved target `Entity` insts.

**4b. `packages/contracts/src/systems/prompt.cairo`** — call site changes (lines 56–75). Instead of computing a single `trail_id` from the player's own location, resolve the command's targets and build a weighted list:

```cairo
let targets: Span<Token> = command.get_targets();
let target_weights: Array<(felt252, u16)> = build_target_weights(targets); // bps, sums to 10000
```

- `build_target_weights` (new helper, could live in `command_type.cairo` or a small new `lib/revenue_weights.cairo`): 0 targets → empty array (fall back to today's trail-level crediting, see below); 1 target → `[(inst, 10000)]`; 2+ targets → flat split, `10000 / targets.len()` each (remainder to the last target so weights sum exactly to 10000). Per Part 2's "Defaults chosen" section, this flat default is intentionally simple — a primary/secondary weighting table by verb/action-type is future work, not blocking this phase.
- If `targets.is_empty()`, keep calling the **existing** `charge_player_actions(player_address, trail_id, actions_amount, game_id)` unchanged — commands with no object ("look", "go north") keep today's behavior exactly. Only object-targeted commands go through the new path.

**4c. `packages/contracts/src/systems/actions_token.cairo`** — new protected entrypoint alongside (not replacing) `charge_player_actions`, so the no-target fallback path above needs zero changes to the existing function:

```cairo
fn charge_player_actions_for_targets(
    ref self: TContractState,
    player_address: ContractAddress,
    targets: Array<(felt252, u16)>,   // (entity inst, weight in bps) — sums to 10000
    actions_amount: u128,
    game_id: u128,
);
```

Body — first line must be `self._assert_caller_is_world_contract(@world);`, unchanged from `charge_player_actions` today. This is not optional: `targets`/`weight_bps` are trusted-input assumptions this function relies on (see the invariant note below), and that trust only holds because the only caller is `prompt.cairo`, itself only reachable through the world dispatcher.

Per target `(inst, weight_bps)`:
1. `target_amount: u128 = actions_amount * weight_bps.into() / 10000`.
2. Read `entity.creator_address`, `trail_owner` (via `trail_token_dispatcher().owner_of(...)`, same as Phase 2), and `pool: EntityRevenuePool`.
3. `owner_share: u128 = (u256{low: target_amount, high: 0} * u256{low: PRECISION + pool.decay, high: 0} / u256{low: 4 * PRECISION, high: 0}).try_into().unwrap()` — i.e. `0.25 × (1 + decay) × target_amount`, widened the same way as Phase 2's mulDiv. `creator_share = owner_share` (identical formula, owner and creator are symmetric by construction).
4. Credit both directly: `world.set_actions_collected_on_content(trail_owner, owner_share)`, `...(entity.creator_address, creator_share)` — reuses the existing `ActionsReward` ledger unchanged, exactly like today's single-recipient credit. **No `CollaboratorSlot` is touched here** — this step is O(1) regardless of how many collaborators the entity has.
5. `pool_share: u128 = target_amount - owner_share - creator_share`. If `pool.total_weight.is_non_zero()`: `pool.pool_index += (u256{low: pool_share, high:0} * u256{low: PRECISION, high:0} / u256{low: pool.total_weight, high:0}).try_into().unwrap()`; write the pool back. If `total_weight == 0` (n=0), `pool_share` is mathematically zero already (see Part 2 doc — the closed form collapses to 100% owner+creator when there are no collaborators), so this is a no-op in practice, not a special case that needs its own branch.

Then burn the fee from the player exactly as `charge_player_actions` already does today (`world.spent_actions`, `self.erc20.burn`) — that part is unchanged, just called once for the whole `actions_amount` regardless of how many targets it got split across.

**Invariant to assert in tests, not just trust**: `Σ target_amount` across all targets in one call `== actions_amount` (exactly — `build_target_weights`'s bps values must sum to 10000, with rounding remainder assigned to the last target rather than dropped), and per target, `owner_share + creator_share + pool_share == target_amount` exactly. Both are cheap to assert directly in the function as a defense-in-depth sanity check, not only in an external test — a failed assert here means the fee split lost or fabricated funds, which is worth reverting the whole transaction over.

- [ ] Implement `charge_player_actions_for_targets`, with the `_assert_caller_is_world_contract` gate as the first line.
- [ ] Implement `build_target_weights` + the `prompt.cairo` branch (targets vs. no-targets). Keep the weight computation entirely inside contract code driven by `command.get_targets()` — never accept a caller-supplied weight array from outside `prompt.cairo`'s own resolution, since that would let an attacker directly control the split.
- [ ] Integration test: "use door" (1 target, entity has 2 collaborators) — assert `ActionsReward` for owner/creator match the closed-form n=2 percentages of the door's `action_cost_amount`, and `EntityRevenuePool.pool_index` increased by the expected amount.
- [ ] Integration test: "give token to officer" (2 targets) — assert the fee splits 50/50 across the two entities' independent owner/creator/pool computations (different entities can have different `n`, different trails even).
- [ ] Regression test: a command with no resolvable noun target still charges 100% to the trail owner via the existing, untouched `charge_player_actions` path.
- [ ] Property/fuzz test: for randomized `n` (0–`MAX_COLLABORATORS`) and randomized `target_amount`, `owner_share + creator_share + pool_share == target_amount` holds exactly (the value-conservation invariant above).

**Exit criteria**: on devnet, a real "use door" command against a door entity with a known creator and 2 collaborators produces the exact percentages from the Part 2 doc's worked table, verified by reading `ActionsReward`/`EntityRevenuePool` after the transaction.

---

## Phase 5 — Client-side surface

Only needed once Phases 1–4 are live on a devnet worth pointing a UI at.

- [ ] Regenerate `models.gen.ts`/`contracts.gen.ts` bindings for `EntityRevenuePool` and the two new/changed entrypoints (same codegen pipeline used for every other model — see `models.gen.ts` entries referenced in [collab-implementation.md](../Collaborative%20Feature/collab-implementation.md)'s key files table for the existing pattern).
- [ ] `packages/client/src/lib/systemCalls.ts` — add `settleCollaboratorSlots(inst, slotIndices)`, following the exact pattern already used for `addCollaborator` (direct `CallData.compile`, not `dispatchDesignerCall`, since this also isn't a single-`Array<T>`-param entrypoint).
- [ ] A revenue view, scoped to what a creator/collaborator can see for their own entities: accrued-but-unsettled estimate (computable client-side from synced `EntityRevenuePool` + the address's known slot indices, same math as the contract's settle step, read-only) and a "Settle & claim" action. Where this lives in the UI (a new panel, or extending `TokenStore`/an existing dashboard) is a product decision, not scoped here — flag before starting this item specifically.

**Exit criteria**: a collaborator can see what they've earned on an entity and pull it into their claimable `ActionsReward` balance from the client, without needing to know slot indices manually.

---

## Phase 6 — Rollout

- [ ] Feature-gate: add a `revenue_split_enabled: bool` to `ActionsConfig` (mirrors the existing admin-settable fields like `action_cost_amount`), defaulting to `false`. `prompt.cairo`'s branch only calls the new `charge_player_actions_for_targets` path when enabled; otherwise everything behaves exactly as it does today. This lets Phases 1–4 be deployed and soak-tested on devnet/staging without changing production payout behavior until explicitly flipped on.
- [ ] No migration needed for existing `ActionsReward` balances — Part 2's "future-only" decision means the new logic only affects revenue from actions charged *after* it's enabled; nothing retroactively recalculates past credits.
- [ ] Once enabled, monitor: total `ActionsReward.collected_actions_amount` credited across (owner + creator + settled collaborators) for a sample of transactions should sum to the same `actions_amount` that's burned — a coded invariant worth asserting in tests, and worth spot-checking manually on staging before flipping the flag in production.

---

## Gas, Hashing & Security

Findings from re-examining the plan specifically for cost and attack surface. One of these (sybil collaborators) is a real gap in the original design, not a hardening nice-to-have — read that one first.

### The sybil-collaborator attack (the important one)

`add_collaborator` is gated to "trail owner or admin," which stops outsiders from calling it — but nothing stops the trail owner from calling it **with an address they themselves control**, claiming a fabricated "collaborator" contribution that never happened. This is exploitable for real value, not just a theoretical integrity gap:

Take an entity where owner ≠ creator, `n = 0` (no collaborators yet): owner and creator each get 50% of every action's revenue (`pool(0)` folds entirely back to them). If the owner now calls `add_collaborator(inst, sybil_address)` where `sybil_address` is a second wallet they personally control, the closed form gives `owner(1) = creator(1) = 37.5%`, `contributor1(1) = 25%` — and since the owner controls `contributor1`'s payout address too, **their real total take becomes 37.5% + 25% = 62.5%, up from 50%, entirely at the creator's expense** (whose real share just dropped from 50% to 37.5%). The owner didn't do any of the work `collaborators` is supposed to represent — they just called an entrypoint they're already allowed to call.

This isn't new access-control surface introduced by Part 2 — the trail owner already has full unilateral publishing authority over their trail (see [collab-implementation.md](../Collaborative%20Feature/collab-implementation.md)), so a maximally adversarial owner already had ways to misattribute content (e.g. publishing fabricated new entities with themselves as `creator_address`). What Part 2 changes is that this authority now has **direct, quantifiable economic value** — self-dealing via `add_collaborator` costs nothing and dilutes a real creator's cut on every future action against that entity, indefinitely.

Options, cheapest to most rigorous:

1. **Shipped in Phase 2 above**: `assert(account != owner, ...)` — blocks the single-address version of the attack (owner adding their own primary wallet) for near-zero cost. Does not stop a fresh, unlinked sybil wallet.
2. **Tie the append to a real on-chain write, not a free-standing call** — fold collaborator-crediting directly into the `create_*` write path (the way `creator_address` attribution already works for new entities: the owner passes the proposer's address as part of actually publishing their proposed data — see Part 1's `publishFromProposal` Pass 3) rather than leaving `add_collaborator` independently callable with an arbitrary address at any time, for any reason. This is close to what's already built, but doesn't fully close the gap either — an owner motivated enough to sybil could still author a throwaway edit "on behalf of" a fake collaborator address and publish it through the normal flow.
3. **Require the collaborator's cryptographic consent** — the collaborator signs an off-chain attestation (e.g. `sign(inst, trail_id, nonce)`), and `add_collaborator` verifies that signature on-chain before appending, instead of trusting the owner's say-so. This is the only option that structurally prevents the attack (a sybil address the owner controls would have to sign for itself, which is definitionally possible — it doesn't stop pure self-dealing with a *fresh* wallet, but it does stop the owner unilaterally naming *someone else's* address without that person's consent, and creates an auditable off-chain artifact). Real cost: signature verification on-chain, a nonce/replay-protection scheme, and new client UX for the collaborator to produce and hand over a signature. Scope this as its own phase if/when the trust assumption below is unacceptable for the product.

**Recommendation**: ship mitigation 1 now (cheap, already in the Phase 2 pseudocode above), and explicitly document the residual trust assumption rather than silently accepting it: **this revenue model assumes trail owners are not actively adversarial toward their own creators/collaborators** — the same trust boundary the publish-approval flow already rests on, now with money attached. Revisit mitigation 3 before this handles revenue at a scale where that assumption becomes a real incentive to violate.

### Gas: why `add_collaborator` cost grows with an entity's own collaborator count

The halving mechanic is inherent to the formula, not an implementation accident: **every existing collaborator's weight changes on every new join**, because half the pool gets redistributed across everyone-so-far each time. There is no way to make `add_collaborator` O(1) while reproducing the exact recursive percentages from the Part 2 doc — the O(n) cost has to live somewhere, and Phase 2 puts it on the join (rare, owner/admin-gated, and the entity's *own* collaborator count bounds it — it never scales with unrelated global state). The `MAX_COLLABORATORS = 200` cap in Phase 2 exists specifically so a popular, heavily-collaborated entity can't grow its join cost into "prohibitively expensive" or block-gas-limit territory — pick the actual number based on a measured `sozo` gas profile of the loop, not the placeholder above.

An alternative design exists that makes `add_collaborator` O(1) by deferring all weighting work to settle time (closed-form summation over the join range a slot has been open for, rather than incremental reweighting) — this trades "rare O(n) join" for "settle cost proportional to how long a given collaborator goes without claiming," which is arguably a *better* griefing profile (the cost is self-inflicted and bounded per-address, not imposed on the whole entity by mere popularity). It's a legitimate harder alternative, not adopted here because it requires computing `Σ 0.5^(n-m)/m` on-chain — a real per-term division inside a loop, with its own precision/gas tradeoffs, harder to audit than the linear reweight in Phase 2. Worth reconsidering if `MAX_COLLABORATORS` ever feels too restrictive in practice.

### Why composite-keyed models, precisely (gas, not just style)

Beyond Phase 1's "arrays force a full rewrite" point: Dojo derives a composite-keyed model's storage address by hashing the key tuple (Poseidon, Dojo's standard multi-key addressing — nothing custom needed on our side, and nothing to audit there, it's the same mechanism every other multi-key model in this codebase already relies on, e.g. `DescriptionText`, `Trigger`). That hash computation has a small real cost per touched slot, which is why Phase 2's bulk join-time settle (which touches every slot anyway) pays a modest constant-factor tax relative to the array design it replaced — but Phase 3's whole reason to exist is touching *only the slots a caller asks for*, and only composite keys make that genuinely O(k) instead of O(n). Given Phase 2 touches every slot regardless of storage layout, and Phase 3's cost profile only works with per-slot addressability, composite keys are the right call on balance.

**If collaborator counts ever need to go far beyond what `MAX_COLLABORATORS` bounds** (not expected at current scale, but worth naming as the standard escape hatch): a Merkle-root-based claim scheme — store only a root hash of all `(address, weight)` pairs on-chain, computed off-chain, with collaborators claiming via a Merkle proof — removes the need to store or touch individual slots on-chain at all. This is significantly more infrastructure (off-chain tree generation, an indexer to serve proofs, a root-update flow) and isn't justified unless the bounded-cap design in Phase 2 proves too restrictive.

### Overflow, precision, and the mulDiv pattern

- **Widen before multiplying, always**: every place this doc computes `weight × delta` or `amount × factor` before dividing (Phase 2's settle, Phase 4's owner/creator/pool shares) casts both `u128` operands to `u256` first. Multiplying two `u128` values natively can overflow long before the true (post-division) result would — Cairo has no implicit widening multiply, so skipping this cast is a straightforward path to silently wrong numbers, not just a revert. Every one of these call sites should have a unit test at the boundary (e.g. `weight` and `delta` both near `u128::MAX / 2`) to catch a regression that removes the widening.
- **`pool_index - checkpoint` assumes `pool_index >= checkpoint`** — true by construction (checkpoints are always assigned *from* a prior `pool_index` read, and `pool_index` only ever increases, never resets — confirmed by Phase 2/4's code above never writing a smaller value to it). Cairo's `u128` subtraction already reverts on underflow by default, so a broken invariant here fails loudly rather than wrapping silently — but it's worth a property test asserting `pool_index` is monotonically non-decreasing across a sequence of random charge/join operations, so a future refactor that violates the invariant is caught before it ships, not after.
- **Rounding dust** is negligible at realistic magnitudes: with `PRECISION = 1e18` and `action_cost_amount` defaulting to `1 ETH_TO_WEI` (`constants/config.cairo`), per-action truncation loss in `pool_share × PRECISION / total_weight` is many orders of magnitude below one unit. This stops being true only if `action_cost_amount` is ever configured down near zero — worth a minimum-value sanity bound on `set_action_cost_amount` if that admin setter is ever exposed to non-trusted callers, cheap defense-in-depth for a scenario that isn't currently reachable.

### Reentrancy and execution-model notes

Starknet transactions execute sequentially — there's no concurrent/multi-threaded state mutation to race, so "two actions landing on the same never-before-touched entity at once" isn't a real hazard the way it might read as one. The one place worth being deliberate about ordering is `charge_player_actions_for_targets`: do all `ActionsReward`/`EntityRevenuePool` state writes *before* `self.erc20.burn(...)`, mirroring `charge_player_actions`'s existing order today — not because `burn` is an untrusted external call (it's the same contract's own `ERC20Component`), but because it keeps the function's effects in a predictable checks-effects-interactions order if `erc20.burn`'s hook logic (`ERC20HooksImpl::before_update`, `actions_token.cairo:445`) ever grows additional checks later.

### Front-running / MEV

Low risk here, worth a short note rather than a mitigation: settling later always yields *more* accrued value than settling earlier (`pool_index` only grows), so there's no incentive to race a settlement transaction, and no way to siphon another collaborator's share by timing yours — the lazy accrual math is fair regardless of when any individual party claims. Nobody outside the trail owner/admin controls *when* `n` changes, so ordinary players have no lever to pull here at all.

---

## Summary table

| Phase | What lands | Depends on | Risk if skipped/reordered |
|---|---|---|---|
| 0 | Part 1 verified (`sozo build`, access-control test) | — | Everything below is built on unverified ground |
| 1 | `EntityRevenuePool` model | 0 | N/A — foundational |
| 2 | `add_collaborator` settle-then-reweight, `MAX_COLLABORATORS` cap, `account != owner` guard | 1 | Formula unverified before real money touches it; skipping the guard reopens the sybil-collaborator attack |
| 3 | `settle_collaborator_slots` | 1, 2 | Collaborators can't realize earnings between joins |
| 4 | Multi-target charge path (real money) | 1, 2, 3 | Skipping tests here risks misdirected fee splits; skipping the world-contract gate lets any caller drive arbitrary weight splits |
| 5 | Client UI | 4 | Feature is invisible/unclaimable without it |
| 6 | Feature flag + rollout | 4 | No way to soak-test without affecting real payouts |

## Key files touched across all phases

| File | Phase(s) |
|---|---|
| `packages/contracts/src/models/entity_revenue.cairo` (new — `EntityRevenuePool` + `CollaboratorSlot`) | 1 |
| `packages/contracts/src/tests/helpers.cairo` | 1 (model registration, both models) |
| `packages/contracts/src/systems/designer.cairo` | 2, 3 — `MAX_COLLABORATORS`, `Errors::INVALID_COLLABORATOR`/`TOO_MANY_COLLABORATORS`/`INVALID_SLOT` added to the existing `mod Errors` block |
| `packages/contracts/src/systems/actions_token.cairo` | 4 — new `charge_player_actions_for_targets`, `_assert_caller_is_world_contract` gate reused |
| `packages/contracts/src/systems/prompt.cairo` | 4 |
| `packages/contracts/src/types/command_type.cairo` | 4 (helper only, `get_targets()` already exists) |
| `packages/contracts/src/models/actions_config.cairo` | 4 (`ActionsReward` reused, unchanged), 6 (`ActionsConfig.revenue_split_enabled`) |
| `packages/contracts/src/tests/*` | 0, 2, 3, 4 |
| `packages/client/src/lib/dojo_bindings/typescript/*.gen.ts` | 5 (regenerated) |
| `packages/client/src/lib/systemCalls.ts` | 5 |
| new client UI component | 5 (location TBD) |
