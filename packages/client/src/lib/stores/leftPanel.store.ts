import { create } from "zustand";
import { queryActionsToken } from "@lib/queriesPanel/uiPanelQueries";

type LeftPanelState = {
  visible: boolean;
  disabled: boolean;

  freeActions: number;
  paidActions: number;

  refreshBalances: () => Promise<void>;

  toggle: () => void;
  show: () => void;
  hide: () => void;
  disable: () => void;
  enable: () => void;
};

export const useLeftPanelStore = create<LeftPanelState>((set) => ({
  visible: false,
  disabled: false,

  freeActions: 0,
  paidActions: 0,

  refreshBalances: async () => {
    const balances = await queryActionsToken();
    if (!balances) return;

    set({
      freeActions: Number(balances.free_actions_balance ?? 0),
      paidActions: Number(balances.paid_actions_balance ?? 0),
    });
  },

  toggle: () => set(s => ({ visible: !s.visible })),
  show: () => set({ visible: true }),
  hide: () => set({ visible: false }),
  disable: () => set({ disabled: true }),
  enable: () => set({ disabled: false }),
}));