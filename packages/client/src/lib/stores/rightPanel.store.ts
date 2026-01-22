import { create } from "zustand";

export const useRightPanelStore = create<{
  visible: boolean;
  toggle: () => void;
  show: () => void;
  hide: () => void;
}>(set => ({
  visible: false,
  toggle: () => set(s => ({ visible: !s.visible })),
  show: () => set({ visible: true }),
  hide: () => set({ visible: false }),
}));