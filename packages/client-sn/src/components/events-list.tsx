import type { ReactNode } from "react";
import type { AppchainMessageEvent } from "@/context/torii-appchain-provider";
import { useAppchainMessageEvents } from "@/context/torii-appchain-provider";
import { useConsumeEvent } from "@/hooks/use-consume-event";
import { feltToString } from "@/lib/utils";

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
				<EventsListItem key={event.uuid} event={event} />
			))}
		</ul>
	);
}

function EventsListItem({ event }: { event: AppchainMessageEvent }) {
	const { mutate, isPending, isSuccess } = useConsumeEvent();

	let status: ReactNode;
	if (isPending) {
		status = <span className="text-sm opacity-70">Consuming...</span>;
	} else if (isSuccess) {
		status = <span className="text-sm opacity-70">Consumed</span>;
	} else {
		status = (
			<button
				type="button"
				onClick={() => mutate(event.payload)}
				className="bg-transparent px-2 py-1 text-accent text-sm underline"
			>
				Consume
			</button>
		);
	}

	return (
		<li className="m-0 flex flex-row items-center gap-2">
			<span>Event #{event.uuid}</span>
			<span className="text-sm opacity-70">
				{feltToString(event.messageType)}
			</span>
			{status}
		</li>
	);
}
