import type { NotificationState } from "@editor/notifications";
import { initialNotificationState } from "@editor/notifications";
import { publishConfigToContract } from "@editor/publisher";
import { StoreBuilder } from "@/lib/utils/storebuilder";
import EditorData from "./editor.data";
import { tick } from "@/lib/utils/utils";
import {
	ConfigSchema,
	transformWithSchema,
	type Config,
	type ValidationError,
} from "./lib/schemas";
import {
	formatValidationError,
	loadConfigFromFile,
	saveConfigToFile,
} from "./editor.utils";
import JSONbig from "json-bigint";

const {
	get,
	set,
	useStore: useEditorStore,
	createFactory,
} = StoreBuilder({
	isDirty: false,
	errors: [] as ValidationError[],
});

const {
	get: getNotification,
	set: setNotification,
	useStore: useNotificationStore,
} = StoreBuilder<NotificationState>(initialNotificationState);

/**
 * Combined actions for the editor, organized by functionality
 */
export const actions = {
	// Notification related actions
	notifications: {
		doLoggedAction: async (action: () => Promise<void>) => {
			actions.notifications.startPublishing();
			await action();
			actions.notifications.finalizePublishing();
		},
		clear: () => {
			setNotification(initialNotificationState);
		},
		showError: (message: string, blocking = false) => {
			setNotification({
				type: "error",
				message,
				blocking,
				logs: undefined,
			});
		},
		showSuccess: (message: string, timeout = 3000) => {
			if (getNotification().blocking) {
				return;
			}
			setNotification({
				type: "success",
				message,
				blocking: false,
				logs: undefined,
				timeout,
			});
		},
		showLoading: (message: string) => {
			setNotification({
				type: "loading",
				message,
				blocking: true,
				logs: undefined,
			});
		},
		startPublishing: async (message = "Publishing to contract...") => {
			if (getNotification().type === "publishing") return;
			console.log("[Notification]: Starting Publishing");
			setNotification({
				type: "publishing",
				message,
				blocking: true,
				logs: [],
			});
			const currentNotification = getNotification();
			return currentNotification.logs || [];
		},

		/**
		 * Add a log entry to a publishing notification
		 */
		addPublishingLog: (log: CustomEvent) => {
			const state = getNotification();
			if (state.type !== "publishing" || state.logs === undefined) {
				console.warn("Cannot add log to non-publishing notification");
				return;
			}
			setNotification({
				...state,
				logs: [...state.logs, log],
			});
		},

		finalizePublishing: () => {
			const state = getNotification();
			actions.notifications.clear();
			if (state.logs === undefined) {
				actions.notifications.showError("No logs to show");
				console.error("No logs to show");
				return;
			}
			if (state.logs.some((log) => log.type === "error")) {
				actions.notifications.showError("Errors while publishing");
			} else {
				actions.notifications.showSuccess("Published to the world successfully");
			}
		},
	},

	// Editor initialization and config operations
	config: {
		/**
		 * Initialize the editor with a config
		 */
		initialize: async () => {
			console.log("> Hi.");
		},

		/**
		 * Load a config into the editor
		 */
		loadConfig: async (config: Config) => {
			console.log("Loading config into editor:", config);
			// Validate the config using our Zod schema
			const { result, errors } = await actions.config.validateConfig(config);
			if (errors.length === 0) {
				try {
					for (const obj of result.dataPool) {
						EditorData().syncItem(obj);
					}
					// Force UI refresh
					setTimeout(() => {
						set({ ...get() });
					}, 100);
					actions.notifications.showSuccess("Config loaded successfully");
				} catch (error) {
					console.error("Error loading config:", error);
					actions.notifications.showError(
						`Error loading config: ${error instanceof Error ? error.message : String(error)}`,
					);
				}
			}
		},

		/**
		 * Save the current config to a JSON file
		 */
		validateConfig: async (config: Config) => {
			// Validate the config using our Zod schema
			const { data, errors } = transformWithSchema(ConfigSchema, config);
			set({
				isDirty: false,
				errors,
			});
			if (errors.length === 0) {
				actions.notifications.showSuccess("Config saved successfully");
			} else {
				actions.notifications.showError(
					`Config has ${errors.length} validation errors. First error: ${formatValidationError(errors[0])}`,
				);
				console.error("Config has validation errors:", errors);
			}
			return { result: data, errors };
		},

		saveConfigToFile: async () => {
			const dataPool = {
				dataPool: [...EditorData().dataPool.values()],
			} as Config;
			const { result, errors } = await actions.config.validateConfig(dataPool);
			// Ensure text definitions are properly formatted and download the file
			if (errors.length === 0) {
				await saveConfigToFile(result);
				actions.notifications.showSuccess("Config saved successfully");
			}
		},

		/**
		 * Load a config from a file with notification feedback
		 */
		loadConfigFromFile: async (file: File) => {
			actions.notifications.showLoading("Loading configuration...");
			try {
				const config = await loadConfigFromFile(file);
				const configClone = JSONbig.parse(JSONbig.stringify(config));
				actions.config.loadConfig(configClone);
				actions.notifications.clear();
				actions.notifications.showSuccess("Config loaded successfully");
				return config;
			} catch (error: unknown) {
				console.error("Error loading config:", error);
				const errorMsg = error instanceof Error ? error.message : String(error);
				actions.notifications.clear();
				actions.notifications.showError(`Error loading config: ${errorMsg}`);
				return null;
			}
		},

		/**
		 * Publish the current config to the contract
		 */
		publishToContract: async () => {
			try {
				await actions.notifications.startPublishing();
				await publishConfigToContract();
				actions.notifications.finalizePublishing();
				await tick();
				console.log(EditorData().dataPool);
				return true;
			} catch (error) {
				const errorMsg = error instanceof Error ? error.message : String(error);
				actions.notifications.showError(
					`Error publishing to contract: ${errorMsg}`,
				);
				return false;
			}
		},
	},
};

// Export a composable store object with all functionality
const EditorStore = createFactory({
	...actions,
});

export default EditorStore;
export { useEditorStore, useNotificationStore };

EditorStore().config.initialize();
