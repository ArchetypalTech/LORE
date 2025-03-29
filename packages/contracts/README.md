<p align="center">
  <h1 align="center">>LORE Contracts</h1>
</p>
<p align="center">
This package contains the Cairo smart contracts that power >LORE - a Dojo based, Zork & MUD inspired, fully onchain interactive multiplayer fiction engine.
</p>

## ⚡ Setup

#### 📦 Install dependencies

```bash
bun install
```

### 💻 Deployment and Management

Deploy contracts to slot:

```bash
bun run slot:deploy
```

Upgrade existing slot deployment:

```bash
bun run slot:upgrade
```

Watch for contract changes:

```bash
bun run slot:watch
```

- Deploymentscripts will use variables in `dojo_slot.toml`, `Scarb.toml`. `dojo_slot.toml` requires `slot_name` to be set to target deployment.

### 🪴 Product may include traces of

| **Technology** | **Purpose**               |
| -------------- | ------------------------- |
| Dojo           | Onchain game engine       |
| Cairo          | Smart contract language   |
| StarkNet       | Layer 2 scaling solution  |
| Scarb          | Package manager for Cairo |
