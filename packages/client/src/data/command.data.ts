import { LORE_CONFIG } from "@lib/config";
import {
	addTerminalContent,
	clearTerminalContent,
} from "@lib/stores/terminal.store";
import { sendCommand } from "@lib/terminalCommands/commandHandler";
import { APP_DATA } from "@/data/app.data";
import {
	HELP_CONTAINER,
	HELP_EXITS,
	HELP_INSPECT,
	HELP_INVENTORY,
	HELP_TEXTS,
} from "@/data/help.data";
import {
	checkForPlayer,
	propertiesRegistered,
	queryOwnedGameTokens,
} from "@/editor/data/editor.data";
import {
	queryCoinsEntity,
	queryGameCoinsBalance,
	queryExecActions,
	queryTriggers,
} from "@/editor/data/editor.data";
import { registerPropertyRegistry } from "@/editor/publisher";
import DojoStore from "@/lib/stores/dojo.store";
import WalletStore from "@/lib/stores/wallet.store";
import GameStore from "@/lib/stores/game.store";

/**
 * Context object passed to each terminal command handler
 * @typedef {Object} CommandContext
 * @property {string} command - The full command string as entered by the user
 * @property {string} cmd - The primary command name (first word of the command)
 * @property {string[]} args - Array of arguments passed to the command
 */
type commandContext = {
	command: string;
	cmd: string;
	args: string[];
};

/**
 * @typedef {Object} TerminalContent
 * @property {string} text - The text content to display in the terminal
 * @property {string} format - Formatting style ('system', 'hash', etc.)
 * @property {boolean} useTypewriter - Whether to use typewriter effect for display
 */

/**
 * ### Terminal System Commands Registry
 *
 * This object contains Client only terminal commands that can be executed in the
 * LORE game interface. Each key represents a command name that users can type,
 * and the value is a function that handles that command.
 *
 * @important Commands NOT case sensitive
 * @important Commands prefixed with _ are reserved (do not show as command)
 * @example
 * // Adding a new command:
 * // 1. Add your command to this object with a handler function
 * TERMINAL_SYSTEM_COMMANDS["mycommand"] = (ctx) => {
 * 	 yourNewCommand: (ctx)
 *   // 2. Access command information from the context
 *   const { command, cmd, args } = ctx;
 *
 *   // 3. Add terminal output
 *   addTerminalContent({
 *     text: `You executed ${cmd} with arguments: ${args.join(", ")}`,
 *     format: "system", // Use 'system' for informational messages, 'hash' for important data
 *     useTypewriter: true, // Enable typewriter effect for text rendering
 *   });
 *
 *   // 4. Perform any other logic needed for your command
 *   // - Access wallet with WalletStore()
 *   // - Forward to contract commands with sendCommand(command, null, bypass)
 *   // - Clear terminal with clearTerminalContent()
 * };
 */
