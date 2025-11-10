import JSONbig from "json-bigint";
import { LORE_CONFIG } from "@lib/config";
import { toast } from "sonner";
import { addAddressPadding, type BigNumberish, num } from "starknet";
import type { TokenBalances } from "@dojoengine/torii-client";
import type {
	Entity,
	ParentToChildren,
	Trigger,
	Effect,
	Condition,
	Exit,
	Action,
	Reactable,
	DescriptionText,
	ComponentTypeEnum,
} from "@/lib/dojo_bindings/typescript/models.gen";
import { StoreBuilder } from "@/lib/utils/storebuilder";
import {
	createDefaultChildToParentComponent,
	createDefaultEntity,
	createDefaultReactableComponent,
	createDefaultDescriptionText,
	createDefaultContainerComponent,
	createDefaultParentToChildrenComponent,
	createPlayerEntity,
	getPlayerSingletonInst,
	getPlayerAddress,
	getPlayerUsername,
	createDefaultAreaComponent,
	getPlayerEntranceInst,
	createDefaultExitComponent,
} from "../lib/components";
import { Notifications } from "../lib/notifications";
import type {
	AnyObject,
	EditorCollection,
	EntityCollection,
	WithStringEnums,
} from "../lib/types";
import type { ChangeSet, EditorAction } from "../lib/types";
import { bigintToAddress, bigintToHex128, bigintEquals, tick, feltToString } from "@/lib/utils/utils";
import { InitDojo } from "@/lib/dojo";
import { getDojoSdk } from "@/lib/stores/dojo.store";
import { ClauseBuilder, ToriiQueryBuilder } from "@dojoengine/sdk";
import { type SchemaType } from "@lib/dojo_bindings/typescript/models.gen";
import { publishEntityCollection, publishConfigToContract } from "@/editor/publisher";


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
	creatorsFilter: [] as bigint[],
});

const getItem = (id: BigNumberish, syncPool = false) =>
	get()[syncPool ? "syncPool" : "dataPool"].get(num.toHex64(id.toString()));

export const getEntity = (id: BigNumberish, syncPool = false) => {
	const item = getItem(id, syncPool);
	if (item === undefined) return undefined;
	return JSONbig.parse(JSONbig.stringify(item)) as EntityCollection;
};

