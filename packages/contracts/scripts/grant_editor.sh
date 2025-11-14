#!/bin/bash
set -euo pipefail

export PROFILE=dev
export WORLD_ADDRESS=0x05dee2ca4cf9c091f17f4607cc048639017fbc2288daf66d8f2f929e61edeeb2

#------------------------------------------------------------------------------
# execute dojo call
#
export ACCOUNT=0x127fd5f1fe78a71f8bcd1fec63e3fe2f0486b6ecd5c86a0466c3a21fa5cfcec # Katana Account #1
export GRANTED=1
sozo -P $PROFILE execute --world $WORLD_ADDRESS --wait lore-designer set_editor $ACCOUNT $GRANTED
