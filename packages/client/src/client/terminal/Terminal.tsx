import DojoStore, { useDojoStore } from "@lib/stores/dojo.store";
import { nextItem, useTerminalStore } from "@lib/stores/terminal.store";
import type { FormEvent, KeyboardEvent } from "react";
import { useEffect, useRef, useState } from "react";
import TerminalLine from "./TerminalLine";
import Typewriter from "./Typewriter";
import "./Terminal.css";
import { sendCommand } from "@lib/terminalCommands/commandHandler";

export default function Terminal() {
	const [inputValue, setInputValue] = useState("");
	const [originalInputValue, setOriginalInputValue] = useState("");
	const [inputHistory, setInputHistory] = useState<string[]>([]);
	const [inputHistoryIndex, setInputHistoryIndex] = useState(0);

	const terminalFormRef = useRef<HTMLFormElement>(null);
	const terminalInputRef = useRef<HTMLInputElement>(null);

	const {
		status: { status },
	} = useDojoStore();
	const { terminalContent, activeTypewriterLine } = useTerminalStore();

	useEffect(() => {
		// Focus input on mount
		if (terminalInputRef.current) {
			// terminalInputRef.current.focus();
		}
		// Set timeout for connection status
		const timeout = setTimeout(() => {
			if (status !== "inputEnabled" && status !== "initialized") {
				DojoStore().setStatus({
					status: "error",
					error: "TIMEOUT",
				});
			}
		}, 5000);

		return () => clearTimeout(timeout);
	}, [status]);

	// Split handleKeyDown to reduce complexity
	const handleUpArrow = (e: KeyboardEvent<HTMLInputElement>) => {
		console.log(e, inputHistoryIndex, inputHistory);
		e.preventDefault();
		if (inputHistoryIndex === 0) {
			setOriginalInputValue(inputValue);
		}
		if (inputHistoryIndex < inputHistory.length) {
			setInputHistoryIndex(inputHistoryIndex + 1);
			setInputValue(inputHistory[inputHistory.length - inputHistoryIndex - 1]);
		}
	};

	const handleDownArrow = (e: KeyboardEvent<HTMLInputElement>) => {
		console.log(e, inputHistoryIndex);
		e.preventDefault();
		if (inputHistoryIndex > 0) {
			setInputHistoryIndex(inputHistoryIndex - 1);
			if (inputHistoryIndex === 1) {
				setInputValue(originalInputValue);
			} else {
				setInputValue(inputHistory[inputHistory.length - inputHistoryIndex + 1]);
			}
		}
	};

	const handleKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
		focusInput();
		switch (e.key) {
			case "ArrowUp":
				handleUpArrow(e);
				break;
			case "ArrowDown":
				handleDownArrow(e);
				break;
			case "Escape":
				e.preventDefault();
				nextItem(activeTypewriterLine);
				break;
			default:
				break;
		}
	};

	const handleSubmit = async (e: FormEvent) => {
		e.preventDefault();

		if (terminalInputRef.current) {
			terminalInputRef.current.disabled = true;
		}
		const command = inputValue;
		setInputHistoryIndex(0);

		if (command === "") return;

		setInputValue("");
		setInputHistory([...inputHistory, command]);

		await sendCommand(command);

		if (terminalInputRef.current) {
			terminalInputRef.current.disabled = false;
			// terminalInputRef.current.focus();
		}
	};

	const focusInput = () => {
		if (terminalInputRef.current) {
			// terminalInputRef.current.focus();
		}
	};

	return (
		<div className="flex h-full w-full items-center justify-center font-berkeley">
			<form
				ref={terminalFormRef}
				onSubmit={handleSubmit}
				onClick={focusInput}
				aria-label="Terminal"
				role=""
				id="terminal"
				className="buzzing h-full w-full overflow-y-auto rounded-md border bg-black p-4 text-green-500"
				style={{
					borderColor:
						status === "error" ? "var(--terminal-error)" : "var(--terminal-system)",
				}}
			>
				<div id="scroller" className="bottom-0 flex w-full flex-col items-end">
					{terminalContent.map((content, index) => (
						<TerminalLine key={index} content={content} />
					))}

					<Typewriter />

					{status === "inputEnabled" && (
						<div id="scroller" className="flex w-full flex-row gap-2">
							<span>&#x3e;</span>
							<input
								id="terminal-input"
								className="terminal-line system w-full border-0 bg-transparent"
								type="text"
								value={inputValue}
								onChange={(e) => setInputValue(e.target.value)}
								ref={terminalInputRef}
								onKeyDown={handleKeyDown}
								style={{ outline: "none" }}
								autoComplete="off"
								autoCorrect="off"
							/>
							<div
								id="input-anchor"
								style={{ overflowAnchor: "auto", height: "1px" }}
							/>
						</div>
					)}
				</div>
			</form>
		</div>
	);
}
