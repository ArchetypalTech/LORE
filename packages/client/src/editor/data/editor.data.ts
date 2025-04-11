import JSONbig from "json-bigint";
import { toast } from "sonner";
import { type BigNumberish, num } from "starknet";
import type {
	Entity,
	ParentToChildren,
} from "@/lib/dojo_bindings/typescript/models.gen";
import { StoreBuilder } from "@/lib/utils/storebuilder";
import {
	createDefaultChildToParentComponent,
	createDefaultEntity,
	createDefaultParentToChildrenComponent,
} from "../lib/components";
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
	get()[syncPool ? "syncPool" : "dataPool"].get(num.toHex64(id.toString()));

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
			a.Entity.name.toString().localeCompare(b.Entity.name.toString()),
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
	const inst = num.toHex64(id.toString());
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
	component: EntityCollection[T] | undefined,
) => {
	if (component === undefined) {
		return removeComponent(inst, componentName);
	}
	const edited = getEntity(inst);
	if (edited === undefined) {
		throw new Error("Entity not found");
	}
	edited[componentName] = component;
	console.log(edited, componentName, component);
	if (
		get().changeSet.some((x) => x.inst === inst && componentName in x.object)
	) {
		console.log(
			get().changeSet.find((x) => x.inst === inst && componentName in x.object),
		);
		set({
			changeSet: get().changeSet.filter(
				(x) => (x.inst === inst && !(componentName in x.object)) || x.inst !== inst,
			),
		});
	}
	// check synced item, do we really need to create an update action
	const syncedEntity = getEntity(inst, true);
	if (syncedEntity?.[componentName] !== undefined) {
		if (
			JSONbig.stringify(syncedEntity[componentName]) ===
			JSONbig.stringify(component)
		) {
			syncItem(edited);
			return edited as EntityCollection;
		}
	}
	createAction("update", inst, { [componentName]: component });
	syncItem(edited);
	console.log(componentName, get().changeSet);
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
	const deleted = { ...edited[componentName] };
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
	// check synced item, do we really need to delete anything
	const syncedEntity = getEntity(inst, true);
	if (syncedEntity?.[componentName] !== undefined) {
		createAction("delete", inst, { [componentName]: deleted });
	}
	syncItem(edited);
	return edited as EntityCollection;
};

const addToParent = (child: EntityCollection, parent: EntityCollection) => {
	const childId = child.Entity.inst;
	const parentId = parent.Entity.inst;
	const newChild = getEntity(childId)!;

	// Check if child already has a parent and remove it if necessary
	if ("ChildToParent" in newChild && newChild.ChildToParent !== undefined) {
		removeParent(getEntity(childId)!);
	}

	const childComponent = createDefaultChildToParentComponent(newChild.Entity);
	childComponent.ChildToParent.parent = parentId;
	console.log(child, childComponent, childId, parentId);
	updateComponent(childId, "ChildToParent", childComponent.ChildToParent);
	// Update the parent's children list
	const newParent = getEntity(parentId)!;
	const parentComponent =
		newParent.ParentToChildren && newParent.ParentToChildren !== undefined
			? { ParentToChildren: { ...newParent.ParentToChildren } }
			: createDefaultParentToChildrenComponent(newParent.Entity);

	// Add child to parent's children array if not already there
	if (!parentComponent.ParentToChildren.children.includes(childId)) {
		parentComponent.ParentToChildren.children.push(childId);
	}

	updateComponent(
		parentId,
		"ParentToChildren",
		parentComponent.ParentToChildren,
	);
};

const removeParent = (child: EntityCollection) => {
	if ("ChildToParent" in child && child.ChildToParent !== undefined) {
		const childId = child.Entity.inst;
		const parentId = child.ChildToParent.parent;

		// Store the parent reference before modifying the child
		const parent = getEntity(parentId);

		// Remove the child's parent reference
		updateComponent(childId, "ChildToParent", undefined);

		if (parent && "Entity" in parent && parent.Entity.inst === parentId) {
			if ("ParentToChildren" in parent && parent.ParentToChildren !== undefined) {
				const newChildren = parent.ParentToChildren.children.filter(
					(c) => c !== childId,
				);

				if (newChildren.length === 0) {
					updateComponent(parentId, "ParentToChildren", undefined);
				} else {
					// Update with the new children list
					const updatedParentComponent = {
						...parent.ParentToChildren,
						children: newChildren,
					};
					updateComponent(parentId, "ParentToChildren", updatedParentComponent);
				}
				EditorData().set({
					isDirty: Date.now(),
				});
				return;
			}
		}

		EditorData().set({
			isDirty: Date.now(),
		});
		throw new Error("Parent missing or invalid");
	}
};

