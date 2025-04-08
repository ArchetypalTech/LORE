import type {
	Entity,
	ParentToChildren,
} from "@/lib/dojo_bindings/typescript/models.gen";
import { StoreBuilder } from "@/lib/utils/storebuilder";
import JSONbig from "json-bigint";
import { toast } from "sonner";
import { type BigNumberish, encode } from "starknet";
import { createRandomName, randomKey } from "../editor.utils";
import { Notifications } from "../lib/notifications";
import type {
	AnyObject,
	EditorCollection,
	EntityCollection,
} from "../lib/types";
import type { ChangeSet, EditorAction } from "../lib/types";

const TEMP_CONSTANT_WORLD_ENTRY_ID = parseInt("0x1c0a42f26b594c").toString();

const {
	get,
	set,
	createFactory,
	useStore: useEditorData,
} = StoreBuilder({
	syncPool: new Map<BigNumberish, AnyObject>(),
	dataPool: new Map<BigNumberish, AnyObject>(),
	parents: [] as ParentToChildren[],
	changeSet: [] as ChangeSet[],
	selectedEntity: undefined as BigNumberish | undefined,
	editedEntity: undefined as EntityCollection | undefined,
	isDirty: undefined as number | undefined,
});

const getItem = (id: BigNumberish, syncPool = false) =>
	get()[syncPool ? "syncPool" : "dataPool"].get(
		encode.sanitizeHex(id.toString()),
	);

const getEntity = (id: BigNumberish, syncPool = false) => {
	const item = getItem(id, syncPool);
	if (item === undefined) return undefined;
	return JSONbig.parse(JSONbig.stringify(item)) as EntityCollection;
};

const getEntities = () =>
	get()
		.dataPool.values()
		.toArray()
		.map((x) => x.Entity && getEntity(x?.Entity?.inst)!)
		.filter((x) => x !== undefined)
		.sort((a, b) =>
			a.Entity.inst.toString().localeCompare(b.Entity.inst.toString()),
		);

const resetChanges = () => {
	set({
		dataPool: new Map<BigNumberish, AnyObject>(get().syncPool),
		changeSet: [],
	});
	selectEntity(get().selectedEntity!);
	toast.dismiss("editor-dirty");
};

const setItem = (obj: AnyObject, id: BigNumberish, sync = false) => {
	const inst = encode.sanitizeHex(id.toString());
	set((prev) => ({
		...prev,
		dataPool: new Map<BigNumberish, AnyObject>(get().dataPool).set(inst, obj),
		syncPool: sync
			? new Map<BigNumberish, AnyObject>(get().syncPool).set(inst, obj)
			: get().syncPool,
	}));
	if (!sync) {
		set({
			isDirty: Date.now(),
		});
		Notifications().needsToPublish();
	}
};

const createAction = (
	type: EditorAction,
	inst: BigNumberish,
	object: EditorCollection,
) => {
	set({
		changeSet: [...get().changeSet, { type, object, inst }],
	});
};

const updateComponent = <T extends keyof EntityCollection>(
	inst: BigNumberish,
	componentName: T,
	component: EntityCollection[T],
) => {
	const edited = getEntity(inst);
	if (edited === undefined) {
		throw new Error("Entity not found");
	}
	edited[componentName] = component;
	if (
		get().changeSet.some((x) => x.inst === inst && componentName in x.object)
	) {
		set({
			changeSet: get().changeSet.filter(
				(x) => x.inst !== inst && componentName in x.object,
			),
		});
	}
	createAction("update", inst, { [componentName]: component });
	syncItem(edited);
	return edited as EntityCollection;
};

const removeComponent = (
	inst: BigNumberish,
	componentName: keyof EntityCollection,
): EntityCollection | undefined => {
	const edited = getEntity(inst);
	if (edited === undefined) {
		throw new Error("Entity not found");
	}
	if (componentName === "Entity") {
		removeEntity(edited);
		return undefined;
	}
	console.warn("removeComponent", edited, componentName);
	const deleted = edited[componentName];
	edited[componentName] = undefined;
	if (
		get().changeSet.some((x) => x.inst === inst && componentName in x.object)
	) {
		console.log("update");
		set({
			changeSet: get().changeSet.filter(
				(x) => x.inst !== inst || (x.inst === inst && !(componentName in x.object)),
			),
		});
	}
	createAction("delete", inst, { [componentName]: deleted });
	syncItem(edited);
	return edited as EntityCollection;
};

const addToParent = (child: EntityCollection, parent: EntityCollection) => {
	const entity = getEntity(child.Entity.inst)!;
	if ("ChildToParent" in entity) {
		removeParent(getEntity(entity.ChildToParent!.inst)!);
	}
};

// const removeChild = (parent: EntityCollection, child: EntityCollection) => {

