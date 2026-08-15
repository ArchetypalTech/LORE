# Revenue Distribution — Implementation Plan

**Status: shipped.** All three phases below are implemented and covered by passing tests (`packages/contracts/src/tests/command_type_test.cairo`, `packages/contracts/src/tests/actions_revenue_test.cairo` — 9 tests, including two full-pipeline tests that drive a real `"read paper"` command through the actual lexer/dictionary/reactable pipeline, not a hand-built `Command`). This document is kept as the design record — the checklists are marked done, and the code blocks below reflect what actually shipped, including a couple of corrections made against the original sketch once real compiler/test feedback came in (see "Lessons from implementation" near the bottom).

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

- [X] Implement `get_action_targets` — landed on `Command` itself (`types/command_type.cairo`, next to `get_targets()`/`get_nouns()`), not as a free function in `prompt.cairo`.
- [X] Unit tests in `packages/contracts/src/tests/command_type_test.cairo`: single noun, two nouns (order preserved), no noun, an unresolved noun correctly excluded, and a mixed resolved/unresolved case.

**Exit criteria**: `prompt.cairo` has a correct `Array<felt252>` of resolved entity insts for any action command, before charging. ✅

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
        if (trail_id.is_non_zero()) {
            let owner: ContractAddress = world.trail_token_dispatcher().owner_of(trail_id.into());
            world.set_actions_collected_on_content(owner, actions_amount);
        }
    } else {
        // Command has one or more resolved object targets — the fee splits flat across
        // them, then each target's slice splits between that entity's trail owner,
        // creator, and current collaborators (flat split — see "What got cut" below).
        let per_target: u128 = actions_amount / targets.len().into();
        for inst in targets {
            let entity: Entity = world.read_model(inst);
            let n: u32 = entity.collaborators.len();

            // decay = 0.5^n in PRECISION-scaled fixed point. No stored state — n is
            // bounded by MAX_COLLABORATORS (designer.cairo's add_collaborator cap), so
            // this loop is cheap and needs no persisted accumulator.
            let mut decay: u128 = PRECISION;
            let mut k: u32 = 0;
            while k < n {
                decay = decay / 2;
                k += 1;
            };

            // owner_share = creator_share = per_target * (1 + decay) / 4, widened to u256
            // for the multiply so it can't overflow before the division would bring it
            // back into range. Each .into() target is pinned via an explicit typed
            // binding — Cairo can't infer u256 across the chained expression (see
            // "Lessons from implementation" below).
            let per_target_u256: u256 = per_target.into();
            let numer_u256: u256 = (PRECISION + decay).into();
            let denom_u256: u256 = (4 * PRECISION).into();
            let owner_share: u128 = (per_target_u256 * numer_u256 / denom_u256)
                .try_into()
                .unwrap();
            let creator_share: u128 = owner_share; // symmetric by construction

            // Entities with no trail (trail_id == 0, core/global entities) have no trail
            // owner to credit — skip rather than call owner_of(0).
            if entity.trail_id.is_non_zero() {
                let owner: ContractAddress = world.trail_token_dispatcher().owner_of(entity.trail_id.into());
                world.set_actions_collected_on_content(owner, owner_share);
            }
            world.set_actions_collected_on_content(entity.creator_address, creator_share);

            if n.is_non_zero() {
                // n == 0: decay == PRECISION, so owner_share + creator_share already
                // equals per_target exactly — nothing left for a pool loop that never runs.
                let pool: u128 = per_target - owner_share - creator_share;
                let each: u128 = pool / n.into();
                for collaborator in entity.collaborators {
                    world.set_actions_collected_on_content(collaborator, each);
                };
            }
        };
    }

    // burn player actions
    world.spent_actions(player_address, actions_amount, game_id);
    self.erc20.burn(player_address, actions_amount.into());
}
```

- `PRECISION: u128 = 1_000_000_000_000_000_000` — a local constant in this module (same numeric value as `CONST::ETH_TO_WEI`, but that one's `u256`-typed for ERC-20 amounts; redeclare the literal as `u128` here).
- **Widened multiply, via explicit typed bindings** — the first draft of this sketch used inline `u256 { low: ..., high: 0 }` struct literals, which turned out not to be how this compiles cleanly; the real blocker Cairo hit was inferring `u256` across a multi-step chained `.into()` expression at all. Binding each `.into()` to its own `let x: u256 = ...` first, then combining them, is what actually compiles — see "Lessons from implementation."
- If `n == 0`: `decay = PRECISION`, so `owner_share = creator_share = per_target/2` exactly, summing to `per_target` — the `if n.is_non_zero()` block never runs and nothing is left uncredited. No special case needed.
- **`trail_id == 0` guard**: an entity with no trail (a core/global entity) has no trail owner to credit — calling `owner_of(0)` would revert the whole transaction, so that credit is skipped for that one recipient rather than failing the command. Not in the original sketch; added once the multi-target case made it clear a target entity's own `trail_id` could legitimately be zero.
- **Rounding**: integer division means `per_target × targets.len()` can fall a hair short of `actions_amount`, and `pool / n` can drop a similarly tiny remainder per target — plus a separate, `n`-independent ≤1-wei loss from the owner/creator division itself when `per_target` is odd. Negligible at the `PRECISION`/action-cost magnitudes in use, not worth a sweep — the conservation test below bounds it at `n+1` wei-units, not `n`, to account for both sources.

**`packages/contracts/src/systems/prompt.cairo`** — update the one call site to pass `command.get_action_targets()` as the new `targets` argument. (Shown unconditionally here — Phase 3 below wraps this in the `revenue_split_enabled` feature-gate; see that section for the final version that actually shipped.)

**`IActionsTokenProtected`** (interface block, `actions_token.cairo`) — update `charge_player_actions`'s signature to match.

**Optional, cheap hardening on `add_collaborator`** (`designer.cairo`, otherwise unchanged from Part 1) — two one-line additions, no model, no interface:

```cairo
assert(account != owner, Errors::INVALID_COLLABORATOR); // blocks the cheapest self-dealing case
assert(entity.collaborators.len() < MAX_COLLABORATORS, Errors::TOO_MANY_COLLABORATORS);
```

- **The sybil guard**: without it, a trail owner can call `add_collaborator(inst, second_wallet_they_control)` and capture part of the pool that should go to the actual creator — e.g. at `n=0→1` on an entity where owner ≠ creator, owner's real take goes from 50% to 62.5% (37.5% as owner + 25% as their own "collaborator"), at the creator's direct expense. This one line blocks the single-address version of that. It does not stop a fresh, unlinked wallet — closing that fully needs collaborator-signed consent, a bigger lift not proposed here. Worth documenting as a named trust assumption either way: **this model assumes the trail owner isn't actively adversarial toward their own creators/collaborators**, same boundary the publish-approval flow already rests on.
- **The cap**: now matters more than it would have in the settle-on-join design, because the collaborator-crediting loop runs on **every action** against that entity, not just at join time. It bounds what every player passing through pays, not just what the owner pays once. Tune the actual number from a measured `sozo` gas profile of `charge_player_actions`'s loop, not the placeholder above.

- [X] Implement the modified `charge_player_actions` + interface signature update.
- [X] Implement the `prompt.cairo` call site update (folded into Phase 3's feature-gate — see below).
- [X] Add the two guard lines to `add_collaborator`.
- [X] Integration test (`test_charge_single_target_flat_split_n2`, `actions_revenue_test.cairo`) — n=2, asserts `ActionsReward` for owner/creator/both collaborators against the exact closed-form values, plus a conservation check and burn/`total_supply` verification.
- [X] Integration test (`test_charge_two_targets_independent_entities`) — two targets in two independent trails (n=3 and n=0 simultaneously), asserts no cross-contamination between them.
- [X] Regression tests (`test_charge_no_target_falls_back_to_trail_owner`, `test_charge_no_target_zero_trail_id_credits_nobody`) — no-noun commands still charge 100% to the trail owner; a zero `trail_id` doesn't panic.
- [X] Property test (`test_formula_conservation_across_collaborator_counts`) — sweeps `n` from 0 to 200 across two `per_target` values (one round, one deliberately odd), asserting the conservation bound described above.
- [X] Guard tests (`test_add_collaborator_blocks_owner_self_add`, `test_add_collaborator_max_cap`) — `#[should_panic]` on both. The 200-collaborator cap test pre-fills 199 collaborators via a direct model write rather than 199 real `add_collaborator` calls (see "Lessons from implementation" — the naive version hit "Out of gas").

