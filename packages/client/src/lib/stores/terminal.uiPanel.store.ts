import { StoreBuilder } from "../utils/storebuilder";

export type ExitInfo = {
  id: number;
  name: string;
  direction: string | number;
  destination: string;
};

export type PuzzleInfo = {
  name: string;
  executed: boolean | undefined;
};

export type UIPanelState = {
  visible: boolean;
  location: string;
  exits: ExitInfo[];
  puzzles: PuzzleInfo[];
  loading: boolean;

  show: () => void;
  hide: () => void;
  setLocation: (v: string) => void;
  setExits: (v: ExitInfo[]) => void;
  setPuzzles: (v: PuzzleInfo[]) => void;
  setLoading: (v: boolean) => void;
};

const { get, set, useStore: useUIPanelStore, createFactory } =
  StoreBuilder<UIPanelState>({
    // Default Values for testing
    visible: true,

    location: "The Oruggin Trail",

    exits: [
      {
        id: 1,
        name: "Anything",
        direction: "Anywhere",
        destination: "The one you set out for",
      },
    ],

    puzzles: [
      {
        name: "Survive the journey",
        executed: false,
      },
    ],

    loading: false,

    // ACTIONS
    show: () => set({ visible: true }),
    hide: () => set({ visible: false }),

    setLocation: (v) => set({ location: v }),
    setExits: (v) => set({ exits: v }),
    setPuzzles: (v) => set({ puzzles: v }),
    setLoading: (v) => set({ loading: v }),
  });

export const getLocation = () => get().location;
const UIPanelStore = createFactory({});

export default UIPanelStore;
export { useUIPanelStore };