import { useEffect } from "react";
import { useAccount } from "@starknet-react/core";
import { useQueryClient } from "@tanstack/react-query";
import { usePermitTokens } from "@/context/tokens-provider";
import { usePermitTokenInfos } from "@/context/torii-starknet-provider";
import { bigintToAddress } from "@/lib/utils";
import { PermitListItem } from "@/components/permit-list-item";

export function PermitList() {
	const { isConnected, address } = useAccount();
	const tokenIds = usePermitTokens();
	const infos = usePermitTokenInfos(tokenIds);

	// reload when 
	const queryClient = useQueryClient();
	useEffect(() => {
		queryClient.invalidateQueries({ queryKey: ["permit-balance", bigintToAddress(address)] });
	}, [tokenIds.length])

	if (!isConnected) return null;
	if (tokenIds.length === 0)
		return <p className="m-0 text-sm opacity-70">No permits owned (Torii)</p>;

	return (
		<ul className="flex list-none flex-col items-center gap-1 p-0">
			Owned permits (Torii)
			{tokenIds.map((id) => (
				<PermitListItem
					key={id}
					tokenId={id}
					isUsed={!!infos.get(BigInt(id).toString())}
				/>
			))}
		</ul>
	);
}