const getEntities = () =>
	Array.from(get().dataPool.values())
		.map((x: any) => x.Entity && getEntity(x?.Entity?.inst)!)
		.filter((x: any) => x !== undefined)
		// Dev Note: we should try to order by created time instead of name
		.sort((a: any, b: any) =>
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

const setIsDirty = () => {
	set({
		isDirty: Date.now(),
	});
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
	key?: BigNumberish,
) => {
	set({
		changeSet: [...get().changeSet, { type, object, inst, key }],
	});
	console.log("Create Action: changeSet", get().changeSet);
};

export const updateComponent = <T extends keyof EntityCollection>(
	inst: BigNumberish,
	componentName: T,
	component: EntityCollection[T] | undefined,
	disableAutoSync = false,
) => {
	if (component === undefined) {
		return removeComponent(inst, componentName);
	}
	const edited = getEntity(inst);
	if (edited === undefined) {
		throw new Error("Entity not found");
	}

	const isMultiKey = [
		"Action",
		"Effect",
		"Trigger",
		"Condition",
		"CONDITION",
		"DESCRIPTIONTEXT",
		"DescriptionText",
	].includes(componentName)

	if (isMultiKey && !edited[componentName]) {
		edited[componentName] = [];
	}

	if (edited[componentName] && Array.isArray(edited[componentName])) {
		let index = edited[componentName].findIndex(
			(i) => i.inst === component.inst && i.key === component.key
		);
		if (index > -1) {
			edited[componentName][index] = component;
		} else {
			edited[componentName].push(component);
			if (componentName === "DescriptionText" && !disableAutoSync) {
				if (edited.Reactable && edited.Reactable.description) {
					const newKey = (component as any).key;
					if (!edited.Reactable.description.includes(newKey)) {
						edited.Reactable.description.push(newKey);
					}
				}
			}
		}
	} else {
		edited[componentName] = component;
	}

	if (isMultiKey) {
		if (
			get().changeSet.some((x) => x.inst === inst && x.key === component.key && componentName in x.object)
		) {
			console.log(
				get().changeSet.find((x) => x.inst === inst && x.key === component.key && componentName in x.object),
			);
			set({
				changeSet: get().changeSet.filter(
					(x) => (x.inst === inst && !(componentName in x.object)) || x.inst !== inst || x.key !== component.key,
				),
			});
		}
	} else {
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
	createAction("update", inst, { [componentName]: component }, component.key);
	syncItem(edited);
	return edited as EntityCollection;
};

export const removeComponent = <T extends keyof EntityCollection>(
	inst: BigNumberish,
	componentName: T,
	index?: number,
	disableAutoSync = false,
): EntityCollection | undefined => {
	const edited = getEntity(inst);
	if (!edited) throw new Error("Entity not found");

	let deleted: any = undefined;
	let key: any = undefined;

	const isMultiKey = [
		"Action",
		"Effect",
		"Trigger",
		"Condition",
		"DescriptionText",
	].includes(componentName as string);

	if (isMultiKey && Array.isArray(edited[componentName])) {
		// --- multi-component array deletion ---
		if (index === undefined || !edited[componentName]?.[index]) {
			console.warn(`No item found at index ${index} for ${componentName}`);
			return edited;
		}

		deleted = edited[componentName][index];
		key = deleted.key;

		// remove from the component array
		edited[componentName].splice(index, 1);

		// special handling for DescriptionText ↔ Reactable.description sync
		if (componentName === "DescriptionText" && edited.Reactable?.description && !disableAutoSync) {
			edited.Reactable.description = edited.Reactable.description.filter(
				(k) => num.toBigInt(k) !== num.toBigInt(key)
			);
			// update Reactable component
			const componentReactable = edited.Reactable as unknown as WithStringEnums<Reactable>;
			createAction("update", inst, { Reactable: componentReactable }, componentReactable.key);
		}

		if (edited[componentName].length === 0) {
			edited[componentName] = undefined;
		}

		// remove from changeSet
		set({
			changeSet: get().changeSet.filter(
				(x) => !(x.inst === inst && x.key === key && componentName in x.object)
			),
		});

	} else {
		// --- single component deletion ---
		deleted = edited[componentName];
		edited[componentName] = undefined;

		// remove from changeSet
		set({
			changeSet: get().changeSet.filter(
				(x) => !(x.inst === inst && componentName in x.object)
			),
		});
	}

	// create delete action only if component existed in synced entity
	const syncedEntity = getEntity(inst, true);
	if (syncedEntity?.[componentName] !== undefined && deleted !== undefined) {
		createAction("delete", inst, { [componentName]: deleted }, key);
	}

	// sync edited entity
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
	// unbreak whatever we're selecting
	if (bigintEquals(get().selectedEntity, inst)) {
		const parentEntity = (entity.ChildToParent !== undefined) ? getEntity(entity.ChildToParent.parent) : undefined;
		// find closest sibling...
		const silbingIds = parentEntity?.ParentToChildren?.children ?? [];
		const index = silbingIds.findIndex((x) => bigintEquals(x, inst));
		if (index != -1 && silbingIds.length > 1) {
			updateSelectedEntityId(silbingIds[index > 0 ? index - 1 : index + 1]);
		} else if (parentEntity) {
			// or select parent...
			updateSelectedEntityId(parentEntity.Entity.inst);
		} else  {
			updateSelectedEntityId(0n);
		}
	}
	// unbreak whatever we're editing
	if (bigintEquals(get().editedEntity?.Entity?.inst, inst)) {
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

// Resore previously selected entity, or use fallback if not found
const restoreSelectedEntity = (fallback_id: BigNumberish) => {
	selectEntity(localStorage.getItem("selected_entity_id") ?? fallback_id);
};

const selectEntity = (id: BigNumberish) => {
	if (get().selectedEntity !== undefined) {
		const entity = getEntity(get().selectedEntity!);
		if (entity !== undefined) {
			syncItem(entity);
		}
	}
	updateSelectedEntityId(id);
	set({ editedEntity: undefined });

	// uncollapse parents of selected entity to make it visible
	let entity = EditorData().getEntity(id);
	while (entity?.ChildToParent) {
		setEntityCollapsed(entity.ChildToParent.parent, false);
		entity = EditorData().getEntity(entity.ChildToParent.parent);
	}
};

const updateSelectedEntityId = (id: BigNumberish) => {
	set({ selectedEntity: id });
	localStorage.setItem("selected_entity_id", bigintToAddress(id));
};

const _uncollapsedKey = (inst: BigNumberish) => (`uncollapsed_${bigintToAddress(inst)}`);
const setEntityCollapsed = (inst: BigNumberish, collapsed: boolean) => {
	if (!collapsed) {
		localStorage.setItem(_uncollapsedKey(inst), "true");
	} else if (localStorage.getItem(_uncollapsedKey(inst)) === "true") {
		localStorage.removeItem(_uncollapsedKey(inst));
	}
};
const isEntityCollapsed = (inst: BigNumberish) => {
	return localStorage.getItem(_uncollapsedKey(inst)) !== "true";
};

const setCreatorsFilter = (creators: bigint[]) => {
	set({ creatorsFilter: creators });
};
const shouldDisplayEntity = (entity: EntityCollection | undefined): boolean => {
	if (!entity) return false;
	const entityCreatorAddress = BigInt(entity?.Entity?.creator_address ?? 0);
	return (
		entityCreatorAddress === 0n ||
		get().creatorsFilter.length === 0 ||
		get().creatorsFilter.includes(entityCreatorAddress)
	);
};

/**
 * Creates a new entity with default reactable component.
 * @returns the new entity
 */
const newEntity = async () => {
	const newEntity = createDefaultEntity();
	syncItem(newEntity);
	updateComponent(newEntity.Entity.inst, "Entity", newEntity.Entity);
	await tick();
	if (get().selectedEntity !== undefined) {
		const e = getEntity(get().selectedEntity!)!;
		console.log(e);
		if (e.ChildToParent !== undefined) {
			const newParent = getEntity(e.ChildToParent.parent)!;
			console.log(newParent);
			addToParent(getEntity(newEntity.Entity.inst)!, newParent);
		}
	}
	selectEntity(newEntity.Entity.inst);
	const descriptionText = createDefaultDescriptionText(newEntity.Entity);
	descriptionText.DescriptionText.text = newEntity.Entity.name;
	descriptionText.DescriptionText.key = 0;
	updateComponent(newEntity.Entity.inst, "DescriptionText", descriptionText.DescriptionText as any);
	const reactable = createDefaultReactableComponent(newEntity.Entity);
	reactable.Reactable.description = [descriptionText.DescriptionText.key];
	updateComponent(newEntity.Entity.inst, "Reactable", reactable.Reactable as any);

	return newEntity;
};

/**
 * Creates a new player entity with the default components.
 * @returns The new player entity
 */
export const getPlayerEntity = (): EntityCollection | undefined => {
	let existingPlayerEntity = getEntity(getPlayerSingletonInst())
	if (existingPlayerEntity?.Entity?.inst) {
		return existingPlayerEntity;
	}
	return undefined;
};

export const newPlayer = async (): Promise<EntityCollection | undefined> => {
	let existingPlayerEntity = getEntity(getPlayerSingletonInst())
	if (existingPlayerEntity) {
		console.warn("Player singleton already exists");
		selectEntity(existingPlayerEntity.Entity.inst);
		return existingPlayerEntity;
	}

	const spawnPoint = await getSpawnPoint();
	if (spawnPoint === undefined) {
		console.error("No spawn point found");
		return;
	}
	console.log("Spawn point:", spawnPoint);

	await syncEntities();

	const playerEntity = createPlayerEntity(spawnPoint.toString());
	syncItem(playerEntity);
	updateComponent(playerEntity.Entity.inst, "Entity", playerEntity.Entity);
	updateComponent(playerEntity.Entity.inst, "Player", playerEntity.Player);
	await tick();

	// parent will be the spawn point	
	const newParent = getEntity(spawnPoint)!;
	// console.log("newParent", newParent);
	const children = playerEntity;
	// console.log("children", children);
	await tick();
	if (!newParent || !children) {
		console.error("Failed to retrieve parent or child entity after tick.", {
			childId: playerEntity.Entity.inst,
			parentId: spawnPoint.toString(),
			newParent,
			children,
		});
		return;
	}
	addToParent(children, newParent);
	selectEntity(playerEntity.Entity.inst);
	const descriptionText = createDefaultDescriptionText(playerEntity.Entity);
	descriptionText.DescriptionText.text = playerEntity.Entity.name;
	descriptionText.DescriptionText.key = 0;
	updateComponent(playerEntity.Entity.inst, "DescriptionText", descriptionText.DescriptionText as any);
	const reactable = createDefaultReactableComponent(
		playerEntity.Entity,
		[descriptionText.DescriptionText],
		playerEntity.Entity.name,
	);
	updateComponent(playerEntity.Entity.inst, "Reactable", reactable.Reactable as any);
	const container = createDefaultContainerComponent(playerEntity.Entity);
	updateComponent(playerEntity.Entity.inst, "Container", container.Container as any);
	return playerEntity;
};


/**
 * Creates a new Area trail for an player Editor entity with the default components.
 * @returns The new entity
 */
const getPlayersTrailEntity = (): EntityCollection | undefined => {
	const walletAddress = getPlayerAddress();
	if (BigInt(walletAddress ?? 0) === 0n) {
		throw new Error("Player entrance instance is 0");
	}
	return getEntity(walletAddress);
};

const createOrSelectPlayersTrailEntity = async () => {
	// find existing entity
	let existingEntity = getPlayersTrailEntity()
	if (existingEntity) {
		console.warn("Player trail entity already exists");
		selectEntity(existingEntity.Entity.inst);
		return existingEntity;
	}

	// player route instance is the wallet address
	const walletAddress = getPlayerAddress();
	const username = getPlayerUsername();

	// create Entity
	const newEntity = createDefaultEntity();
	newEntity.Entity.inst = walletAddress;
	newEntity.Entity.name = `${username}'s Trail`;
	newEntity.Entity.alt_names = [username];
	syncItem(newEntity);
	updateComponent(newEntity.Entity.inst, "Entity", newEntity.Entity);
	await tick();

	const descriptionText = createDefaultDescriptionText(newEntity.Entity);
	descriptionText.DescriptionText.text = newEntity.Entity.name;
	descriptionText.DescriptionText.key = 0;
	updateComponent(newEntity.Entity.inst, "DescriptionText", descriptionText.DescriptionText as any);

	const reactable = createDefaultReactableComponent(
		newEntity.Entity,
		[descriptionText.DescriptionText],
		newEntity.Entity.name,
	);
	updateComponent(newEntity.Entity.inst, "Reactable", reactable.Reactable as any);

	const area = createDefaultAreaComponent(newEntity.Entity);
	area.Area.is_spawn_point = false;
	area.Area.progress_percentage = 0;
	area.Area.preserve_children = false;
	updateComponent(newEntity.Entity.inst, "Area", area.Area as any);

	// create way back to crossroads
	await createExit({
		leads_to: crossroadsInst,
		name: `Crossroads`,
		description: `Way back to the Crossroads`,
		parentInst: newEntity.Entity.inst,
		altNames: [`crossroads`],
		autoSelect: false,
	});

	// select it
	selectEntity(newEntity.Entity.inst);

	return newEntity;
};


/**
 * Creates a new Area trail for an player Editor entity with the default components.
 * @returns The new entity
 */
const crossroadsInst = '0x00e0c2c6ce0cdff92c8e857cbde8b7e1ff75cabd59d015389e90aef0a033a976';
const getPlayersEntranceEntity = (): EntityCollection | undefined => {
	const entranceInst = getPlayerEntranceInst();
	if (entranceInst === 0n) {
		throw new Error("Player entrance instance is 0");
	}
	return entranceInst ? getEntity(entranceInst) : undefined;
};
const createOrSelectPlayersEntranceEntity = async (): Promise<EntityCollection> => {
	const crossroadsEntity = getEntity(crossroadsInst);
	// find existing entity
	let existingEntity = getPlayersEntranceEntity()
	if (existingEntity) {
		console.warn("Player entrance entity already exists");
		addToParent(existingEntity, crossroadsEntity!);
		selectEntity(existingEntity.Entity.inst);
		return existingEntity;
	}

	// player entrance instance is derived from the wallet address
	const entranceInst = getPlayerEntranceInst();
	const walletAddress = getPlayerAddress();
	const username = getPlayerUsername();

	const trialCount = crossroadsEntity?.ParentToChildren?.children.length ?? 0;

	const newEntity = await createExit({
		leads_to: walletAddress,
		name: `T${trialCount + 1}-${username}`,
		description: `${username}'s trail entrance`,
		parentInst: crossroadsInst,
		inst: entranceInst,
		altNames: [username],
		autoSelect: true,
	});
	console.log("DEBUG: createOrSelectPlayersEntranceEntity() newEntity: ", newEntity);
	return newEntity;
};

export const createExit = async ({
	leads_to,
	name,
	description,
	parentInst,
	inst,
	altNames = [],
	autoSelect = true,
}: {
	leads_to: BigNumberish
	name: string
	description: string
	parentInst: BigNumberish
	inst?: BigNumberish
	altNames?: string[]
	autoSelect?: boolean
}): Promise<EntityCollection> => {
	// create Entity
	const newEntity = createDefaultEntity();
	if (inst && BigInt(inst) !== 0n) {
		newEntity.Entity.inst = bigintToAddress(inst);
	}
	newEntity.Entity.name = name;
	newEntity.Entity.alt_names = altNames;
	syncItem(newEntity);
	updateComponent(newEntity.Entity.inst, "Entity", newEntity.Entity);
	await tick();

	const descriptionText = createDefaultDescriptionText(newEntity.Entity);
	descriptionText.DescriptionText.text = description;
	descriptionText.DescriptionText.key = 0;
	updateComponent(newEntity.Entity.inst, "DescriptionText", descriptionText.DescriptionText as any);

	const reactable = createDefaultReactableComponent(
		newEntity.Entity,
		[descriptionText.DescriptionText],
		description,
	);
	updateComponent(newEntity.Entity.inst, "Reactable", reactable.Reactable as any);

	const exit = createDefaultExitComponent(newEntity.Entity);
	exit.Exit.leads_to = bigintToAddress(leads_to);
	updateComponent(newEntity.Entity.inst, "Exit", exit.Exit as any);

	// add to parent
	addToParent(newEntity, getEntity(parentInst)!);
	
	// select it
	if (autoSelect) {
		selectEntity(newEntity.Entity.inst);
	}
	return newEntity;
};



const logPool = () => {
	const poolArray = Array.from(get().dataPool.values());
	const syncPoolArray = Array.from(get().syncPool.values());
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

/**
 * This handles fetching the property registry for a given component type
 * @param componentType 
 * @returns the property names for the given component type
 */
export const syncPropertyRegistry = async (componentType: ComponentTypeEnum): Promise<string[] | undefined> => {
	let properties_array: string[] | undefined;
	try {
		const sdk = getDojoSdk();
		const queryProperties = () => {
			const builder = new ToriiQueryBuilder<SchemaType>();
			// const query = builder.withOffset(0).withLimit(1000);

			const query = builder.withCursor("").withLimit(1000).includeHashedKeys().withEntityModels(["lore-PropertyRegistry"]);
			return query;
		};
		const result = await sdk.getEntities({ query: queryProperties() });
		// console.log("resuelt asycn", result);

		result.getItems().forEach((item) => {
			const registry = item.models?.lore?.PropertyRegistry;
			if (registry?.component_type === componentType) {
				// console.log("Matched registry:", registry);
				properties_array = registry?.properties?.map((x) => x.name);
				// console.log("properties_array", properties_array);
			}
		});
	} catch (error) {
		console.error("Error fetching properties from Torii:", error);
		throw error;
	}
	return properties_array;
};

/**
 * This handles fetching the spawn point from the first entity with an area component with is_spawn_point set to true
 * @returns The spawn point entity inst
 */
export const getSpawnPoint = async (): Promise<BigNumberish | undefined> => {
	let areaInst: BigNumberish | undefined;
	try {
		const sdk = getDojoSdk();
		const querySpawnPoint = () => {
			const builder = new ToriiQueryBuilder<SchemaType>();
			const query = builder.withCursor("").withLimit(1000).includeHashedKeys().withEntityModels(["lore-Area"]);
			return query;
		};
		const result = await sdk.getEntities({ query: querySpawnPoint() });
		result.getItems().forEach((item) => {
			// Get models with type area
			const area = item.models?.lore?.Area;
			// Check if area is a spawn point
			if (area?.is_spawn_point && area?.inst) {
				// Return the spawn point entity inst
				// This will only work if there is only one spawn point
				// If there are multiple spawn points, this will return the first one
				areaInst = area.inst.toString();
			}
		});
	} catch (error) {
		console.error("Error fetching spawn point from Torii:", error);
		throw error;
	}
	return areaInst;
}

/**
 * Checks if a player exists using the account address
 * @param account The controller address of the player
 * @returns True if the player exists, false otherwise
 */
export const getPlayer = async (account: string): Promise<boolean> => {
  console.log("getPlayer account using", account);

  // Normalize Ethereum addresses (lowercase + remove extra leading zeros)
  const normalizeAddress = (addr: string) =>
    addr.replace(/^0x0+/, "0x").toLowerCase();
  const normalizedAccount = normalizeAddress(account);

  try {
    const sdk = getDojoSdk();
    const query = new ToriiQueryBuilder<SchemaType>()
      .withCursor("")
      .withLimit(1000)
      .includeHashedKeys()
      .withEntityModels(["lore-Player"]);

    const result = await sdk.getEntities({ query });

    return result.getItems().some((item) => {
      const player = item.models?.lore?.Player;
      console.log("player", player);

      const playerAddress = player?.address
        ? normalizeAddress(player.address)
        : null;
      console.log("playerAddress", playerAddress);

      if (playerAddress === normalizedAccount) {
        return true;
      }
      return false;
    });
  } catch (error) {
    console.error("Error fetching player from Torii:", error);
    throw error;
  }
};

export const getAccountRoles = async (address: string): Promise<string[]> => {
  try {
    const sdk = getDojoSdk();
    const query = new ToriiQueryBuilder<SchemaType>()
      .withCursor("")
      .withLimit(1000)
      .includeHashedKeys()
			.withClause(
				new ClauseBuilder<SchemaType>().keys(
					["lore-AccessGrantedEvent"],
					[bigintToAddress(address), undefined]
				).build()
			)
      .withEntityModels(["lore-AccessGrantedEvent"]);

    const result = await sdk.getEventMessages({ query });

		const roles = result?.getItems()
			?.map((item) => item.models?.lore?.AccessGrantedEvent?.role as BigNumberish)
			?.map((role) => {
				const roleString = feltToString(role);
				return roleString.startsWith("ROLE_") ? roleString : roleString === "" ? "DEFAULT_ADMIN_ROLE" : role as string;
			}) ?? [] as string[];
		// console.log("DEBUG: getAccountRoles(): ", roles);

		return roles;
  } catch (error) {
    console.error("Error fetching account permissions from Torii:", error);
    throw error;
  }
};

export const propertiesRegistered = async (
  maxRetries = 5,
  delayMs = 2000
): Promise<boolean> => {
  try {
    const sdk = getDojoSdk();
    const query = new ToriiQueryBuilder<SchemaType>()
      .withCursor("")
      .withLimit(1000)
      .includeHashedKeys()
      .withEntityModels(["lore-PropertyRegistry"]);

    for (let attempt = 0; attempt < maxRetries; attempt++) {
      const result = await sdk.getEntities({ query });
      const items = result.getItems();
      console.log(
        `propertiesRegistered attempt ${attempt + 1}: found ${items.length} registries`,
        items
      );

      if (items.length >= 6) {
        console.log("✅ All 6 PropertyRegistry components are registered");
        return true;
      }

      // Wait before retrying
      if (attempt < maxRetries - 1) {
        await new Promise((res) => setTimeout(res, delayMs));
      }
    }

    console.warn(
      `⚠️ Properties not fully registered after ${maxRetries} retries`
    );
    return false;
  } catch (error) {
    console.error("Error fetching properties from Torii:", error);
    throw error;
  }
};

export const queryCoinsPerGame = async (gameId: bigint): Promise<bigint> => {
  let coins_quantiy: bigint = 0n;
	try {
		// 1. Get the original entity
		const sdk = getDojoSdk();
		const query_entities = new ToriiQueryBuilder<SchemaType>()
      .withCursor("")
      .withLimit(1000)
      .includeHashedKeys()
      .withEntityModels(["lore-Entity"]);

    const result = await sdk.getEntities({ query: query_entities });


    const coinsEntity = result.getItems().find((item) => {
      return item.models?.lore?.Entity?.name === "COINS";
    });
		console.log("DEBUG: queryCoinsPerGame() coinsEntity: ", coinsEntity);

		const coinsInst = BigInt(coinsEntity?.models?.lore?.Entity?.inst ?? 0);
		if (!coinsInst) {
			console.error("ERROR: queryCoinsPerGame() coinsInst is undefined");
			return 0n;
		}
		console.log("DEBUG: queryCoinsPerGame() coinsInst: ", coinsInst);

		// query game instance map
		let game_inst_map: BigNumberish = await queryGameInstaceMap(gameId, coinsInst);
		console.log("DEBUG: queryCoinsPerGame() game_inst_map.inst: ", game_inst_map);

		// query inventory item
		const inv_item_inst = await queryInvItemGIMap(game_inst_map, coinsInst);
		console.log("DEBUG: queryCoinsPerGame() inv_item_inst: ", inv_item_inst);

		coins_quantiy = BigInt(inv_item_inst);
		
  } catch (error) {
    console.error("Error fetching coins entity from Torii:", error);
    throw error;
  }
	return coins_quantiy;
};

export const queryGameInstaceMap = async (gameId: bigint, inst: bigint): Promise<bigint> => {
	let game_inst_map: bigint = 0n;
	try{
		const sdk = getDojoSdk();
		// Get the game instance using the coins entity and the game id
		const query_coins_game_inst = new ToriiQueryBuilder<SchemaType>()
      .withCursor("")
      .withLimit(1000)
      .includeHashedKeys()
      .withClause(
				new ClauseBuilder<SchemaType>().keys(
					["lore-GameInstanceMap"],
					[bigintToHex128(gameId), bigintToAddress(inst)]
				).build()
			).withEntityModels(["lore-GameInstanceMap"]);
		
		const result_coins_game_inst = await sdk.getEntities({ query: query_coins_game_inst });
		console.log("DEBUG: queryCoinsPerGame() result_coins_game_inst: ", result_coins_game_inst);

		game_inst_map = BigInt(result_coins_game_inst.getItems().at(0)?.models?.lore?.GameInstanceMap?.game_inst ?? 0);
		
		
	} catch (error) {
		console.error("Error fetching game instance map from Torii:", error);
		throw error;
	}
	return game_inst_map; 
};

export const queryInvItemGIMap = async (gameInst: bigint, origInst: bigint): Promise<bigint> => {
	let inv_item_inst: bigint = 0n;
	try{
		const sdk = getDojoSdk();
		// get invItem
		const queryValue = gameInst != 0n ? gameInst : origInst;
		const query_inv_item = new ToriiQueryBuilder<SchemaType>()
			.withCursor("")
			.withLimit(1000)
			.includeHashedKeys()
			.withClause(
				new ClauseBuilder<SchemaType>().keys(
					["lore-InventoryItem"],
					[bigintToHex128(queryValue)]
				).build()
			).withEntityModels(["lore-InventoryItem"]);
			
			
			const result_inv_item = await sdk.getEntities({ query: query_inv_item });
			console.log("DEBUG: queryInvItemGIMap() result_inv_item: ", result_inv_item);

			inv_item_inst = BigInt(result_inv_item.getItems().at(0)?.models?.lore?.InventoryItem?.quantity ?? 0);
	} catch (error) {
		console.error("Error fetching inventory item from Torii:", error);
		throw error;
	}
	return inv_item_inst;
};


export const queryGameCoinsBalance = async (inst: BigNumberish): Promise<BigNumberish> => {
  try {
    const sdk = getDojoSdk();
    const query = new ToriiQueryBuilder<SchemaType>()
      .withCursor("")
      .withLimit(1000)
      .includeHashedKeys()
      .withEntityModels(["lore-InventoryItem"]);

    const result = await sdk.getEntities({ query });

    const coinsEntity = result.getItems().find((item) => {
      return item.models?.lore?.InventoryItem?.inst === inst;
    });

    return coinsEntity?.models?.lore?.InventoryItem?.quantity ?? 0; // fallback if not found
  } catch (error) {
    console.error("Error fetching coins balance from Torii:", error);
    throw error;
  }
};

export type GameToken = {
	token_id: number;
	name: string;
};
export const queryOwnedGameTokens = async (ownerAddress: BigNumberish): Promise<GameToken[]> => {
  try {
    const sdk = getDojoSdk();
		// get all tokens owned by the address
    const tokens: TokenBalances = await sdk.getTokenBalances({
			contractAddresses: [addAddressPadding(LORE_CONFIG.manifests.game_token.address)],
			accountAddresses: [addAddressPadding(ownerAddress)],
		});
		const result: GameToken[] = tokens.items
			.filter((item) => BigInt(item.balance) > 0n)
			.filter((item) => item.token_id !== undefined)
			.sort((a, b) => Number(BigInt(a.token_id ?? 0)) - Number(BigInt(b.token_id ?? 0)))
			.map((item) => ({
				token_id: Number(BigInt(item.token_id ?? 0)),
				name: `game-${BigInt(item.token_id ?? 0).toString()}`,
			}));
		return result;
  } catch (error) {
    console.error("Error fetching owned game tokens from Torii:", error);
    throw error;
  }
};

export let playerFound = false;
export let playerExists = false;

/**
 * Checks if a player exists and creates one if it doesn't
 */
export const checkForPlayer = async () => {
	if (!playerExists) {
		playerFound = await getPlayer(getPlayerAddress());
		console.log("playerFound", playerFound);
		if (playerFound) {
			playerExists = true;
		} else {
			const player = await newPlayer();
			if (player) {
				await publishEntityCollection(player);
				await publishConfigToContract();
				playerExists = true;
			}
		}
	}
}

export const queryTriggers = async () => {
	try { 
		const sdk = getDojoSdk();
		const query = new ToriiQueryBuilder<SchemaType>()
			.withCursor("")
			.withLimit(1000)
			.includeHashedKeys()
			.withEntityModels(["lore-TriggerIndex"]);

			const result = await sdk.getEntities({ query });

			const triggers = result.getItems().map((item) => {
				console.log("DEBUG: TriggerIndex", item.models?.lore?.TriggerIndex);
				return item.models?.lore?.TriggerIndex;
			});

			return triggers;
	} catch (error) {
		console.error("Error fetching triggers from Torii:", error);
		throw error;
	}
};

export const queryExecActions = async () => {
	try {
		const sdk = getDojoSdk();
		const query = new ToriiQueryBuilder<SchemaType>()
			.withCursor("")
			.withLimit(1000)
			.includeHashedKeys()
			.withEntityModels(["lore-ActionExecuted"]);

			const result = await sdk.getEntities({ query });

			const actions = result.getItems().map((item) => {
				console.log("DEBUG: ActionExecuted", item.models?.lore?.ActionExecuted);
				return item.models?.lore?.ActionExecuted;
			});

			return actions;
	} catch (error) {
		console.error("Error fetching actions from Torii:", error);
		throw error;
	}
};

// every model that supports Instance<>
export const gameInstModels: `${string}-${string}`[] = [
	"lore-Player",
	"lore-Area",
	"lore-Container",
	"lore-Exit",
	"lore-InventoryItem",
	"lore-Reactable",
	"lore-ParentToChildren",
	"lore-ChildToParent",
];
export const queryGameComponents = async (gameId: BigNumberish) => {
	try {
		const sdk = getDojoSdk();
		// get all game instances for the game id
		const query_game_insts = new ToriiQueryBuilder<SchemaType>()
			.withCursor("")
			.withLimit(90000)
			.includeHashedKeys()
			.withClause(
				new ClauseBuilder<SchemaType>().keys(
					["lore-GameInstanceMap"],
					[bigintToHex128(gameId), undefined]
				).build()
			)
			.withEntityModels(["lore-GameInstanceMap"]);
			const result_game_insts = await sdk.getEntities({ query: query_game_insts });
			const game_insts = result_game_insts.getItems()
			.filter((item) => item.models?.lore?.GameInstanceMap?.game_id !== undefined)
			.map((item) => bigintToAddress(item.models?.lore?.GameInstanceMap?.game_inst ?? 0));
		// console.log("DEBUG: queryGameComponents() game_insts: ", game_insts);

		// get all components for the game instances
		const query_components = new ToriiQueryBuilder<SchemaType>()
			.withCursor("")
			.withLimit(90000)
			.includeHashedKeys()
			.withClause(
				new ClauseBuilder<SchemaType>().compose().or(
					game_insts.map((inst) => new ClauseBuilder<SchemaType>().keys(gameInstModels, [inst])),
				).build()
			)
			.withEntityModels(gameInstModels);
			const result_components = await sdk.getEntities({ query: query_components });
			const components = result_components.getItems()
				.map(item => item.models?.lore ?? {}) as EntityCollection[];
			// console.log("DEBUG: queryGameComponents() components: ", components);

			return components;
	} catch (error) {
		console.error("Error fetching actions from Torii:", error);
		throw error;
	}
};

const syncEntities = async () => {
	try {
		const { sdk, query } = await InitDojo();
		const result = await sdk.getEntities({ query: query() });

		if (result && Array.isArray(result.getItems())) {
			// Clear existing pools
			set({
				syncPool: new Map<BigNumberish, AnyObject>(),
				dataPool: new Map<BigNumberish, AnyObject>(),
			});

			// Update pools with fetched data
			result.getItems().forEach((item) => {
				if (item.models?.lore) {
					const entity = item.models.lore;
					// Handle all component types
					if (entity.Entity?.inst) {
						// For Entity components, set the full entity
						setItem(entity as AnyObject, entity.Entity.inst, true);
					}
				}
			});

			// Update pools with fetched data
			result.getItems().forEach((item) => {
				if (item.models?.lore) {
					const entity = item.models.lore;
					// Handle all component types
					// if (entity.Entity?.inst) {
					// 	// For Entity components, set the full entity
					// 	setItem(entity as AnyObject, entity.Entity.inst, true);
					// } else
					if (entity.Trigger?.inst) {
						// For Trigger components, find parent entity and merge
						const parentEntity = getEntity(entity.Trigger.inst, true);
						if (parentEntity && entity.Trigger) {
							if (!parentEntity.Trigger) {
								parentEntity.Trigger = [];
							}
							// Check if this trigger already exists (by key) and update or add
							const existingIndex = parentEntity.Trigger.findIndex(
								(t: any) => t.key === entity.Trigger!.key
							);
							if (existingIndex > -1) {
								parentEntity.Trigger[existingIndex] = entity.Trigger as Trigger;
							} else {
								parentEntity.Trigger.push(entity.Trigger as Trigger);
							}
							setItem(parentEntity as AnyObject, entity.Trigger.inst, true);
						}
					} 
					
					if (entity.Effect?.inst) {
						// For Effect components, find parent entity and merge
						const parentEntity = getEntity(entity.Effect.inst, true);
						if (parentEntity && entity.Effect) {
							if (!parentEntity.Effect) {
								parentEntity.Effect = [];
							}
							// Check if this effect already exists (by key) and update or add
							const existingIndex = parentEntity.Effect.findIndex(
								(e: any) => e.key === entity.Effect!.key
							);
							if (existingIndex > -1) {
								parentEntity.Effect[existingIndex] = entity.Effect as Effect;
							} else {
								parentEntity.Effect.push(entity.Effect as Effect);
							}
							setItem(parentEntity as AnyObject, entity.Effect.inst, true);
						}
					} 
					
					if (entity.Condition?.inst) {
						// For Condition components, find parent entity and merge
						const parentEntity = getEntity(entity.Condition.inst, true);
						if (parentEntity && entity.Condition) {
							if (!parentEntity.Condition) {
								parentEntity.Condition = [];
							}
							// Check if this condition already exists (by key) and update or add
							const existingIndex = parentEntity.Condition.findIndex(
								(c: any) => c.key === entity.Condition!.key
							);
							if (existingIndex > -1) {
								parentEntity.Condition[existingIndex] = entity.Condition as Condition;
							} else {
								parentEntity.Condition.push(entity.Condition as Condition);
							}
							setItem(parentEntity as AnyObject, entity.Condition.inst, true);
						}
					} 
					
					if (entity.Exit?.inst) {
						// For Exit components, find parent entity and merge
						const parentEntity = getEntity(entity.Exit.inst, true);
						if (parentEntity && entity.Exit) {
							parentEntity.Exit = entity.Exit as Exit;
							setItem(parentEntity as AnyObject, entity.Exit.inst, true);
						}
					}
					
					if (entity.Action?.inst) {
						// For Action components, find parent entity and merge
						const parentEntity = getEntity(entity.Action.inst, true);
						if (parentEntity && entity.Action) {
							if (!parentEntity.Action) {
								parentEntity.Action = [];
							}
							// Check if this action already exists (by key) and update or add
							const existingIndex = parentEntity.Action.findIndex(
								(a: any) => a.key === entity.Action!.key
							);
							if (existingIndex > -1) {
								parentEntity.Action[existingIndex] = entity.Action as Action;
							} else {
								parentEntity.Action.push(entity.Action as Action);
							}
							setItem(parentEntity as AnyObject, entity.Action.inst, true);
						}
					}

					if (entity.DescriptionText?.inst) {
						// For DescriptionText components, find parent entity and merge
						const parentEntity = getEntity(entity.DescriptionText.inst, true);
						if (parentEntity && entity.DescriptionText) {
							if (!parentEntity.DescriptionText) {
								parentEntity.DescriptionText = [];
							}

							// Check if this description already exists (by key) and update or add
							const existingIndex = parentEntity.DescriptionText.findIndex(
								(d: any) => d.key === entity.DescriptionText!.key
							);
							if (existingIndex > -1) {
								parentEntity.DescriptionText[existingIndex] = entity.DescriptionText as DescriptionText;
							} else {
								parentEntity.DescriptionText.push(
									entity.DescriptionText as DescriptionText
								);
							}
							setItem(
								parentEntity as AnyObject,
								entity.DescriptionText.inst,
								true
							);
						}
					}
				}
			});
		}
	} catch (error) {
		console.error("Error fetching from Torii:", error);
		throw error;
	}
};

const EditorData = createFactory({
	get,
	setIsDirty,
	getEntities,
	getEntity,
	newEntity,
	getPlayersTrailEntity,
	getPlayersEntranceEntity,
	createOrSelectPlayersTrailEntity,
	createOrSelectPlayersEntranceEntity,
	removeEntity,
	selectEntity,
	setEntityCollapsed,
	isEntityCollapsed,
	setCreatorsFilter,
	shouldDisplayEntity,
	updateComponent,
	restoreSelectedEntity,
	removeComponent,
	logPool,
	resetChanges,
	dojoSync,
	addToParent,
	removeParent,
	getPlayerEntity,
	newPlayer,
	syncEntities,
	TEMP_CONSTANT_WORLD_ENTRY_ID,
});

export default EditorData;
export { useEditorData };
