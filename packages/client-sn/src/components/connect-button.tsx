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
				<button type="button" style={styles.button} onClick={openInventory}>
					{username ?? `${address?.slice(0, 6)}…${address?.slice(-4)}`}
				</button>
			) : (
				<button
					type="button"
					style={styles.button}
					onClick={() => connect({ connector: controllerConnector })}
				>
					Connect Controller
				</button>
			)}

			{isConnected && (
				<button
					type="button"
					style={styles.disconnect}
					onClick={() => disconnect()}
				>
					Disconnect
				</button>
			)}
		</>
	);
}

const styles: Record<string, React.CSSProperties> = {
	button: {
		marginTop: "1rem",
		padding: "0.75rem 1.5rem",
		fontSize: "1rem",
		fontFamily: "inherit",
		color: "#0a0a0a",
		background: "#e6e6e6",
		border: "none",
		borderRadius: "0.5rem",
		cursor: "pointer",
	},
	disconnect: {
		padding: "0.25rem 0.5rem",
		fontSize: "0.8rem",
		fontFamily: "inherit",
		color: "#888",
		background: "transparent",
		border: "none",
		cursor: "pointer",
		textDecoration: "underline",
	},
};
