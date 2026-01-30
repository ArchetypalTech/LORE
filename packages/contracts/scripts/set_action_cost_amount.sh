#!/bin/bash
set -euo pipefail

if [ $# -ge 2 ]; then
  export PROFILE=$1
  export ACTIONS_COST=$2
else
  echo "Usage: $0 <profile> <actions_cost_with_18_decimals>"
  exit 1
fi

export WORLD_ADDRESS=0x06edbd6fb23929a69ff0fef81f09e3c7689ac01050e4ddb43dc6273f18b37403

#------------------------------------------------------------------------------
# execute dojo call
#
sozo -P $PROFILE execute --world $WORLD_ADDRESS --wait lore-actions_token set_action_cost_amount $ACTIONS_COST
