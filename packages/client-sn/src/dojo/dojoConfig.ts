import { createDojoConfig } from "@dojoengine/core";
// L2 Starknet world manifest. client-sn always targets packages/starknet (lore_sn),
// never the L3 packages/contracts (lore) engine.
import manifest from "@lore/starknet/manifest_sepolia.json";

/** Dojo namespace of the L2 world (see packages/starknet/dojo_sepolia.toml). */
export const NAMESPACE = "lore_sn";

/** Cartridge-hosted Starknet Sepolia RPC the L2 world is deployed to. */
export const RPC_URL = "https://api.cartridge.gg/x/starknet/sepolia/rpc/v0_9";

/** Torii indexer for the L2 world (Cartridge slot `lore_sn-stage`). */
export const TORII_URL = "https://api.cartridge.gg/x/lore_sn-stage/torii";

export const dojoConfig = createDojoConfig({ manifest });

export const WORLD_ADDRESS = dojoConfig.manifest.world.address;
