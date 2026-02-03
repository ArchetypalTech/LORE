import { StoreBuilder } from "../utils/storebuilder";

export type ExitInfo = {
  id: number;
  name: string;
  direction: string | number;
  destination: string;
};

export type PuzzleInfo = {
  name: string;
  description: string;
  executed: boolean | undefined;
};

export type UIPanelState = {
  visible: boolean;
  location: string;
  exits: ExitInfo[];
  puzzles: PuzzleInfo[];
  loading: boolean;
  loadingE: boolean;
  loadingP: boolean;

  show: () => void;
  hide: () => void;
  setLocation: (v: string) => void;
  setExits: (v: ExitInfo[]) => void;
  setPuzzles: (v: PuzzleInfo[]) => void;
  setLoading: (v: boolean) => void;
  setLoadingE: (v: boolean) => void;
  setLoadingP: (v: boolean) => void;
};

export const DefaultValues =  () => {
  const panel = UIPanelStore();
  if (panel.visible) {
    panel.setLocation("The Oruggin Trail");
    panel.setExits([
      {
        id: 1,
        name: "Anything",
        direction: "Anywhere",
        destination: "The one you set out for",
      },
    ]);
    panel.setPuzzles([
      {
        name: "Survive the journey",
        description: "Emabark on a journey and get to the end",
        executed: false,
      },
    ]);
  }
}


const { get, set, useStore: useUIPanelStore, createFactory } =
  StoreBuilder<UIPanelState>({
    // Default Values for testing
    visible: false,

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
        description: "Emabark on a journey and get to the end",
        executed: false,
      },
    ],

    loading: false,
    loadingE: false,
    loadingP: false,

    // ACTIONS
    show: () => set({ visible: true }),
    hide: () => set({ visible: false }),

    setLocation: (v) => set({ location: v }),
    setExits: (v) => set({ exits: v }),
    setPuzzles: (v) => set({ puzzles: v }),
    setLoading: (v) => set({ loading: v }),
    setLoadingE: (v) => set({ loadingE: v }),
    setLoadingP: (v) => set({ loadingP: v }),
  });

export const getLocation = () => get().location;
const UIPanelStore = createFactory({});

export default UIPanelStore;
export { useUIPanelStore };