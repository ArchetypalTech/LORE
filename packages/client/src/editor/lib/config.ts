import JSONbig from "json-bigint";
import { toast } from "sonner";
import { StoreBuilder } from "@/lib/utils/storebuilder";
import EditorData from "../data/editor.data";
import {
	formatValidationError,
	loadConfigFile,
	saveConfigToFile,
} from "../editor.utils";
import { Notifications } from "./notifications";
import {
	ConfigSchema,
	type ConfigSchemaType,
	transformWithSchema,
} from "./schemas";

const { get, set, createFactory } = StoreBuilder({});

const config = {
	/**
	 * Initialize the editor with a config
	 */
	initialize: async () => {
		console.log("[LORE]: > Hi.");
	},

	/**
	 * Load a config into the editor
	 */
	loadConfig: async (config: ConfigSchemaType) => {
		console.log("Loading config into editor:", config);
		// Validate the config using our Zod schema
		const { result, errors } = await Config().validateConfig(config);
		if (errors.length === 0) {
			try {
				for (const obj of result.dataPool) {
					EditorData().dojoSync(obj);
				}
				// Force UI refresh
				setTimeout(() => {
					set({ ...get() });
				}, 100);
				Notifications().showSuccess("Config loaded successfully");
			} catch (error) {
				console.error("Error loading config:", error);
				Notifications().showError(
					`Error loading config: ${error instanceof Error ? error.message : String(error)}`,
				);
			}
		}
	},

	/**
	 * Save the current config to a JSON file
	 */
	validateConfig: async (config: ConfigSchemaType) => {
		const { data, errors } = transformWithSchema(ConfigSchema, config);
		set({
			isDirty: false,
			errors,
		});
		if (errors.length > 0) {
			Notifications().showError(
				`Config has ${errors.length} validation errors. First error: ${formatValidationError(errors[0])}`,
			);
			console.error("Config has validation errors:", errors);
		}
		return { result: data, errors };
	},

	saveConfigToFile: async () => {
		const dataPool = {
			dataPool: [...EditorData().dataPool.values()],
		} as ConfigSchemaType;
		const { result, errors } = await config.validateConfig(dataPool);
		if (errors.length === 0) {
			await saveConfigToFile(result);
			Notifications().showSuccess("Config saved successfully");
		}
	},

	/**
	 * Load a config from a file with notification feedback
	 */
	loadConfigFromFile: async (file: File) => {
		toast.loading("Loading configuration...", { id: "loading-config" });
		try {
			const config = await loadConfigFile(file);
			const configClone = JSONbig.parse(JSONbig.stringify(config));
			Config().loadConfig(configClone);
			toast.dismiss("loading-config");
			toast.success("Config loaded successfully");
			return config;
		} catch (error: unknown) {
			console.error("Error loading config:", error);
			const errorMsg = error instanceof Error ? error.message : String(error);
			toast.dismiss("loading-config");
			toast.error(`Error loading config: ${errorMsg}`);
		}
		return null;
	},
};

export const Config = createFactory({
	...config,
});

// Initialize
Config().initialize();
