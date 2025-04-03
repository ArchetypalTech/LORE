import { StoreBuilder } from "@/lib/utils/storebuilder";
import { createRandomName, generateNumericUniqueId } from "./editor.utils";
import type {
	Entity,
	ParentToChildren,
	SchemaType,
} from "@/lib/dojo_bindings/typescript/models.gen";
import type { BigNumberish } from "starknet";

export type AnyObject = Partial<SchemaType["lore"]>;
export type EntityCollection = { Entity: Entity } & Partial<SchemaType["lore"]>;
export type ModelCollection = {
	[K in keyof AnyObject]?: Partial<AnyObject>;
};

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
	const isSelected = get().selectedEntity?.Entity.inst === id;
	if (isSelected) {
		set({ selectedEntity: undefined });
	}
	set((prev) => ({
		...prev,
		entities: prev.entities.filter((e) => e.inst !== entity.inst),
	}));
	const newDataPool = new Map<string, AnyObject>(get().dataPool);
	newDataPool.delete(id);
	set((prev) => ({
		...prev,
		dataPool: newDataPool,
	}));
};

const getItem = (id: BigNumberish) => get().dataPool.get(id);

const syncItem = (obj: AnyObject) => {
	try {
		if (obj === undefined) return;
		// @dev: Ignore things we aren't storing in the datapool, this needs to be expanded
		if ("Dict" in obj) {
			return;
		}
		let name = "";

		// @dev: retrieve instance value
		const findInstValue = (obj: AnyObject): BigNumberish | undefined => {
			for (const key of Object.keys(obj)) {
				if (key.startsWith("inst")) {
					return obj["inst" as keyof typeof obj] as string;
				}
				if (typeof obj[key as keyof typeof obj] === "object") {
					const res = findInstValue(obj[key as keyof typeof obj]);
					if (res !== undefined) return res;
				}
			}
			return undefined;
		};

		const inst = findInstValue(obj);

		// merge items into datapool (or new if don't exist)
		if (inst !== undefined) {
			const existing = get().dataPool.get(inst) || {};
			if (existing === undefined) {
				console.error("Existing object not found:", inst, obj);
				return;
			}
			Object.assign(existing, obj);
			setItem({ ...existing } as AnyObject, inst);
		}

		// add Entity models to entities
		if ("Entity" in (obj as { Entity: Entity })) {
			addEntity(obj.Entity as Entity);
			name = obj.Entity!.name;
		}

		setTimeout(() => {
			set({
				isDirty: Date.now(),
			});
		}, 1);

		console.log(
			`[Editor] Sync${name ? `: ${name}` : ""}: ${
				// biome-ignore lint/suspicious/noExplicitAny: <force extract type from keys>
				Object.keys(obj as any)
			}`,
			obj,
			get(),
		);

		if ("ParentToChildren" in obj || "ChildToParent" in obj) {
			// we might have a re-parenting so we force update the hierarchy
			set({ entities: [...get().entities] });
		}
	} catch (e) {
		console.error("data-sync error:", e, "object: ", obj);
	}
};

const deleteItem = async (id: string) => {
	// if (get().rooms[id] !== undefined) {
	// 	const room = get().rooms[id] as T_Room;
	// 	console.log("TEST Deleting room", room);
	// 	await deleteItem(room.txtDefId);
	// 	for (const objId of room.object_ids) {
	// 		await deleteItem(objId);
	// 	}
	// 	await deleteRoom(room.roomId);
	// }
	// if (get().objects[id] !== undefined) {
	// 	const object = get().objects[id] as T_Object;
	// 	console.log("TEST Deleting object", object);
	// 	await deleteItem(object.txtDefId);
	// 	for (const actionId of object.objectActionIds) {
	// 		await deleteItem(actionId);
	// 	}
	// 	await removeObjectFromRoom(object);
	// 	await deleteObject(object.objectId);
	// }
	// if (get().actions[id] !== undefined) {
	// 	const action = get().actions[id] as T_Action;
	// 	await removeActionFromObject(action);
	// 	await deleteAction(action.actionId);
	// 	console.log("TEST Deleting action", action);
	// }
	// if (get().txtDefs[id] !== undefined) {
	// 	const txtDef = get().txtDefs[id] as T_TextDefinition;
	// 	await deleteTxt(txtDef.id);
	// 	console.log("TEST Deleting txtDef", txtDef);
	// }
};

const selectEntity = (id: BigNumberish) => {
	set({ selectedEntity: get().dataPool.get(id) });
};

const newEntity = (entity: Entity) => {
	const inst = generateNumericUniqueId();
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
