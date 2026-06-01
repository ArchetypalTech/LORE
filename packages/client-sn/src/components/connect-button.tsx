import { useEffect, useState } from "react";
import { useAccount, useConnect, useDisconnect } from "@starknet-react/core";
import { controllerConnector } from "@/dojo/connector";

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
		<>
			{isConnected ? (
				<button type="button" onClick={openInventory}>
					{username ?? `${address?.slice(0, 6)}…${address?.slice(-4)}`}
				</button>
			) : (
				<button
					type="button"
					onClick={() => connect({ connector: controllerConnector })}
				>
					Connect Controller
				</button>
			)}

			{isConnected && (
				<button
					type="button"
					className="btn-link"
					onClick={() => disconnect()}
				>
					Disconnect
				</button>
			)}
		</>
	);
}
