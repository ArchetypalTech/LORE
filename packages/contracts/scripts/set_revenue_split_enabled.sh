#!/bin/bash
set -euo pipefail

if [ $# -ge 2 ]; then
  export PROFILE=$1
  export ENABLED=$2
else
  echo "Usage: $0 <profile> <true|false>"
  exit 1
fi

if [ "$ENABLED" == "true" ]; then
  export ENABLED_VALUE=1
elif [ "$ENABLED" == "false" ]; then
  export ENABLED_VALUE=0
else
  echo "Usage: $0 <profile> <true|false>"
  exit 1
fi

export WORLD_ADDRESS=0x06edbd6fb23929a69ff0fef81f09e3c7689ac01050e4ddb43dc6273f18b37403

#------------------------------------------------------------------------------
# execute dojo call
#
sozo -P $PROFILE execute --world $WORLD_ADDRESS --wait lore-actions_token set_revenue_split_enabled $ENABLED_VALUE
