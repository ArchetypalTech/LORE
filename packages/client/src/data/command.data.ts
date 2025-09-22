import { LORE_CONFIG } from "@lib/config";
import {
	addTerminalContent,
	clearTerminalContent,
} from "@lib/stores/terminal.store";
import { sendCommand } from "@lib/terminalCommands/commandHandler";
import { APP_DATA } from "@/data/app.data";
import { HELP_TEXTS, HELP_EXITS, HELP_INSPECT, HELP_CONTAINER, HELP_INVENTORY } from "@/data/help.data";
import DojoStore from "@/lib/stores/dojo.store";
import WalletStore from "../lib/stores/wallet.store";
import { checkForPlayer, propertiesRegistered, queryOwnedGameTokens, } from "@/editor/data/editor.data";
import {registerPropertyRegistry} from "../editor/publisher";
import { queryCoinsEntity, queryGameCoinsBalance } from "@/editor/data/editor.data";
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
			style: { textAlign: "center" },
		});
	},
	_description: () => {
		addTerminalContent({
			text: APP_DATA.description,
			format: "system",
			useTypewriter: true,
			speed: 4,
			style: { textAlign: "center" },
		});
	},
	_hint: () => {
		addTerminalContent({
			text: 'type [command] [target], or type "help"| "ls"',
			format: "input",
			useTypewriter: true,
		});
	},
	_connect_wallet: () => {
		addTerminalContent({
			text: "type [connect] to connect",
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
			text: `Welcome back ${WalletStore().username}`,
			format: "hash",
			useTypewriter: true,
		});
	},
	_current_game: () => {
		addTerminalContent({
			text: GameStore().gameId != undefined ? `You are playing game #${GameStore().gameId}...` : `New game...`,
			format: "hash",
			useTypewriter: true,
		});
	},
	_create_game: () => {
		// an empty command will create a game if not already created
		// sendCommand(``);
	},
	ls: async () => {
		if (!WalletStore().isConnected) {
			sendCommand("_not_yet_connected");
			return;
		}
		const tokens = await queryOwnedGameTokens(WalletStore().walletAddress || 0n);
		const text: string[] = [];
		
		if (tokens.length === 0) {
			text.push("You have no games. Type [create_game] to start a new a game");
		} else {
			text.push(`Found ${tokens.length} games:`);
			tokens.forEach((token) => {
				text.push(`- ${token.name}`);
			});
			text.push(`Type [load game_name] to resume a game`);
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
		const res = await WalletStore().connectController();
		console.log(res);
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
	help:() => {
		const header = "Entities/Objects might have the following properties that can be that allow you to interact with them:";
		// Handle help command
		addTerminalContent({
			text: header + "\n\n" + Object.entries(HELP_TEXTS)
				.map(([cmd, content]) => 
					`> ${cmd.padEnd(10)}\n${content.description}\n${content.usage}\n${content.more}`
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
				.map(([cmd, content]) => `> ${cmd.padEnd(10)}\n${content.description}\n${content.usage}\n${content.examples?.join("\n")}`)
				.join("\n\n")}`,
			format: "hash",
			useTypewriter: true,
		});
	},
	help_exits: () => {
		// Handle help inspect command
		addTerminalContent({
			text: `available commands:\n\n${Object.entries(HELP_EXITS)
				.map(([cmd, content]) => `> ${cmd.padEnd(10)}\n${content.description}\n${content.usage}\n${content.examples?.join("\n")}`)
				.join("\n\n")}`,
			format: "hash",
			useTypewriter: true,
		});
	},
	help_container: () => {
		// Handle help inspect command
		addTerminalContent({
			text: `available commands:\n\n${Object.entries(HELP_CONTAINER)
				.map(([cmd, content]) => `> ${cmd.padEnd(10)}\n${content.description}\n${content.usage}\n${content.examples?.join("\n")}`)
				.join("\n\n")}`,
			format: "hash",
			useTypewriter: true,
		});
	},
	help_inventory: () => {
		// Handle help inspect command
		addTerminalContent({
			text: `available commands:\n\n${Object.entries(HELP_INVENTORY)
				.map(([cmd, content]) => `> ${cmd.padEnd(10)}\n${content.description}\n${content.usage}\n${content.examples?.join("\n")}`)
				.join("\n\n")}`,
			format: "hash",
			useTypewriter: true,
		});
	},
	coins_balance: async () => {
		const coinsEntity = await queryCoinsEntity();
		const coinsBalance = await queryGameCoinsBalance(coinsEntity);
		addTerminalContent({
			text: `You have ${coinsBalance} Usants coins`,
			format: "hash",
			useTypewriter: true,
		});
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
