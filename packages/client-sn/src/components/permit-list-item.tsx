import type { ReactNode } from "react";
import { useUsePermit } from "@/hooks/use-use-permit";

export function PermitListItem({
	tokenId,
	isUsed,
}: {
	tokenId: string;
	isUsed: boolean;
}) {
	const { mutate, isPending, isSuccess } = useUsePermit();
	const id = BigInt(tokenId).toString();

	// Keep showing "Using..." after the tx confirms until the subscribed model
	// reflects is_used, so the label never flickers back to "Use".
	const using = isPending || (isSuccess && !isUsed);

	let status: ReactNode;
	if (isUsed) {
		status = <span className="text-sm opacity-70">Used</span>;
	} else if (using) {
		status = <span className="text-sm opacity-70">Using...</span>;
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
