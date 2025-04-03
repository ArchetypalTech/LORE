import { SystemCalls, type DesignerCall } from "../lib/systemCalls";
import { actions } from "./editor.store";
import EditorData, { type EntityCollection } from "./editor.data";
import type {
	Area,
	Entity,
	Inspectable,
} from "@/lib/dojo_bindings/typescript/models.gen";
import { string } from "zod";

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
		await publishInspectable(collection.Inspectable);
	}
	if ("Area" in collection) {
		await publishArea(collection.Area);
	}
};

const publishEntity = async (entity: Entity) => {
	const entityData: Array<Entity> = [Object.values(entity)];
	await dispatchDesignerCall("create_entity", entityData);
};

const publishInspectable = async (inspectable: Inspectable) => {
	const inspectableData: Array<Inspectable> = [Object.values(inspectable)];
	await dispatchDesignerCall("create_inspectable", inspectableData);
};

const publishArea = async (area: Area) => {
	const areaData: Area = [
		area.inst,
		area.direction === typeof string ? area.direction : 0,
		area.is_area,
	];
	await dispatchDesignerCall("create_area", [areaData]);
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
		actions.notifications.addPublishingLog(
			new CustomEvent("designerCall", { detail: { call, args } }),
		);
		return response.json();
	} catch (error) {
		actions.notifications.addPublishingLog(
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
