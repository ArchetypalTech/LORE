import { useLeftPanelStore } from "@/lib/stores/leftPanel.store";
import { ActionShaft } from "../utils/actionShaft";

export const LeftActionPanel = () => {
  const actions = useLeftPanelStore(s => s.actions);

  const shafts: number[] = [];
  let remaining = actions;

  while (remaining > 0) {
    shafts.push(remaining);
    remaining -= 20;
  }

  if (shafts.length === 0) shafts.push(0);

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

      <div className="flex flex-col gap-4">
        {shafts.map((value, i) => (
          <ActionShaft
            key={i}
            value={value}
            isLast={i === shafts.length - 1}
          />
        ))}
      </div>
    </div>
  );
};