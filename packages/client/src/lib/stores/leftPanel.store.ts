import { create } from "zustand";

type LeftPanelState = {
  visible: boolean;
  actions: number;
  lastChange: "consume" | "gain" | null;

  toggle: () => void;
  show: () => void;
  hide: () => void;

  consumeAction: () => void;
  gain5Actions: () => void;
  gain1Actions: () => void;
};

export const useLeftPanelStore = create<LeftPanelState>((set, get) => ({
  visible: true,
  actions: 20,
  lastChange: null,

  toggle: () => set(s => ({ visible: !s.visible })),
  show: () => set({ visible: true }),
  hide: () => set({ visible: false }),

  consumeAction: () =>
    set(s => ({
      actions: Math.max(0, s.actions - 1),
      lastChange: "consume",
    })),

  gain5Actions: () =>
    set(s => ({
      actions: s.actions + 5,
      lastChange: "gain",
    })),
  gain1Actions: () =>
    set(s => ({
      actions: s.actions + 1,
      lastChange: "gain",
    })),
}));