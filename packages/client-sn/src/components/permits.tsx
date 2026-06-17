import { useAccount } from "@starknet-react/core";
import { PermitList } from "@/components/permit-list";
import { useOpenBundle } from "@/hooks/use-open-bundle";
import { usePermitBalance } from "@/hooks/use-permit-balance";

export function Permits() {
	const { isConnected, address } = useAccount();

	const { permitBalance } = usePermitBalance(address!);
	const openBundle = useOpenBundle();

	if (!isConnected) return null;
	return (
		<div className="flex flex-col items-center gap-3">
			<div className="flex flex-row items-center justify-center gap-2">
				<p className="m-0">Permits balance (RPC):</p>
				<p className="m-0">{permitBalance}</p>
			</div>
			<button type="button" onClick={openBundle}>
				Purchase Bundle
			</button>
			<PermitList />
		</div>
	);
}
