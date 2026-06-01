# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

>LORE is a Dojo-based, Zork & MUD inspired, fully onchain interactive multiplayer fiction engine. Players type natural-language commands into a terminal; the commands are parsed and executed entirely on-chain by Cairo contracts. The world (rooms, items, NPCs, puzzles) is data authored through a web-based editor and published on-chain — there is no hardcoded game; the engine interprets entities + components.

## Monorepo layout (Bun workspaces)

- `packages/client` — React 19 + Vite frontend (the terminal + the world editor). Talks to Dojo via `@dojoengine/sdk` and Torii.
- `packages/contracts` — L3 (Katana/appchain) Dojo game contracts. This is where the game engine lives. Package name `lore`.
- `packages/starknet` — L2 (Starknet) Dojo contracts + Saya settlement integration for the appchain deployment. Package name `lore_sn`.

The client depends on `@lore/contracts` (workspace) to import generated manifests and TS bindings. `@lore/contracts` also depends on `@lore/client` (workspace) for shared deploy-time data.

## Toolchain

Pinned in `.tool-versions` (install with `asdf install`): scarb 2.13.1, sozo 1.8.6, katana 1.7.0, torii 1.8.7, saya 0.2.2. Dojo lib version is `=1.8.0` (see Scarb.toml). Package manager is **Bun** (not npm/pnpm). Cairo edition `2024_07`.

## Commands

Run from repo root unless noted. Dev orchestration uses `mprocs` (multi-process configs in `mprocs.*.yaml`).

```bash
bun install                 # install all workspaces
bun run dev                 # local mode: katana --dev + contracts watch + torii + client (https://localhost:5173)
bun run dev:slot            # slot mode: watch/compile local contracts, deploy to Slot
bun run dev:saya            # Saya mode: two katanas (L2 sim + L3 game) + Saya server
```

`bun run dev` serves the game at `https://localhost:5173` and the world editor at `https://localhost:5173/editor` over **https** (mkcert generates a local cert on first run and prompts for sudo to add the root cert to the OS keychain).

### Client (`packages/client`)

```bash
bun run dev                 # vite dev (development mode)
bun run build               # vite build
bun run lint                # oxlint --fix + biome check --write
bun run lint:ci             # CI lint (no writes)
```

### Contracts (`packages/contracts`) — the game engine

```bash
bun run dev:watch           # sozo build (+ TS bindings) → migrate → inspect, watching for changes
bun run slot:deploy         # deploy to Slot (profile slot)
bun run slot:upgrade        # upgrade existing Slot deployment
sozo test --profile dev     # run Cairo tests (snforge-style via cairo_test / dojo_cairo_test)
sozo build --profile dev    # build only
```

Tests live in `packages/contracts/src/tests/` and are wired in `lib.cairo` under `#[cfg(test)] mod tests`. Run a single test by name with sozo's filter, e.g. `sozo test --profile dev <substring_of_test_name>`.

The dev watcher (`scripts/dev.watch.ts`) regenerates TypeScript bindings into `packages/client/src/lib/dojo_bindings/typescript/` (`contracts.gen.ts`, `models.gen.ts`) on every contract change — **client code should import from these generated bindings rather than redefining model types**.

### Starknet L2 / Saya deploy (`packages/starknet`)

Multi-step L2→L3→Saya deployment; see `packages/starknet/README.md`. Requires `.env.sepolia` / `.env.mainnet` with settlement + dojo account keys.

```bash
bun run sepolia:deploy      # deploy L2 core + dojo contracts, create appchain config
bun run sepolia:slot        # create the L3 Katana slot instance from appchain config
```

## Contract architecture (`packages/contracts/src`)

The engine is an **Entity–Component** model on top of Dojo. Everything in the world is an `Entity`; behavior comes from attaching component models to it.

- `systems/` — Dojo contracts (the only externally callable entry points):
  - `prompt.cairo` — main gameplay entry. `prompt(cmd: ByteArray, game_id)` lexes the command, charges actions, dispatches to the command handler.
  - `designer.cairo` — world-authoring (editor publishes through this).
  - `game_token.cairo` / `trail_token.cairo` / `actions_token.cairo` — ERC-721/ERC-20 tokens (game NFT, trail/story progress, the `actions` currency).
- `models/` — Dojo models = entities + components: `entity`, `area` (rooms), `exit`, `container`, `inventory_item`, `reactable`, `condition`, `trigger`, `effect`, `player`, `player_account`, `hub`, `*_token_info`, `actions_config`.
- `lib/` — engine internals:
  - `a_lexer.cairo` — tokenizes raw player input into a `Command`.
  - `c_handler.cairo` — `handle_command(...)`: routes a parsed `Command` to system vs. world actions, applies conditions/effects, returns `Result<(), Error>`.
  - `dns.cairo` — service discovery: typed dispatchers to other systems/tokens by Dojo name (`world.lexer_dispatcher()`, `actions_token_protected_dispatcher()`, etc.). Use these to call between systems.
  - `access.cairo` — auth (`AccessTrait`); `messaging.cairo` — L2↔L3 messaging; `random.cairo`, `trophies.cairo`, `errors_texts_output.cairo`.
- `types/` — enums: `command_type`, `action_type`, `component_type`, `direction_type`, `property_type`.
- `constants/` — `errors`, `config`, `appchain`, `token_metadata`.

**Actions economy**: every command costs `actions` (an 18-decimal ERC-20). New players get 5 free actions + 1/hour. To playtest without grinding, from `packages/contracts`: `./scripts/mint_actions_to.sh <profile> <addr> <amount>` or `./scripts/set_action_cost_amount.sh <profile> 0` (set back to `1000000000000000000` for 1/command).

## Client architecture (`packages/client/src`)

- `client/terminal/` — the in-game terminal UI (`Terminal.tsx`, typewriter, audio, side panels).
- `editor/` — the world editor: `inspectors/` (one per component type), `publisher.ts` (writes the world on-chain via the `designer` system), `lib/schemas.ts`.
- `lib/stores/` — Zustand stores. `dojo.store.ts` owns the Dojo SDK connection, Torii queries, and command dispatch; `game.store.ts`, `token.store.ts`, `wallet.store.ts`, etc.
- `lib/dojo_bindings/typescript/` — **generated**; do not hand-edit (biome ignores `*.gen.*`).
- `lib/config_profiles.ts` / `lib/config.ts` — per-profile (`dev` | `slot` | `stage` | `appchain-sepolia`) chain id, RPC, Torii URL, contract addresses (built from imported manifests). Wallet is Cartridge Controller; local dev also has burner accounts.
- `lib/terminalCommands/commandHandler.ts` — `sendCommand` bridges terminal input → `prompt` system call.

## Deployment profiles

Both Cairo packages declare Dojo profiles in `Scarb.toml` with matching `dojo_<profile>.toml` config files. Contracts (L3): `dev`, `slot`, `stage`, `saya-test`, `appchain-sepolia`. Starknet (L2): `dev`, `saya-test`, `sepolia`. Manifests (`manifest_<profile>.json`) are committed and consumed by the client. Slot service creation commands are in `slot_commands.md`.

## Conventions

- **Lint/format**: Biome (tab indent, `indentWidth: 1`) + oxlint for the client. Biome enforces sorted Tailwind classes (`className`, `cn()`), `useImportType`/`useExportType`, `useTemplate`, and a cognitive-complexity cap of 15. Generated `*.gen.*` files are excluded. Cairo: `cairo1` formatter, format-on-save **off** for `.cairo`.
- Prefer the generated Dojo bindings for model/contract types in the client; don't recreate them.
- `CLAUDE.md` is gitignored (kept local).
