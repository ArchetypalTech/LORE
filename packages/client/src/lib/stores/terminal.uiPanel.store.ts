import { StoreBuilder } from "../utils/storebuilder";

export type ExitInfo = {
  id: number;
  name: string;
  direction: string | number;
  destination: string;
  is_enterable: boolean;
};

export type PuzzleInfo = {
  name: string;
  executed: boolean;
};

export type UIPanelState = {
  visible: boolean;
  location: string;
  exits: ExitInfo[];
  puzzles: PuzzleInfo[];

  show: () => void;
  hide: () => void;
  setLocation: (v: string) => void;
  setExits: (v: ExitInfo[]) => void;
  setPuzzles: (v: PuzzleInfo[]) => void;
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
        is_enterable: true,
      },
      {
        id: 2,
        name: "Collapsed Pier",
        direction: "east",
        destination: "Tidepath Edge",
        is_enterable: false,
      },
      {
        id: 3,
        name: "Broken Tram Line",
        direction: "south",
        destination: "Lower Rail Tunnels",
        is_enterable: true,
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

    // ACTIONS
    show: () => set({ visible: true }),
    hide: () => set({ visible: false }),

    setLocation: (v) => set({ location: v }),
    setExits: (v) => set({ exits: v }),
    setPuzzles: (v) => set({ puzzles: v }),
  });

const UIPanelStore = createFactory({});

export default UIPanelStore;
export { useUIPanelStore };