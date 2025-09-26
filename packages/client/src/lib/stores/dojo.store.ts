import type { ParsedEntity, StandardizedQueryResult } from "@dojoengine/sdk";

import { InitDojo } from "@lib/dojo";
import { ClauseBuilder, ToriiQueryBuilder} from "@dojoengine/sdk";
import { CairoCustomEnum, BigNumberish } from "starknet";
import EditorData from "@/editor/data/editor.data";
import type { EntityCollection } from "@/editor/lib/types";
import { LORE_CONFIG } from "../config";
// @dev Use the Dojo bindings, *avoid* recreating these where possible
import type {
	PlayerStory,
	StoryLine,
	SchemaType,
	PlayerAccount,
} from "../dojo_bindings/typescript/models.gen";
import { sendCommand } from "../terminalCommands/commandHandler";
import { StoreBuilder } from "../utils/storebuilder";
import { bigintToHex128, decodeDojoText, processWhitespaceTags } from "../utils/utils";
import { addTerminalContent } from "./terminal.store";
import { getPlayerAddress } from "@/editor/lib/components";
import * as torii from "@dojoengine/torii-client";
import GameStore from "./game.store";


/**
 * Represents the current status of the Dojo system.
 * @typedef {Object} DojoStatus
 * @property {'loading' | 'initialized' | 'inputEnabled' | 'error' | 'controller'} status - Current status of the Dojo system
 * @property {string | null} error - Error message if status is 'error', null otherwise
 */
export type DojoStatus = {
	status: "loading" | "initialized" | "inputEnabled" | "error" | "controller";
	error: string | null;
};

let connectionTimeout: Timer | undefined;

const _lastKeyUsedName = (game_id: BigNumberish) => (`lastKeyUsed_${BigInt(game_id).toString()}`);

const {
	get,
	set,
	useStore: useDojoStore,
	createFactory,
} = StoreBuilder({
	status: {
		status: "initialized",
		error: null,
	} as DojoStatus,
	playerStory: undefined as PlayerStory | undefined,
	playerLine: undefined as StoryLine | undefined,
	config: undefined as Awaited<ReturnType<typeof InitDojo>> | undefined,
	lastProcessedText: "",
	originalStoryLength: 0,
	existingSubscription: undefined as torii.Subscription | undefined,
	// printedKeys: new Set<number>(),
	getLastKeyUsed: (game_id: BigNumberish) => (
		Number(localStorage.getItem(_lastKeyUsedName(game_id)) || "-1")
	),
	setLastKeyUsed: (game_id: BigNumberish, key: number) => {
		localStorage.setItem(_lastKeyUsedName(game_id), String(key));
	},
});

const setStatus = (status: DojoStatus) => set({ status });

/**
 * Processes and sets new output from a player
 * Decodes and formats text before adding it to the terminal
 * @param {Outputter | undefined} playerStory - Output data from a player
 */
const setOutputter = async (playerStory: PlayerStory | undefined) => {
	if (!playerStory) return;

	const lastKeyUsed: number = get().getLastKeyUsed(playerStory.game_id);

	// Fetch all StoryLines for this player
	const allStoryLines: StoryLine[] = [];
	try {
		const { sdk } = await InitDojo();
		const builder = new ToriiQueryBuilder<SchemaType>();
		const query = builder
			.withCursor("")
			.withLimit(3000)
			.includeHashedKeys()
			.withClause(
				new ClauseBuilder<SchemaType>().keys(
					["lore-StoryLine"],
					[bigintToHex128(playerStory.game_id)]
				).build()
			)
			.withEntityModels(["lore-StoryLine"]);

		const result = await sdk.getEntities({ query });
		// console.log("[DEBUG:OUTPUTTER] result", result);
		result.getItems().forEach((entity) => {
			const model = entity.models?.lore?.StoryLine;
			if (
				model &&
				model.game_id !== undefined &&
				model.key !== undefined &&
				model.line &&
				String(model.game_id) === String(playerStory.game_id)
			) {
				allStoryLines.push({
					game_id: model.game_id,
					key: model.key,
					line: model.line,
					line_type: model.line_type as CairoCustomEnum,
				});
			}
		});
	} catch (error) {
		console.error("Error fetching StoryLine models from Torii:", error);
		return;
	}

	// Filter new keys and normalize to number
	let newLines: StoryLine[] = allStoryLines.sort((a, b) => Number(a.key) - Number(b.key));
	
	if (lastKeyUsed !== -1) {
		newLines = newLines.filter((s) => Number(s.key) > lastKeyUsed);
	} else {
		// get responses from last command
		for (let i = newLines.length - 1; i >= 0; i--) {
			if (newLines[i].line_type.toString() === "Command") {
				newLines = newLines.slice(i + 1);
				break;
			}
		}
	}

	// console.log("[DEBUG:OUTPUTTER] allStoryLines:", allStoryLines);
	// console.log("[DEBUG:OUTPUTTER] newLines:", newLines);

	if (newLines.length === 0) return;

	// Update lastKeyUsed and printedKeys
	const maxKey = Number(newLines[newLines.length - 1].key);
	get().setLastKeyUsed(playerStory.game_id, maxKey);

	// Add lines to terminal
	for (const s of newLines) {
		if (s.line_type.toString() == "Command") {
			continue;
		}
		const trimmed = s.line.trim();
		const lines = processWhitespaceTags(trimmed);
		for (const l of lines) {
			const sys = l.startsWith("+sys+");
			const formatted = l.replaceAll("+sys+", "");
			addTerminalContent({
				text: formatted,
				format: sys ? "hash" : l.startsWith("> ") ? "input" : "out",
				useTypewriter: true,
			});
		}
	}

	set({ lastProcessedText: newLines.map((s) => s.line).join("\n"), playerStory });
};

