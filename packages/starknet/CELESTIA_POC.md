# Appchain POC with Celestia/Sepolia

Local proof of concept L2/L3/Celestia


### Setup environment variables

Fill env variables in `/packages/starknet/.env.sepolia`:

```bash
# /packages/starknet/.env.sepolia
export SETTLEMENT_ACCOUNT_ADDRESS=...
export SETTLEMENT_ACCOUNT_PRIVATE_KEY=...
export CELESTIA_TOKEN=...
```

## Terminal 1: Start L3 Katana locally

```bash
cd packages/starknet
source .env.sepolia
export APPCHAIN_ID=lore_appchain
export KATANA_L3_BIN=./bin/katana-1.7.0-snos.4
export KATANA_L3_PORT=5050
export DATA_PATH=./data/${APPCHAIN_ID}
export KATANA_L3_DB_PATH=./data/db/${APPCHAIN_ID}
echo ">>> APPCHAIN_ID: [${APPCHAIN_ID}]"
echo ">>> DATA_PATH: [${DATA_PATH}]"
echo ">>> KATANA_L3_PORT: [${KATANA_L3_PORT}]"
echo ">>> KATANA_L3_BIN: [${KATANA_L3_BIN}]"
echo ">>> KATANA_L3_DB_PATH: [${KATANA_L3_DB_PATH}]"
# delete database to deploy a new appchain
rm -rf ${KATANA_L3_DB_PATH}
${KATANA_L3_BIN} --version
${KATANA_L3_BIN} \
  --chain ${DATA_PATH} \
  --db-dir ${KATANA_L3_DB_PATH} \
  --http.port ${KATANA_L3_PORT}
  # --dev --dev.no-fee
  # --http.cors_origins "*" \
  # --cartridge.controllers --cartridge.paymaster
  # --block-time ${BLOCK_TIME} --sequencing.block-max-cairo-steps ${MAX_CAIRO_STEPS}
```

```
PREFUNDED ACCOUNTS
==================

| Account address |  0x1f401c745d3dba9b9da11921d1fb006c96f571e9039a0ece3f3b0dc14f04c3d
| Private key     |  0x7230b49615d175307d580c33d6fda61fc7b9aec91df0f5c1a5ebe3b8cbfee02
| Public key      |  0x78e6e3e4a50285be0f6e8d0b8a61044033e24023df6eb95979ae4073f159ae6
```


## Terminal 2: Migrate L3 Katana locally

Execute only once, as we're using a local database.

```bash
cd packages/contracts
export PROFILE=saya-test
sozo -P ${PROFILE} build
sozo -P ${PROFILE} inspect
sozo -P ${PROFILE} migrate
# sozo -P ${PROFILE} migrate --l1-data-gas 20000000000 --l1-gas 20000000000 --l1-gas-price 20000000000 --l2-gas-price 20000000000 --l1-data-gas-price 20000000000 --l2-gas 20000000000
```


## Terminal 3: Start Saya locally

Setup env variables (1st step)

```bash
cd packages/starknet
source .env.sepolia
export APPCHAIN_ID=lore_appchain
export DATA_PATH=./data/${APPCHAIN_ID}
export DB_DIR=./data/db/${APPCHAIN_ID}
export ROLLUP_RPC=http://localhost:5050
export SETTLEMENT_RPC=https://api.cartridge.gg/x/starknet/sepolia/rpc/v0_9
export SETTLEMENT_PILTOVER_ADDRESS=$(grep '^core_contract' ${DATA_PATH}/config.toml | sed -E 's/core_contract = "([^"]+)"/\1/')
export CELESTIA_RPC=https://celestia.mocha.glihm.com
echo ">>> DB_DIR: [${DB_DIR}]"
echo ">>> SETTLEMENT_RPC: [${SETTLEMENT_RPC}]"
echo ">>> ROLLUP_RPC: [${ROLLUP_RPC}]"
echo ">>> SETTLEMENT_PILTOVER_ADDRESS: [${SETTLEMENT_PILTOVER_ADDRESS}]"
echo ">>> SETTLEMENT_ACCOUNT_ADDRESS: [${SETTLEMENT_ACCOUNT_ADDRESS}]"
echo ">>> SETTLEMENT_ACCOUNT_PRIVATE_KEY: [${SETTLEMENT_ACCOUNT_PRIVATE_KEY}]"
echo ">>> CELESTIA_RPC: [${CELESTIA_RPC}]"
echo ">>> CELESTIA_TOKEN: [${CELESTIA_TOKEN}]"
#----------------
# start saya
#
# rm -rf ${DB_DIR}/saya.db
echo ">>> Starting Saya..."
saya --version
saya persistent start \
  --mock-snos-from-pie \
  --mock-layout-bridge-program-hash 0x43c5c4cc37c4614d2cf3a833379052c3a38cd18d688b617e2c720e8f941cb8
  # --settlement-rpc ${SETTLEMENT_RPC} \
  # --settlement-piltover-address ${SETTLEMENT_PILTOVER_ADDRESS} \
  # --settlement-account-address ${SETTLEMENT_ACCOUNT_ADDRESS} \
  # --settlement-account-private-key ${SETTLEMENT_ACCOUNT_PRIVATE_KEY} \
  # --rollup-rpc ${ROLLUP_RPC} \
  # --db-dir ${DB_DIR} \
```



## Terminal 4: Run some L3 transaction

Test transaction to check on Celestia...

```bash
export PROFILE=saya-test
cd packages/contracts
./scripts/mint_actions_to.sh $PROFILE 0x1234 20
# Transaction hash: 0x0189b5e9147e13fe6869aa1768c28aa26ce01930434ff319fae6e4750ef60b0d
sozo -P $PROFILE call lore-actions_token balance_of 0x1234
# [ 0x0x000000000000000000000000000000000000000000000001158e460913d00000 0x0x0000000000000000000000000000000000000000000000000000000000000000 ]
```
