#!/usr/bin/env bash
set -e

source "$(dirname "$0")/utils.sh"

WORLD_ADDRESS="$(get_profile_env "$PROFILE" world_address)"
GAME_TOKEN_ADDRESS="$(get_contract_address "$PROFILE" lore-game_token)"
TRAIL_TOKEN_ADDRESS="$(get_contract_address "$PROFILE" lore-trail_token)"

echo ">>> Dojo world = [$WORLD_ADDRESS]"
echo ">>> Game token = [$GAME_TOKEN_ADDRESS]"
echo ">>> Trail token = [$TRAIL_TOKEN_ADDRESS]"

wait-port 5050

torii \
  --http.cors_origins "*" \
  --world "$WORLD_ADDRESS" \
  --indexing.contracts \
    erc721:"$GAME_TOKEN_ADDRESS",erc721:"$TRAIL_TOKEN_ADDRESS"