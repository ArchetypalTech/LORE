import { CallData, byteArray, type RawArgsArray } from "starknet";
import { LORE_CONFIG } from "@lib/config";
import { toCairoArray } from "../editor/utils";
import WalletStore from "./stores/wallet.store";
import { sendCommand } from "./terminalCommands/commandHandler";

/**
 * Sends a command to the entity contract.
 * Clientside call for player commands.
 *
 * @param {string} command - The command to send
 * @returns {Promise<void>}
 */
async function execCommand(command: string): Promise<void> {
	// if using slot, send to controller
	if (LORE_CONFIG.useController) {
		if (!WalletStore().isConnected) {
			sendCommand("_not_yet_connected");
			return;
		}
	}

	try {
		const formData = new FormData();
		formData.append("command", command);
		formData.append("route", "sendMessage");
		console.time("calltime");
		console.log(command);
		const calldata = CallData.compile([byteArray.byteArrayFromString(command)]);
		if (LORE_CONFIG.useController) {
			console.log("[CONTROLLER] execControllerCommand", command);
			WalletStore().controller?.account?.execute([
				{
					contractAddress: LORE_CONFIG.contracts.entity.address,
					entrypoint: "prompt",
					calldata,
				},
			]);
		} else {
			console.log("[KATANA-DEV] execControllerCommand", command);
			await LORE_CONFIG.contracts.entity.invoke("prompt", [calldata]);
		}
		console.timeEnd("calltime");
	} catch (error) {
		console.error("Error sending command:", error as Error);
	}
}

/**
 * Formats a command message into calldata for contract invocation.
 * Splits the message into an array of commands and converts them to byte arrays.
 *
 * @param {string} message - The message to format
 * @returns {Promise<{calldata: RawArgsArray, cmds: string[]}>} The formatted calldata and command array
 */
async function formatCallData(message: string) {
	const cmds_raw = message.split(/\s+/);
	const cmds = cmds_raw.filter((word) => word !== "");
	const cmd_array = cmds.map((cmd) => byteArray.byteArrayFromString(cmd));
	// create message as readable contract data
	const calldata = CallData.compile([cmd_array, 23]);
	console.log("formatCallData(cmds): ", cmds, " -> calldata ->", calldata);
	return { calldata, cmds };
}

export type DesignerCall =
	| "create_entity"
	| "create_inspectable"
	| "create_area"
	| "create_exit"
	| "delete_entity"
	| "delete_inspectable"
	| "delete_area"
	| "delete_exit";

type DesignerCallProps = {
	call: DesignerCall;
	args: unknown[];
};

/**
 * Sends a call to the designer contract.
 * Handles different types of calls with appropriate data formatting.
 *
 * @param {string} props - JSON string containing the call and args properties
 * @returns {Promise<Response>} The response from the contract call
 * @throws {Error} If the contract call fails
 */
async function execDesignerCall(props: DesignerCallProps) {
	const { call, args } = props;
	try {
		// other calls follow the same format Array<Object> see Cairo Models

		const data = toCairoArray(args).flat() as RawArgsArray;
		const calldata = CallData.compile(data);

		let response: unknown;
		if (LORE_CONFIG.useController) {
			if (!WalletStore().isConnected) {
				throw new Error("Wallet not connected");
			}
			console.log("[CONTROLLER DESIGNERCALL]", call, args);
			response = await WalletStore().controller?.account?.execute([
				{
					contractAddress: LORE_CONFIG.contracts.designer.address,
					entrypoint: call,
					calldata,
				},
			]);
		} else {
			response = await LORE_CONFIG.contracts.designer.invoke(call, calldata);
		}
		// we do a manual wait because the waitForTransaction is super slow
		await new Promise((r) => setTimeout(r, 500));

		return new Response(JSON.stringify(response), {
			headers: {
				"Content-Type": "application/json",
			},
			status: 200,
		});
	} catch (error) {
		throw new Error(
			`[${(error as Error).message}] @ execDesignerCall[${call}](args): ${JSON.stringify(args)} `,
		);
	}
}

/**
 * SystemCalls object that exports all the functions for external use.
 *
 * @namespace
 * @property {Function} execDesignerCall - Function to send calls to the designer contract
 * @property {Function} execCommand - Function to send commands to the entity contract
 * @property {Function} execControllerCommand - Function to send commands through the controller
 */
export const SystemCalls = {
	execDesignerCall,
	execCommand,
};