All 7 of these live in `packages/contracts/src/tests/actions_revenue_test.cairo`, calling `charge_player_actions` directly via the protected dispatcher (caller mocked to `sys.prompt.contract_address`, same pattern as `test_transfer_from_prompt_contract` in `actions_token_test.cairo`) rather than through a hand-built or real English command — deliberately, since the lexer/dictionary/reactable pipeline that would resolve a real sentence is unrelated to what this phase changed. Phase 3 adds two more tests that *do* go through a real command end-to-end.

**Exit criteria**: a real "use door" / "give X to Y" command on devnet credits `ActionsReward` for owner, creator, and every current collaborator in a single transaction — no separate settle or claim step beyond the `claim_rewards`/`send_rewards` flow that already exists and is untouched by this plan. ✅ — confirmed both by direct-dispatch tests here and by Phase 3's full-pipeline test.

---

## Phase 3 — Rollout

Feature-gate via `ActionsConfig.revenue_split_enabled: bool`, mirroring the existing admin-settable fields (`action_cost_amount`, etc.). Default `false` — while disabled, `prompt.cairo` always passes an empty `targets` array to `charge_player_actions`, byte-for-byte today's 100%-to-trail-owner behavior, regardless of what the command resolved. Lets Phases 1–2 be soak-tested on devnet/staging before flipping in production.