export const TERMINAL_SYSTEM_COMMANDS: {
	[key: string]: (command: commandContext) => void;
} = {
	_bootLoader: () => {
		if (LORE_CONFIG.useController) {
			if (!WalletStore().isConnected) {
				sendCommand("_connect_wallet");
			} else {
				sendCommand("_welcome_back");
				sendCommand("_current_game");
			}
		}

		sendCommand("_hint");

		DojoStore().setStatus({
			status: "inputEnabled",
			error: null,
		});
	},
	_intro: () => {
		addTerminalContent({
			text: APP_DATA.intro,
			format: "system",
			useTypewriter: true,
			speed: 4,
		});
	},
	_description: () => {
		addTerminalContent({
			text: APP_DATA.description,
			format: "system",
			useTypewriter: true,
			speed: 4,
		});
	},

	_hint: () => {
		addTerminalContent({
			text: 'type [command] [target], or type "help" | "ls"',
			format: "input",
			useTypewriter: true,
		});
	},
	_connect_wallet: () => {
		addTerminalContent({
			text: "type [connect] and be able to [load] games or [create] a new one",
			format: "hash",
			useTypewriter: true,
		});
	},
	_not_yet_connected: () => {
		addTerminalContent({
			text: "not connected, use [connect] to connect",
			format: "hash",
			useTypewriter: true,
		});
	},
	_welcome_back: () => {
		addTerminalContent({
			text: `welcome back ${WalletStore().username}`,
			format: "shog",
			useTypewriter: true,
		});
	},
	_current_game: () => {
		addTerminalContent({
			text:
				GameStore().gameId != undefined
					? `You are playing game-${GameStore().gameId}...`
					: `New game...`,
			format: "hash",
			useTypewriter: true,
		});
	},
	create: (context: commandContext) => {
		// an empty command will create a game if not already created
		if (!WalletStore().isConnected) {
			sendCommand("_not_yet_connected");
			return;
		}
		if (context.args[0] === "game") {
			// "create game"
			sendCommand(`g_create_game`);
		} else {
			addTerminalContent({
				text: `Did you mean [create game]?`,
				format: "hash",
				useTypewriter: true,
			});
		}
	},
	load: async (context: commandContext) => {
		if (!WalletStore().isConnected) {
			sendCommand("_not_yet_connected");
			return;
		}
		// allow "game-123" or "123"
		let game_id = Number(context.args[0].split("-").at(-1));
		if (isNaN(game_id)) {
			addTerminalContent({
				text: `Did you mean [load game_name]?`,
				format: "error",
				useTypewriter: true,
			});
			return;
		}
		// current game?
		if(GameStore().gameId != undefined && game_id == Number(GameStore().gameId)) {
			sendCommand("_current_game");
			return;
		}
		// check ownership...
		const tokens = await queryOwnedGameTokens(WalletStore().walletAddress || 0n);
		if (!tokens.find((token) => token.token_id === game_id)) {
			addTerminalContent({
				text: `Not your game!`,
				format: "hash",
				useTypewriter: true,
			});
			return;
		}
		// load...
		sendCommand(`g_load_game ${game_id}`);
		const text = [
			`██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███████████████████
██░░░░░░░░░░░░░░░░░░░░░░░░▓▓▒▒░░▓▓░░░░▓▓░░░░▓▓▓▓▒▒▓▓▓▓▒▒▓▓▓▓▒▒▓▓▓
██░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓░░░░▓▓░░░░▓▓░░░░▓▓░░░░▓▓░░░░▓▓░░░░▒
██▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓▓▓▓▒▒▓▓▓▓▓
██▓▓▒▒▒▒▓▓░░▓▓▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓▓▓▓▒▒▓▓▓▓▓
██▓▓▒▒▒▒░░░░▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▒▒▒▒▒▒▓▓▓▓▒▒▓▓▓▓░░░░▓▓▒▒▓▓▓▓▓
██▓▓▒▒▒▒░░░░▒▒▒▒▒▒▒▒▓▓▓▓▓▓▒▒▓▓▓▓▒▒▒▒▓▓▒▒▓▓▓▓▓▓▒▒▓▓░░░░▒▒▓▓▒▒▓▓▓▓░
██▓▓▒▒▒▒░░░░▒▒▒▒▒▒▒▒▓▓▓▓░░░░░░▓▓▒▒▓▓▒▒░░░░░░▓▓▒▒▓▓░░░░▒▒▓▓▒▒▓▓▓▓▒
██▓▓▒▒▒▒░░██▓▓▒▒▒▒▒▒▒▒░░▒▒░░░░▓▓▒▒▒▒▓▓▓▓░░░░▓▓▒▒▓▓░░░░▒▒▓▓▒▒▓▓▓▓░
██▓▓▒▒▒▒▓▓▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▒▒▓▓▓▓▒▒▓▓▓▓▓▓▒▒░░▓▓▒▒▓▓▓▓▓▓░░▓▓▒▒▓▓▒▒▓
██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░▒▒▒▒▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒░░▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒
██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▓▓▓▓▒▒▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒
██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▒▒▒▒▒▒▓▓░░▒▒▓▓▒▒▒▒▓▓▒▒▒▒▒▒▒▒▒▒▓▓▓▓▒▒▒▒▒▒▒
██▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░▓▓▒▒▓▓▒▒▒▒▒▒▓▓▒▒▒▒▓▓▒▒▒▒▓▓▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒
██▓▓▓▓▓▓▓▓▓▓░░▒▒▒▒▓▓▓▓▒▒▒▒▒▒░░▓▓▒▒░░▒▒▓▓▓▓▒▒░░▒▒▓▓▒▒▓▓▓▓▓▓▒▒▒▒▒▒░
██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███████████████████`,
			"GAME LOADED",
		].join("\n");
		addTerminalContent({
			text,
			format: "out",
			useTypewriter: true,
			speed: 1,
		});
	},
	ls: async () => {
		if (!WalletStore().isConnected) {
			sendCommand("_not_yet_connected");
			return;
		}
		const tokens = await queryOwnedGameTokens(WalletStore().walletAddress || 0n);
		const text: string[] = [];

		if (tokens.length === 0) {
			text.push("You have no games. Type [create game] to start a new a game");
		} else {
			text.push(`Found ${tokens.length} games:`);
			tokens.forEach((token) => {
				text.push(`> ${token.name} ${BigInt(token.token_id) == GameStore().gameId ? "(CURRENT)" : ""}`);
			});
			text.push(`Type [load game_name] to resume a game`);
			text.push(`Type [create game] to start a new a game`);
		}
		addTerminalContent({
			text: text.join("\n"),
			format: "hash",
			useTypewriter: true,
		});
	},
	_fatal_error: () => {
		addTerminalContent({
			text: `FATAL+ERROR: ${WalletStore().username}`,
			format: "error",
			useTypewriter: true,
		});
	},
	clear: () => {
		clearTerminalContent();
	},
	connect: async () => {
		if (WalletStore().isConnected) {
			addTerminalContent({
				text: "already connected, use [disconnect] to disconnect",
				format: "hash",
				useTypewriter: true,
			});
			return;
		}
		await WalletStore().connectController();
		// console.log(res);
		if (WalletStore().isConnected) {
			const { username, walletAddress } = WalletStore();
			addTerminalContent({
				text: `Connected:\n${JSON.stringify({ username, walletAddress }, null, 2)}`,
				format: "hash",
				useTypewriter: true,
			});
		}
		// Check properties
		await registerPropertyRegistry();

		let propertyRegistryFound = await propertiesRegistered();
		// Check properties
		if (!propertyRegistryFound) {
			console.log("PropertyRegistry not found");
		} else {
			console.log("PropertyRegistry found");
		}
		// Call the check for player
		addTerminalContent({
			text: "You're getting ready...",
			format: "hash",
			useTypewriter: true,
		});
		await checkForPlayer();
		// player created is done or done finding player
		addTerminalContent({
			text: "You're ready to continue your journey.",
			format: "hash",
			useTypewriter: true,
		});
	},
	wallet: async () => {
		if (!WalletStore().isConnected) {
			sendCommand("_not_yet_connected");
			return;
		}
		await WalletStore().openUserProfile();
	},
	disconnect: async () => {
		if (!WalletStore().isConnected) {
			sendCommand("_not_yet_connected");
			return;
		}
		await WalletStore().disconnectController();
		addTerminalContent({
			text: "disconnected",
			format: "hash",
			useTypewriter: true,
		});
		return;
	},
	controller: () => {
		if (LORE_CONFIG.useController) {
			if (!WalletStore().isConnected) {
				sendCommand("_not_yet_connected");
				return;
			}
			WalletStore().controller?.openProfile("inventory");
		}
	},
	_bypass: ({ command }) => {
		// DEMO for commands that need to intercept the msd stream, and then call the contract
		sendCommand(command, null, true);
	},
	help: () => {
		const header =
			"Entities/Objects might have the following properties that can be that allow you to interact with them:";
		// Handle help command
		addTerminalContent({
			text:
				header +
				"\n\n" +
				Object.entries(HELP_TEXTS)
					.map(
						([cmd, content]) =>
							`> ${cmd.padEnd(10)}\n${content.description}\n${content.usage}\n${content.more}`,
					)
					.join("\n\n"),
			format: "hash",
			useTypewriter: true,
		});
	},
	help_inspect: () => {
		// Handle help inspect command
		addTerminalContent({
			text: `available commands:\n\n${Object.entries(HELP_INSPECT)
				.map(
					([cmd, content]) =>
						`> ${cmd.padEnd(10)}\n${content.description}\n${content.usage}\n${content.examples?.join("\n")}`,
				)
				.join("\n\n")}`,
			format: "hash",
			useTypewriter: true,
		});
	},
	help_exits: () => {
		// Handle help inspect command
		addTerminalContent({
			text: `available commands:\n\n${Object.entries(HELP_EXITS)
				.map(
					([cmd, content]) =>
						`> ${cmd.padEnd(10)}\n${content.description}\n${content.usage}\n${content.examples?.join("\n")}`,
				)
				.join("\n\n")}`,
			format: "hash",
			useTypewriter: true,
		});
	},
	help_container: () => {
		// Handle help inspect command
		addTerminalContent({
			text: `available commands:\n\n${Object.entries(HELP_CONTAINER)
				.map(
					([cmd, content]) =>
						`> ${cmd.padEnd(10)}\n${content.description}\n${content.usage}\n${content.examples?.join("\n")}`,
				)
				.join("\n\n")}`,
			format: "hash",
			useTypewriter: true,
		});
	},
	help_inventory: () => {
		// Handle help inspect command
		addTerminalContent({
			text: `available commands:\n\n${Object.entries(HELP_INVENTORY)
				.map(
					([cmd, content]) =>
						`> ${cmd.padEnd(10)}\n${content.description}\n${content.usage}\n${content.examples?.join("\n")}`,
				)
				.join("\n\n")}`,
			format: "hash",
			useTypewriter: true,
		});
	},
	_triggers: () => {
		const triggers = queryTriggers();
		console.log("TRIGGERS RESULT", triggers);
	},
	_actions: () => {
		const actions = queryExecActions();
		console.log("ACTIONS RESULT", actions);
	},
	connection: async () => {
		const dest = {
			endpoints: LORE_CONFIG.endpoints,
			mode: import.meta.env.MODE,
		};
		addTerminalContent({
			text: JSON.stringify(dest, null, 2),
			format: "system",
			useTypewriter: true,
		});
	},
} as const;

