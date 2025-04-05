import { StoreBuilder } from "@/lib/utils/storebuilder";
import { createRandomName, randomKey } from "../editor.utils";
import type {
	Entity,
	ParentToChildren,
} from "@/lib/dojo_bindings/typescript/models.gen";
import { encode, num, type BigNumberish } from "starknet";
import type {
	AnyObject,
	EntityCollection,
	EntityComponents,
} from "../lib/schemas";
import { dispatchDesignerCall } from "../publisher";
import { toast } from "sonner";
import { Config } from "../lib/config";
import JSONbig from "json-bigint";

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
	deletedQueue: [] as AnyObject[],
	selectedEntity: undefined as BigNumberish | undefined,
	editedEntity: undefined as EntityCollection | undefined,
	isDirty: undefined as number | undefined,
});

const getItem = (id: BigNumberish) =>
	get().dataPool.get(encode.sanitizeHex(id.toString()));

const getEntity = (id: BigNumberish) =>
	JSONbig.parse(JSONbig.stringify(getItem(id))) as EntityCollection;

const getEntities = () =>
	get()
		.entities.map((x) => getEntity(x.inst)!)
		.filter((x) => x !== undefined)
		.sort((x) => parseInt(x.Entity.inst.toString()));

const setItem = (obj: AnyObject, id: BigNumberish, sync = false) => {
	set((prev) => ({
		...prev,
		dataPool: new Map<BigNumberish, AnyObject>(get().dataPool).set(
			encode.sanitizeHex(id.toString()),
			obj,
		),
	}));
	if (!sync) {
		set({
			isDirty: Date.now(),
		});
		toast("Your changes are not yet published", {
			id: "editor-dirty",
			duration: Infinity,
			position: "bottom-center",
			action: {
				label: "Publish",
				onClick: () => Config().publishToContract(),
			},
		});
	}
};

const addEntity = (entity: Entity) => {
	set((prev) => ({
		...prev,
		entities: [...prev.entities.filter((e) => e.inst !== entity.inst), entity],
	}));
};

const removeComponent = (
	entity: EntityCollection,
	component: EntityCollection[keyof EntityCollection],
	componentName: keyof EntityCollection,
): EntityCollection => {
	const edited = { ...entity! } as EntityCollection;
	const deleted = { ...component };
	edited[componentName] = undefined;
	EditorData().set({
		deletedQueue: [
			...EditorData().deletedQueue,
			{ [componentName]: deleted } as Partial<EntityCollection>,
		],
	});
	EditorData().syncItem(edited);
	return edited as EntityCollection;
};

const removeParent = (child: EntityCollection, parent: EntityCollection) => {
	console.log("rp", child, parent);
	if ("ChildToParent" in child && "ParentToChildren" in parent) {
		console.log("rp2", child, parent);
		if (child.ChildToParent!.parent === parent.Entity.inst) {
			console.log("rp3", child, parent);
			removeComponent(
				child,
				{ ChildToParent: child.ChildToParent! },
				"ChildToParent",
			);
			EditorData().syncItem(child);
			parent.ParentToChildren!.children = parent.ParentToChildren!.children.filter(
				(c) => c !== child.Entity.inst,
			);
			if (parent.ParentToChildren!.children.length === 0) {
				removeComponent(
					parent,
					{ ["ParentToChildren"]: parent.ParentToChildren! },
					"ParentToChildren",
				);
			}
			EditorData().syncItem(parent);
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
	const isSelected = get().selectedEntity === inst;
	if (isSelected) {
		set({ selectedEntity: undefined });
	}
	console.log("remove", entity);
	if ("ParentToChildren" in entity) {
		const children = (
			entity.ParentToChildren as ParentToChildren
		)?.children.flat();
		children.forEach((child) => {
			removeParent(getEntity(child)!, getEntity(inst));
		});
	}
	Object.keys(entity).forEach((key) => {
		removeComponent(entity, entity[key as keyof EntityCollection], key);
	});
	const newDataPool = new Map<BigNumberish, AnyObject>(get().dataPool);
	newDataPool.delete(inst);
	set((prev) => ({
		...prev,
		entities: prev.entities.filter((e) => e.inst !== inst),
		dataPool: newDataPool,
		isDirty: Date.now(),
	}));
	toast("Your changes are not yet published", {
		id: "editor-dirty",
		duration: Infinity,
		position: "bottom-center",
		action: {
			label: "Publish",
			onClick: () => Config().publishToContract(),
		},
	});
};

const syncItem = (
	obj: AnyObject,
	{ verbose = false, sync = false }: { verbose?: boolean; sync?: boolean } = {},
) => {
	console.warn(obj, "trave");
	try {
		if (obj === undefined) return;
		// @dev: Ignore things we aren't storing in the datapool, this needs to be expanded
		if ("Dict" in obj) {
			return;
		}
		let name = "";
		// @dev: add Entity models to entities
		if ("Entity" in (obj as { Entity: Entity })) {
			addEntity(obj.Entity as Entity);
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
		console.log(obj);
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
	if (get().selectedEntity !== undefined) {
		syncItem(getEntity(get().selectedEntity!));
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
	selectEntity(newEntity.inst);
	return newEntity;
};

const logPool = () => {
	const poolArray = get().dataPool.values().toArray();
	console.info("Pool");
	console.table(poolArray);
	console.info("DeleteQueue", get().deletedQueue);
	console.info("Entities", get().entities);
	console.info("Selected", get().selectedEntity);
	console.info("Edited", get().editedEntity);
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
	updateSelectedEntity,
	removeComponent,
	deleteItem,
	logPool,
	TEMP_CONSTANT_WORLD_ENTRY_ID,
});

export default EditorData;
export { useEditorData };
