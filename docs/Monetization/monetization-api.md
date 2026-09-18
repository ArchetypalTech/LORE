# Monetization — API Reference

Reference for every entrypoint, model field, and config flag involved in spending, splitting, and claiming `actions_token`. For the *why* behind the revenue-split formula, see [monetization-revenue-distribution.md](monetization-revenue-distribution.md); for the *why* and the current gap behind the two claim paths, see [claiming-rewards.md](claiming-rewards.md). This document only covers the *what* — signatures, gating, effects.

## Overview

```
player spends actions to run a command
        │
        ▼
charge_player_actions (actions_token.cairo)
        │
        ├─ revenue_split_enabled == false          → 100% to trail owner
        │
        └─ revenue_split_enabled == true, command
           resolved one or more object targets      → split per target: owner / creator / collaborators
        │
        ▼
credit lands in ActionsReward (per address, cumulative across every trail/entity)
        │
        ▼
claim it back out — two independent paths:
        │
        ├─ g_claim_actions → claim_actions   (mints on L3 immediately — working)
        │
        └─ claim_rewards                     (batches + requests an L2 permit — L2 half unfinished)
```

---

## Spending actions

### `ActionsConfig.action_cost_amount: u128`

Fixed cost per non-free (`CommandType::Action`) command. Admin-settable via `set_action_cost_amount(ref self, action_cost_amount: u128)`.

```
packages/contracts/scripts/set_action_cost_amount.sh <profile> <amount_with_18_decimals>
```

### `calculate_action_cost(player: Player, command_type: CommandType) -> Result<u128, Error>`

`IActionsTokenProtected` — gated to the world contract only (`_assert_caller_is_world_contract`). Called from `prompt.cairo` before every command executes.

| Case | Result |
|---|---|
| `player.game_id == 0` | always `Ok(0)` — game 0 is the free/testing template layer |
| `command_type != Action` | `Ok(0)` — movement/system commands are free |
| `command_type == Action`, `game_id != 0` | opportunistically claims any accrued free actions first, then returns `action_cost_amount`; `Err(InsufficientActionsBalance)` if the player can't cover it |

### `charge_player_actions(player_address: ContractAddress, targets: Array<felt252>, trail_id: u128, actions_amount: u128, game_id: u128)`

`IActionsTokenProtected` — same gating. Called once per successful, non-free command from `prompt.cairo`.

