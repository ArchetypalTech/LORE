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
import { BigNumberish } from "starknet";

const { get, set, createFactory } = StoreBuilder({});

/**
 * Recursively sync nested components/entities into the store
 */
const deepSync = (obj: any) => {
	EditorData().dojoSync(obj);
	const nestedKeys = ["children", "parent", "Components", "subEntities", "Trigger", "Condition", "Effect", "Action", "DescriptionText"];
	for (const key of nestedKeys) {
		if (obj[key] && Array.isArray(obj[key])) {
			for (const child of obj[key]) {
				deepSync(child);
			}
		}
	}
};

/**
 * Recursively register parent-child relationships
 */
const registerParentChildLinks = (obj: any, parentInst?: BigNumberish) => {
  const inst = obj?.Entity?.inst || obj.inst;
  if (inst && parentInst !== undefined) {
    const { get, set } = EditorData();
    let parents = get().parents || [];

    // Find if the parent already exists in the array
    let parentEntry = parents.find(p => p.inst === parentInst);

    if (!parentEntry) {
      // Create a new ParentToChildren entry if none exists
      parentEntry = {
        inst: parentInst,
        is_parent: true,
        children: [],
      };
      parents.push(parentEntry);
    }

    // Add child if not already included
    if (!parentEntry.children.includes(inst)) {
      parentEntry.children.push(inst);
    }

    set({ parents });
  }

  const nestedKeys = ["children", "Components", "subEntities", "Trigger", "Condition", "Effect", "Action"];
  for (const key of nestedKeys) {
    if (Array.isArray(obj[key])) {
      for (const child of obj[key]) {
        registerParentChildLinks(child, inst);
      }
    }
  }
};

/**
 * Recursively build a flat changeSet from all entities/components
 */
const buildChangeSet = (obj: any): any[] => {
	const inst = obj?.Entity?.inst || obj.inst;
	const set: any[] = inst
		? [{ type: "update" as const, inst, object: obj }]
		: [];

	const nestedKeys = ["children", "parent", "Components", "subEntities", "Action", "Condition", "Effect", "Trigger"];
	for (const key of nestedKeys) {
		if (obj[key] && Array.isArray(obj[key])) {
			for (const child of obj[key]) {
				set.push(...buildChangeSet(child));
			}
		}
	}

	return set;
}

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

		const { result, errors } = await Config().validateConfig(config);
		if (errors.length === 0) {
			try {
				let fullChangeSet: any[] = [];

				for (const obj of result.dataPool) {
					deepSync(obj);
					registerParentChildLinks(obj);
					fullChangeSet.push(...buildChangeSet(obj));
				}

				EditorData().set({
					changeSet: fullChangeSet,
				});

				// Force UI refresh
				setTimeout(() => {
					set({ ...get() });
				}, 100);

				Notifications().showSuccess("Config loaded successfully");
			} catch (error) {
				console.error("Error loading config:", error);
				Notifications().showError(
					`Error loading config: ${
						error instanceof Error ? error.message : String(error)
					}`,
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
			await Config().loadConfig(configClone);
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
