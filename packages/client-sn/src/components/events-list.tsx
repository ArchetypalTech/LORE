import { feltToString } from "@/lib/utils";
import { useAppchainMessageEvents } from "@/hooks/use-appchain-message-events";

export function EventsList() {
	const events = useAppchainMessageEvents();

	if (events.length === 0)
		return (
			<p className="m-0 text-sm opacity-70">No appchain events (Torii)</p>
		);

	return (
		<ul className="flex list-none flex-col items-center gap-1 p-0">
			Appchain events (Torii)
			{events.map((event) => (
				<li
					key={event.uuid}
					className="m-0 flex flex-row items-center gap-2"
				>
					<span>Event #{event.uuid}</span>
					<span className="text-sm opacity-70">
						{feltToString(event.messageType)}
					</span>
					<button
						type="button"
						onClick={() => {}}
						className="bg-transparent px-2 py-1 text-accent text-sm underline"
					>
						Consume
					</button>
				</li>
			))}
		</ul>
	);
}
