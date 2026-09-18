# Claiming Rewards — Two Paths, One Ledger

Every address credited by the revenue split (or, before that flag existed, every trail owner) accrues balance in one place: `ActionsReward` (`packages/contracts/src/models/actions_config.cairo`). This document covers what happens *after* that credit lands — how an owner, creator, or collaborator actually turns it into something usable. See [monetization-revenue-distribution.md](monetization-revenue-distribution.md) for how the credit gets there in the first place.

## The shared ledger

```cairo
pub struct ActionsReward {
    #[key]
    pub player_address: ContractAddress,
    pub collected_actions_amount: u128,     // lifetime total ever credited
    pub claimed_actions_amount: u128,       // lifetime total already claimed
}
```

`claimable_actions_amount()` = `collected_actions_amount - claimed_actions_amount`. Both claim paths below read and write the *same* fields on the *same* model — they're two different withdrawal mechanisms over one balance, not two separate pots. Claiming through one reduces what's available to the other.

---

## Path 1 — `g_claim_actions` → `claim_actions` (working — this is what `_claim` uses)

**Client** (`packages/client/src/data/command.data.ts`) — `_claim`, underscore-prefixed per this file's own convention (reserved: not listed in `help`, still callable by typing `_claim`):

```ts
_claim: () => {
    if (!WalletStore().isConnected) {
        sendCommand("_not_yet_connected");
        return;
    }
    sendCommand("g_claim_actions").then(async () => {
        await updateBalances();
        await updateClaimableRewards();
    });
},
```

No amount argument — `g_claim_actions` always claims everything currently claimable in one shot. It's a thin wrapper: forward a system command through the normal `prompt()` pipeline, then refresh the two left-panel reads.

**System command** (`packages/contracts/src/lib/c_handler.cairo`):

```cairo
if (system_command == "g_claim_actions") {
    let rewards: ActionsReward = world.read_model(player.address);
    let actions_claimable_amount: u128 = rewards.claimable_actions_amount();
    if (actions_claimable_amount.is_non_zero()) {
        let actions_claimable: u32 = (actions_claimable_amount / CONST::ETH_TO_WEI.low).try_into().unwrap();
        world.actions_token_protected_dispatcher().claim_actions(player.address, actions_claimable);
        ...
    } else {
        return Result::Err(Error::InsufficientActionsToClaim);
    }
    return Result::Ok(());
}
```

