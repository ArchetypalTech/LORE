import { ConnectButton } from "@/components/connect-button";

export default function App() {
	return (
		<main className="flex min-h-screen flex-row gap-4">
			<div className="flex flex-1 flex-col items-end justify-center gap-3">
				<h1 className="m-0 text-4xl tracking-wider">&gt;ORUG</h1>
			</div>
			<div className="flex flex-1 flex-col items-start justify-center gap-3">
				<ConnectButton />
			</div>
		</main>
	);
}
