import { useEffect, useState } from "react";
import { useAccount, useConnect, useDisconnect } from "@starknet-react/core";
import { NetworkBadge } from "@/components/network-badge";
import { controllerConnector } from "@/dojo/connector";
import { shortAddress } from "@/lib/utils";

export function ConnectButton() {
	const { connect } = useConnect();
	const { disconnect } = useDisconnect();
	const { address, isConnected } = useAccount();
	const [username, setUsername] = useState<string>();

	// Resolve the Controller username once connected.
	useEffect(() => {
		if (!isConnected) {
			setUsername(undefined);
			return;
		}
		controllerConnector.username()?.then(setUsername).catch(console.error);
	}, [isConnected]);

	// Connected: the button shows the username and opens the Controller inventory.
	const openInventory = () =>
		controllerConnector.controller.openProfile("inventory");

	return (
		<div className="flex flex-row items-center gap-4">
			{isConnected ? (
				<button type="button" onClick={openInventory}>
					{username ?? shortAddress(address)}
				</button>
			) : (
				<button
					type="button"
					onClick={() => connect({ connector: controllerConnector })}
				>
					Connect Controller
				</button>
			)}

			<div className="flex flex-col items-start gap-1 text-sm opacity-60">
				<NetworkBadge />
				{isConnected && (
					<button
						type="button"
						className="bg-transparent px-2 py-1 text-sm text-[#888] underline"
						onClick={() => disconnect()}
					>
						Disconnect
					</button>
				)}
			</div>
		</div>
	);
}
