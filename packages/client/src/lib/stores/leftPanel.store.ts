import { create } from "zustand";
import { queryActionsToken, queryClaimableActionsCount } from "@lib/queriesPanel/uiPanelQueries";

type LeftPanelState = {
  visible: boolean;
  disabled: boolean;

  freeActions: number;
  paidActions: number;
  claimableRewards: number;

  refreshBalances: (freeActions: number, paidActions: number) => void;
  refreshClaimableRewards: (claimableRewards: number) => void;
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
  claimableRewards: 0,

  refreshBalances: (freeActions: number, paidActions: number) => set({
    freeActions,
    paidActions
  }),
  refreshClaimableRewards: (claimableRewards: number) => set({ claimableRewards }),
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

// Owner/creator/collaborator rewards accrued from monetization revenue splits
// (docs/Monetization/monetization-revenue-distribution.md), claimable via the
// `claim` terminal command.
export const updateClaimableRewards = async () => {
  const leftPanel = useLeftPanelStore.getState();
  const claimableRewards = await queryClaimableActionsCount();
  leftPanel.refreshClaimableRewards(claimableRewards);
}