const onPlayerStory = (playerStory: PlayerStory) => {
	const gameId = GameStore().gameId;
	const normalizedStoryId: bigint = BigInt(playerStory.game_id);
	const normalizedGameId: bigint | null = (gameId != null ? BigInt(gameId) : null);
	// console.log("[DEBUG:STORY] normalizedStoryId", normalizedStoryId);
	// console.log("[DEBUG:STORY] normalizedGameId", normalizedGameId);
	if (normalizedStoryId === normalizedGameId) {
		// console.log("[DEBUG:STORY] onPlayerStory", playerStory);
		setOutputter(playerStory as PlayerStory);
		return;
	}
};

const onReponseData = (
    responseData: ParsedEntity<SchemaType>["models"]["lore"],
) => {
    // console.log("[DEBUG] onReponseData", responseData);

    // Check if there’s a PlayerStory update
		const playerStory: PlayerStory | undefined = responseData.PlayerStory as PlayerStory;
    if (playerStory && playerStory.story_line !== undefined) {
        // console.log("[DEBUG] RD playerStory received", playerStory);
        // Pass directly to setOutputter via onPlayerStory
        onPlayerStory(playerStory);
    }

		// if the player's game was created or has changed
		const playerAccount: PlayerAccount = responseData.PlayerAccount as PlayerAccount;
    if (playerAccount && playerAccount.current_game_id !== undefined) {
			if (BigInt(playerAccount.address) === BigInt(getPlayerAddress())) {
				GameStore().setPlayerGameId(playerAccount.current_game_id);
				sendCommand("_current_game");
			}
    }

    // Always sync EditorData for lore entities
    EditorData().dojoSync(responseData as EntityCollection, { verbose: true });
};

// Resets the local storage of the processed text and keys
// const resetDojoState = () => {
// 	set({
// 		lastKeyUsed: -1,
// 		originalStoryLength: 0,
// 		printedKeys: new Set<number>(),
// 		playerStory: undefined,
// 		lastProcessedText: "",
// 	});
// 	localStorage.removeItem("lastKeyUsed");
// 	localStorage.removeItem("printedKeys");
// };

/*
	onSubscription is a callback function that is passed to the sub function in the config object.
	It is called whenever a new entity is created or updated.
	The function is responsible for updating the playerStory and editor data.
*/
const onSubscription = (response: {
	data?: StandardizedQueryResult<SchemaType> | undefined;
	error?: Error;
}) => {
	if (response.error) {
		console.error("Error setting up entity sync:", response.error);
		setStatus({
			status: "error",
			error: response.error.message || "SYNC FAILURE",
		});
		return;
	}
	for (const responseData of response?.data || []) {
		if (responseData.models?.lore) {
			onReponseData(responseData.models.lore);
		}
	}
};

/**
 * Initializes the Dojo configuration and sets up subscriptions
 * Handles subscription to entities and updates playerStory when relevant data changes
 * @param {Awaited<ReturnType<typeof InitDojo>>} config - The Dojo configuration
 * @returns {Promise<void>}
 */
const initializeConfig = async (
	config: Awaited<ReturnType<typeof InitDojo>>,
) => {
	set({ config });
	const { existingSubscription } = get();
	if (config === undefined) return;

	console.log("[DOJO]: CONFIG ", config);
	connectionTimeout = setTimeout(() => {
		const status = {
			status: "error",
			error: "Connection timeout",
		} as DojoStatus;
		setStatus(status);
		sendCommand(`_fatal_error ${status.error}`);
		window.location.reload();
	}, 50000);

	if (existingSubscription !== undefined) return;

	try {
		const [initialEntities, subscription] = await config.sub(onSubscription);
		if (!LORE_CONFIG.EDITOR_MODE) {
			sendCommand("_intro");
			sendCommand("_description");
		}
		const entities = Array.isArray(initialEntities) ? initialEntities : [initialEntities];
				for (const responseData of entities) {
					if (responseData.models?.lore) {
						onReponseData(responseData.models.lore);
					}
				}
		clearTimeout(connectionTimeout);

		setStatus({
			status: "initialized",
			error: null,
		});
		sendCommand("_bootLoader");

		console.log("[DOJO]: initialized");
		set({ existingSubscription: subscription });
	} catch (e) {
		const status = {
			status: "error",
			error: (e as Error).message || "SYNC FAILURE",
		} as DojoStatus;
		setStatus(status);
		sendCommand(`_fatal_error ${status.error}`);
		console.error("Error setting up entity sync:", e);
	}
};

/**
 * Factory object returning the Dojo store and its actions
 * @returns {Object} The Dojo store with state and actions
 */
const DojoStore = createFactory({
	setStatus,
	setOutputter,
	initializeConfig,
});

export default DojoStore;
export { useDojoStore };
