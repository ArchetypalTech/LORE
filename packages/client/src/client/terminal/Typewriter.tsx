import type { TerminalContentItem } from "@lib/stores/terminal.store";
import { nextItem, useTerminalStore } from "@lib/stores/terminal.store";
import UserStore from "@lib/stores/user.store";
import { useEffect, useState } from "react";
import TerminalLine from "./TerminalLine";

export default function Typewriter() {
	const [displayContent, setDisplayContent] =
		useState<TerminalContentItem | null>(null);
	const minTypingDelay = 2;
	const maxTypingDelay = 9;

	const { activeTypewriterLine, typewriterSpeedMultiplier } = useTerminalStore();

	useEffect(() => {
		// Reset display content when activeTypewriterLine changes
		setDisplayContent(null);

		if (activeTypewriterLine === null) {
			return;
		}

		// Fast mode - instant display
		if (
			activeTypewriterLine.useTypewriter === false ||
			UserStore().typewriter_effect === false
		) {
			nextItem(activeTypewriterLine);
			return;
		}

		// Clone the content item for animation
		const newDisplayContent = { ...activeTypewriterLine, text: "" };
		setDisplayContent(newDisplayContent);

		let currentIndex = 0;
		const text = activeTypewriterLine.text;
		const baseDelay = (activeTypewriterLine.speed || 6) *(Math.random() * (maxTypingDelay - minTypingDelay) + minTypingDelay);
		const delay = baseDelay / typewriterSpeedMultiplier;

		const interval = setInterval(() => {
			if (currentIndex >= text.length) {
				clearInterval(interval);
				nextItem(activeTypewriterLine);
				return;
			}

			const char = text[currentIndex];
			setDisplayContent((prev) =>
				prev ? { ...prev, text: prev.text + char } : prev,
			);
			currentIndex++;
		}, delay);

		// Cleanup interval on unmount or when activeTypewriterLine changes
		return () => {
			clearInterval(interval);
		};
	}, [activeTypewriterLine, typewriterSpeedMultiplier]);

	if (displayContent === null) {
		return null;
	}

	return <TerminalLine content={displayContent} />
}
