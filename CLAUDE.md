# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LORE is a Dojoengine-based, Zork & MUD inspired, fully onchain interactive multiplayer fiction engine. It's a monorepo with two main packages:

- **client**: React/TypeScript frontend game client with terminal interface and world editor
- **contracts**: Cairo smart contracts using Dojo framework for game logic and world state

## Development Commands

### Root Level Commands
- `bun run dev` - Start local development mode (runs Katana blockchain, Torii indexer, and client)
- `bun run dev:slot` - Start slot mode for deployment testing (creates SSL cert, requires sudo)
- `bun install` - Install all dependencies

### Client Package (`packages/client/`)
- `bun run dev` - Start Vite dev server in development mode
- `bun run dev:slot` - Start Vite dev server in slot mode
- `bun run build` - Build for production
- `bun run build:slot` - Build for slot deployment
- `bun run lint` - Run both oxlint and biome linting
- `bun run lint:biome` - Run biome formatter and linter with auto-fix
- `bun run lint:oxlint` - Run oxlint with auto-fix
- `bun run preview` - Preview production build

### Contracts Package (`packages/contracts/`)
- `bun run dev:watch` - Watch and rebuild contracts in dev mode
- `bun run slot:deploy` - Deploy contracts to slot
- `bun run slot:upgrade` - Upgrade contracts on slot
- `bun run slot:watch` - Watch contracts for slot deployment

### Cairo/Dojo Commands
- `sozo build` - Build Cairo contracts
- `sozo migrate apply` - Apply migrations
- `katana --dev --dev.no-fee --http.cors_origins "*"` - Start local Katana blockchain
- `torii --world <address> --http.cors_origins "*"` - Start Torii indexer

## Architecture

### Frontend Architecture
- **Framework**: React 18 with TypeScript, Vite for bundling
- **Styling**: TailwindCSS v4 with custom CRT terminal effects
- **State Management**: Zustand stores for dojo, terminal, user, and wallet state
- **Routing**: Wouter for client-side routing
- **Dojo Integration**: Uses @dojoengine/sdk v1.5.10 for blockchain interactions

### Key Frontend Components
- **Terminal**: Interactive command-line interface (`src/client/terminal/`)
- **Editor**: World editor for creating/modifying game entities (`src/editor/`)
- **SystemCalls**: Contract interaction layer (`src/lib/systemCalls.ts`)
- **Dojo Setup**: SDK initialization and configuration (`src/lib/dojo.ts`)

### Cairo Contract Architecture
- **Cairo Version**: 2.10.1 with Dojo v1.5.0
- **Main Systems**:
  - `prompt.cairo` - Handles player commands and text parsing
  - `designer.cairo` - World creation and entity management
- **Components**: Entity component system with models for areas, players, containers, etc.
- **Libraries**: Lexer, command handler, random text generation, entity relationships

### Data Flow
1. Player enters commands in terminal → SystemCalls.execCommand()
2. Commands sent to prompt.cairo contract → lexer parses → command handler executes
3. State changes stored in Dojo world → Torii indexes events
4. Client subscribes to entity updates via Dojo SDK → UI updates reactively

## Environment Configuration

The project supports multiple environments:
- **Local**: Uses Katana dev blockchain, no fees, CORS enabled
- **Slot**: Deployment environment with SSL certificates via mkcert
- **Development**: Standard development mode with hot reload

World editor available at `/editor` route for creating and publishing game worlds.

## Testing

Currently no test scripts are configured in package.json. Check for Cairo tests in `packages/contracts/src/tests/`.

## Tooling

- **Linting**: Biome (primary) + Oxlint for TypeScript/React
- **Package Manager**: Bun (required v1.2.3+)
- **Process Management**: mprocs for running multiple services
- **Dependencies**: Uses pnpm workspace configuration
