import { toast } from "sonner";
import { byteArray, num } from "starknet";
import {
	type Area,
	directionActionsMap,
	type ChildToParent,
	direction,
	type Entity,
	type Exit,
	exitActions,
	type Inspectable,
	inspectableActions,
	type ParentToChildren,
} from "@/lib/dojo_bindings/typescript/models.gen";
import { tick } from "@/lib/utils/utils";
import { type DesignerCall, SystemCalls } from "../lib/systemCalls";
import EditorData from "./data/editor.data";
import { Notifications } from "./lib/notifications";
import { toEnumIndex } from "./lib/schemas";
import type { EntityCollection } from "./lib/types";
import type { ChangeSet } from "./lib/types";

/**
 * Publishes a game configuration to the contract
 * @param config The game configuration to publish
 * @returns A promise that resolves when the publishing is complete
 */
export const publishConfigToContract = async (changes?: ChangeSet[]) => {
	// Then process each room in the config
	// Create entity

	try {
		await Notifications().startPublishing();
		await publishChangeset(changes);
		Notifications().finalizePublishing();
		await tick();
		console.log(EditorData().dataPool);
		return true;
	} catch (error) {
		const errorMsg = error instanceof Error ? error.message : String(error);
		Notifications().showError(`Error publishing to contract: ${errorMsg}`);
		return false;
	}
};

const publishChangeset = async (changes?: ChangeSet[]) => {
	const preparedChanges = changes || EditorData().changeSet;
	for (const change of preparedChanges) {
		try {
			if (change.type === "update") {
				await publishEntityCollection(change.object as EntityCollection);
			}
			if (change.type === "delete") {
				await deleteCollection(change.object as EntityCollection);
			}
		} catch (error) {
			console.error("Error creating room:", error);
			toast.error(
				`Error creating ${Object.keys(change.object).join(",")}: ${error instanceof Error ? error.message : String(error)}`,
				{ richColors: true, duration: 4000, dismissible: true },
			);
		} finally {
			EditorData().set({
				changeSet: EditorData().changeSet.filter((x) => x !== change),
			});
			console.log(EditorData().changeSet);
			if (EditorData().changeSet.length > 0) {
				Notifications().needsToPublish();
			} else {
				toast.dismiss("editor-dirty");
			}
		}
	}
};

const publishEntityCollection = async (collection: EntityCollection) => {
	if ("Entity" in collection && collection.Entity !== undefined) {
		await publishEntity(collection.Entity);
	}
	if ("Inspectable" in collection && collection.Inspectable !== undefined) {
		await publishInspectable(collection.Inspectable);
	}
	if ("Area" in collection && collection.Area !== undefined) {
		await publishArea(collection.Area);
	}
	if ("Exit" in collection && collection.Exit !== undefined) {
		await publishExit(collection.Exit);
	}
	if ("ChildToParent" in collection && collection.ChildToParent !== undefined) {
		await publishChildToParent(collection.ChildToParent);
	}
	if (
		"ParentToChildren" in collection &&
		collection.ParentToChildren !== undefined
	) {
		await publishParentToChildren(collection.ParentToChildren);
	}
};

const publishEntity = async (entity: Entity) => {
	const entityData = [
		num.toBigInt(entity.inst.toString()),
		entity.is_entity,
		byteArray.byteArrayFromString(entity.name),
		entity.alt_names.length > 0
			? entity.alt_names
					.filter((x) => x.length > 0)
					.map((x) => byteArray.byteArrayFromString(x))
			: 0,
	];
	await dispatchDesignerCall("create_entity", [entityData]);
};

const publishInspectable = async (inspectable: Inspectable) => {
	const inspectableData = [
		num.toBigInt(inspectable.inst.toString()),
		inspectable.is_inspectable,
		inspectable.is_visible,
		inspectable.description.length > 0
			? inspectable.description
					.filter((x) => x.length > 0)
					.map((x) => byteArray.byteArrayFromString(x))
			: 0,
		inspectable.action_map.length > 0
			? inspectable.action_map.map((x) => [
					byteArray.byteArrayFromString(x.action),
					0,
					toEnumIndex(x.action_fn, inspectableActions),
				])
			: 0,
	];
	await dispatchDesignerCall("create_inspectable", [inspectableData]);
};