**Entrypoint** (`packages/contracts/src/systems/actions_token.cairo`, `IActionsTokenProtected` — gated to `_assert_caller_is_world_contract`, so it's not directly callable by a player wallet, only reachable through `prompt()`):

```cairo
fn claim_actions(ref self: ContractState, recipient: ContractAddress, actions_count: u32) {
    let mut world: WorldStorage = self.world_default();
    self._assert_caller_is_world_contract(@world);
    self._mint_to(ref world, recipient, actions_count, ActionsSource::ActionsClaimed);
    world.set_actions_claimed_as_rewards(recipient, actions_count.into() * CONST::ETH_TO_WEI.low);
}
```

`_mint_to(..., ActionsSource::ActionsClaimed)` mints real, spendable `actions_token` (the soulbound ERC-20) directly into `PlayerBalances.paid_actions_balance` — synchronous, single L3 transaction, visible in the balance immediately (`minted_actions` in `player_account.cairo` handles the `ActionsClaimed` source the same way as `Airdrop`). `set_actions_claimed_as_rewards` marks the same amount claimed in `ActionsReward` so it can't be claimed twice.

**Status: fully working.** No L2, no cross-chain messaging, nothing missing.

---

## Path 2 — `claim_rewards` (L3 half works, L2 half is an unfinished stub)

**Entrypoint** (`packages/contracts/src/systems/actions_token.cairo`, `IActionsTokenPublic` — directly callable by any player, unlike `claim_actions`):

```cairo
fn claim_rewards(ref self: ContractState, rewards_count: u32) {
    let mut world: WorldStorage = self.world_default();
    let caller: ContractAddress = starknet::get_caller_address();
    let (claimable_rewards_count, claimable_reward_actions_amount): (u32, u128) =
        self._get_claimable_rewards_count(@world, caller);
    assert(rewards_count.is_non_zero() && rewards_count <= claimable_rewards_count, Errors::INVALID_REWARDS_COUNT);
    world.set_actions_claimed_as_rewards(caller, claimable_reward_actions_amount);
    let payload: Array<felt252> = world.pack_mint_permit_rewards_payload(
        APPCHAIN::PERMIT_TYPES::CREATOR_REWARD, caller, rewards_count,
    );
    self._send_message(ref world, payload);
}
```

Two structural differences from Path 1:

- **Batched, not raw.** `_get_claimable_rewards_count` floors the claimable balance to whole units of `trail_reward_actions_count` (default 20, `set_trail_reward_actions_count`). 15 claimable actions with a batch size of 20 shows `rewards_count = 0` here, even though Path 1 could claim all 15 right now.
- **Doesn't mint anything on L3.** It marks the batch claimed and fires an L3→L2 cross-chain message (`_send_message` → `send_message_to_l1_syscall`) requesting a `CREATOR_REWARD`-type permit be minted on a *separate* Dojo world — `packages/starknet` ("lore_sn"), its own `world_address`, its own RPC endpoint, unrelated to the appchain the game itself runs on (see [Architecture note](#architecture-note) below).

**Where it dead-ends** — `packages/starknet/src/systems/permit_token.cairo`, `consume_message`:

```cairo
fn _consume_message(ref self: ContractState, payload: Span<felt252>) {
    ...
    let _msg_hash: felt252 = messaging.consume_message_from_appchain(
        messaging_config.appchain_contract, payload,
    );
    // msg successfully consumed, we can proceed and process the data
    // in the payload.
    // for i in 0..payload.len() { ... }   <- commented out, does nothing
}
```

This proves the message was delivered — and stops. It never mints a `PermitTokenInfo` / ERC-721. The unpacker it would need, `unpack_mint_permit_rewards_payload`, already exists in the same package (`packages/starknet/src/models/appchain.cairo`, mirrored byte-for-byte from the L3 package's version) — it's just never called from anywhere. Compare to `purchased_starter_pack` in the same file, which *does* do the real work (`erc721_combo._mint_next`, `write_model(@PermitTokenInfo{...})`) — for a different permit source (cartridge purchases), unrelated to `claim_rewards`.

Even once that's fixed, there's a second gap: `_use_permit` (the function that redeems a permit back into spendable L3 actions) is `internal`-only, invoked in exactly one place — automatically inside `purchased_starter_pack`. There's no public `use_permit(permit_id)` entrypoint a player could call themselves for a `CREATOR_REWARD` permit, and `permit_token_test.cairo` has zero test coverage for the `consume_message` / creator-reward path — every existing test there exercises only `purchased_starter_pack`.

**Status: L3 half complete, L2 half unimplemented.** Calling `claim_rewards` today succeeds, marks the batch claimed, and sends a real, successfully-consumed cross-chain message — that produces nothing. No error, no NFT, no way back to the actions that got marked claimed. **Not wired to the client** — nothing in `packages/client` calls `claimRewards` or `getClaimableRewardsCount` (the generated `contracts.gen.ts` still has bindings for both, since dojo's codegen generates one for every entrypoint regardless of whether the client uses it).

There's also `send_rewards` (`actions_token.cairo`) — owner-of-contract-only, sends `FREE_REWARD`-type permits as a manual promo/airdrop tool. Same L2 dependency, same gap, not part of the creator/collaborator flow.

### Architecture note

`packages/starknet` is a fully separate Dojo world from the one the game runs on. Its `dojo_*.toml` profiles (`dev`, `appchain-sepolia`, `saya-test`, `slot`) point at a Katana/Cartridge appchain used for the permit-token side specifically — it is not the public Starknet mainnet or Sepolia testnet, despite the profile name. It has its own generated TypeScript SDK (`packages/starknet/bindings/typescript/`), untouched and unimported anywhere in `packages/client`.

---

## Comparison

| | Path 1: `g_claim_actions` → `claim_actions` | Path 2: `claim_rewards` |
|---|---|---|
| Reachable via | `_claim` terminal command | not wired to the client |
| Caller-facing entrypoint | `claim_actions` (protected — only via `prompt()`) | `claim_rewards` (public — any player, direct) |
| Granularity | exact claimable amount | floored to whole `trail_reward_actions_count` batches |
| Mints on L3? | yes, immediately | no — only marks claimed, fires a message |
| Depends on | nothing else | a second Dojo world whose `consume_message` doesn't finish the job |
| Status | **working** | **L3 half works, L2 half is an unfinished stub** |

---

## What it would take to finish Path 2

1. `packages/starknet/src/systems/permit_token.cairo` — finish `_consume_message`: unpack the payload (`unpack_mint_permit_rewards_payload` already exists, unused), mint a `PermitTokenInfo`, and either auto-use it (mirroring `purchased_starter_pack`) or expose a public `use_permit(permit_id)` if manual redemption is the intended UX.
2. Test coverage for that path in `permit_token_test.cairo` — none exists today.
3. Client-side, only after (1) and (2): a second RPC/world provider pointed at `lore_sn`, importing the already-generated `packages/starknet/bindings/typescript` SDK, plus whatever UI/command surface the redemption step needs.

None of this is started. Path 1 is the only claim mechanism that's usable end-to-end today.

---

## Where the left-panel "claimable" number comes from

`packages/client/src/lib/queriesPanel/uiPanelQueries.ts`, `queryClaimableActionsCount` — reads `ActionsReward` directly via Torii and computes `collected_actions_amount - claimed_actions_amount`, matching Path 1's raw semantics exactly. Deliberately **not** `get_claimable_rewards_count` (the batched view built for Path 2's argument) — that would under-report what `_claim` can actually claim right now, showing 0 in cases where there's real, immediately-claimable balance below one batch.

There's also an older, independent display surface: the in-game `g_actions` text command (`c_handler.cairo`) prints `collected` / `claimed` / `claimable` / `permits claimable` as narrative story text. It uses the batched view for its last line, since it was written for Path 2 — so it can show `permits claimable: 0` in the same case where the left panel correctly shows a positive claimable count. Not a bug in either place, just two different denominations for two different claim mechanisms.

---

## Key files

| File | Role |
|---|---|
| `packages/client/src/data/command.data.ts` | `_claim` terminal command |
| `packages/client/src/lib/stores/leftPanel.store.ts` | `claimableRewards` state, `updateClaimableRewards` |
| `packages/client/src/lib/queriesPanel/uiPanelQueries.ts` | `queryClaimableActionsCount` — raw Torii read of `ActionsReward` |
| `packages/contracts/src/lib/c_handler.cairo` | `g_claim_actions` / `g_actions` system command handlers |
| `packages/contracts/src/systems/actions_token.cairo` | `claim_actions` (Path 1); `claim_rewards` / `get_claimable_rewards_count` / `send_rewards` (Path 2) |
| `packages/contracts/src/models/actions_config.cairo` | `ActionsReward` ledger, `ActionsRewardTrait` |
| `packages/contracts/src/models/player_account.cairo` | `ActionsSource::ActionsClaimed` — how a Path 1 mint is categorized in `PlayerBalances` |
| `packages/starknet/src/systems/permit_token.cairo` | L2 side of Path 2 — `consume_message` (stub), `_use_permit` (internal-only), `purchased_starter_pack` (working, unrelated permit source) |
| `packages/starknet/src/models/appchain.cairo` | `unpack_mint_permit_rewards_payload` — exists, unused |
