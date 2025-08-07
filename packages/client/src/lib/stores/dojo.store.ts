import type { ParsedEntity, StandardizedQueryResult } from "@dojoengine/sdk";

import { InitDojo } from "@lib/dojo";
import { ToriiQueryBuilder} from "@dojoengine/sdk";
import { num } from "starknet";
import EditorData from "@/editor/data/editor.data";
import type { EntityCollection } from "@/editor/lib/types";
import { LORE_CONFIG } from "../config";
// @dev Use the Dojo bindings, *avoid* recreating these where possible
import type {
	PlayerStory,
	StoryLine,
	SchemaType,
} from "../dojo_bindings/typescript/models.gen";
import { sendCommand } from "../terminalCommands/commandHandler";
import { StoreBuilder } from "../utils/storebuilder";
import { decodeDojoText, processWhitespaceTags } from "../utils/utils";
import { addTerminalContent } from "./terminal.store";
import WalletStore from "./wallet.store";
import type { Subscription } from "rxjs";
import type { DojoStatus } from "./types";

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
	lastKeyUsed: Number(localStorage.getItem("lastKeyUsed") ?? "-1"),
	config: undefined as Awaited<ReturnType<typeof InitDojo>> | undefined,
	lastProcessedText: "",
	originalStoryLength: 0,
	existingSubscription: undefined as Subscription | undefined,
	// printedKeys: new Set<number>(),
	printedKeys: new Set<number>(
		JSON.parse(localStorage.getItem("printedKeys") || "[]")
	),
});

const setStatus = (status: DojoStatus) => set({ status });

/**
 * Processes and sets new output from a player
 * Decodes and formats text before adding it to the terminal
 * @param {Outputter | undefined} playerStory - Output data from a player
 */
const setOutputter = async (playerStory: PlayerStory | undefined) => {
	if (!playerStory) return;

	const previousStory = get().playerStory?.story || [];
	const newStory = playerStory.story;
	const isNewText = previousStory.length > 0;

	const lastKeyUsed = get().lastKeyUsed ?? -1;

	const printed = get().printedKeys;

	// Get only new keys (greater than last used), sorted ascending, and remove from printed set
	const rawNewKeys = newStory
		.map(Number)
		.filter((key) => key > lastKeyUsed && !printed.has(key));

	if (rawNewKeys.length === 0) return;

	const newKeys = [...new Set(rawNewKeys)].sort((a, b) => a - b);
	set({ lastKeyUsed: Number(newKeys[newKeys.length - 1]) });
	// Store last key used in local storage
	localStorage.setItem("lastKeyUsed", String(newKeys[newKeys.length - 1]));
	// Add new keys to printed set and persist
	for (const key of newKeys) {
		printed.add(Number(key));
	}
	// Add printed keys to local storage
	set({ printedKeys: printed });
	localStorage.setItem("printedKeys", JSON.stringify(Array.from(printed)));

	// Fetch StoryLine models directly from Torii
	const allStoryLines: StoryLine[] = [];
	try {
		const { sdk } = await InitDojo();
		const builder = new ToriiQueryBuilder<SchemaType>();
		const query = builder
			.withCursor("")
			.withLimit(3000)
			.includeHashedKeys()
			.withEntityModels(["lore-StoryLine"]);

		const result = await sdk.getEntities({ query });
		result.getItems().forEach((entity) => {
			const model = entity.models?.lore?.StoryLine;
			if (
				model &&
				model.inst &&
				model.key !== undefined &&
				model.line &&
				String(model.inst) === String(playerStory.inst)
			) {
				allStoryLines.push({
					inst: model.inst,
					key: model.key,
					line: model.line,
				});
			}
		});
	} catch (error) {
		console.error("Error fetching StoryLine models from Torii:", error);
		throw error;
	}

	// Build a map of key => line
	const storyLineMap = new Map<string, string>();
	for (const s of allStoryLines) {
		const keyStr = String(s.key);
		if (!storyLineMap.has(keyStr)) {
			storyLineMap.set(keyStr, s.line);
		}
	}

	// Map new keys to lines
	const storyLines: string[] = [];
	for (const key of newKeys) {
		const line = storyLineMap.get(String(key));
		if (line) {
			storyLines.push(line);
		}
	}

	if (storyLines.length === 0) return;

	// Remove prompt line if duplicated
	if (isNewText && storyLines[0]?.startsWith("> ")) {
		storyLines.shift();
	}

	const newText = storyLines.join("\n");
	//console.log("[STORY]:", newText);

	const trimmedNewText = decodeDojoText(newText.trim());
	const lines = processWhitespaceTags(trimmedNewText);

	set({
		lastProcessedText: trimmedNewText,
		playerStory,
	});

	// Add new lines to terminal
	for (const line of lines) {
		const sys = line.startsWith("+sys+");
		const formatted = line.replaceAll("+sys+", "");

		addTerminalContent({
			text: formatted,
			format: sys ? "hash" : line.startsWith("> ") ? "input" : "out",
			useTypewriter: true,
		});
	}
};

const onPlayerStory = (playerStory: Partial<PlayerStory>) => {
	const address = !LORE_CONFIG.useController
		? LORE_CONFIG.wallet.address
		: WalletStore().controller?.account?.address;
	const normalizedPlayerId = num.cleanHex(String(playerStory.inst));
	const normalizedAddress = num.cleanHex(String(address));
	if (normalizedPlayerId === normalizedAddress) {
		setOutputter(playerStory as PlayerStory);
		return;
	}
};

const onReponseData = (
	responseData: ParsedEntity<SchemaType>["models"]["lore"],
) => {
	// console.log("[DOJO] onReponseData", responseData);
	if (responseData.PlayerStory && responseData.PlayerStory.story) {
		if (get().originalStoryLength === 0) {
			// Set original length AFTER handling the first story
			onPlayerStory(responseData.PlayerStory);
			set({ originalStoryLength: responseData.PlayerStory.story.length });
		} else {
			const slicedStory = {
				...responseData.PlayerStory,
				story: responseData.PlayerStory.story.slice(get().originalStoryLength),
			};
			onPlayerStory(slicedStory);
		}
	}
	EditorData().dojoSync(responseData as EntityCollection, {
		verbose: true,
	});
};

// Resets the local storage of the processed text and keys
const resetDojoState = () => {
	set({
		lastKeyUsed: -1,
		originalStoryLength: 0,
		printedKeys: new Set<number>(),
		playerStory: undefined,
		lastProcessedText: "",
	});
	localStorage.removeItem("lastKeyUsed");
	localStorage.removeItem("printedKeys");
};

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
