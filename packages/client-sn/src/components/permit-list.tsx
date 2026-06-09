import { useAccount } from "@starknet-react/core";
import { usePermitTokenInfos } from "@/hooks/use-permit-token-infos";
import { usePermitTokens } from "@/hooks/use-permit-tokens";

export function PermitList() {
	const { isConnected } = useAccount();
	const tokenIds = usePermitTokens();
	const infos = usePermitTokenInfos(tokenIds);

	if (!isConnected) return null;
	if (tokenIds.length === 0)
		return <p className="m-0 text-sm opacity-70">No permits owned</p>;

	return (
		<ul className="flex list-none flex-col items-center gap-1 p-0">
			{tokenIds.map((id) => {
				const isUsed = infos.get(BigInt(id).toString());
				return (
					<li key={id} className="m-0 flex flex-row items-center gap-2">
						<span>Permit #{BigInt(id).toString()}</span>
						<span className="text-sm opacity-70">
							{isUsed ? "Used" : "Not used"}
						</span>
					</li>
				);
			})}
		</ul>
	);
}
