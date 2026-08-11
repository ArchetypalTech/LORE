# Revenue Distribution — Implementation Plan

Step-by-step plan for building Part 2 of [monetization-revenue-distribution.md](monetization-revenue-distribution.md) (owner/creator/collaborator revenue split on player actions).

**This is a rewrite after feedback on the first draft.** The original version introduced a settle-on-join accumulator (`EntityRevenuePool` + `CollaboratorSlot` models, a `settle_collaborator_slots` claim step) to reproduce the proposal doc's join-order-weighted formula in O(1) per action. That's real complexity — new models, a management surface, a second thing to keep in sync — for a feature that doesn't need persisted state at all if one part of the formula is simplified. This version has **no new models and no settle step**: every action computes and credits owner, creator, and every current collaborator in one pass, directly into the `ActionsReward` ledger that already exists.

## Old plan vs. new plan

| | Old (rejected) | New (this doc) |
|---|---|---|
| New models | `EntityRevenuePool`, `CollaboratorSlot` (composite-keyed, one per collaborator slot) | None |
| `add_collaborator` | Rewrites every existing slot's weight on each join (settle-then-reweight, O(n) at join time) | Unchanged from Part 1 — just appends. Two optional one-line guards added (sybil block, max-count cap) |
| Crediting owner/creator/collaborators | Owner/creator credited per action (O(1)); collaborators accrue lazily into a per-slot balance, not paid out yet | Owner, creator, **and every current collaborator** credited directly per action, straight into `ActionsReward` — nothing deferred |
| Claiming | New `settle_collaborator_slots` entrypoint required first (moves accrued pool balance into `ActionsReward`), *then* the existing `claim_rewards`/`send_rewards` | Just the existing `claim_rewards`/`send_rewards` — nothing new |
| Collaborator formula | Join-order-weighted — earlier joiners keep out-earning later ones at the same `n` (matches the proposal doc's worked table exactly) | Flat, even split across current collaborators — shrinks as more join, but doesn't reward *when* someone joined |
| Where the O(n) gas cost lands | Once per join, paid by the trail owner/admin | Every action against that entity, paid by whichever player issues the command |
| `command.get_targets()` citation | Used as "already resolves entity targets" (incorrect — it returns *unresolved* nouns) | Corrected to `command.get_nouns()`, which is what's actually resolved |
| Phases | 6 (models, reweight, settle, charge-path, client, rollout) | 3 (target resolution, charge-path, rollout) |

Full reasoning for each row is in "What got cut, and why" further down.

---

## What's already done (Part 1 — unchanged by this plan)

`Entity.collaborators: Array<ContractAddress>` and the owner/admin-gated `add_collaborator(inst, account)` entrypoint. Nothing here changes except two optional one-line additions noted in Phase 2 below.

### Phase 0 — Verified ✅

- [X] `sozo build` in `packages/contracts`.
- [X] Access-control test for `add_collaborator`.
- [X] Client round-trip confirmed on devnet.

Nothing further needed here.

---

## Phase 1 — Resolve action targets in `prompt.cairo`

**Correction from the first draft**: it cited `Command::get_targets()` (`types/command_type.cairo:182`) as already returning resolved entity targets. Reading the actual function, it does the opposite — it collects noun tokens whose `.target` is still **zero** (`if token.target != 0 { continue; }` skips anything already resolved), almost certainly for error-reporting ("I don't know what that means"), not for finding what a command acted on.

The right source is `Command::get_nouns()` (`types/command_type.cairo:154`) — every noun token, each with `.target` already populated by the parser with the resolved `Entity` inst before `handle_command` runs (confirmed by `c_handler.cairo`'s own loop, which trusts `*noun.target` is already a valid entity inst: `EntityImpl::get_entity(@world, *noun.target)`). "use door" → one noun. "give token to officer" → two nouns, each independently resolved.

**`packages/contracts/src/types/command_type.cairo`** (or a small free function in `prompt.cairo` — either is fine, it's five lines):

```cairo
fn get_action_targets(self: @Command) -> Array<felt252> {
    let mut targets: Array<felt252> = array![];
    for noun in self.get_nouns() {
        if *noun.target != 0 {
            targets.append(*noun.target);
        }
    };
    (targets)
}
```

Call this from `prompt.cairo` right where `command` is already in scope (today's line ~56, after a successful parse), and pass the result into the modified `charge_player_actions` call from Phase 2 instead of only `trail_id`.

- [ ] Implement `get_action_targets`.
- [ ] Unit test: "use door" → one target. "give token to officer" → two targets. "look" (no noun) → empty array.

**Exit criteria**: `prompt.cairo` has a correct `Array<felt252>` of resolved entity insts for any action command, before charging.

---

## Phase 2 — Compute and credit shares directly in `charge_player_actions`

No new models, no settle step. Everything below reads only what already exists (`Entity.creator_address`, `Entity.collaborators`, `trail_token_dispatcher().owner_of(...)`) and writes only to the existing `ActionsReward` ledger via the existing `set_actions_collected_on_content`.

**`packages/contracts/src/systems/actions_token.cairo`** — `charge_player_actions` gains a `targets` parameter and branches on whether any were found:

```cairo
const MAX_COLLABORATORS: u32 = 200; // bounds this loop — see note below, it now runs on every action

fn charge_player_actions(
    ref self: ContractState,
    player_address: ContractAddress,
    targets: Array<felt252>,      // resolved entity insts from prompt.cairo — empty for object-less commands
    trail_id: u128,               // kept for the no-target fallback, unchanged from today
    actions_amount: u128,
    game_id: u128,
) {
    let mut world: WorldStorage = self.world_default();
    self._assert_caller_is_world_contract(@world);

    if targets.is_empty() {
        // No object in the command ("look", "go north") — unchanged: 100% to the trail owner.
        if trail_id.is_non_zero() {
            let owner: ContractAddress = world.trail_token_dispatcher().owner_of(trail_id.into());
            world.set_actions_collected_on_content(owner, actions_amount);
        }
    } else {
        let per_target: u128 = actions_amount / targets.len().into();
        for inst in targets {
            let entity: Entity = world.read_model(inst);
            let entity_trail_id: u128 = world.get_entity_trail_id(inst);
            let owner: ContractAddress = world.trail_token_dispatcher().owner_of(entity_trail_id.into());
            let n: u32 = entity.collaborators.len();

            // decay = 0.5^n in PRECISION-scaled fixed point — no stored state, just a bounded loop.
            let mut decay: u128 = PRECISION;
            let mut k: u32 = 0;
            while k < n {
                decay = decay / 2;
                k += 1;
            };

            let owner_share: u128 = (u256 { low: per_target, high: 0 } * u256 { low: PRECISION + decay, high: 0 }
                / u256 { low: 4 * PRECISION, high: 0 }).try_into().unwrap();
            let creator_share: u128 = owner_share; // symmetric by construction
            world.set_actions_collected_on_content(owner, owner_share);
            world.set_actions_collected_on_content(entity.creator_address, creator_share);

            if n.is_non_zero() {
                let pool: u128 = per_target - owner_share - creator_share;
                let each: u128 = pool / n.into(); // flat split — see "What got cut" below
                for collaborator in entity.collaborators {
                    world.set_actions_collected_on_content(collaborator, each);
                };
            }
        }
    }

    world.spent_actions(player_address, actions_amount, game_id);
    self.erc20.burn(player_address, actions_amount.into());
}
```

- `PRECISION: u128 = 1_000_000_000_000_000_000` — a local constant in this module (same numeric value as `CONST::ETH_TO_WEI`, but that one's `u256`-typed for ERC-20 amounts; redeclare the literal as `u128` here).
- **Widened multiply**: `per_target × (PRECISION + decay)` is computed in `u256` before dividing, then narrowed back with `.try_into().unwrap()`. Multiplying two `u128`s directly can overflow before the true post-division result would — this applies to any weight/share × amount computation in this function.
- If `n == 0`: `decay = PRECISION`, so `owner_share = creator_share = per_target/2` exactly, summing to `per_target` — the `if n.is_non_zero()` block never runs and nothing is left uncredited. No special case needed.
- **Rounding**: integer division means `per_target × targets.len()` can fall a hair short of `actions_amount`, and `pool / n` can drop a similarly tiny remainder per target. At the `PRECISION`/action-cost magnitudes already in use elsewhere in this codebase this is dust, not worth a sweep — but worth a test asserting the total ever dropped per action stays negligible and is never *created* (never rounds up).

**`packages/contracts/src/systems/prompt.cairo`** — update the one call site:

```cairo
world.actions_token_protected_dispatcher().charge_player_actions(
    player.address,
    command.get_action_targets(),
    world.get_entity_trail_id(player.inst),
    actions_amount,
    player.game_id,
);
```

**`IActionsTokenProtected`** (interface block, `actions_token.cairo`) — update `charge_player_actions`'s signature to match.

**Optional, cheap hardening on `add_collaborator`** (`designer.cairo`, otherwise unchanged from Part 1) — two one-line additions, no model, no interface:

```cairo
assert(account != owner, Errors::INVALID_COLLABORATOR); // blocks the cheapest self-dealing case
assert(entity.collaborators.len() < MAX_COLLABORATORS, Errors::TOO_MANY_COLLABORATORS);
```

- **The sybil guard**: without it, a trail owner can call `add_collaborator(inst, second_wallet_they_control)` and capture part of the pool that should go to the actual creator — e.g. at `n=0→1` on an entity where owner ≠ creator, owner's real take goes from 50% to 62.5% (37.5% as owner + 25% as their own "collaborator"), at the creator's direct expense. This one line blocks the single-address version of that. It does not stop a fresh, unlinked wallet — closing that fully needs collaborator-signed consent, a bigger lift not proposed here. Worth documenting as a named trust assumption either way: **this model assumes the trail owner isn't actively adversarial toward their own creators/collaborators**, same boundary the publish-approval flow already rests on.
- **The cap**: now matters more than it would have in the settle-on-join design, because the collaborator-crediting loop runs on **every action** against that entity, not just at join time. It bounds what every player passing through pays, not just what the owner pays once. Tune the actual number from a measured `sozo` gas profile of `charge_player_actions`'s loop, not the placeholder above.

- [ ] Implement the modified `charge_player_actions` + interface signature update.
- [ ] Implement the `prompt.cairo` call site update.
- [ ] Add the two guard lines to `add_collaborator`.
- [ ] Integration test: "use door" (entity has 2 collaborators) — assert `ActionsReward` for owner/creator/both collaborators match the closed-form n=2 percentages of `action_cost_amount`, flat-split among collaborators.
- [ ] Integration test: "give token to officer" (2 targets, independent entities/trails) — assert the fee splits evenly across the two targets, each independently split by its own entity's owner/creator/collaborators.
- [ ] Regression test: a command with no noun target charges 100% to the trail owner, byte-for-byte the same as today.
- [ ] Property test: for randomized `n` (0..`MAX_COLLABORATORS`) and randomized `per_target`, `owner_share + creator_share + Σ collaborator shares` lands within rounding dust of `per_target`, never over it.
- [ ] Test: `add_collaborator(inst, owner_address)` reverts with `INVALID_COLLABORATOR`; the 201st collaborator on one entity reverts with `TOO_MANY_COLLABORATORS`.

**Exit criteria**: a real "use door" / "give X to Y" command on devnet credits `ActionsReward` for owner, creator, and every current collaborator in a single transaction — no separate settle or claim step beyond the `claim_rewards`/`send_rewards` flow that already exists and is untouched by this plan.

---

## Phase 3 — Rollout

- [ ] Feature-gate via `ActionsConfig.revenue_split_enabled: bool` (mirrors existing admin-settable fields like `action_cost_amount`), default `false`. `prompt.cairo` only resolves/passes `targets` when enabled; otherwise it calls the same path with an empty `targets` array, which is byte-for-byte today's behavior. Lets this be soak-tested on devnet/staging before flipping in production.
- [ ] No migration needed — this only affects revenue from actions charged after the flag flips; nothing retroactive.
- [ ] Before enabling in production, spot-check the conservation invariant (Phase 2's property test) against a sample of real staging transactions.

---

## What got cut from the first draft, and why

| Cut | Was for | Why it's gone |
|---|---|---|
| `EntityRevenuePool` model | O(1)-per-action accounting via a persistent index | Adds storage, a `get_or_init` pattern, and ongoing maintenance for state this design doesn't need — direct crediting handles it in one pass, no index to keep consistent. |
| `CollaboratorSlot` model | Per-collaborator weight/checkpoint, needed to make join-order weighting cheap | Existed only in service of the formula below — goes with it. |
| `settle_collaborator_slots` entrypoint | Realizing pool earnings into `ActionsReward` on demand | Nothing to settle — crediting happens directly at charge time, straight into `ActionsReward`, the same ledger and the same `claim_rewards`/`send_rewards` flow that already existed before any of this. |
| Join-order-weighted collaborator formula (contributor1 > contributor2 > contributor3 at the same `n`) | Earlier joiners keep out-earning later ones | Only cheap with the state above — computed fresh with no memory of join order, it's O(n²) per action, since every collaborator's share would need its own join-history sum on every single command. **Replaced with a flat, even split of the pool across current collaborators.** Still shrinks per-collaborator as more people join (same `pool/n`-style dilution), just no longer rewards *when* someone joined, only *that* they're currently a collaborator. |

Owner/creator's `0.25 × (1 + 0.5ⁿ)` formula is unchanged in both versions — it was already a pure function of `n`, needing no stored state either way.

**The trade-off this makes, stated plainly**: gas cost moves from "rare, owner-paid, at join time" (the cut design) to "every single action, paid by whoever's playing" (this design) — an entity with many collaborators now makes every command against it proportionally more expensive for players, forever, not just the act of adding someone. The `MAX_COLLABORATORS` cap above exists specifically to bound that. If this turns out to matter in practice (heavily-collaborated entities seeing real player friction from the extra gas), the settle-on-join design is the fix, and this document's git history has the fully worked version if it's needed later.

---

## Key files

| File | Role |
|---|---|
| `packages/contracts/src/types/command_type.cairo` | `get_action_targets` helper |
| `packages/contracts/src/systems/prompt.cairo` | Calls `get_action_targets`, passes result to `charge_player_actions` |
| `packages/contracts/src/systems/actions_token.cairo` | `charge_player_actions` — signature + body rewritten; `IActionsTokenProtected` interface updated |
| `packages/contracts/src/systems/designer.cairo` | `add_collaborator` — two added guard lines, nothing else |
| `packages/contracts/src/models/actions_config.cairo` | `ActionsReward` reused unchanged; `ActionsConfig.revenue_split_enabled` added for rollout |
| `packages/contracts/src/tests/*` | New tests per phase above |