// --- COINS SUBCOMMANDS ---
const coinsSubcommands: Record<string, () => Promise<void>> = {
  // Main "balance" functionality
  balance: async () => {
    const gameId = GameStore().gameId;
    if (!gameId) {
      addTerminalContent({
        text: "You can't check your Usants coins as you haven't started a game yet",
        format: "error",
        useTypewriter: true,
      });
      return;
    }
    const coinsEntity = await queryCoinsEntity();
    const coinsBalance = await queryGameCoinsBalance(coinsEntity);
    addTerminalContent({
      text: `You have ${coinsBalance} Usants coins`,
      format: "hash",
      useTypewriter: true,
    });
  },

  // Aliases for "balance"
  amount: async () => coinsSubcommands.balance(),
  count: async () => coinsSubcommands.balance(),
  check: async () => coinsSubcommands.balance(),
  "balance of coins": async () => coinsSubcommands.balance(),
  "amount of coins": async () => coinsSubcommands.balance(),
  "coins check": async () => coinsSubcommands.balance(),
  "coins count": async () => coinsSubcommands.balance(),
	"count coins": async () => coinsSubcommands.balance(),
};

// --- REGISTER COINS COMMAND ---
TERMINAL_SYSTEM_COMMANDS["coins"] = async (ctx: commandContext) => {
  const subcommand = ctx.args.join(" ").toLowerCase();

  if (!subcommand) {
    addTerminalContent({
      text: 'Did you mean [coins balance]?',
      format: "hash",
      useTypewriter: true,
    });
    return;
  }

  const handler = coinsSubcommands[subcommand] || coinsSubcommands[ctx.args[0]?.toLowerCase()];

  if (handler) {
    await handler();
  } else {
    addTerminalContent({
      text: `Unknown coins command: "${subcommand}"`,
      format: "error",
      useTypewriter: true,
    });
  }
};