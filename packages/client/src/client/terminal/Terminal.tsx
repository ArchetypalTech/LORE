import DojoStore, { useDojoStore } from "@lib/stores/dojo.store";
import {
	nextItem,
	printingStatus,
	useTerminalStore,
} from "@lib/stores/terminal.store";
import type { FormEvent, KeyboardEvent } from "react";
import { useEffect, useRef, useState } from "react";
import LoadingMessage from "./loader";
import TerminalLine from "./TerminalLine";
import Typewriter from "./Typewriter";
import "./Terminal.css";
import { sendCommand } from "@lib/terminalCommands/commandHandler";
import { BigNumberish } from "starknet";
import { useSyncGameId } from "@/lib/stores/game.store";

export default function Terminal({
	gameId: inputGameId,
}: {
	gameId?: BigNumberish;
}) {
	const gameId = useSyncGameId(inputGameId);

	const [inputValue, setInputValue] = useState("");
	const [originalInputValue, setOriginalInputValue] = useState("");
	const [inputHistory, setInputHistory] = useState<string[]>([]);
	const [inputHistoryIndex, setInputHistoryIndex] = useState(0);

	const terminalFormRef = useRef<HTMLFormElement>(null);
	const terminalInputRef = useRef<HTMLTextAreaElement>(null);
	const [cursorPos, setCursorPos] = useState(0);
	const textAnchorRef = useRef<HTMLInputElement>(null);
	const scroller = useRef<HTMLElement>(null);

	const {
		status: { status },
	} = useDojoStore();
	const { terminalContent, activeTypewriterLine } = useTerminalStore();
	// const { originalStoryLength } = useDojoStore();

	useEffect(() => {
		// Focus input on mount
		if (terminalInputRef.current) {
			terminalInputRef.current.focus();
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

	useEffect(() => {
		const updateCursorPos = () => {
			if (terminalInputRef.current) {
				setCursorPos(terminalInputRef.current.selectionStart);
			}
		};
		const ta = terminalInputRef.current;
		if (ta) {
			ta.addEventListener("selectionchange", updateCursorPos);
			ta.addEventListener("click", updateCursorPos);
			ta.addEventListener("keyup", updateCursorPos);

			return () => {
				ta.removeEventListener("selectionchange", updateCursorPos);
				ta.removeEventListener("click", updateCursorPos);
				ta.removeEventListener("keyup", updateCursorPos);
			};
		}
	}, []);

	// Split handleKeyDown to reduce complexity
	const handleUpArrow = (e: KeyboardEvent<HTMLTextAreaElement>) => {
		// console.log(e, inputHistoryIndex, inputHistory);
		e.preventDefault();
		if (inputHistoryIndex === 0) {
			setOriginalInputValue(inputValue);
		}
		if (inputHistoryIndex < inputHistory.length) {
			setInputHistoryIndex(inputHistoryIndex + 1);
			setInputValue(inputHistory[inputHistory.length - inputHistoryIndex - 1]);
		}
	};

	const handleDownArrow = (e: KeyboardEvent<HTMLTextAreaElement>) => {
		// console.log(e, inputHistoryIndex);
		e.preventDefault();
		if (inputHistoryIndex > 0) {
			setInputHistoryIndex(inputHistoryIndex - 1);
			if (inputHistoryIndex === 1) {
				setInputValue(originalInputValue);
			} else {
				setInputValue(
					inputHistory[inputHistory.length - inputHistoryIndex + 1],
				);
			}
		}
	};

	const handleKeyDown = (e: KeyboardEvent<HTMLTextAreaElement>) => {
		focusInput();
		switch (e.key) {
			case "Enter":
				e.preventDefault();
				handleSubmit(e);
				break;
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

		const command = inputValue;
		setInputHistoryIndex(0);

		if (command === "") return;

		setInputValue("");
		setInputHistory([...inputHistory, command]);
		printingStatus(true);

		if (textAnchorRef.current && terminalFormRef.current)
			terminalFormRef.current.scrollTo({
				top: scroller.current?.clientHeight,
				left: 0,
				behavior: "smooth",
			});
		setTimeout(async () => await sendCommand(command, gameId), 1000);
	};

	const focusInput = () => {
		if (terminalInputRef.current) {
			terminalInputRef.current.focus();
		}
	};

	return (
		<div className="flex h-full w-full items-center justify-center font-primary">
			<form
				ref={terminalFormRef}
				onSubmit={handleSubmit}
				onClick={focusInput}
				aria-label="Terminal"
				id="terminal"
				className="shadow-2xl shadow-emerald-950 buzzing h-full w-full rounded-md overflow-y-auto md:border bg-black text-green-500"
				style={{
					borderColor:
						status === "error"
							? "var(--terminal-error)"
							: "var(--terminal-system)",
				}}
			>
				<div className="screen relative ">
					<div
						id="scroller"
						className="flex w-full flex-col items-end p-4"
						ref={scroller}
					>
						{terminalContent.map((content, index) => (
							<TerminalLine key={index} content={content} />
						))}

						<Typewriter />

						{status === "inputEnabled" && (
							<div id="scroller" className="flex w-full flex-row gap-2">
								<div
									ref={textAnchorRef}
									id="input-anchor"
									className="font-secondary"
								/>
							</div>
						)}
					</div>
					<div className="sticky text-[1rem] z-10 bottom-[4.5em] md:bottom-[3.8rem] h-4 w-full backdrop-blur-lg"></div>
					<div className="flex flex-row p-4 pb-6 md:pb-4 sticky bottom-0 z-10 theme-primary-background items-center">
						{useTerminalStore().isPrinting && <LoadingMessage />}
						{!useTerminalStore().isPrinting && <span>{`>`}</span>}
						<textarea
							rows={1}
							id="terminal-input"
							className="terminal-line system w-full border-0 bg-transparent p-2 pl-0"
							value={inputValue}
							onChange={(e) => setInputValue(e.target.value)}
							ref={terminalInputRef}
							onKeyDown={handleKeyDown}
						></textarea>
						<div
							className="crt-text fadeInOut"
							style={{
								position: "absolute",
								top: "1.35em",
								left: `calc(${cursorPos}ch + 1.75rem)`,
								pointerEvents: "none",
								fontSize: "inherit",
							}}
						>
							{"\u2588"}
						</div>
					</div>
				</div>
			</form>
		</div>
	);
}
