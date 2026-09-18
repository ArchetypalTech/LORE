import { useLeftPanelStore } from "@/lib/stores/leftPanel.store";
import { ActionShaft } from "../utils/actionShaft";

export const LeftActionPanel = () => {
  const freeActions = useLeftPanelStore(s => s.freeActions);
  const paidActions = useLeftPanelStore(s => s.paidActions);
  const claimableRewards = useLeftPanelStore(s => s.claimableRewards);

  return (
    <div
      className="
        flex flex-col items-center gap-4 p-3
        bg-black/60 border border-emerald-500/40
        rounded-2xl shadow-xl
        text-green-300
      "
    >
      <p className="text-xs tracking-widest opacity-80">
        ACTIONS
      </p>

      {/* Free Actions */}
      <div className="flex flex-col items-center gap-1">
        <span className="text-[10px] opacity-60">FREE</span>
        <ActionShaft value={freeActions} max={5} />
      </div>

      {/* Token Actions */}
      <div className="flex flex-col items-center gap-1">
        <span className="text-[10px] opacity-60">TOKEN</span>
        <ActionShaft value={paidActions} max={20} />
      </div>

      {/* Claimable Rewards (owner/creator/collaborator revenue) */}
      {claimableRewards > 0 && (
        <div className="flex flex-col items-center gap-1">
          <span className="text-[10px] opacity-60">REWARDS</span>
          <span className="text-sm font-semibold">
            {claimableRewards} claimable
          </span>
        </div>
      )}
    </div>
  );
};