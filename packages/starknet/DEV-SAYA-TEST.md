# Katana / Starknet / Saya integration

> ❌ DEPRECATED! now use [./DEV-SEPOLIA.md](./DEV-SEPOLIA.md)

Based on: [https://github.com/glihm/starknet-messaging-dev/tree/l2-l3-saya](https://github.com/glihm/starknet-messaging-dev/tree/l2-l3-saya)

Useful references:
- [Starknet contract addresses](https://docs.herodotus.dev/herodotus-docs/developers/contract-addresses)


## SETUP

* Install tool versions specified [here](https://github.com/glihm/starknet-messaging-dev/blob/l2-l3-saya/README_saya.md#requirements)

```bash
asdf install
```


## DEPLOYMENT (sepolia/mainnet)

Let's define some nomenclature:

- `/packages/starknet` L2 profile: `sepolia` or `mainnet`
- `/packages/contracts` L3 profile: `appchain-sepolia` or `appchain-mainnet`
- Slot services: `lore_appchain_<PROFILE>` (katana and torii)
- Appchain id: `lore-appchain-<PROFILE>`. Note: this is the config file used to deploy Katana, and the chain id

Deployment is a multi-step process:

1. Deploy L2 (Starknet) core contract, dojo contracts, and create appchain config
2. Create the L3 (Katana) slot instance, using the appchain config
3. Deploy L3 game contracts
4. Configure all contracts addresses on L2 and L3 for messaging
5. Deploy Saya (local or remote)


### Step 0: Setup environment variables

Use account and keys for STARKNET (sepolia/mainnet)

```bash
# /packages/starknet/.env.sepolia
export SETTLEMENT_ACCOUNT_ADDRESS=...
export SETTLEMENT_ACCOUNT_PRIVATE_KEY=...
export DOJO_ACCOUNT_ADDRESS=...
export DOJO_PRIVATE_KEY=...
```


### Step 1: Deploy L2

```bash
# Deploy to sepolia (mainnet is the same process)
export PROFILE=sepolia
cd packages/starknet
. .env.sepolia
bun run sepolia:sn_deploy $PROFILE
```

When it runs for the first time, it will deploy and print `Core contract address` and block number `At block`, then it's expected to fail. We add those to `dojo_<PROFILE>.toml` and run again. The script can be run multiple times, it always skip what's already deployed.

```bash
# >> saya core-contract deploy --salt 0x6c6f72655f736e5f305f325f30
# [2026-02-24T22:46:50Z INFO  saya::core_contract::utils] Contract Core contract deployed.
# [2026-02-24T22:46:50Z INFO  saya::core_contract::utils] Tx hash   : 0x1ec64d8af41a36a6814178074d094f0a4819ac3994b6b655b39dee4354a338
# [2026-02-24T22:46:50Z INFO  saya::core_contract::utils] At block  : 6881095
# [2026-02-24T22:46:50Z INFO  saya::core_contract::cli] Core contract address: 0x9496013cd0ffc7111c6c8358830d0f0453615b56f99a1258781301c90401ab
```

### Step 2: Create L3 Katana on slot

```bash
# Create L3 Katana on slot
export PROFILE=sepolia
cd packages/starknet
. .env.sepolia
bun run sepolia:sn_slot $PROFILE
# verify chain id
starkli chain-id  --rpc "https://api.cartridge.gg/x/lore-appchain-${PROFILE}/katana"
0x57505f4c4f52455f415050434841494e (WP_LORE_APPCHAIN_SEPOLIA)
# list accounts for contrats dojo config
slot deployments logs "lore-appchain-${PROFILE}" katana --limit 100
```

### Step 3: Deploy L3 game contracts

```bash
# ! on a different terminal
# Create L3 Katana on slot
export PROFILE=appchain-sepolia
cd packages/contracts
bun run appchain-sepolia:migrate $PROFILE
```







## TESTING Locally

Running L2 and L3 locally (not the game)...

### Katana L3

Currently, we need a specific Katana version for L3

* ~~Copy `katana_l3` to `/packages/starknet/bin` (ask Glihm or copy from Docker image)~~
* Copy `katana-1.7.0-snos.4` to `/packages/starknet/bin` (ask Glihm or copy from Docker image)

### Deploy and start L2 / L3...

```bash
# Run L2+L3
bun run dev:saya-test
# ...wait unil initializer says: 👍 Ready!!
```

Test messaging

```bash
export L2_WORLD_ADDRESS=0x07d90bdb9b6af74c5c9c29e16a909e82e9faa78da2bf6c35b07504262592f17a
export L3_WORLD_ADDRESS=0x06edbd6fb23929a69ff0fef81f09e3c7689ac01050e4ddb43dc6273f18b37403
export RECIPIENT=0x1234
export PROFILE=saya-test
#
# L2 > L3 messaging
#
# L2: send message to mint actions on L3
cd packages/starknet/
sozo -P $PROFILE model get lore_sn-PermitConfig 1
sozo -P $PROFILE execute --world $L2_WORLD_ADDRESS --wait lore_sn-permit_token purchased_bundle $RECIPIENT
# L2: validate permits balance (must be 0x1)
sozo -P $PROFILE call --world $L2_WORLD_ADDRESS lore_sn-permit_token balance_of $RECIPIENT
#
# L3: validate actions balance (must be greater than zero)
cd packages/contracts/
sozo -P $PROFILE call --world $L3_WORLD_ADDRESS lore-actions_token balance_of $RECIPIENT
#
# L3 > L2 messaging
#
# L3: send message to mint rewards on L2
cd packages/contracts/
source .env.dev-sepolia
sozo -P $PROFILE model get lore-ActionsConfig 1
sozo -P $PROFILE execute --world $L3_WORLD_ADDRESS --wait lore-actions_token airdrop_rewards $RECIPIENT 0x1
# L3: find message event (the last one must be lore-AppchainMessageEvent)
sozo -P $PROFILE events --world $L3_WORLD_ADDRESS | tail -n 9
#
# L2: consume message -- use the last 5 values from the printed event above
cd packages/starknet/
sozo -P $PROFILE execute --world $L2_WORLD_ADDRESS --wait lore_sn-permit_token consume_message arr:\
0x0000000000000000000000000000000000000000000000000000000000000001,\
0x000000000000000000000000004d494e545f5045524d49545f52455741524453,\
0x000000000000000000000000000000000000000000465245455f524557415244,\
0x0000000000000000000000000000000000000000000000000000000000001234,\
0x0000000000000000000000000000000000000000000000000000000000000001
# L2: validate permits balance (must be 0x2)
sozo -P $PROFILE call --world $L2_WORLD_ADDRESS lore_sn-permit_token balance_of $RECIPIENT
```
