import { LORE_CONFIG } from "@lib/config";
import JSONbig from "json-bigint";
import { BigNumberish, byteArray, CairoOption, CairoOptionVariant, CallData, InvokeFunctionResponse, type RawArgsArray, Call, Account } from "starknet";
import { toCairoArray } from "@/editor/editor.utils";
import WalletStore from "./stores/wallet.store";
import { sendCommand } from "./terminalCommands/commandHandler";
import { addAddressPadding } from "starknet";
import { addTerminalContent } from "@lib/stores/terminal.store";
import { DojoCall } from "@dojoengine/core";

/**
 * Sends a command to the entity contract.
 * Clientside call for player commands.
 *
 * @param {string} command - The command to send
 * @returns {Promise<void>}
 */
async function execCommand(command: string, game_id?: BigNumberish | null | undefined): Promise<void> {
	if (!WalletStore().isConnected) {
		sendCommand("_not_yet_connected");
		return;
	}

	const { prompt } = LORE_CONFIG.world;
	try {
		const account = WalletStore().account as Account;
		const response = await prompt.prompt(
			account,
			command,
			game_id == null ? new CairoOption(CairoOptionVariant.None) : new CairoOption(CairoOptionVariant.Some, game_id)
		);
		// wait for transaction async
		if (response) {
			await account.waitForTransaction(response.transaction_hash, { retryInterval: 200 }).then((receipt) => {
				validateReceiptStatus(receipt); // just log!
			});
		}
	} catch (error) {
		console.error("Error sending command:", game_id, error as Error);
		// case there is a TX error, add empty line to allow continue playing
		addTerminalContent({
					text: "",
					format: "hash",
					useTypewriter: true,
				});
	}
}

export type DesignerEntrypoints =
	| "register_property_registry"
	| "create_player"
	| "create_entity"
	| "create_reactable"
	| "create_description_text"
	| "create_area"
	| "create_hub"
	| "create_trail"
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
	| "delete_hub"
	| "delete_trail"
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
	entrypoint: DesignerEntrypoints;
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
	const { entrypoint, args } = props;
	if (!WalletStore().isConnected) {
		sendCommand("_not_yet_connected");
		return;
	}

	try {
		// prepare the call
		// based on contracts.gen.ts
		const data = toCairoArray(args).flat() as RawArgsArray;
		const calldata = CallData.compile(data);
		const call: Call = {
			contractAddress: addAddressPadding(LORE_CONFIG.manifests.designer.address),
			entrypoint,
			calldata,
		};
		// console.log("DEBUG: CALLLDATA:", entrypoint, args, data, calldata, call);

		// make the call
		const account = WalletStore().account as Account;
		const response = await account.execute([call], {
			tip: 0,
		});
		// wait for transaction async
		if (response) {
			await account.waitForTransaction(response.transaction_hash, { retryInterval: 200 }).then((receipt) => {
				validateReceiptStatus(receipt, [call]); // just log!
			});
			// we do a manual wait because the waitForTransaction is super slow
			// await new Promise((r) => setTimeout(r, 500));
		}
	} catch (error) {
		console.error("DESIGNER ERROR: execDesignerCall()", entrypoint, args);
		throw new Error((error as Error).message);
	}
}

function validateReceiptStatus(receipt: any, calls?: (Call | DojoCall)[]): boolean {
  if (receipt.execution_status != 'SUCCEEDED') {
    if (receipt.execution_status == 'REVERTED') {
      console.error(`Transaction reverted:`, receipt.revert_reason, calls)
    } else {
      console.error(`Transaction error [${receipt.execution_status}]:`, receipt, calls)
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
