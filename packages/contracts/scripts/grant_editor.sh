#!/bin/bash
set -euo pipefail

export PROFILE=dev
export WORLD_ADDRESS=0x0189849c1a8851e3ad29a83c92ae7bee9d1e5fb3b9aff33eb61493f402580f1a

#------------------------------------------------------------------------------
# execute dojo call
#
export ACCOUNT=0x127fd5f1fe78a71f8bcd1fec63e3fe2f0486b6ecd5c86a0466c3a21fa5cfcec # Katana Account #1
export GRANTED=1
sozo -P $PROFILE execute --world $WORLD_ADDRESS --wait lore-designer set_editor $ACCOUNT $GRANTED
