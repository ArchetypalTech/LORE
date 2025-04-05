import type { InitDojo } from "@lib/dojo";
import { addTerminalContent } from "./terminal.store";
import { LORE_CONFIG } from "../config";
import WalletStore from "./wallet.store";
// @dev Use the Dojo bindings, *avoid* recreating these where possible
import type {
	PlayerStory,
	SchemaType,
} from "../dojo_bindings/typescript/models.gen";
import { processWhitespaceTags, decodeDojoText } from "../utils/utils";
import { StoreBuilder } from "../utils/storebuilder";
import EditorData from "@/editor/data/editor.data";
import type { AnyObject } from "@/editor/lib/schemas";
import { sendCommand } from "../terminalCommands/commandHandler";
import type { ParsedEntity, StandardizedQueryResult } from "@dojoengine/sdk";
import { num } from "starknet";

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
		status: "loading",
		error: null,
	} as DojoStatus,
	playerStory: undefined as PlayerStory | undefined,
	config: undefined as Awaited<ReturnType<typeof InitDojo>> | undefined,
	lastProcessedText: "",
	existingSubscription: undefined as unknown | undefined,
});

const setStatus = (status: DojoStatus) => set({ status });

/**
 * Processes and sets new output from a player
 * Decodes and formats text before adding it to the terminal
 * @param {Outputter | undefined} playerStory - Output data from a player
 */
const setOutputter = async (playerStory: PlayerStory | undefined) => {
	const oldLines = get().playerStory?.story || [];
	const isNewText = oldLines.length > 0;

	if (playerStory === undefined) {
		return;
	}
	// remove lines we already have
	const storyLines = playerStory.story.slice(oldLines.length);

	// @dev: this is a hack for now - we only have array indices for the story, this might not be the best approach- we still want an immediate (frontend) prompt, but we also store the prompt in the story
	if (isNewText && storyLines[0].startsWith("> ")) {
		storyLines.shift();
	}
	console.log(oldLines, storyLines);

	const newText = Array.isArray(storyLines)
		? storyLines.join("\n")
		: storyLines || ""; // Ensure it's always a string

	console.log("[STORY]:", newText);

	// @dev decode and reprocess text to escape characters such as %20 and %2C, we can not create calldata with \n or other escape characters because the Starknet processor will go into an infinite loop 🥳
	const trimmedNewText = decodeDojoText(newText.trim());
	const lines: string[] = processWhitespaceTags(trimmedNewText);
	set({ lastProcessedText: trimmedNewText });
	set({ playerStory });

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
	if (responseData.PlayerStory) {
		onPlayerStory(responseData.PlayerStory);
	}
	EditorData().syncItem(responseData as AnyObject, {
		verbose: true,
		sync: true,
	});
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
	}, 5000);

	if (existingSubscription !== undefined) return;

	try {
		const [initialEntities, subscription] = await config.sub(onSubscription);
		if (!LORE_CONFIG.EDITOR_MODE) {
			sendCommand("_intro");
		}
		for (const responseData of initialEntities || []) {
			if (responseData.models?.lore) {
				onReponseData(responseData.models.lore);
			}
		}
		clearTimeout(connectionTimeout);

		setStatus({
			status: "initialized",
			error: null,
		});
		// if (!LORE_CONFIG.EDITOR_MODE) {
		sendCommand("_bootLoader");
		// }

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