const removeEntity = (entity: EntityCollection) => {
	if (!("Entity" in entity)) {
		throw new Error("Entity is not an entity");
	}
	const inst = entity.Entity!.inst;
	// unbreak whatever we're editing / selecting
	if (get().selectedEntity === inst) {
		const index = getEntities().findIndex((x) => x.Entity?.inst === inst);
		set({ selectedEntity: getEntities()[index + 1]?.Entity?.inst });
	}
	if (get().editedEntity?.Entity?.inst === inst) {
		set({ editedEntity: undefined });
	}
	// unparent all children
	if ("ParentToChildren" in entity && entity.ParentToChildren !== undefined) {
		const children = (
			entity.ParentToChildren as ParentToChildren
		)?.children.flat();
		children.forEach((child) => {
			removeParent(getEntity(child)!);
		});
	}
	if ("ChildToParent" in entity && entity.ChildToParent !== undefined) {
		removeParent(getEntity(entity.ChildToParent!.inst)!);
	}

	// remove all potential update actions for this entity
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
		if (
			"Entity" in (obj as { Entity: Entity }) &&
			(obj as { Entity: Entity }).Entity !== undefined
		) {
			name = (obj as { Entity: Entity }).Entity.name;
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

			// Process object for component deletions and merging
			const merged = processMergedObject(existing, obj);

			const compare = JSONbig.stringify(merged).includes(
				JSONbig.stringify(existing),
			);
			if (!compare) {
				setItem(merged as AnyObject, inst, sync);
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

/**
 * Helper function that properly processes component deletions during merging
 * Handles removing undefined components and safely merging with existing data
 */
const processMergedObject = (
	existing: AnyObject,
	newObj: AnyObject,
): AnyObject => {
	// Create a new object to store the result
	const result = {} as Record<string, unknown>;

	// First copy all existing properties
	Object.keys(existing).forEach((key) => {
		// Use type assertion to ensure TypeScript accepts the indexing
		result[key] = (existing as Record<string, unknown>)[key];
	});

	// Then process the new object's keys
	Object.keys(newObj).forEach((key) => {
		// Get the value with proper type safety
		const value = (newObj as Record<string, unknown>)[key];

		// If the value is undefined, delete the property
		if (value === undefined) {
			delete result[key];
		} else {
			// Otherwise, update the property
			result[key] = value;
		}
	});

	// Preserve special properties if needed
	if (
		"_actionRecord" in existing &&
		(existing as Record<string, unknown>)._actionRecord !== undefined
	) {
		result._actionRecord = (existing as Record<string, unknown>)._actionRecord;
	}

	return result as AnyObject;
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

const newEntity = () => {
	const newEntity = createDefaultEntity();
	syncItem(newEntity);
	updateComponent(newEntity.Entity.inst, "Entity", newEntity.Entity);
	if (get().selectedEntity !== undefined) {
		const e = getEntity(newEntity.Entity.inst)!;
		const newParent = getEntity(get().selectedEntity!)!;
		addToParent(e, newParent);
	} else {
		selectEntity(newEntity.Entity.inst);
	}
	return newEntity;
};

const logPool = () => {
	const poolArray = get().dataPool.values().toArray();
	const syncPoolArray = get().syncPool.values().toArray();
	console.info("DataPool");
	console.table(poolArray);
	console.log("DataPool", get().dataPool);
	console.info("SyncPool");
	console.table(syncPoolArray);
	console.log("SyncPool", get().syncPool);
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
	addToParent,
	removeParent,
	TEMP_CONSTANT_WORLD_ENTRY_ID,
});

export default EditorData;
export { useEditorData };