const publishArea = async (area: Area) => {
	const areaData = [
		num.toBigInt(area.inst.toString()),
		area.is_area,
		area.is_enterable,
		toEnumIndex(area.direction, direction),
		num.toBigInt(area.leads_to.toString()),
		area.action_map.length > 0
			? area.action_map.map((x) => [
					byteArray.byteArrayFromString(x.action),
					0,
					toEnumIndex(x.action_fn, directionActionsMap),
				])
			: 0,
	];
	await dispatchDesignerCall("create_area", [areaData]);
};

const publishExit = async (exit: Exit) => {
	const exitData = [
		num.toBigInt(exit.inst.toString()),
		exit.is_exit,
		exit.is_enterable,
		num.toBigInt(exit.leads_to.toString()),
		toEnumIndex(exit.direction_type, direction),
		exit.action_map.length > 0
			? exit.action_map.map((x) => [
					byteArray.byteArrayFromString(x.action),
					0,
					toEnumIndex(x.action_fn, exitActions),
				])
			: 0,
	];
	await dispatchDesignerCall("create_exit", [exitData]);
};

const publishChildToParent = async (childToParent: ChildToParent) => {
	const childToParentData = [
		num.toBigInt(childToParent.inst.toString()),
		childToParent.is_child,
		num.toBigInt(childToParent.parent),
	];
	await dispatchDesignerCall("create_child", [childToParentData]);
};

const publishParentToChildren = async (parentToChildren: ParentToChildren) => {
	const parentToChildrenData = [
		num.toBigInt(parentToChildren.inst.toString()),
		parentToChildren.is_parent,
		parentToChildren.children.length > 0
			? parentToChildren.children.map((x) => num.toBigInt(x))
			: 0,
	];
	await dispatchDesignerCall("create_parent", [parentToChildrenData]);
};

const deleteCollection = async (model: EntityCollection) => {
	if ("Entity" in model && model.Entity !== undefined) {
		await dispatchDesignerCall("delete_entity", [
			num.toBigInt(model.Entity!.inst),
		]);
	}
	if ("Inspectable" in model && model.Inspectable !== undefined) {
		await dispatchDesignerCall("delete_inspectable", [
			num.toBigInt(model.Inspectable!.inst),
		]);
	}
	if ("Area" in model && model.Area !== undefined) {
		await dispatchDesignerCall("delete_area", [num.toBigInt(model.Area!.inst)]);
	}
	if ("Exit" in model && model.Exit !== undefined) {
		await dispatchDesignerCall("delete_exit", [num.toBigInt(model.Exit!.inst)]);
	}
	if ("ChildToParent" in model && model.ChildToParent !== undefined) {
		await dispatchDesignerCall("delete_child", [
			num.toBigInt(model.ChildToParent!.inst),
		]);
	}
	if ("ParentToChildren" in model && model.ParentToChildren !== undefined) {
		await dispatchDesignerCall("delete_parent", [
			num.toBigInt(model.ParentToChildren!.inst),
		]);
	}
	if ("Player" in model) {
	}
};

/**
 * Helper function to send designer call
 * @param call The designer call type
 * @param args The arguments for the call
 * @returns The response from the API
 */
export const dispatchDesignerCall = async (
	call: DesignerCall,
	args: unknown[],
) => {
	try {
		const response = await SystemCalls.execDesignerCall({ call, args });
		Notifications().addPublishingLog(
			new CustomEvent("designerCall", { detail: { call, args } }),
		);
		return response.json();
	} catch (error) {
		Notifications().addPublishingLog(
			new CustomEvent("error", {
				detail: { error: { message: (error as Error).message }, call, args },
			}),
		);
		if ((error as Error).message.includes("too many")) {
			console.error(
				"Torii && Katana might need a reset when it says too many connections",
			);
		}
		throw new Error(
			`Error sending designer call: ${(error as Error).message}, ${call}, ${args}`,
		);
	}
};
