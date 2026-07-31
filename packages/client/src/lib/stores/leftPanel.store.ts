import { create } from "zustand";
import { queryActionsToken } from "@lib/queriesPanel/uiPanelQueries";

type LeftPanelState = {
  visible: boolean;
  disabled: boolean;

  freeActions: number;
  paidActions: number;

  refreshBalances: (freeActions: number, paidActions: number) => void;
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

  refreshBalances: (freeActions: number, paidActions: number) => set({
    freeActions,
    paidActions
  }),
  toggle: () => set(s => ({ visible: !s.visible })),
  show: () => set({ visible: true }),
  hide: () => set({ visible: false }),
  disable: () => set({ disabled: true }),
  enable: () => set({ disabled: false }),
}));

export const updateBalances = async () => {
  const leftPanel = useLeftPanelStore.getState();
  const balances = await queryActionsToken();
  if (!balances) return;

  leftPanel.refreshBalances(
    Number(balances.free_actions_balance ?? 0),
    Number(balances.paid_actions_balance ?? 0)
  );
}