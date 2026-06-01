# client-sn

React 19 + Vite frontend for the **L2 Starknet world** (`lore_sn`). This is an
independent client from `packages/client`; it always targets `packages/starknet`
(consuming its `@lore/starknet` manifests), never the L3 `packages/contracts`
engine.

## Start the client

From this package (`packages/client-sn`):

```bash
bun install        # from the repo root, installs all workspaces
bun run dev        # vite dev server (https), default profile: sepolia
bun run build      # tsc + vite production build
bun run preview    # serve the production build on :8081
```

The dev server runs over **https** (mkcert generates a local cert on first run).

## Switching profiles via `.env`

The active profile is resolved in `src/dojo/dojoConfig.ts` and drives the RPC,
Torii URL, chain, namespace, manifest, and contract addresses
(see `src/dojo/config_profiles.ts`). Available profiles:

| Profile   | Target                         | RPC                                                    |
| --------- | ------------------------------ | ------------------------------------------------------ |
| `dev`     | local L2 katana                | `http://localhost:50000/`                              |
| `sepolia` | Starknet Sepolia (`lore_sn`)   | `https://api.cartridge.gg/x/starknet/sepolia/rpc/v0_9` |
| `mainnet` | Starknet Mainnet (`lore_sn`)   | `https://api.cartridge.gg/x/starknet/mainnet/rpc/v0_9` |

Select a profile by setting `VITE_PROFILE` in a `.env` (or `.env.local`) file at
the package root:

```bash
# packages/client-sn/.env
VITE_PROFILE=dev
```

If `VITE_PROFILE` is unset, the Vite mode is used, falling back to `sepolia`.

Optional per-run overrides (take precedence over the profile's defaults):

```bash
VITE_RPC_URL=...     # override the RPC node URL
VITE_TORII_URL=...   # override the Torii indexer URL
VITE_SLOT=...        # override the slot name
```
