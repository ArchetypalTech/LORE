import DojoStore, { useDojoStore } from "@lib/stores/dojo.store";
import {
	nextItem,
	printingStatus,
	useTerminalStore,
} from "@lib/stores/terminal.store";
import type { FormEvent, KeyboardEvent as ReactKeyboardEvent } from "react";
import { useEffect, useRef, useState } from "react";
import IntroLoader from "./IntroLoader";
import LoadingMessage from "./Loader";
import TerminalLine from "./TerminalLine";
import Typewriter from "./Typewriter";
import "./Terminal.css";
import { sendCommand } from "@lib/terminalCommands/commandHandler";
import { BigNumberish } from "starknet";
import { useSyncGameId } from "@/lib/stores/game.store";


export function SetTimerForIdle(newTimeout: number) {
	const store = useTerminalStore();
	store.setIdleTimeout(newTimeout);
}

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
	const scroller = useRef<HTMLDivElement>(null);

	const {
		status: { status },
	} = useDojoStore();
	const { terminalContent, activeTypewriterLine, isPrinting, setIdleVideoPlaying, idleTimeout } = useTerminalStore();
	// const { originalStoryLength } = useDojoStore();

	const [userNearBottom, setUserNearBottom] = useState(true);

	// --- IDLE VIDEO STATE ---
	const [isIdle, setIsIdle] = useState(false);
	const idleTimeoutRef = useRef<number | null>(null);
	const IDLE_DELAY = 1 * 1000 * idleTimeout; // 30 seconds (30000 ms)
	// 2 minutes (120000 ms)
	
	// helper: clear timer
	const clearIdleTimer = () => {
		if (idleTimeoutRef.current) {
			window.clearTimeout(idleTimeoutRef.current);
			idleTimeoutRef.current = null;
		}
	};

	// reset timer & cancel idle
	const resetIdleTimer = () => {
		clearIdleTimer();

		if (isIdle || useTerminalStore.getState().idleVideoPlaying) {
			setIsIdle(false);
			setIdleVideoPlaying(false);
		}

		idleTimeoutRef.current = window.setTimeout(() => {
			console.log("Idle timer fired! Showing video");
			setIsIdle(true);
			setIdleVideoPlaying(true);
		}, IDLE_DELAY);
	};

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

  // FIX ADDED: Track user scroll state
	useEffect(() => {
      const el = scroller.current;
      if (!el) return;

      const handleScroll = () => {
          const atBottom =
              el.scrollHeight - el.scrollTop - el.clientHeight > 50;
          setUserNearBottom(atBottom);
      };

      el.addEventListener("scroll", handleScroll);
      return () => el.removeEventListener("scroll", handleScroll);
  }, []);

  // FIX ADDED: Auto-scroll only if user is near bottom
  useEffect(() => {
      const el = scroller.current;
      if (!el) return;
      if (!userNearBottom) return;

      requestAnimationFrame(() => {
          el.scrollTo({
              top: el.scrollHeight,
              behavior: "smooth",
          });
      });
  }, [terminalContent, activeTypewriterLine, isPrinting, userNearBottom]);

  // When printing STARTS → always force-scroll to bottom
	useEffect(() => {
			if (!isPrinting) return; // only when printing begins

			const el = scroller.current;
			if (!el) return;

			requestAnimationFrame(() => {
					el.scrollTo({
							top: el.scrollHeight,
							behavior: "smooth",
					});
			});
	}, [isPrinting]);

  // Re-focus textarea whenever new content prints
  useEffect(() => {
      if (status === "inputEnabled" && !isPrinting) {
          terminalInputRef.current?.focus();
      }
  }, [terminalContent, activeTypewriterLine, isPrinting, status]);

	// update cursor position
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

	// Auto-refocus when clicking inside the terminal area (unless focus is locked)
useEffect(() => {
	const handleClick = (e: MouseEvent) => {
		const { focusLocked } = useTerminalStore.getState();
		if (!focusLocked) return; // skip if focus is locked by another UI (e.g. wallet)

		const terminalEl = terminalFormRef.current;
		if (terminalEl && terminalEl.contains(e.target as Node)) {
			terminalInputRef.current?.focus();
		}
	};

	document.addEventListener("click", handleClick);
	return () => document.removeEventListener("click", handleClick);
}, []);

