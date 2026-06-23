import { useEffect } from "react";
import { useAccount } from "@starknet-react/core";
import { useQueryClient } from "@tanstack/react-query";
import { usePermitTokens } from "@/context/tokens-provider";
import { usePermitTokenInfos } from "@/context/torii-starknet-provider";
import { useUsePermit } from "@/hooks/use-use-permit";
import { bigintToAddress } from "@/lib/utils";

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

function PermitListItem({
	tokenId,
	isUsed,
}: {
	tokenId: string;
	isUsed: boolean;
}) {
	const { mutate, isPending, isSuccess } = useUsePermit();
	const id = BigInt(tokenId).toString();

	let status: React.ReactNode;
	if (isPending) {
		status = <span className="text-sm opacity-70">Using...</span>;
	} else if (isUsed || isSuccess) {
		status = <span className="text-sm opacity-70">Used</span>;
	} else {
		status = (
			<button
				type="button"
				onClick={() => mutate(tokenId)}
				className="bg-transparent px-2 py-1 text-accent text-sm underline"
			>
				Use
			</button>
		);
	}

	return (
		<li className="m-0 flex flex-row items-center gap-2">
			<span>Permit #{id}</span>
			{status}
		</li>
	);
}
