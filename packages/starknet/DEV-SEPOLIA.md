# Katana TEE / Starknet / Saya integration

## QUICKSTART

Once bootstrapped...

* Create `packages/starknet/.env.dev-sepolia` based on `.env.dev-sepolia.example`

```bash
bun run dev:sepolia
```

* L3 Helpers

```bash
#
# L3 Katana
#
export RECIPIENT=0x0550212D3F13a373DfE9e3Ef6aA41fBA4124BDe63FD7955393f879De19f3F47F
export L3_PROFILE=appchain-sepolia
# Actions balance
cd packages/contracts/
sozo -P $L3_PROFILE call lore-actions_token balance_of $RECIPIENT
# Airdrop a reward > message to L2
sozo -P $L3_PROFILE execute --wait lore-actions_token airdrop_rewards $RECIPIENT 0x1
# get last event (message)
sozo -P $L3_PROFILE events  | tail -n 9
-----
> Event emitted (lore-AppchainMessageEvent) [block:57 / tx:0x04028c2cfa583dc7e7f9834b02902d65b298a6e47b17a07838990bdde72794b1]
Selector: 0x03d690231464187d245c60621c09209061a40347b82077ec4cb8e145179de19d
Contract: lore-actions_token
Keys: 0x0000000000000000000000000000000000000000000000000000000000000001
Values: 0x00dcbeb1f415c0c3e8ae300f3550ff9d649c03c2aeea5ec15f9862139ac3857b, 0x01f0ae4fbfd635cabdeecb5567b9f210fb6d71fa07ce358373ce7de3cb586265, 0x0190095702bd73b4df73b4b1adeccead913087066ba6a92a8df806655a15d4f4, 0x0000000000000000000000000000000000000000000000000000000000000039, 0x000000000000000000000000000000000000000000000000000000006a2b604d, 0x065524806c2092b8bd49c0edb187dc22bf70ee1bc28f4ce73ebdade2e022268c, 0x000000000000000000000000004d494e545f5045524d49545f52455741524453, 0x0000000000000000000000000000000000000000000000000000000000000005, 0x0000000000000000000000000000000000000000000000000000000000000001, 0x000000000000000000000000004d494e545f5045524d49545f52455741524453, 0x0000000000000000000000000000000000005245574152445f41495244524f50, 0x0550212d3f13a373dfe9e3ef6aa41fba4124bde63fd7955393f879de19f3f47f, 0x0000000000000000000000000000000000000000000000000000000000000001
-----
#
# L2 Starknet
#
export RECIPIENT=0x0550212D3F13a373DfE9e3Ef6aA41fBA4124BDe63FD7955393f879De19f3F47F
export L2_PROFILE=sepolia
# L2: consume message -- use the last 5 values from the printed event above
cd packages/starknet/
sozo -P $L2_PROFILE execute --wait lore_sn-permit_token consume_message arr:\
0x0000000000000000000000000000000000000000000000000000000000000001,\
0x00dcbeb1f415c0c3e8ae300f3550ff9d649c03c2aeea5ec15f9862139ac3857b,\
0x01f0ae4fbfd635cabdeecb5567b9f210fb6d71fa07ce358373ce7de3cb586265,\
0x0190095702bd73b4df73b4b1adeccead913087066ba6a92a8df806655a15d4f4,\
0x0000000000000000000000000000000000000000000000000000000000000039,\
0x000000000000000000000000000000000000000000000000000000006a2b604d,\
0x065524806c2092b8bd49c0edb187dc22bf70ee1bc28f4ce73ebdade2e022268c,\
0x000000000000000000000000004d494e545f5045524d49545f52455741524453,\
0x0000000000000000000000000000000000000000000000000000000000000005,\
0x0000000000000000000000000000000000000000000000000000000000000001,\
0x000000000000000000000000004d494e545f5045524d49545f52455741524453,\
0x0000000000000000000000000000000000005245574152445f41495244524f50,\
0x0550212d3f13a373dfe9e3ef6aa41fba4124bde63fd7955393f879de19f3f47f,\
0x0000000000000000000000000000000000000000000000000000000000000001
# L2: validate permits balance (must be 0x2)
sozo -P $L2_PROFILE call lore_sn-permit_token balance_of $RECIPIENT

#
# ADMIN
#
# update bundles
sozo -P $L2_PROFILE execute lore_sn-setup update_bundles
```


## BOOTSTRAP (ONCE)

