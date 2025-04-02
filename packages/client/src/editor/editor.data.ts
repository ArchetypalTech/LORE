import { StoreBuilder } from "@/lib/utils/storebuilder";
import { createRandomName, generateNumericUniqueId } from "./editor.utils";
import { decodeDojoText } from "@/lib/utils/utils";
import { publishRoom, publishObject, dispatchDesignerCall } from "./publisher";
import type {
	Entity,
	Player,
	Inspectable,
	Area,
	Exit,
	InventoryItem,
	Container,
	Dict,
	ParentToChildren,
	ChildToParent,
	SchemaType,
} from "@/lib/dojo_bindings/typescript/models.gen";

export type AnyObject = { Entity: Entity } & Partial<SchemaType["lore"]>;

const TEMP_CONSTANT_WORLD_ENTRY_ID = parseInt("0x1c0a42f26b594c").toString();

const {
	get,
	set,
	createFactory,
	useStore: useEditorData,
} = StoreBuilder({
	dataPool: new Map<string, AnyObject>(),
	entities: [] as Entity[],
	parents: [] as ParentToChildren[],
	selectedEntity: undefined as AnyObject | undefined,
	isDirty: Date.now(),
});

const getEntities = () =>
	get()
		.entities.map((x) => get().dataPool.get(x.inst.toString())!)
		.sort((x) => parseInt(x.Entity.inst.toString()));

const getEntity = (id: string) => get().dataPool.get(id);

const setItem = (obj: AnyObject, id: string) => {
	set((prev) => ({
		...prev,
		dataPool: new Map<string, AnyObject>(get().dataPool).set(id, obj),
	}));
};

const addEntity = (entity: Entity) => {
	set((prev) => ({
		...prev,
		entities: [...prev.entities.filter((e) => e.inst !== entity.inst), entity],
	}));
};

const removeEntity = (entity: Entity) => {
	set((prev) => ({
		...prev,
		entities: prev.entities.filter((e) => e.inst !== entity.inst),
	}));
};

const clearItem = (id: string) => {
	const newDataPool = new Map<string, AnyObject>(get().dataPool);
	newDataPool.delete(id);
	set((prev) => ({
		...prev,
		dataPool: newDataPool,
	}));
};

const getItem = (id: string) => get().dataPool.get(id);

const syncItem = (obj: AnyObject) => {
	if (obj === undefined) return;
	if ("Dict" in obj || "PlayerStory" in obj) {
		return;
	}
	if ("Entity" in (obj as { Entity: Entity })) {
		addEntity(obj.Entity);
	}
	if ("Player" in (obj as { Player: Player })) {
		// const player = { ...(obj as { Player: Player }) };
	}
	setItem(obj, obj.Entity.inst.toString());
	setTimeout(() => {
		set({
			isDirty: Date.now(),
		});
	}, 1);
	console.log(
		`[Editor] Sync: ${
			// biome-ignore lint/suspicious/noExplicitAny: <force extract type from keys>
			Object.keys(obj as any)
		}`,
		obj,
		get(),
	);
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

const selectEntity = (id: string) => {
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
	selectEntity,
	deleteItem,
	logPool,
	TEMP_CONSTANT_WORLD_ENTRY_ID,
});

export default EditorData;
export { useEditorData };