const removeParent = (child: EntityCollection) => {
	console.log("rp", child);
	if ("ChildToParent" in child) {
		const parent = getEntity(child.ChildToParent!.parent)!;
		console.log("rp2", child, parent);
		if (child.ChildToParent!.parent === parent.Entity.inst) {
			console.log("rp3", child, parent);
			createAction("delete", child.ChildToParent!.inst, {
				["ChildToParent" as keyof EntityCollection]: child.ChildToParent!,
			});
			child.ChildToParent = undefined;
			parent.ParentToChildren!.children = parent.ParentToChildren!.children.filter(
				(c) => c !== child.Entity.inst,
			);
			if (parent.ParentToChildren!.children.length === 0) {
				createAction("delete", parent.ParentToChildren!.inst, {
					["ParentToChildren" as keyof EntityCollection]: parent.ParentToChildren!,
				});
			}
			syncItem(child);
			syncItem(parent);
			EditorData().set({
				isDirty: Date.now(),
			});
			return;
		}
		throw new Error("Not parent of child");
	}
	throw new Error("Child does not have parent");
};

const removeEntity = (entity: EntityCollection) => {
	if (!("Entity" in entity)) {
		throw new Error("Entity is not an entity");
	}
	const inst = entity.Entity!.inst;
	if (get().selectedEntity === inst) {
		const index = getEntities().findIndex((x) => x.Entity?.inst === inst);
		set({ selectedEntity: getEntities()[index + 1]?.Entity?.inst });
	}
	if (get().editedEntity?.Entity?.inst === inst) {
		set({ editedEntity: undefined });
	}
	// unparent all children
	if ("ParentToChildren" in entity) {
		const children = (
			entity.ParentToChildren as ParentToChildren
		)?.children.flat();
		children.forEach((child) => {
			removeParent(getEntity(child)!);
		});
	}
	if ("ChildToParent" in entity) {
		removeParent(getEntity(entity.ChildToParent!.inst)!);
	}

	// remove all potential create/update actions for this entity
	const prevUpdates = get().changeSet.filter(
		(x) => x.inst === inst && x.type === "update",
	);
	set({
		changeSet: get().changeSet.filter((x) => !prevUpdates.includes(x)),
	});

	// check if actually exists in original datapool
	if (getEntity(inst, true) !== undefined) {
		// remove all components
		Object.keys(entity).forEach((key) => {
			if (key === "Entity") return;
			removeComponent(entity.Entity.inst, key as keyof EntityCollection);
		});
		// add to changeset
		createAction("delete", entity.Entity.inst, {
			["Entity" as keyof EntityCollection]: entity.Entity!,
		});
	}

	// remove from data pool
	const newDataPool = new Map<BigNumberish, AnyObject>(get().dataPool);
	newDataPool.delete(inst);
	set((prev) => ({
		...prev,
		dataPool: newDataPool,
		isDirty: Date.now(),
	}));
	Notifications().needsToPublish();
};

const syncItem = (
	obj: AnyObject,
	{ verbose = false, sync = false }: { verbose?: boolean; sync?: boolean } = {},
) => {
	try {
		if (obj === undefined) return;
		// @dev: Ignore things we aren't storing in the datapool, this needs to be expanded
		if ("Dict" in obj) {
			return;
		}
		let name = "";
		// @dev: add Entity models to entities
		if ("Entity" in (obj as { Entity: Entity })) {
			name = obj.Entity!.name;
		}
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

		// @dev: merge items into datapool (or new if don't exist)
		if (inst !== undefined) {
			const existing = { ...getItem(inst) };
			if (existing === undefined) {
				console.error("Existing object not found:", inst, obj);
				return;
			}
			const merged = { ...existing, ...obj };
			const compare = JSONbig.stringify(merged).includes(
				JSONbig.stringify(existing),
			);
			if (!compare) {
				setItem({ ...merged } as AnyObject, inst, sync);
			}
		}

		if (verbose)
			console.log(
				`[Editor] Sync${name ? `: ${name}` : ""}: ${
					// biome-ignore lint/suspicious/noExplicitAny: <force extract type from keys>
					Object.keys(obj as any)
				}`,
				obj,
				get(),
			);
		set({ isDirty: Date.now() });
	} catch (e) {
		console.error("data-sync error:", e, "object: ", obj);
	}
};

const selectEntity = (id: BigNumberish) => {
	if (get().selectedEntity !== undefined) {
		const entity = getEntity(get().selectedEntity!);
		if (entity !== undefined) {
			syncItem(entity);
		}
	}
	set({ selectedEntity: id, editedEntity: undefined });
};

const updateSelectedEntity = (entity: EntityCollection) => {
	const selectedEntity = get().selectedEntity!;
	Object.assign(selectedEntity, entity);
	set({ selectedEntity });
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
	updateComponent(newEntity.inst, "Entity", newEntity);
	selectEntity(newEntity.inst);
	return newEntity;
};

const logPool = () => {
	const poolArray = get().dataPool.values().toArray();
	console.info("Pool");
	console.table(poolArray);
	console.info("ChangeSet", get().changeSet);
	console.info("Entities", getEntities());
	console.info("Selected", get().selectedEntity);
	console.info("Edited", get().editedEntity);
};

const dojoSync = (
	obj: AnyObject,
	{ verbose = false }: { verbose?: boolean; sync?: boolean } = {},
) => {
	syncItem(obj, { verbose, sync: true });
};

const EditorData = createFactory({
	getEntities,
	getEntity,
	newEntity,
	removeEntity,
	selectEntity,
	updateComponent,
	updateSelectedEntity,
	removeComponent,
	logPool,
	resetChanges,
	dojoSync,
	TEMP_CONSTANT_WORLD_ENTRY_ID,
});

export default EditorData;
export { useEditorData };
