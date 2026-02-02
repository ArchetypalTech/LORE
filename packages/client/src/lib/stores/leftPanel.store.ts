import { create } from "zustand";

type LeftPanelState = {
  visible: boolean;
  disabled: boolean;
  actions: number;
  lastChange: "consume" | "gain" | null;

  toggle: () => void;
  show: () => void;
  hide: () => void;

  consumeAction: () => void;
  consume6Actions: () => void;
  gain5Actions: () => void;
  gain1Actions: () => void;
  disable: () => void;
  enable: () => void;
};

export const useLeftPanelStore = create<LeftPanelState>((set, get) => ({
  visible: false,
  disabled: false,
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
  consume6Actions: () =>
    set(s => ({
      actions: Math.max(0, s.actions - 6),
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
  disable: () =>
    set({disabled: true}),
  enable: () =>
    set({disabled: false}),
}));