import { StoreBuilder } from "../utils/storebuilder";

export type ExitInfo = {
  id: number;
  name: string;
  direction: string;
  destination: string;
};

export type UIPanelState = {
  visible: boolean;
  location: string;
  exits: ExitInfo[];
  puzzles: string[];

  show: () => void;
  hide: () => void;
  setLocation: (v: string) => void;
  setExits: (v: ExitInfo[]) => void;
  setPuzzles: (v: string[]) => void;
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
      "Reactivate the tram control node",
      "Decode the warehouse access sigil",
      "Stabilize the tidepath frequency",
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