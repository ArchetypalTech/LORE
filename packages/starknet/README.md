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
# Run Katana
bun run local_saya
```
