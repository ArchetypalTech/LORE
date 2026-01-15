import type { HTMLAttributes } from "react";
import { StoreBuilder } from "../utils/storebuilder";
import { decodeDojoText } from "../utils/utils";

/**
 * Types of formatting that can be applied to terminal content.
 * @typedef {string} FormatType
 */
export type FormatType = "input" | "hash" | "error" | "out" | "shog" | "system";

export type TerminalContentItem = {
	text: string;
	format: FormatType;
	useTypewriter?: boolean;
	speed?: number;
	style?: HTMLAttributes<HTMLDivElement>["style"];
	isPrinting?: boolean;
	enableAudio: boolean;
	volumeAudio: number;
};

const {
	get,
	set,
	useStore: useTerminalStore,
	createFactory,
} = StoreBuilder({
	isPrinting: false as boolean,
	enableAudio: false as boolean,
	terminalContent: [] as TerminalContentItem[],
	activeTypewriterLine: null as TerminalContentItem | null,
	contentQueue: [] as TerminalContentItem[],
	volumeAudio: 0.40,
	focusLocked: true as boolean,
	playTrailer: true,
	idleVideoPlaying: false,
  setIdleVideoPlaying: (v: boolean) => set({ idleVideoPlaying: v }),
	setPlayTrailer: (v: boolean) => set({ playTrailer: v }),
});

/**
 * Adds a new item to the terminal content queue.
 * If no typewriter effect is currently active, it will start processing the queue.
 * @param {TerminalContentItem} item - The terminal content item to add
 */
export function addTerminalContent(item: TerminalContentItem) {
	item.text = decodeDojoText(item.text);
	set({
		contentQueue: [...get().contentQueue, item],
	});

	if (get().activeTypewriterLine === null) {		
		nextItem(null);
	}
}

export function printingStatus(state: boolean) {
	set({
		isPrinting: state
	});
}

export function increaseVolume() {
	let volume = get().volumeAudio
	volume += 0.1
	if(volume > 1 ) return 
	set({ volumeAudio: volume });
}
export function decreaseVolume() {
	let volume = get().volumeAudio
	volume -= 0.1
	if(volume < 0.1 ) return 
	set({ volumeAudio: volume });
}

export function toggleMuted() {
	set({
		enableAudio: !get().enableAudio
	});
}
export function unMute() {
	set({
		enableAudio: true
	});
}

/**
 * Locks terminal focus so it won't steal input from other UI (e.g. wallet modals)
 */
export function lockTerminalFocus() {
	set({ focusLocked: false });
}

/**
 * Unlocks terminal focus so typing/clicking works again
 */
export function unlockTerminalFocus() {
	set({ focusLocked: true });
}

/**
 * Processes the next item in the terminal content queue.
 * If a typewriter effect has finished, adds it to the permanent content.
 * @param {TerminalContentItem|null} newContent - The content that has finished its typewriter effect, if any
 */
export const nextItem = async (newContent: TerminalContentItem | null) => {
	const state = get();

	// Check if newContent is in the currentItem
	if (newContent && state.activeTypewriterLine === newContent) {
		set({
			terminalContent: [...state.terminalContent, newContent],
			activeTypewriterLine: null,
		});
	}

	if (state.contentQueue.length > 0) {
		const nextItem = state.contentQueue[0];
		if (nextItem) {
			printingStatus(true);
			set({
				contentQueue: state.contentQueue.filter((item) => item !== nextItem),
				activeTypewriterLine: nextItem,
			});
		}
	} 
	// disable printing notice once queue is empty and mode has been typewriter
	if(!state.contentQueue.length && state.activeTypewriterLine?.useTypewriter) printingStatus(false);
	
};

/**
 * Clears all content from the terminal.
 */
export function clearTerminalContent() {
	set({ terminalContent: [] });
}

/**
 * Helper toggle for turning on/off playTrailer
 */
export function toggleTrailer() {
	set({ playTrailer: !get().playTrailer });
}

/**
 * Factory function that returns all terminal store state and methods.
 * Can be used to access the terminal store outside of React components.
 * @returns {Object} The terminal store state and methods
 */
const TerminalStore = createFactory({
	addTerminalContent,
	nextItem,
	clearTerminalContent,
	lockTerminalFocus,
	unlockTerminalFocus,
});

export default TerminalStore;
export { useTerminalStore };
