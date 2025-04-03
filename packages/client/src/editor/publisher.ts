import { SystemCalls, type DesignerCall } from "../lib/systemCalls";
import { actions } from "./editor.store";
import EditorData, { type EntityCollection } from "./editor.data";

/**
 * Publishes a game configuration to the contract
 * @param config The game configuration to publish
 * @returns A promise that resolves when the publishing is complete
 */
export const publishConfigToContract = async (): Promise<void> => {
	// Then process each room in the config
	for (const entity of EditorData().getEntities()) {
		// Create entity
		console.log("Creating entity:", entity);
		try {
			await publishEntity(entity);
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

export const publishEntity = async (_entity: EntityCollection) => {
	// const txtDef = EditorData().getItem(room.txtDefId) as T_TextDefinition;
	// await processTxtDef(txtDef);
	// const roomData = [
	// 	parseInt(room.roomId),
	// 	roomTypeToIndex(room.roomType), // Map to index
	// 	biomeTypeToIndex(room.biomeType), // Map to index
	// 	// Use text definition ID from the roomDescription object if available
	// 	parseInt(room.txtDefId),
	// 	room.shortTxt,
	// 	room.object_ids.map((id: string) => parseInt(id)) || 0,
	// 	0,
	// ];
	// await dispatchDesignerCall("create_rooms", [roomData]);
	// await processRoomObjects(room);
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
