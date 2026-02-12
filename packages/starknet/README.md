# Katana / Starknet / Saya integration

Based on: [https://github.com/glihm/starknet-messaging-dev/tree/l2-l3-saya](https://github.com/glihm/starknet-messaging-dev/tree/l2-l3-saya)


## TESTING Locally

* Install tool versions specified [here](https://github.com/glihm/starknet-messaging-dev/blob/l2-l3-saya/README_saya.md#requirements)

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
