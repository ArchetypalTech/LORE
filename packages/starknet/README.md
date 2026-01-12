# Katana / Starknet / Saya integration

Based on: [https://github.com/glihm/starknet-messaging-dev/tree/l2-l3-saya](https://github.com/glihm/starknet-messaging-dev/tree/l2-l3-saya)


## Running Locally

* Install tool versions specified [here](https://github.com/glihm/starknet-messaging-dev/tree/l2-l3-saya?tab=readme-ov-file#requirements)

### Katana L3

Currently, we need a specific Katana version for L3

* Copy `katana_l3` to `/packages/starknet/bin` (ask Glihm or copy from Docker image)

* Replace `account_address` and `private_key` in `/packages/contracts/dojo_dev.toml`:

```toml
# account_address = "0x6677fe62ee39c7b07401f754138502bab7fac99d2d3c5d37df7d1c6fab10819"
# private_key = "0x3e3979c1ed728490308054fe357a9f49cf67f80f9721f44cc57235129e090f4"

# katana_l3
account_address = "0x1f401c745d3dba9b9da11921d1fb006c96f571e9039a0ece3f3b0dc14f04c3d"
private_key = "0x7230b49615d175307d580c33d6fda61fc7b9aec91df0f5c1a5ebe3b8cbfee02"
```

### Deploy and start L2 / L3...

```bash
# Run L2+L3
bun run dev:saya
# ...wait unil initializer says: 👍 Done!
```

Test messaging

```bash
export L2_WORLD_ADDRESS=0x07d90bdb9b6af74c5c9c29e16a909e82e9faa78da2bf6c35b07504262592f17a
export L3_WORLD_ADDRESS=0x06edbd6fb23929a69ff0fef81f09e3c7689ac01050e4ddb43dc6273f18b37403
export RECIPIENT=0x1234
#
# L2 > L3 messaging
#
# L2: send message to mint actions on L3
cd packages/starknet/
sozo model get lore_sn-PermitConfig 1
sozo execute --world $L2_WORLD_ADDRESS --wait lore_sn-permit_token purchased_starter_pack $RECIPIENT
# L2: validate permits balance (must be 0x1)
sozo call --world $L2_WORLD_ADDRESS lore_sn-permit_token balance_of $RECIPIENT
#
# L3: validate actions balance (must be greater than zero)
cd packages/contracts/
sozo model get lore-ActionsConfig 1
sozo call --world $L3_WORLD_ADDRESS lore-actions_token balance_of $RECIPIENT
#
# L3 > L2 messaging
#
# L3: send message to mint rewards on L2
cd packages/contracts/
sozo execute --world $L3_WORLD_ADDRESS --wait lore-actions_token send_rewards $RECIPIENT 0x1
# L3: find message event (the last one must be lore-AppchainMessageEvent)
sozo events --world $L3_WORLD_ADDRESS | tail -n 9
#
# L2: consume message
cd packages/contracts/
sozo execute --world $L2_WORLD_ADDRESS --wait lore_sn-permit_token consume_message arr:0x1,0x4d494e545f5045524d49545f52455741524453,0x465245455f524557415244,0x1234,0x1
# L2: validate permits balance (must be 0x2)
sozo call --world $L2_WORLD_ADDRESS lore_sn-permit_token balance_of $RECIPIENT
```
