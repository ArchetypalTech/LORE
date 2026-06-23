import { useAccount } from "@starknet-react/core";
import { useMutation } from "@tanstack/react-query";
import { CallData } from "starknet";
import { PROFILE } from "@/dojo/dojoConfig";

const PERMIT_TOKEN_ADDRESS =
	PROFILE.contractAddresses.starknet.permit_token;

/**
 * Mutation that calls `consume_message` on the permit_token contract with an
 * appchain message's raw `Array<felt252>` payload, sending the transaction with
 * the connected Controller account (starknet.js) and awaiting its receipt.
 *
 * The L2 messaging contract reverts if the message isn't registered as
 * consumable, so a resolved mutation means the message was consumed on-chain.
 */
export function useConsumeEvent() {
	const { account } = useAccount();

	return useMutation({
		mutationFn: async (payload: string[]): Promise<string> => {
			if (!account) throw new Error("No connected account");
			// consume_message takes a Span<felt252>; pass the event payload as-is.
			console.log(`Consume payload:`, payload)
			const { transaction_hash } = await account.execute([
				{
					contractAddress: PERMIT_TOKEN_ADDRESS,
					entrypoint: "consume_message",
					calldata: CallData.compile({ payload }),
				},
			], {
				tip: 0,
			});
			await account.waitForTransaction(transaction_hash);
			return transaction_hash;
		},
	});
}
