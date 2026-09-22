import { useState } from "react";
import { PinForm } from "@/components/pin-form";
import { isUnlocked, rememberUnlock } from "@/lib/pin";

/** Shows the walkthrough video once the PIN has been entered (remembered for a while in this browser). */
export function WalkthroughGate() {
	const [locked, setLocked] = useState(() => !isUnlocked());

	if (locked) {
		return (
			<div className="grid gap-8 rounded-lg p-16 shadow-lg">
				<section className="grid h-dvh place-content-center text-amber-700 backdrop-blur-lg">
					<PinForm
						onUnlock={() => {
							rememberUnlock();
							setLocked(false);
						}}
					/>
				</section>
			</div>
		);
	}

	return (
		<section className="grid h-dvh place-content-center">
			<iframe
				title="Walkthrough"
				src={import.meta.env.VITE_WALKTHROUGH_EMBED}
				width="1200px"
				height="700px"
				allow="autoplay"
				className="aspect-[12/7] h-auto max-w-full"
			/>
		</section>
	);
}