Based on:
- [katana/docs/tee-deployment.md](https://github.com/dojoengine/katana/blob/main/docs/tee-deployment.md)
- [cross-chain-game/docs/deployment.md](https://github.com/dojoengine/katana/blob/demo/cross-chain-messaging/examples/cross-chain-game/docs/deployment.md)


### Setup

* Install tool versions from [./tool-versions](./tool-versions)

```bash
asdf install
bun i
```

* Build `saya-ops`

```bash
# cleanup
rm -rf bin/build
mkdir bin/build
cd bin/build
#
# build Saya 0.4.x
# as in: https://github.com/dojoengine/saya/blob/main/README.md
git clone https://github.com/dojoengine/saya
cd saya
git checkout v0.4.2
make install-scarb
python3 -m venv sequencer_venv
. sequencer_venv/bin/activate
CFLAGS="-I$(brew --prefix gmp)/include" LDFLAGS="-L$(brew --prefix gmp)/lib" \
  pip install "cairo-lang==0.14.0.1"
cairo-compile --version   # must print: cairo-compile 0.14.0.1
#
# We only need the TEE prover. Each bin/* is its own cargo workspace, so building
# bin/persistent-tee compiles only saya-tee's dependency closure — there are no
# feature flags to trim, and the other two binaries are skipped entirely:
#   bin/persistent      -> target/release/saya       (Atlantic / sovereign)  -- SKIP
#   bin/ops             -> target/release/saya-ops   (piltover deploy/config) -- SKIP
#   bin/persistent-tee  -> target/release/saya-tee   (TEE prover; needs cairo-compile)
cd bin/ops && cargo build --release && cd ../..
cd bin/persistent-tee && cargo build --release && cd ../..
cp ./bin/ops/target/release/saya-ops ../..
cp ./bin/persistent-tee/target/release/saya-tee ../..
#
# cleanup
cd ../../..
rm -rf bin/build
```

### Deployments

> Based on: [https://github.com/dojoengine/katana/blob/main/docs/tee-deployment.md#development-mode-mock-tee](https://github.com/dojoengine/katana/blob/main/docs/tee-deployment.md#development-mode-mock-tee)

* Deploy the mock TEE registry

```bash
export SEED="lore_sn_0_2_6"
export SAYA_SALT=$(starkli to-cairo-string "$SEED")
source .env.dev-sepolia
./bin/saya-ops core-contract \
  --account-address  "$DEPLOYER_ADDRESS" \
  --private-key      "$DEPLOYER_PRIVATE_KEY" \
  --settlement-rpc-url "$STARKNET_RPC_URL" \
  --settlement-chain-id sepolia \
  --output json \
  declare-and-deploy-tee-registry-mock \
  --salt "$SAYA_SALT"
```

```
# grab contract_address from the JSON output — call this TEE_REGISTRY_ADDRESS
2026-06-23 12:30:38.818 -03:00 DEBUG saya_ops::core_contract::utils: Contract already declared. contract=TEE registry mock
2026-06-23 12:30:44.871 -03:00 DEBUG saya_ops::core_contract::utils: Contract deployed. contract=TEE registry mock
2026-06-23 12:30:44.871 -03:00 TRACE saya_ops::core_contract::utils: At block tx_hash=0x6816d08470150280383c4c6644f2e6caff39eac0cc0445ad32227969a243b4f block=11115588
{"command":"declare-and-deploy-tee-registry-mock","class_hash":"0x663dafa18fa3407049671a9a3f79b1a0cdb2ebae33326a4cd568068b0aab7cd","contract_address":"0x4f2e4e1f3d2ee238e14cb2a64d824ee7b8bc08d1c95f4de92772d778481b924","salt":"0x6c6f72655f736e5f305f325f36","tx_hash":"0x6816d08470150280383c4c6644f2e6caff39eac0cc0445ad32227969a243b4f","deployed_block":11115588}
```

* Initialize the rollup, declares and deploys the Piltover

```bash
# remove old
rm -rf ./data/dev-sepolia/chain-config
rm -rf ./data/dev-sepolia/chain-data
rm -rf ./data/dev-sepolia/saya/saya.db
# create new
export TEE_REGISTRY_ADDRESS=0x4f2e4e1f3d2ee238e14cb2a64d824ee7b8bc08d1c95f4de92772d778481b924
export CHAIN_CONFIG_PATH=./data/dev-sepolia/chain-config
./bin/katana-tee init rollup \
  --id MY_APPCHAIN_DEV \
  --settlement-chain               "$STARKNET_RPC_URL" \
  --settlement-account-address     "$DEPLOYER_ADDRESS" \
  --settlement-account-private-key "$DEPLOYER_PRIVATE_KEY" \
  --tee \
  --tee-registry-address "$TEE_REGISTRY_ADDRESS" \
  --output-path "${CHAIN_CONFIG_PATH}"
```

```
✓ Deployment successful (0x3b1edb674c8553a617bf4e62484b51b4412228a708fc4a8166b11528e8329ba) at block #11115684

CHAIN
=====

| Chain ID        | MY_APPCHAIN_DEV (0x4d595f415050434841494e5f444556)
| Config file     | ./data/dev-sepolia/chain-config/config.toml
| Genesis file    | ./data/dev-sepolia/chain-config/genesis.json


SETTLEMENT LAYER
================

| Proof category  | TEE
| Proof type      | AMD SEV-SNP + SP1 Groth16
| Chain ID        | SN_SEPOLIA (0x534e5f5345504f4c4941)
| RPC URL         | https://api.cartridge.gg/x/starknet/sepolia/rpc/v0_10
| Core contract   | 0x3b1edb674c8553a617bf4e62484b51b4412228a708fc4a8166b11528e8329ba
| Deployed block  | #11115684
| Fact registry   | 0x04f2e4e1f3d2ee238e14cb2a64d824ee7b8bc08d1c95f4de92772d778481b924
| Config hash     | 0x0375989d4cdb7be11e01408bd6d604b0a7d01c6f599ae1b2e0d1228cda9a1199
```

```bash
# get PILTOVER_ADDRESS from chain config
echo $(grep '^core_contract' ./data/dev-sepolia/chain-config/config.toml | head -1 | awk -F'"' '{print $2}')
0x3b1edb674c8553a617bf4e62484b51b4412228a708fc4a8166b11528e8329ba
# save for later...
export PILTOVER_ADDRESS=0x3b1edb674c8553a617bf4e62484b51b4412228a708fc4a8166b11528e8329ba
```
