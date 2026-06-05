import { useAccount } from "@starknet-react/core";
import { useOpenBundle } from "../hooks/use-open-bundle";
import { usePermitCount } from "../hooks/use-permit-count";

export function Permits() {
	const { isConnected, address } = useAccount();

	const { permitCount } = usePermitCount(address!);
	const openBundle = useOpenBundle();

	if (!isConnected) return <></>;
	return (
		<>
			<div className="flex flex-row items-center justify-center gap-2">
				<p className="m-0">Owned Permits:</p>
				<p className="m-0">{permitCount}</p>
			</div>
			<div className="flex flex-row items-center justify-center gap-2">
				<button type="button" onClick={openBundle}>
					Purchase Bundle
				</button>
			</div>
		</>
	);
}
