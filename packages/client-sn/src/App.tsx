import { ConnectButton } from "@/components/connect-button";
import { Permits } from "@/components/permits";
import { Actions } from "@/components/actions";

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

			<div className="flex w-full flex-row gap-4">
				<div className="flex flex-1 flex-col items-end justify-top gap-3">
					<h3>L2 (Starknet)</h3>
					<Permits />
				</div>

				{/* separator */}
				<div className="h-[400px] w-px bg-gray-300 mx-4" />

				<div className="flex flex-1 flex-col items-start justify-top gap-3">
					<h3>L3 (Katana)</h3>
					<Actions />
				</div>
			</div>


			<div className="flex-1" />
		</div>
	);
}
