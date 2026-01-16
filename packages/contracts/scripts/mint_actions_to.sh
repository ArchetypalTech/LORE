#!/bin/bash
set -euo pipefail

if [ $# -ge 3 ]; then
  export PROFILE=$1
  export ACCOUNT=$2
  export ACTIONS_COUNT=$3
else
  echo "Usage: $0 <profile> <account> <actions_count>"
  exit 1
fi

export WORLD_ADDRESS=0x06edbd6fb23929a69ff0fef81f09e3c7689ac01050e4ddb43dc6273f18b37403

#------------------------------------------------------------------------------
# execute dojo call
#
sozo -P $PROFILE execute --world $WORLD_ADDRESS --wait lore-actions_token mint_to $ACCOUNT $ACTIONS_COUNT
