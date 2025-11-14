#!/bin/bash
set -euo pipefail

export CHAIN_ID=KATANA_DA_LOCAL
export SETTLEMENT_CHAIN=sepolia
export SETTLEMENT_ADDRESS=0x020dD2C29473df564F9735B7c16063Eb3B7A4A3bd70a7986526636Fe33E8227d
export SETTLEMENT_PRIVATE_KEY=
export CHAIN_CONFIG_PATH=./chain-config-sepolia

katana init rollup \
  --id $CHAIN_ID \
  --settlement-chain $SETTLEMENT_CHAIN \
  --settlement-account-address $SETTLEMENT_ADDRESS \
  --settlement-account-private-key $SETTLEMENT_PRIVATE_KEY \
  --output-path $CHAIN_CONFIG_PATH

# deployed on sepolia
# account: 0x020dD2C29473df564F9735B7c16063Eb3B7A4A3bd70a7986526636Fe33E8227d
# ✓ Deployment successful (0x40684c12ed05a96798fe8d0c91d278c8885ea716bba4436fb06c3038246f37b) at block #2864564
