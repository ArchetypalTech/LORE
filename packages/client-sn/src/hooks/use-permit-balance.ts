import { useProvider } from "@starknet-react/core";
import { useQuery } from "@tanstack/react-query";
import { uint256 } from "starknet";
import { bigintToAddress } from "@/lib/utils";
import { PROFILE } from "@/dojo/dojoConfig";

const PERMIT_TOKEN_ADDRESS =
	PROFILE.contractAddresses.starknet.permit_token;

export function usePermitBalance(address: string | undefined) {
	const { provider } = useProvider();

	const result = useQuery({
		queryKey: ["permit-balance", bigintToAddress(address)],
		enabled: !!address,
		queryFn: async (): Promise<number> => {
			const result = await provider.callContract({
				contractAddress: PERMIT_TOKEN_ADDRESS,
				entrypoint: "balance_of",
				calldata: [address as string],
			});
			// balance_of returns a u256 (low, high) → combine into a bigint.
			const balance = uint256.uint256ToBN({
				low: result[0],
				high: result[1],
			});
			return Number(balance);
		},
	});

  return {
    ...result,
    permitBalance: result.data,
  }
}
