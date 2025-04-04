import { StoreBuilder } from "@/lib/utils/storebuilder";
import { createRandomName, randomKey } from "./editor.utils";
import type {
	Entity,
	ParentToChildren,
} from "@/lib/dojo_bindings/typescript/models.gen";
import { num, type BigNumberish } from "starknet";
import type { AnyObject, EntityCollection } from "./lib/schemas";
import { dispatchDesignerCall } from "./publisher";

const TEMP_CONSTANT_WORLD_ENTRY_ID = parseInt("0x1c0a42f26b594c").toString();

const {
	get,
	set,
	createFactory,
	useStore: useEditorData,
} = StoreBuilder({
	dataPool: new Map<BigNumberish, AnyObject>(),
	entities: [] as Entity[],
	parents: [] as ParentToChildren[],
	selectedEntity: undefined as AnyObject | undefined,
	isDirty: Date.now(),
});

const getEntities = () =>
	(get().entities.map((x) => get().dataPool.get(x.inst)!) as EntityCollection[])
		.filter((x) => x !== undefined)
		.sort((x) => parseInt(x.Entity.inst.toString()));

const getEntity = (id: BigNumberish) =>
	get().dataPool.get(id) as EntityCollection;

const setItem = (obj: AnyObject, id: BigNumberish) => {
	set((prev) => ({
		...prev,
		dataPool: new Map<BigNumberish, AnyObject>(get().dataPool).set(id, obj),
	}));
};

const addEntity = (entity: Entity) => {
	set((prev) => ({
		...prev,
		entities: [...prev.entities.filter((e) => e.inst !== entity.inst), entity],
	}));
};

const removeEntity = (entity: Entity) => {
	const id = entity.inst;
	const isSelected = get().selectedEntity?.Entity?.inst === id;
	if (isSelected) {
		set({ selectedEntity: undefined });
	}
	set((prev) => ({
		...prev,
		entities: prev.entities.filter((e) => e.inst !== entity.inst),
	}));
	const newDataPool = new Map<BigNumberish, AnyObject>({ ...get().dataPool });
	newDataPool.delete(id);
	set((prev) => ({
		...prev,
		dataPool: newDataPool,
	}));
};

const getItem = (id: BigNumberish) => get().dataPool.get(id);

const syncItem = (obj: AnyObject, verbose = false) => {
	try {
		if (obj === undefined) return;
		// @dev: Ignore things we aren't storing in the datapool, this needs to be expanded
		if ("Dict" in obj) {
			return;
		}
		let name = "";

		// @dev: retrieve instance value
		const findInstValue = (obj: AnyObject): BigNumberish | undefined => {
			// First check if 'inst' property exists directly
			if ("inst" in obj) {
				return obj.inst as BigNumberish;
			}
			// Then iterate through keys to find nested instance
			for (const key of Object.keys(obj)) {
				const value = obj[key as keyof typeof obj];
				if (value && typeof value === "object" && !Array.isArray(value)) {
					// Type guard to ensure we're passing a compatible value
					const nestedObj = value as AnyObject;
					const res = findInstValue(nestedObj);
					if (res !== undefined) return res;
				}
			}
			return undefined;
		};

		const inst = findInstValue(obj);
		console.log(obj);
		// @dev: merge items into datapool (or new if don't exist)
		if (inst !== undefined) {
			const existing = { ...(get().dataPool.get(inst) || {}) };
			if (existing === undefined) {
				console.error("Existing object not found:", inst, obj);
				return;
			}
			Object.assign(existing, obj);
			setItem({ ...existing } as AnyObject, inst);
		}

		// @dev: add Entity models to entities
		if ("Entity" in (obj as { Entity: Entity })) {
			addEntity(obj.Entity as Entity);
			name = obj.Entity!.name;
		}

		set({
			isDirty: Date.now(),
		});

		if (verbose)
			console.log(
				`[Editor] Sync${name ? `: ${name}` : ""}: ${
					// biome-ignore lint/suspicious/noExplicitAny: <force extract type from keys>
					Object.keys(obj as any)
				}`,
				obj,
				get(),
			);

		if ("ParentToChildren" in obj || "ChildToParent" in obj) {
			// @dev: we might have a re-parenting so we force update the hierarchy
			set({ entities: [...get().entities] });
		}
	} catch (e) {
		console.error("data-sync error:", e, "object: ", obj);
	}
};

// TODO: implement
const deleteItem = async (model: AnyObject) => {
	if ("Entity" in model) {
		await dispatchDesignerCall("delete_entity", [
			num.toBigInt(model.Entity!.inst),
		]);
	}
	if ("Inspectable" in model) {
		await dispatchDesignerCall("delete_inspectable", [
			num.toBigInt(model.Entity!.inst),
		]);
	}
	if ("Area" in model) {
		await dispatchDesignerCall("delete_area", [num.toBigInt(model.Entity!.inst)]);
	}
	if ("Exit" in model) {
		await dispatchDesignerCall("delete_exit", [num.toBigInt(model.Entity!.inst)]);
	}
	if ("ChildToParent" in model) {
	}
	if ("ParentToChildren" in model) {
	}
	if ("Player" in model) {
	}
};

const selectEntity = (id: BigNumberish) => {
	set({ selectedEntity: get().dataPool.get(id) });
};

const newEntity = (entity: Entity) => {
	const inst = randomKey();
	const newEntity: Entity = {
		inst,
		is_entity: true,
		name: `${createRandomName()}`,
		alt_names: [],
	};
	Object.assign(newEntity, entity);
	syncItem({ Entity: newEntity });
	return newEntity;
};

const logPool = () => {
	const poolArray = get().dataPool.values().toArray();
	console.info("Text Definitions");
	console.table(poolArray);
};

const EditorData = createFactory({
	getEntities,
	getEntity,
	getItem,
	setItem,
	syncItem,
	newEntity,
	removeEntity,
	selectEntity,
	deleteItem,
	logPool,
	TEMP_CONSTANT_WORLD_ENTRY_ID,
});

export default EditorData;
export { useEditorData };
