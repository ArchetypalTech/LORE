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

    location: "The Forgotten Dock",

    exits: [
      {
        id: 1,
        name: "Rust-Eaten Gate",
        direction: "north",
        destination: "Abandoned Warehouse",
      },
      {
        id: 2,
        name: "Collapsed Pier",
        direction: "east",
        destination: "Tidepath Edge",
      },
      {
        id: 3,
        name: "Broken Tram Line",
        direction: "south",
        destination: "Lower Rail Tunnels",
      },
    ],

    puzzles: [
      {
        name: "Reactivate the tram control node",
        executed: false,
      },
      {
        name: "Decode the warehouse access sigil",
        executed: false,
      },
      {
        name: "Stabilize the tidepath frequency",
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

const UIPanelStore = createFactory({});

export default UIPanelStore;
export { useUIPanelStore };