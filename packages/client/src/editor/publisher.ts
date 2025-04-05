import { SystemCalls, type DesignerCall } from "../lib/systemCalls";
import EditorData from "./data/editor.data";
import type { EntityCollection } from "./lib/schemas";
import type {
	Area,
	Entity,
	Exit,
	Inspectable,
} from "@/lib/dojo_bindings/typescript/models.gen";
import { directionToIndex, inspectableActionsToIndex } from "./lib/schemas";
import { byteArray, num } from "starknet";
import { Notifications } from "./lib/notifications";

/**
 * Publishes a game configuration to the contract
 * @param config The game configuration to publish
 * @returns A promise that resolves when the publishing is complete
 */
export const publishConfigToContract = async (): Promise<void> => {
	// Then process each room in the config
	for (const collection of EditorData().getEntities()) {
		// Create entity
		console.log("Creating entityCollection:", collection);
		try {
			await publishEntityCollection(collection);
		} catch (error) {
			console.error("Error creating room:", error);
			throw new Error(
				`Error creating room: ${error instanceof Error ? error.message : String(error)}`,
			);
		}
	}
};

// export const processTxtDef = async (txtDef: T_TextDefinition) => {
// 	if (txtDef.id === "0") {
// 		return;
// 	}
// 	const t = txtDef.text;
// 	actions.notifications.startPublishing();
// 	const txtData = [
// 		parseInt(txtDef.id), // ID for the text
// 		parseInt(txtDef.owner), // Owner ID
// 		t.length > 0 ? encodeURI(decodeDojoText(t)) : " ", // The actual text content
// 	];
// 	await dispatchDesignerCall("create_txts", [txtData]);
// };

export const publishEntityCollection = async (collection: EntityCollection) => {
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
					inspectableActionsToIndex(x.action_fn),
				])
			: 0,
	];
	await dispatchDesignerCall("create_inspectable", [inspectableData]);
};

const publishArea = async (area: Area) => {
	const areaData = [
		num.toBigInt(area.inst.toString()),
		area.is_area,
		directionToIndex(area.direction),
	];
	await dispatchDesignerCall("create_area", [areaData]);
};

const publishExit = async (exit: Exit) => {
	const exitData = [
		num.toBigInt(exit.inst.toString()),
		exit.is_exit,
		exit.is_enterable,
		num.toBigInt(exit.leads_to.toString()),
		directionToIndex(exit.direction_type),
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
