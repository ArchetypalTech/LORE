import { useQuery } from "@tanstack/react-query";
import { uint256 } from "starknet";
import { bigintToAddress } from "@/lib/utils";
import { PROFILE } from "@/dojo/dojoConfig";
import { useAppchainProvider } from "@/hooks/use-appchain";

const ACTIONS_TOKEN_ADDRESS =
	PROFILE.contractAddresses.appchain.actions_token;

export function useActionsBalance(address: string | undefined) {
	const provider = useAppchainProvider();

	const result = useQuery({
		queryKey: ["actions-balance", bigintToAddress(address)],
		enabled: !!address,
		refetchInterval: 5000,
		queryFn: async (): Promise<number> => {
			const result = await provider.callContract({
				contractAddress: ACTIONS_TOKEN_ADDRESS,
				entrypoint: "balance_of",
				calldata: [address as string],
			});
			// balance_of returns a u256 (low, high) → combine into a bigint.
			const balance = uint256.uint256ToBN({
				low: result[0],
				high: result[1],
			});
			return Number(balance / (10n ** 18n));
		},
	});

  return {
    ...result,
    actionsBalance: result.data,
  }
}