| Branch | Behavior |
|---|---|
| `targets.is_empty()` | 100% of `actions_amount` credited to the trail owner (via `trail_id`), if `trail_id != 0`. Same regardless of `revenue_split_enabled` — this is the fallback/pre-split behavior. |
| `targets` non-empty | `actions_amount` splits flat across `targets.len()` entities; each slice then splits owner/creator/collaborators (see [split formula](#the-split-formula) below). Only reached when `revenue_split_enabled == true` **and** the command resolved at least one object. |

Always ends the same way regardless of branch: burns `actions_amount` from the player (`spent_actions` + `erc20.burn`).

---

## Revenue split — the flag

### `ActionsConfig.revenue_split_enabled: bool`

Default `false` on `dojo_init`. Read once per command, in `prompt.cairo`:

```cairo
let targets: Array<felt252> = if actions_config.revenue_split_enabled {
    command.get_action_targets()
} else {
    array![]
};
```

When `false`, `charge_player_actions` always takes the empty-targets branch — byte-for-byte the pre-split behavior, regardless of what the command actually resolved.

### `set_revenue_split_enabled(enabled: bool)`

`IActionsTokenPublic` — admin-gated (`_assert_caller_is_admin`: namespace owner, or any address granted player-admin). No client UI for this — ops-only.

```
packages/contracts/scripts/set_revenue_split_enabled.sh <profile> <true|false>
```

Toggling only affects actions charged *after* the flip — no migration, nothing retroactive; a world that's already deployed keeps whatever value it currently has stored until this is called against it directly.

### The split formula (once enabled, per target entity)

```
n = entity.collaborators.len()
decay = 0.5ⁿ
owner_share = creator_share = per_target × (1 + decay) / 4
pool = per_target − owner_share − creator_share
each_collaborator = pool / n                     (flat split — not join-order-weighted)

per_target = actions_amount / targets.len()
```

Entities with `trail_id == 0` skip the owner credit (nothing to own). `n == 0` collapses to `owner_share = creator_share = per_target / 2`, no collaborator loop. Full derivation, worked multi-object examples, and the `add_collaborator` guardrails (sybil block via `assert(account != owner, ...)`, `MAX_COLLABORATORS` cap): [monetization-revenue-distribution.md](monetization-revenue-distribution.md).

---

## Where credit lands

### `ActionsReward`

```cairo
pub struct ActionsReward {
    #[key]
    pub player_address: ContractAddress,
    pub collected_actions_amount: u128,   // lifetime total ever credited
    pub claimed_actions_amount: u128,     // lifetime total already claimed
}
```

One row per address, accruing across every trail/entity that address is owner, creator, or collaborator on — not scoped to a single object.

### `set_actions_collected_on_content(player_address: ContractAddress, actions_amount: u128)`

Internal (`ActionsRewardTrait`). `collected_actions_amount += actions_amount`. Called once per credited address, per targeted action — once for the owner, once for the creator, once per collaborator (or once total, for the owner only, on the no-targets fallback).

---

## Claiming — two independent paths

Full narrative, code, and current status for both: [claiming-rewards.md](claiming-rewards.md). Reference summary:

### Path 1 — `g_claim_actions` (working)

| | |
|---|---|
| Trigger | `_claim` terminal command → `"g_claim_actions"` system command |
| Entrypoint | `claim_actions(recipient: ContractAddress, actions_count: u32)` — `IActionsTokenProtected`, world-contract-only |
| Amount | always the full claimable balance — no partial claims |
| Effect | mints `actions_count` real spendable actions to `recipient`'s `paid_actions_balance` immediately (`ActionsSource::ActionsClaimed`); marks the same amount `claimed_actions_amount` |
| Dependencies | none |
| Status | **working** |

### Path 2 — `claim_rewards` (partial)

| | |
|---|---|
| Trigger | not wired to the client — called directly |
| Entrypoint | `claim_rewards(rewards_count: u32)` — `IActionsTokenPublic`, any player, direct |
| Amount | `rewards_count`, capped by `get_claimable_rewards_count(recipient) -> u32` — floored to whole `trail_reward_actions_count`-sized batches |
| Effect | marks `rewards_count × trail_reward_actions_count` actions claimed; sends an L3→L2 message requesting `rewards_count` `CREATOR_REWARD` permits on `packages/starknet` (the "lore_sn" world) |
| Dependencies | `packages/starknet`'s `permit_token.consume_message` — currently a stub, never mints the requested permit |
| Status | **L3 half working, L2 half unimplemented — net effect today: credit marked claimed, nothing received** |

### Admin/promo path

`send_rewards(recipient: ContractAddress, rewards_count: u32)` — `IActionsTokenPublic`, owner-of-contract only. Same `FREE_REWARD`-permit mechanism and same L2 gap as Path 2. Not part of the creator/collaborator flow.

### `get_claimable_rewards_count(recipient: ContractAddress) -> u32`

View, `IActionsTokenPublic`. Returns whole `trail_reward_actions_count`-sized batches only — built as Path 2's argument source, **not** a general "how much can this address claim" read (Path 1 can claim more than this number ever shows, since it doesn't batch). The client reads `ActionsReward` directly instead (`queryClaimableActionsCount`) to avoid under-reporting.

### `set_trail_reward_actions_count(trail_reward_actions_count: u32)`

`IActionsTokenPublic` — admin-gated. Sets the batch size `get_claimable_rewards_count` / `claim_rewards` use. Default `20` (`APPCHAIN::CREATOR_REWARD_ACTIONS_COUNT`). Does not affect Path 1 at all.

---

## Client surfaces

| Surface | File | Calls |
|---|---|---|
| `_claim` terminal command | `packages/client/src/data/command.data.ts` | `sendCommand("g_claim_actions")` |
| `mint` terminal command (dev/testing) | `packages/client/src/data/command.data.ts` | `world.actions_token.mintTo` — admin-only `mint_to`, unrelated to the reward-claim flow; tops up a wallet's balance directly |
| Left panel "REWARDS" readout | `packages/client/src/lib/stores/leftPanelAction.tsx` | `useLeftPanelStore().claimableRewards`, refreshed by `updateClaimableRewards()` |
| Claimable-amount read | `packages/client/src/lib/queriesPanel/uiPanelQueries.ts` | `queryClaimableActionsCount` — raw Torii read of `ActionsReward`, not the batched view |
| `g_actions` in-game text command | `packages/contracts/src/lib/c_handler.cairo` | prints collected / claimed / claimable / permits-claimable as narrative story text — an older, independent display surface; its last line uses the batched view, so it can read `0` in cases where the left panel correctly shows a positive claimable amount |

---

## Ops scripts (`packages/contracts/scripts/`)

| Script | Entrypoint | Notes |
|---|---|---|
| `set_revenue_split_enabled.sh <profile> <true\|false>` | `set_revenue_split_enabled` | admin-only |
| `set_action_cost_amount.sh <profile> <amount>` | `set_action_cost_amount` | admin-only |
| `mint_actions_to.sh <profile> <account> <amount>` | `mint_to` | admin-only, direct mint — bypasses spend/claim entirely, for funding test wallets |

All three hardcode `WORLD_ADDRESS` to the value shared by the `dev` / `appchain-sepolia` / `saya-test` / `slot` profiles — **wrong for `stage`**, which deploys to a different world address. None of them derive `--world` from the target profile's own manifest.

---

## Status summary

| Piece | Status |
|---|---|
| Spend / charge (`charge_player_actions`) | shipped |
| Revenue split formula | shipped, feature-gated (`revenue_split_enabled`, default `false`) |
| `add_collaborator` guardrails (sybil block, cap) | shipped |
| Claim Path 1 (`g_claim_actions` → `claim_actions`) | shipped, working, wired to the client (`_claim`) |
| Claim Path 2 (`claim_rewards`) | L3 half shipped; L2 mint (`consume_message`) unimplemented |
| L2 permit redemption (`use_permit`) | no public entrypoint exists yet, even once minting is fixed |
| Client L2 provider/wallet wiring for Path 2 | none exists |
