import { useAccount } from "@starknet-react/core";
import { EventsList } from "@/components/events-list";
import { useActionsBalance } from "@/hooks/use-actions-balance";

export function Actions() {
	const { isConnected, address } = useAccount();
	const { actionsBalance } = useActionsBalance(address!);

	if (!isConnected) return null;
	return (
		<div className="flex flex-col items-center gap-3">
			<div className="flex flex-row items-center justify-center gap-2">
				<p className="m-0">Actions balance (RPC):</p>
				<p className="m-0">{actionsBalance}</p>
			</div>
			<button type="button" onClick={() => {}}>
				Airdrop Reward
			</button>
			<EventsList />
		</div>
	);
}