// Auto-refocus when typing while terminal input is unfocused (unless locked)
useEffect(() => {
	const handleKeydown = (e: globalThis.KeyboardEvent) => {
		const { focusLocked } = useTerminalStore.getState();
		if (!focusLocked) return;

		const input = terminalInputRef.current;
		if (!input) return;

		if (document.activeElement !== input && status === "inputEnabled" && !isPrinting) {
			e.preventDefault();
			input.focus();
		}
	};

	window.addEventListener("keydown", handleKeydown);
	return () => window.removeEventListener("keydown", handleKeydown);
}, [status, isPrinting]);

	// Split handleKeyDown to reduce complexity
	const handleUpArrow = (e: ReactKeyboardEvent<HTMLTextAreaElement>) => {
		e.preventDefault();
		if (inputHistoryIndex === 0) {
			setOriginalInputValue(inputValue);
		}
		if (inputHistoryIndex < inputHistory.length) {
			setInputHistoryIndex(inputHistoryIndex + 1);
			setInputValue(inputHistory[inputHistory.length - inputHistoryIndex - 1]);
		}
	};

	const handleDownArrow = (e: ReactKeyboardEvent<HTMLTextAreaElement>) => {
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

	// ---------------------- IDLE DETECTION: listen to user activity ----------------------
	useEffect(() => {
		if (typeof window === "undefined") return;

		const onActivity = () => {
			resetIdleTimer();
		};

		// Attach to window/document as before
		window.addEventListener("mousemove", onActivity);
		window.addEventListener("keydown", onActivity);
		window.addEventListener("click", onActivity);
		window.addEventListener("touchstart", onActivity);

		// Also attach to the terminal form to catch clicks and keydowns inside textarea
		const formEl = terminalFormRef.current;
		if (formEl) {
			formEl.addEventListener("keydown", onActivity);
			formEl.addEventListener("click", onActivity);
		}

		// Scroll listener
		const scrollerEl = scroller.current;
		if (scrollerEl) scrollerEl.addEventListener("scroll", onActivity);

		// Start the timer
		resetIdleTimer();

		return () => {
			window.removeEventListener("mousemove", onActivity);
			window.removeEventListener("keydown", onActivity);
			window.removeEventListener("click", onActivity);
			window.removeEventListener("touchstart", onActivity);

			if (formEl) {
				formEl.removeEventListener("keydown", onActivity);
				formEl.removeEventListener("click", onActivity);
			}

			if (scrollerEl) scrollerEl.removeEventListener("scroll", onActivity);

			clearIdleTimer();
			setIdleVideoPlaying(false);
		};
	}, []);

	// If idle state changes locally, ensure store is in sync (extra safety)
	useEffect(() => {
		console.log("Idle state changed:", isIdle);
		setIdleVideoPlaying(isIdle);
	}, [isIdle, setIdleVideoPlaying]);


	const handleKeyDown = (e: ReactKeyboardEvent<HTMLTextAreaElement>) => {
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
		setCursorPos(0);
		setInputHistory([...inputHistory, command]);
		printingStatus(true);

		if (textAnchorRef.current && terminalFormRef.current)
			scroller.current?.scrollTo({
				top: scroller.current.scrollHeight,
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
			 {/* Terminal form */}
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
					<div className="top-2">
						{status === "initialized" && <IntroLoader />}
					</div>
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
							<div className="flex w-full flex-row gap-2">
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
						{!useTerminalStore().isPrinting && status === "inputEnabled" && (
							<span>{`>`}</span>
						)}
						<textarea
							rows={1}
							disabled={useTerminalStore().isPrinting}
							id="terminal-input"
							className="terminal-line system w-full border-0 bg-transparent p-2 pl-0"
							value={inputValue}
							onChange={(e) => setInputValue(e.target.value)}
							ref={terminalInputRef}
							onKeyDown={handleKeyDown}
						></textarea>
						
						<div
							className="crt-text fadeInOut absolute pointer-none top-[1.35em]"
							style={{
								left: `calc(${cursorPos}ch + 1.85rem)`,
								visibility:
									useTerminalStore().isPrinting || status !== "inputEnabled"
										? "hidden"
										: "visible",
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
