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

## 💕 ~~Quickstart installer:~~

Since Dojo 1.5 Katana and Torii have been seperated and this quickstart won't work, we'll be updating this soon.

~~Automated installer for installing [scarb](https://github.com/software-mansion/scarb) and [dojo](https://book.dojoengine.org/getting-started#install-using-asdf) using [asdf](https://asdf-vm.com/) and [homebrew](https://brew.sh/).~~

~~🚸 Update your `$PATH` [getting started with ASDF](https://asdf-vm.com/guide/getting-started.html) variables to make sure `katana` works.~~

```bash
## DONT DO THIS UNTIL WE'VE UPDATED IT!
bun run quickstart
```

<hr/>

## 🕹️ Development:

#### Development MODE (local):

```bash
bun run dev
```

> 🛖 Development MODE (local) runs a local instance of Katana, Torii and the client at `https://localhost:5173` and `https://localhost:5173/editor`. It also uses Cartridge Controller for wallet management.

_will create a local SSL certificate with mkcert and asks for sudo password_

- First run - make sure password is passed to terminal in order to add root certificate to your OS keychain
- ssl keys are added to `package/client/ssl`

**Trouble shooting** Sometimes you have a valid cert, but it browser says connection is insecure:

- You may need to restart your browser in order to register new root ssl cert.

#### Slot MODE:

_will create a local SSL certificate with mkcert and asks for sudo password_

```bash
bun run dev:slot
```

> 🎲 Slot MODE watches + compiles local contracts and allows you to deploy to slot & configures the client to connect to Slot at `https://localhost:5173` and `https://localhost:5173/editor` (use _https_)

<hr/>

## 🗺️ World deployment:

Initial deployments start with an empty world, use the editor at `https://localhost:5173/editor` to create and publish a world.

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


## 🌎 Celestia Setup:

### Initialize / deploy settlement chain contract
> from [Katana docs](https://book.dojoengine.org/toolchain/katana/advanced#chain-initialization)

* Edit and run `scripts/da_sepolia_init.sh`

```
export CHAIN_ID=KATANA_DA_LOCAL
export SETTLEMENT_CHAIN=sepolia
export SETTLEMENT_ADDRESS=<ADDRESS>
export SETTLEMENT_PRIVATE_KEY=<PRIVATE_KEY>
export CHAIN_CONFIG_PATH=./chain-config-sepolia
```

* Config files are saved in `./chain-config-sepolia/`


### Run local Katana + Celestia Sepolia

* run: `bun run dev:da`
* katana will start with chain id `KATANA_DA_LOCAL`


### Install Saya

> Saya docker image: [https://github.com/dojoengine/saya/pkgs/container/saya](https://github.com/dojoengine/saya/pkgs/container/saya)

* Install and run [Docker Desktop](https://docs.docker.com/desktop/)
* Install Saya...

```
docker pull ghcr.io/dojoengine/saya:v0.1.2
docker run ghcr.io/dojoengine/saya:v0.1.2 saya --version
```

### Run Saya

> from [Saya docs](https://book.dojoengine.org/toolchain/saya/persistent#run-saya)

* Saya will use `.env.persistent.sepolia`
* run: `source .env.persistent.sepolia && saya persistent start`
* PREFERABLY: `bun run dev:da`

