# Katana / Starknet / Saya integration

Based on: [https://github.com/glihm/starknet-messaging-dev/tree/l2-l3-saya](https://github.com/glihm/starknet-messaging-dev/tree/l2-l3-saya)


## SETUP

* Install tool versions specified [here](https://github.com/glihm/starknet-messaging-dev/blob/l2-l3-saya/README_saya.md#requirements)

```bash
asdf install
```


## DEPLOYMENT (sepolia/mainnet)

Setup environment variables

```bash
# .env.sepolia
export SETTLEMENT_ACCOUNT_ADDRESS=...
export SETTLEMENT_ACCOUNT_PRIVATE_KEY=...
export DOJO_ACCOUNT_ADDRESS=...
export DOJO_PRIVATE_KEY=...
```

Deploy L2 (Starknet)

```bash
# Deploy to sepolia
export PROFILE=sepolia
. .env.sepolia
cd packages/starknet
bun run sepolia:deploy $PROFILE

# >> saya core-contract declare
# [2026-02-24T22:46:44Z INFO  saya::core_contract::utils] Contract Core contract already declared.
# [2026-02-24T22:46:44Z INFO  saya::core_contract::cli] Core contract class hash: 0x1d7927de261ef86b08e58f850b47a1ed93587f87167b512cded4c1a1b3391a3

# >> saya core-contract deploy --salt 0x6c6f72655f736e5f305f325f30
# [2026-02-24T22:46:50Z INFO  saya::core_contract::utils] Contract Core contract deployed.
# [2026-02-24T22:46:50Z INFO  saya::core_contract::utils] Tx hash   : 0x1ec64d8af41a36a6814178074d094f0a4819ac3994b6b655b39dee4354a338
# [2026-02-24T22:46:50Z INFO  saya::core_contract::utils] At block  : 6881095
# [2026-02-24T22:46:50Z INFO  saya::core_contract::cli] Core contract address: 0x9496013cd0ffc7111c6c8358830d0f0453615b56f99a1258781301c90401ab

# :: Setting up program...
# >> saya core-contract setup-program --chain-id lore_appchain
# [2026-02-26T00:15:17Z INFO  saya::core_contract::cli] Starknet OS config hash: 0x5c2a46422ec5a12ae5212a7938ba96814f68d8676c5084d24cc154ebcf38212
# [2026-02-26T00:15:23Z INFO  saya::core_contract::cli] Set program info transaction submitted: Hash(0x199fa9d16c486885e20b635c53825ac2bf83dbe8c7958b41d99213bb17cfd64)
# [2026-02-26T00:15:29Z INFO  saya::core_contract::cli] Fact registry set transaction submitted: Hash(0x543d44ab3aaeac0355ae9f709019e669ad8fc0bdd56e92cbacb6ed43e672420)
```

References:
- [Starknet contract addresses](https://docs.herodotus.dev/herodotus-docs/developers/contract-addresses)


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
sozo -P $PROFILE execute --world $L2_WORLD_ADDRESS --wait lore_sn-permit_token purchased_starter_pack $RECIPIENT
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
sozo -P $PROFILE model get lore-ActionsConfig 1
sozo -P $PROFILE execute --world $L3_WORLD_ADDRESS --wait lore-actions_token send_rewards $RECIPIENT 0x1
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