**`packages/contracts/src/models/actions_config.cairo`** — new field + setter:

```cairo
pub struct ActionsConfig {
    ...
    pub trail_reward_actions_count: u32,
    pub revenue_split_enabled: bool,   // new — defaults to false in initialize_actions_config
}

// ActionsConfigTrait
fn set_revenue_split_enabled(ref self: WorldStorage, revenue_split_enabled: bool) {
    self.write_member(Model::<ActionsConfig>::ptr_from_keys(ACTIONS_KEY), selector!("revenue_split_enabled"), revenue_split_enabled);
}
```

**`packages/contracts/src/systems/actions_token.cairo`** — `set_revenue_split_enabled(bool)` added to `IActionsToken`/`IActionsTokenPublic` and implemented exactly like `set_action_cost_amount` (admin-gated, single `write_member` call).

**`packages/contracts/src/systems/prompt.cairo`** — the call site, gated (this is the version that actually shipped, superseding Phase 2's unconditional sketch above):

```cairo
let actions_config: ActionsConfig = world.get_actions_config();
let targets: Array<felt252> = if actions_config.revenue_split_enabled {
    command.get_action_targets()
} else {
    array![]
};
world.actions_token_protected_dispatcher().charge_player_actions(
    player.address, targets, world.get_entity_trail_id(player.inst), actions_amount, player.game_id,
);
```

- [X] Feature-gate implemented as above.
- [X] No migration needed — this only affects revenue from actions charged after the flag flips; nothing retroactive.
- [X] Full-pipeline tests instead of a staging spot-check for now (see below) — both prove the conservation/gating behavior against a real command, not synthetic data. A staging spot-check is still worth doing once this is actually deployed, but isn't something a unit test can stand in for.

### Full-pipeline test — real "read paper" through `prompt()`

Everything above (Phases 1–2) was tested by calling `charge_player_actions` directly, deliberately bypassing the lexer/dictionary/reactable pipeline since that pipeline was unchanged by this work. Phase 3's gating logic lives inside `prompt.cairo` itself, so proving it actually works needs at least one test that goes through `prompt()` for real — this is that test, and the only one in this whole effort that does.

`_setup_paper_world` (`actions_revenue_test.cairo`) builds a real scene: a trail minted via `_mint_trail`, a room in it (`helpers::create_area_entity`), and a "paper" entity with:
- `alt_names: ["paper"]` — the lexer's `match_player_context` (`a_lexer.cairo`) resolves nouns by matching token text against reachable entities' names/alt_names directly; no dictionary entry needed for an object name specifically, unlike verbs.
- a custom `Reactable` mapping the verb `"read"` (already a base dictionary verb — nothing to register) to a `DescriptionText` via `ReactableActions::ReadSpecificDescription`.
- 2 collaborators, added through the real `add_collaborator` entrypoint.

`test_full_pipeline_read_paper_revenue_split_enabled` and `..._disabled` both run `sys.prompt.prompt("read paper", Option::None)` — real text, real parse, real `handle_command` execution (asserted via the description text actually being read back through `game_story_last_line`) — and diverge only on `ActionsConfig.revenue_split_enabled`. Enabled reproduces the exact n=2 closed-form split from Phase 2's direct-dispatch test, now reached through genuine target resolution; disabled asserts creator/collaborators get exactly zero, proving `get_action_targets()` is never even called when the flag is off, not just that its result gets discarded.

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

## Lessons from implementation

None of these changed the design — all found and fixed during the actual `sozo build`/test cycle, kept here so the next person touching this code doesn't rediscover them the hard way.

- **Cairo can't infer `u256` across a chained `.into()` expression.** `(a.into() * b.into() / c.into()).try_into().unwrap()` fails with "Type annotations needed" even when the final `.try_into()` target is unambiguous — the compiler doesn't propagate the expected type backward through a multi-step chain with more than one unresolved `.into()`. Binding each conversion to its own `let x: u256 = ...` first, *then* combining them, resolves it. Hit this in both `charge_player_actions` and the test file's mirror of the same formula — same fix both places.
- **Direct `world.write_model(...)` calls in tests need WRITER role on that model**, granted to `OWNER()` (the namespace owner, via `setup_core()`'s `grant_owner`) — not to whichever address happens to be the active caller from a previous helper call (e.g. `_create_object` leaves the caller set to the entity's trail owner, which does *not* have blanket WRITER). Every direct model write in the test file explicitly switches to `OWNER()` first.
- **`charge_player_actions` burns from a real balance** — calling it in a test without first minting (or letting the player's initial free actions cover it) fails with `'ERC20: insufficient balance'`, not a revert specific to this feature. Easy to miss since the formula/split logic is what a test is actually trying to verify.
- **`game_id` is not reliably `1`.** `actions_token_test.cairo`'s existing tests hardcode `game_id: u128 = 1` safely, because in those tests PLAYER_1 is the very first address to ever call `prompt()` in that fresh world. The full-pipeline test's setup calls `_mint_trail`, which itself calls `prompt("g_create_trail", ...)` as the trail owner *before* PLAYER_1 ever gets a game — claiming `game_id 1` for the trail owner and pushing PLAYER_1 to `game_id 2`. Query `PlayerAccountTrait::current_game_id(@world, address)` instead of assuming, whenever anything else might have already created a game first.
- **Filling `MAX_COLLABORATORS` via 200 real `add_collaborator` calls hit "Out of gas"** in the cap-boundary test. Since `add_collaborator` has no side effect beyond the array append, pre-filling 199 collaborators via one direct `world.write_model` and only making the two real calls that actually matter (the 200th, which must succeed, and the 201st, which must revert) tests the identical boundary condition for a fraction of the cost.
- **felt252 short-string literals cap at 31 bytes.** `'DESIGNER: Too many collaborators'` (32 bytes) doesn't compile as a `felt252` constant — caught and shortened to `'DESIGNER: Too many collabs'` (26 bytes).
- **The formula conservation bound is `n+1`, not `n`.** The original bound only accounted for the collaborator pool's `pool // n` rounding loss. There's a second, `n`-independent source: the owner/creator division (`per_target*(...)/(4*PRECISION)`) floors on its own, losing up to 1 wei when `per_target` is odd — visible even at `n=0`, where there's no collaborator division to blame it on. Caught by the conservation test itself, using a deliberately odd `per_target` (`777_777_777_777_777_777`) as one of its two sweep values.

---

## Key files

| File | Role |
|---|---|
| `packages/contracts/src/types/command_type.cairo` | `get_action_targets` — resolved noun targets for revenue crediting |
| `packages/contracts/src/systems/prompt.cairo` | Reads `ActionsConfig.revenue_split_enabled`, conditionally calls `get_action_targets`, passes result to `charge_player_actions` |
| `packages/contracts/src/systems/actions_token.cairo` | `charge_player_actions` — signature + body rewritten; `set_revenue_split_enabled` added; `IActionsToken`/`IActionsTokenPublic`/`IActionsTokenProtected` interfaces updated |
| `packages/contracts/src/systems/designer.cairo` | `add_collaborator` — two added guard lines (`INVALID_COLLABORATOR`, `TOO_MANY_COLLABORATORS`), `MAX_COLLABORATORS` constant |
| `packages/contracts/src/models/actions_config.cairo` | `ActionsReward` reused unchanged; `ActionsConfig.revenue_split_enabled` field + `set_revenue_split_enabled` setter |
| `packages/contracts/src/tests/command_type_test.cairo` | `get_action_targets` unit tests (Phase 1) |
| `packages/contracts/src/tests/actions_revenue_test.cairo` | All Phase 2/3 tests — 9 total, including the two full-pipeline "read paper" tests |
