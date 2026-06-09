import { useAccount } from "@starknet-react/core";
import { usePermitTokens } from "@/hooks/use-permit-tokens";

export function PermitList() {
	const { isConnected } = useAccount();
	const tokenIds = usePermitTokens();

	if (!isConnected) return null;
	if (tokenIds.length === 0)
		return <p className="m-0 text-sm opacity-70">No permits owned</p>;

	return (
		<ul className="flex list-none flex-col items-center gap-1 p-0">
			{tokenIds.map((id) => (
				<li key={id} className="m-0">
					Permit #{BigInt(id).toString()}
				</li>
			))}
		</ul>
	);
}
