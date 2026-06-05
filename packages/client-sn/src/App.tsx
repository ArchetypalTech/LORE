import { ConnectButton } from "@/components/connect-button";
import { Permits } from "./components/permits";

export default function App() {
	return (
		<div className="flex flex-col min-h-screen gap-4">
			<div className="flex-1" />

			<div className="flex w-full flex-row gap-4">
				<div className="flex flex-1 flex-col items-end justify-center gap-3">
					<h1 className="m-0 text-4xl tracking-wider">&gt;ORUG</h1>
				</div>
				<div className="flex flex-1 flex-col items-start justify-center gap-3">
					<ConnectButton />
				</div>
			</div>

			<hr />

			<Permits />

			<div className="flex-1" />
		</div>
	);
}
