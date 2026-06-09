import { useAccount } from "@starknet-react/core";
import { PermitList } from "@/components/permit-list";
import { useOpenBundle } from "@/hooks/use-open-bundle";
import { usePermitCount } from "@/hooks/use-permit-count";

export function Permits() {
	const { isConnected, address } = useAccount();

	const { permitCount } = usePermitCount(address!);
	const openBundle = useOpenBundle();

	if (!isConnected) return null;
	return (
		<div className="flex flex-col items-center gap-3">
			<div className="flex flex-row items-center justify-center gap-2">
				<p className="m-0">Owned Permits:</p>
				<p className="m-0">{permitCount}</p>
			</div>
			<PermitList />
			<button type="button" onClick={openBundle}>
				Purchase Bundle
			</button>
		</div>
	);
}
