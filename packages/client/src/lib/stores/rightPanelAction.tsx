import { useState } from "react";
import { Settings } from "lucide-react";
import { sendCommand } from "@lib/terminalCommands/commandHandler";
import {
  increaseTypewriterSpeed,
  decreaseTypewriterSpeed,
  useTerminalStore,
} from "@lib/stores/terminal.store";

const panelClass =
  "flex flex-col gap-3 p-3 bg-black/60 border border-emerald-500/40 rounded-2xl shadow-xl text-green-300 w-[100px]";

const btnClass = (disabled?: boolean, active?: boolean) =>
  `w-full py-2 text-sm font-medium text-green-300
  border border-emerald-500/40 rounded-lg
  transition-colors duration-200
  whitespace-normal break-words text-center
  ${disabled
    ? "opacity-40 cursor-not-allowed"
    : active
    ? "bg-emerald-500/20"
    : "hover:bg-emerald-500/10"
  }`;

export const RightActionPanel = () => {
  const [settingsOpen, setSettingsOpen] = useState(false);
  const speed = useTerminalStore(s => s.typewriterSpeedMultiplier);
  const atMax = speed >= 3;
  const atMin = speed <= 0.33;

  return (
    <div className="flex items-start gap-2">
      {/* Settings subpanel */}
      {settingsOpen && (
        <div className={panelClass}>
          <button onClick={() => sendCommand("_toggleTrailer")} className={btnClass()}>
            Toggle Trailer
          </button>
          <button onClick={decreaseTypewriterSpeed} disabled={atMin} className={btnClass(atMin)}>
            Print Speed −
          </button>
          <button disabled className={btnClass(true)}>
            Speed {speed.toFixed(2)}×
          </button>
          <button onClick={increaseTypewriterSpeed} disabled={atMax} className={btnClass(atMax)}>
            Print Speed +
          </button>
          <button onClick={() => sendCommand("help")} className={btnClass()}>
            Help
          </button>
          <button onClick={() => sendCommand("_bugReport")} className={btnClass()}>
            Report Bug
          </button>
        </div>
      )}

      {/* Main panel */}
      <div className={panelClass}>
        <button onClick={() => sendCommand("wallet")} className={btnClass()}>
          Wallet
        </button>
        <button
          onClick={() => setSettingsOpen(o => !o)}
          className={btnClass(false, settingsOpen)}
        >
          <Settings size={16} className="mx-auto" />
        </button>
      </div>
    </div>
  );
};

export default RightActionPanel;
