import { SystemCalls, type DesignerCall } from "../lib/systemCalls";
import EditorData from "./data/editor.data";
import type { EntityCollection } from "./lib/schemas";
import {
	direction,
	inspectableActions,
	type Area,
	type Entity,
	type Exit,
	type Inspectable,
} from "@/lib/dojo_bindings/typescript/models.gen";
import { toEnumIndex } from "./lib/schemas";
import { byteArray, num } from "starknet";
import { Notifications } from "./lib/notifications";

/**
 * Publishes a game configuration to the contract
 * @param config The game configuration to publish
 * @returns A promise that resolves when the publishing is complete
 */
export const publishConfigToContract = async (): Promise<void> => {
	// Then process each room in the config
	// Create entity
	try {
		await publishChangeset();
	} catch (error) {
		console.error("Error creating room:", error);
		throw new Error(
			`Error creating room: ${error instanceof Error ? error.message : String(error)}`,
		);
	}
};

const publishChangeset = async () => {
	const changes = EditorData().changeSet;
	for (const change of changes) {
		if (change.type === "create") {
			await publishEntityCollection(change.object as EntityCollection);
		}
		if (change.type === "update") {
			await publishEntityCollection(change.object as EntityCollection);
		}
		if (change.type === "delete") {
			await deleteCollection(change.object as EntityCollection);
		}
	}
};

const publishEntityCollection = async (collection: EntityCollection) => {
	if ("Entity" in collection) {
		await publishEntity(collection.Entity);
	}
	if ("Inspectable" in collection) {
		await publishInspectable(collection.Inspectable!);
	}
	if ("Area" in collection) {
		await publishArea(collection.Area!);
	}
	if ("Exit" in collection) {
		await publishExit(collection.Exit!);
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
		toEnumIndex(area.direction, direction),
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
		// exit.action_map.length > 0
		// 	? exit.action_map.map((x) => [
		// 			byteArray.byteArrayFromString(x.action),
		// 			0,
		// 			inspectableActionsToIndex(x.action_fn),
		// 		])
		// 	: 0,
		0,
	];
	await dispatchDesignerCall("create_exit", [exitData]);
};

const deleteCollection = async (model: EntityCollection) => {
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
		console.error(
			`Error sending designer call: ${(error as Error).message}, ${call}, ${args}`,
		);
	}
};
