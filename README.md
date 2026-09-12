<p align="center">
  <h1 align="center">>LORE</h1>
</p>
<p align="center">a Dojo based, Zork & MUD inspired, fully onchain interactive multiplayer fiction engine.
</p>

## ⚡ Setup

### 📦 Install the repo with [Bun](https://bun.sh)

Clone the repository, then install dependencies with [Bun](https://bun.sh)

```bash
bun install
```

<!-- ## 💕 ~~Quickstart installer:~~

Since Dojo 1.5 Katana and Torii have been seperated and this quickstart won't work, we'll be updating this soon.

~~Automated installer for installing [scarb](https://github.com/software-mansion/scarb) and [dojo](https://book.dojoengine.org/getting-started#install-using-asdf) using [asdf](https://asdf-vm.com/) and [homebrew](https://brew.sh/).~~

~~🚸 Update your `$PATH` [getting started with ASDF](https://asdf-vm.com/guide/getting-started.html) variables to make sure `katana` works.~~

```bash
## DONT DO THIS UNTIL WE'VE UPDATED IT!
bun run quickstart
``` -->

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

| **Package** | **Description**              |
| ----------- | ---------------------------- |
| `client`    | Game client                  |
| `contracts` | L3 Dojo contracts (Katana)   |
| `starknet`  | L2 Dojo contracts (Starknet) |

## 🕹️ Development:

### Development MODE (local):

```bash
bun run dev
```

> 🛖 Development MODE (local) runs a local instance of Katana, Torii and the client at `https://localhost:5173` and `https://localhost:5173/editor`. It also uses Cartridge Controller for wallet management.

_will create a local SSL certificate with mkcert and asks for sudo password_

- First run - make sure password is passed to terminal in order to add root certificate to your OS keychain
- ssl keys are added to `package/client/ssl`

**Trouble shooting** Sometimes you have a valid cert, but it browser says connection is insecure:

- You may need to restart your browser in order to register new root ssl cert.

<!-- ### Slot MODE:

_will create a local SSL certificate with mkcert and asks for sudo password_

```bash
bun run dev:slot
```

> 🎲 Slot MODE watches + compiles local contracts and allows you to deploy to slot & configures the client to connect to Slot at `https://localhost:5173` and `https://localhost:5173/editor` (use _https_) -->

### Saya MODE:

```bash
bun run dev:saya
```

> 🎲 Saya mode will start two instances of Katana (one to simulate L2/Starknet and another for L3/Game) and a Saya server. See  [packages/starknet/README.md](./packages/starknet/README.md) for more info.

<hr/>


## 🗺️ O'Ruggin Trail story deployment:

Initial deployments start with an empty world, use the editor at `https://localhost:5173/editor` to create and publish a world.


## 🕹️ Playtesting:

Every command now costs an amount of `actions`, an ERC-20 token.

* Each command cost 1 action
* Every new player gets 5 free actions to start
* Every 15 minutes, 1 free action is given to the player
* Use this command in-game to see your actions balance: `g_actions` 

You need actions to play even on localhost. There are two alternatives to playtest...

```sh
# Alternative 1: Grant actions to a player
# example: mint 20 actions to account 0x1234 on profile dev
cd packages/contracts
./scripts/mint_actions_to.sh dev 0x1234 20

# Alternative 2: Set actions cost free
cd packages/contracts
./scripts/set_action_cost_amount.sh dev 0

# set back to 1 action/command (action is ERC-20 and have 18 decimals)
./scripts/set_action_cost_amount.sh dev 1000000000000000000
```

## 💰 Monetization

It has been implemented a monetization system, where owner of trails, creator of objects and collaborators can gain actions based on their participation on each entity as well the interaction of users with objects.

Owners, creators and collaborators can claim via the in-game terminal with the command:
```sh
_claimRewards
```

Please check the documentation about the Monetization System [here](docs/Monetization)