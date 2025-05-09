<p align="center">
  <h1 align="center">>LORE</h1>
</p>
<p align="center">a Dojo based, Zork & MUD inspired, fully onchain interactive multiplayer fiction engine.
</p>

## ⚡ Setup

#### 📦 Install the repo with [Bun](https://bun.sh)

Clone the repository, then install dependencies with [Bun](https://bun.sh)

```bash
bun install
```

## 💕 Quickstart installer:

Automated installer for installing [scarb](https://github.com/software-mansion/scarb) and [dojo](https://book.dojoengine.org/getting-started#install-using-asdf) using [asdf](https://asdf-vm.com/) and [homebrew](https://brew.sh/).

🚸 Update your `$PATH` [getting started with ASDF](https://asdf-vm.com/guide/getting-started.html) variables to make sure `katana` works.

```bash
bun run quickstart
```
<hr/>

## 🕹️ Development:

#### Development MODE (local):

```bash
bun run dev
```

> 🛖 Development MODE (local) runs a local instance of Katana, Torii and the client at `http://localhost:5173` and `http://localhost:5173/editor` (without _SSL_, make sure to use `http`)

#### Slot MODE:
_will create a local SSL certificate with mkcert and asks for sudo password_

```bash
bun run dev:slot
```

> 🎲 Slot MODE watches + compiles local contracts and allows you to deploy to slot & configures the client to connect to Slot at `https://localhost:5173` and `https://localhost:5173/editor` (use _https_)

<hr/>

## 🗺️ World deployment:

Initial deployments start with an empty world, use the editor at `http://localhost:5173/editor` to create and publish a world.

## 🔧 Manual dependency installation:

```bash
brew install asdf
asdf plugin add scarb
asdf plugin add dojo https://github.com/dojoengine/asdf-dojo

asdf install scarb <version>
asdf install dojo <version>
```

## 📦 Packages

This is a monorepo containing the following packages:

| **Package** | **Description** |
| ----------- | --------------- |
| `client`    | Game client     |
| `contracts` | Dojo contracts  |
