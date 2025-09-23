import { LORE_CONFIG } from "@lib/config";
import JSONbig from "json-bigint";
import { BigNumberish, byteArray, CairoOption, CairoOptionVariant, CallData, InvokeFunctionResponse, type RawArgsArray, Call } from "starknet";
import { toCairoArray } from "@/editor/editor.utils";
import WalletStore from "./stores/wallet.store";
import { sendCommand } from "./terminalCommands/commandHandler";

/**
 * Sends a command to the entity contract.
 * Clientside call for player commands.
 *
 * @param {string} command - The command to send
 * @returns {Promise<void>}
 */
async function execCommand(command: string, game_id?: BigNumberish | null | undefined): Promise<void> {
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
		const calldata = CallData.compile([
			byteArray.byteArrayFromString(command),
			game_id == null ? new CairoOption(CairoOptionVariant.None) : new CairoOption(CairoOptionVariant.Some, game_id)
		]);
		if (LORE_CONFIG.useController) {
			console.log("[CONTROLLER] execControllerCommand:", game_id, command, calldata);
			let calls: Call[] = [{
					contractAddress: LORE_CONFIG.contracts.entity.address,
					entrypoint: "prompt",
					calldata,
				}];
			const response: InvokeFunctionResponse | undefined = await WalletStore().controller?.account?.execute(calls);
			// wait for transaction async
			if (response) {
				WalletStore().controller?.account?.waitForTransaction(response.transaction_hash, { retryInterval: 200 }).then((receipt) => {
					validateReceiptStatus(receipt, calls); // just log!
				});
			}
		} else {
			console.log("[KATANA-DEV] execControllerCommand", command);
			await LORE_CONFIG.contracts.entity.invoke("prompt", [calldata]);
		}
		console.timeEnd("calltime");
	} catch (error) {
		console.error("Error sending command:", game_id, error as Error);
	}
}

export type DesignerCall =
	| "register_property_registry"
	| "create_player"
	| "create_entity"
	| "create_reactable"
	| "create_description_text"
	| "create_area"
	| "create_exit"
	| "create_inventory_item"
	| "create_container"
	| "create_trigger"
	| "create_condition"
	| "create_effect"
	| "create_action"
	| "create_parent"
	| "create_child"
	| "delete_player"
	| "delete_entity"
	| "delete_reactable"
	| "delete_description_text"
	| "delete_area"
	| "delete_exit"
	| "delete_inventory_item"
	| "delete_container"
	| "delete_trigger"
	| "delete_effect"
	| "delete_action"
	| "delete_condition"
	| "delete_parent"
	| "delete_child";

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

		let response: InvokeFunctionResponse | undefined;
		if (LORE_CONFIG.useController) {
			if (!WalletStore().isConnected) {
				throw new Error("Wallet not connected");
			}
			console.log("[CONTROLLER DESIGNERCALL]", call, args);
			let calls: Call[] = [{
					contractAddress: LORE_CONFIG.contracts.designer.address,
					entrypoint: call,
					calldata,
				}];
			response = await WalletStore().controller?.account?.execute(calls);
			// wait for transaction async
			if (response) {
				WalletStore().controller?.account?.waitForTransaction(response.transaction_hash, { retryInterval: 200 }).then((receipt) => {
					validateReceiptStatus(receipt, calls); // just log!
				});
			}
		} else {
			response = await LORE_CONFIG.contracts.designer.invoke(call, calldata);
		}

		// we do a manual wait because the waitForTransaction is super slow
		await new Promise((r) => setTimeout(r, 500));

		return new Response(JSONbig.stringify(response), {
			headers: {
				"Content-Type": "application/json",
			},
			status: 200,
		});
	} catch (error) {
		throw new Error(
			`[${(error as Error).message}] @ execDesignerCall[${call}](args): ${JSONbig.stringify(args)} `,
		);
	}
}

function validateReceiptStatus(receipt: any, calls: Call[]): boolean {
  if (receipt.execution_status != 'SUCCEEDED') {
    if (receipt.execution_status == 'REVERTED') {
      console.error(`Transaction reverted:`, calls, receipt.revert_reason)
    } else {
      console.error(`Transaction error [${receipt.execution_status}]:`, calls, receipt)
    }
    return false
  }
  return true
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
