import { useProvider } from "@starknet-react/core";
import { useQuery } from "@tanstack/react-query";
import { uint256 } from "starknet";
import { selectedProfileConfig } from "@/dojo/dojoConfig";

const PERMIT_TOKEN_ADDRESS =
	selectedProfileConfig.contractAddresses.permit_token;

/**
 * Reads the permit_token `balanceOf` for the given address on the active
 * profile's L2 world. Returns the owned permit count as a number.
 */
export function usePermitCount(address: string | undefined) {
	const { provider } = useProvider();

	const result = useQuery({
		queryKey: ["permit-count", PERMIT_TOKEN_ADDRESS, address],
		enabled: !!address,
		queryFn: async (): Promise<number> => {
			const result = await provider.callContract({
				contractAddress: PERMIT_TOKEN_ADDRESS,
				entrypoint: "balanceOf",
				calldata: [address as string],
			});
			// balanceOf returns a u256 (low, high) → combine into a bigint.
			const balance = uint256.uint256ToBN({
				low: result[0],
				high: result[1],
			});
			return Number(balance);
		},
	});

  return {
    ...result,
    permitCount: result.data,
  }
}
