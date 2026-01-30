import { useLeftPanelStore } from "@/lib/stores/leftPanel.store";
import { ActionShaft } from "../utils/actionShaft";

export const LeftActionPanel = () => {
  const actions = useLeftPanelStore(s => s.actions);

  return (
    <div
      className="
        flex flex-col items-center gap-3 p-3
        bg-black/60 border border-emerald-500/40
        rounded-2xl shadow-xl
        text-green-300
      "
    >
      <p className="text-xs tracking-widest opacity-80">
        ACTIONS
      </p>

      <ActionShaft actions={actions} />
    </div>
  );
};