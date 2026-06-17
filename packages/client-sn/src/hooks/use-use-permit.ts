import { useAccount } from "@starknet-react/core";
import { useMutation } from "@tanstack/react-query";
import { CallData } from "starknet";
import { PROFILE } from "@/dojo/dojoConfig";

const PERMIT_TOKEN_ADDRESS =
	PROFILE.contractAddresses.starknet.permit_token;

/**
 * Mutation that calls `use_permits` on the permit_token contract for a single
 * token id, sending the transaction with the connected account (starknet.js)
 * and awaiting its receipt. On success the `PermitTokenInfo.is_used` model flips
 * to true, which the entity subscription picks up — no manual cache work needed.
 */
export function useUsePermit() {
	const { account } = useAccount();

	return useMutation({
		mutationFn: async (tokenId: string): Promise<string> => {
			if (!account) throw new Error("No connected account");
			// use_permits takes a Span<u128>; send the single id.
			const { transaction_hash } = await account.execute([
				{
					contractAddress: PERMIT_TOKEN_ADDRESS,
					entrypoint: "use_permits",
					calldata: CallData.compile({ token_ids: [tokenId] }),
				},
			]);
			await account.waitForTransaction(transaction_hash);
			return transaction_hash;
		},
	});
}
