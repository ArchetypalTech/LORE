# Katana TEE / Starknet / Saya integration

## QUICKSTART

Once bootstrapped...

* Create `packages/starknet/.env.dev-sepolia` based on `.env.dev-sepolia.example`

```bash
bun run dev:sepolia
```


## BOOTSTRAP (ONCE)

Based on:
- [katana/docs/tee-deployment.md](https://github.com/dojoengine/katana/blob/main/docs/tee-deployment.md)
- [cross-chain-game/docs/deployment.md](https://github.com/dojoengine/katana/blob/demo/cross-chain-messaging/examples/cross-chain-game/docs/deployment.md)


### Setup

* Install tool versions specified [here](https://github.com/glihm/starknet-messaging-dev/blob/l2-l3-saya/README_saya.md#requirements)

```bash
asdf install
bun i
```

* Build Katana

```bash
# cleanup
rm -rf bin/build
mkdir bin/build
cd bin/build
#
# build Katana
git clone https://github.com/dojoengine/katana
cd katana
git checkout main
git submodule update --init --recursive \
  crates/contracts/contracts/avnu \
  crates/contracts/contracts/openzeppelin \
  crates/contracts/contracts/piltover \
  crates/contracts/contracts/vrf
#
# Install every scarb version the sub-builds pin via asdf.
asdf install scarb 2.8.2
asdf install scarb 2.11.4
asdf install scarb 2.12.2
asdf install scarb 2.13.1
asdf install scarb 2.15.0
#
# Now build (-> ./target/release/katana).
cargo build --release --features tee-mock -p katana
cp ./target/release/katana ../../katana-tee
#
# cleanup
cd ../../..
rm -rf bin/build
```


* Build Saya

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
git checkout v0.4.1
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
export SAYA_SALT=0x112233
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
2026-06-04 18:35:39.337 -03:00 DEBUG saya_ops::core_contract::utils: Contract already declared. contract=TEE registry mock
2026-06-04 18:35:48.240 -03:00 DEBUG saya_ops::core_contract::utils: Contract deployed. contract=TEE registry mock
2026-06-04 18:35:48.240 -03:00 TRACE saya_ops::core_contract::utils: At block tx_hash=0x41bbf1437febbb74f2b018c9d05bf123f7fa152a4dacbeeeea7c66e102e3449 block=10468283
{"command":"declare-and-deploy-tee-registry-mock","class_hash":"0x663dafa18fa3407049671a9a3f79b1a0cdb2ebae33326a4cd568068b0aab7cd","contract_address":"0x198668fe81be498c21b4cc0a422414f64567f7e4e41ddd3bd431e198e65c25a","salt":"0x112233","tx_hash":"0x41bbf1437febbb74f2b018c9d05bf123f7fa152a4dacbeeeea7c66e102e3449","deployed_block":10468283}
(sequencer_venv) ~/Dev/Realms/LORE/packages/starknet $ 
```

* Initialize the rollup, declares and deploys the Piltover

```bash
export TEE_REGISTRY_ADDRESS=0x198668fe81be498c21b4cc0a422414f64567f7e4e41ddd3bd431e198e65c25a
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
✓ Deployment successful (0x1d62bbfe26acd33903f24aef1497aa17029bc71ea9da51a0051677eb00e5aa3) at block #10468729

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
| RPC URL         | https://api.cartridge.gg/x/starknet/sepolia/rpc/v0_9
| Core contract   | 0x1d62bbfe26acd33903f24aef1497aa17029bc71ea9da51a0051677eb00e5aa3
| Deployed block  | #10468729
| Fact registry   | 0x0198668fe81be498c21b4cc0a422414f64567f7e4e41ddd3bd431e198e65c25a
| Config hash     | 0x0375989d4cdb7be11e01408bd6d604b0a7d01c6f599ae1b2e0d1228cda9a1199
```

```bash
# get PILTOVER_ADDRESS from chain config
echo $(grep '^core_contract' ./data/dev-sepolia/chain-config/config.toml | head -1 | awk -F'"' '{print $2}')
0x1d62bbfe26acd33903f24aef1497aa17029bc71ea9da51a0051677eb00e5aa3
# save for later...
export PILTOVER_ADDRESS=0x1d62bbfe26acd33903f24aef1497aa17029bc71ea9da51a0051677eb00e5aa3
```

