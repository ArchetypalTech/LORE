#!/bin/bash
echo "Running project setup..."
export PATH="/home/linuxbrew/.bun/bin:$PATH"
cd /workspaces/LORE && bun run ./scripts/quickstart.ts -y