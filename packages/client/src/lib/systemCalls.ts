import { LORE_CONFIG } from "@lib/config";
import { BigNumberish, CairoOption, CairoOptionVariant, CallData, type RawArgsArray, Call, Account, byteArray } from "starknet";
import { toCairoArray } from "@/editor/editor.utils";
import { sendCommand } from "./terminalCommands/commandHandler";
import { addTerminalContent } from "@lib/stores/terminal.store";
import { DojoCall } from "@dojoengine/core";
import WalletStore from "./stores/wallet.store";
import type { ApprovedProposal } from "@lib/dojo_bindings/typescript/models.gen";

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

	const account = WalletStore().account as Account;
	let calls: Call[] = [];

	try {
		// Option 1: call contract through world
		// const { prompt } = LORE_CONFIG.world;
		// const response = await prompt.prompt(
		// 	account,
		// 	command,
		// 	game_id == null ? new CairoOption(CairoOptionVariant.None) : new CairoOption(CairoOptionVariant.Some, game_id)
		// );

		// Option 2: call contract from provider
		// const { provider } = LORE_CONFIG;
		// //@ts-ignore
		// const response = await provider.prompt(
		// 	account, [
		// 	command,
		// 	game_id == null ? new CairoOption(CairoOptionVariant.None) : new CairoOption(CairoOptionVariant.Some, game_id)
		// 	]
		// );

		// Option 3: call contract directly
		const calldata = CallData.compile([
			byteArray.byteArrayFromString(command),
			game_id == null ? new CairoOption(CairoOptionVariant.None) : new CairoOption(CairoOptionVariant.Some, game_id)
		]);
		calls.push({
			contractAddress: LORE_CONFIG.contractAddresses.prompt,
			entrypoint: "prompt",
			calldata,
		});

		// make the call
		console.log(`👉 execCommand(${game_id}) [${command}]`, calls);
		const response = await account.execute(calls, {
			tip: 0,
		});
		// wait for transaction async
		if (response) {
			await account.waitForTransaction(response.transaction_hash, { retryInterval: 200 }).then((receipt) => {
				validateReceiptStatus(receipt, calls); // just log!
			});
		}
	} catch (error) {
		console.error(`❌ PROMPT ERROR: execCommand(${game_id}) [${command}]:`, calls, error as Error);
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
	| "delete_child"
	| "submit_for_review"
	| "approve_proposal"
	| "reject_proposal";

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

	const account = WalletStore().account as Account;
	const calls: Call[] = [];

	try {
		// prepare the call
		// based on contracts.gen.ts
		const data = toCairoArray(args).flat() as RawArgsArray;
		const calldata = CallData.compile(data);
		calls.push({
			contractAddress: LORE_CONFIG.contractAddresses.designer,
			entrypoint,
			calldata,
		});
		// make the call
		const response = await account.execute(calls, {
			tip: 0,
		});
		// wait for transaction async
		if (response) {
			await account.waitForTransaction(response.transaction_hash, { retryInterval: 200 }).then((receipt) => {
				validateReceiptStatus(receipt, calls); // just log!
			});
			// we do a manual wait because the waitForTransaction is super slow
			// await new Promise((r) => setTimeout(r, 500));
		}
	} catch (error) {
		console.error(`❌ DESIGNER ERROR: execDesignerCall() [${entrypoint}]:`, args, calls, error as Error);
		throw new Error((error as Error).message);
	}
}

function validateReceiptStatus(receipt: any, calls?: (Call | DojoCall)[]): boolean {
	if (receipt.execution_status == 'SUCCEEDED') {
		console.log(`👍 Transaction successful:`, calls);
		return true;
	}
	const msg = receipt.execution_status === 'REVERTED'
		? `Transaction reverted: ${receipt.revert_reason}`
		: `Transaction error: ${receipt.execution_status}`;
	console.error(`⚠️ ${msg}:`, calls, receipt);
	throw new Error(msg);
}


async function approveProposal(proposal: ApprovedProposal): Promise<void> {
	if (!WalletStore().isConnected) return;
	const caller = WalletStore().account as Account;
	const calldata = CallData.compile([
		proposal.trail_id,
		proposal.proposer,
		proposal.w_single_keys,
		proposal.w_description_texts,
		proposal.w_multi_keys,
		proposal.d_single_keys,
		proposal.d_description_texts,
		proposal.d_multi_keys,
	]);
	const calls: Call[] = [{
		contractAddress: LORE_CONFIG.contractAddresses.designer,
		entrypoint: "approve_proposal",
		calldata,
	}];
	try {
		const response = await caller.execute(calls, { tip: 0 });
		if (response) {
			await caller.waitForTransaction(response.transaction_hash, { retryInterval: 200 }).then((receipt) => {
				validateReceiptStatus(receipt, calls);
			});
		}
	} catch (error) {
		console.error("❌ DESIGNER ERROR: approveProposal():", calls, error as Error);
		throw new Error((error as Error).message);
	}
}

async function rejectProposal(trailId: bigint, proposer: string): Promise<void> {
	if (!WalletStore().isConnected) return;
	const caller = WalletStore().account as Account;
	const calldata = CallData.compile([trailId, proposer]);
	const calls: Call[] = [{
		contractAddress: LORE_CONFIG.contractAddresses.designer,
		entrypoint: "reject_proposal",
		calldata,
	}];
	try {
		const response = await caller.execute(calls, { tip: 0 });
		if (response) {
			await caller.waitForTransaction(response.transaction_hash, { retryInterval: 200 }).then((receipt) => {
				validateReceiptStatus(receipt, calls);
			});
		}
	} catch (error) {
		console.error("❌ DESIGNER ERROR: rejectProposal():", calls, error as Error);
		throw new Error((error as Error).message);
	}
}

async function grantAccessToTrail(trailId: bigint, account: string, granting: boolean): Promise<void> {
	if (!WalletStore().isConnected) return;
	const caller = WalletStore().account as Account;
	const calldata = CallData.compile([account, trailId, granting]);
	const calls: Call[] = [{
		contractAddress: LORE_CONFIG.contractAddresses.designer,
		entrypoint: "grant_access_to_trail",
		calldata,
	}];
	try {
		const response = await caller.execute(calls, { tip: 0 });
		if (response) {
			await caller.waitForTransaction(response.transaction_hash, { retryInterval: 200 }).then((receipt) => {
				validateReceiptStatus(receipt, calls);
			});
		}
	} catch (error) {
		console.error("❌ DESIGNER ERROR: grantAccessToTrail():", calls, error as Error);
		throw new Error((error as Error).message);
	}
}

/**
 * SystemCalls object that exports all the functions for external use.
 *
 * @namespace
 * @property {Function} execDesignerCall - Function to send calls to the designer contract
 * @property {Function} execCommand - Function to send commands to the entity contract
 * @property {Function} grantAccessToTrail - Function to grant/revoke trail collaboration access
 */
export const SystemCalls = {
	execDesignerCall,
	execCommand,
	grantAccessToTrail,
	approveProposal,
	rejectProposal,
};
