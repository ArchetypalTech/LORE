import { ConnectButton } from "@/components/connect-button";

export default function App() {
	return (
		<main style={styles.main}>
			<h1 style={styles.title}>&gt;LORE</h1>
			<p style={styles.subtitle}>Starknet client</p>
			<ConnectButton />
		</main>
	);
}

const styles: Record<string, React.CSSProperties> = {
	main: {
		minHeight: "100vh",
		display: "flex",
		flexDirection: "column",
		alignItems: "center",
		justifyContent: "center",
		gap: "0.75rem",
		fontFamily: "ui-monospace, SFMono-Regular, Menlo, monospace",
		background: "#0a0a0a",
		color: "#e6e6e6",
	},
	title: { margin: 0, fontSize: "2.5rem", letterSpacing: "0.05em" },
	subtitle: { margin: 0, opacity: 0.6 },
};
