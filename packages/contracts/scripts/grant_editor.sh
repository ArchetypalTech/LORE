#!/bin/bash
set -euo pipefail

export PROFILE=dev
export WORLD_ADDRESS=0x06edbd6fb23929a69ff0fef81f09e3c7689ac01050e4ddb43dc6273f18b37403`

#------------------------------------------------------------------------------
# execute dojo call
#
export ACCOUNT=0x127fd5f1fe78a71f8bcd1fec63e3fe2f0486b6ecd5c86a0466c3a21fa5cfcec # Katana Account #1
export GRANTED=1
sozo -P $PROFILE execute --world $WORLD_ADDRESS --wait lore-designer set_editor $ACCOUNT $GRANTED
