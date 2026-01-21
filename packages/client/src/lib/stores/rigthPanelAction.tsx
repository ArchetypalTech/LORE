import { sendCommand } from "@lib/terminalCommands/commandHandler";
import {
  increaseTypewriterSpeed,
  decreaseTypewriterSpeed,
  useTerminalStore,
} from "@lib/stores/terminal.store";

export const RightActionPanel = () => {

  const speed = useTerminalStore(s => s.typewriterSpeedMultiplier);
  const atMax = speed >= 3;
  const atMin = speed <= 0.33;

  const buttons = [
    { label: "Toggle Trailer", onClick: () => sendCommand("_toggleTrailer") },
    { label: "Print Speed −", onClick: decreaseTypewriterSpeed, disabled: atMin },
    { label: `Speed ${speed.toFixed(2)}×`, onClick: () => { }, disabled: true },
    { label: "Print Speed +", onClick: increaseTypewriterSpeed, disabled: atMax },
    { label: "Help", onClick: () => sendCommand("help") },
    { label: "Report Bug", onClick: () => sendCommand("_bugReport") },
    { label: "Wallet", onClick: () => sendCommand("wallet") },
  ];

  return (
    <div className="flex-none w-[100px] flex justify-center items-start">
      <div className="flex flex-col gap-3 p-3
                      bg-black/60 border border-emerald-500/40
                      rounded-2xl shadow-xl text-green-300">
        {buttons.map((btn, idx) => (
          <button
            key={idx}
            onClick={btn.onClick}
            disabled={btn.disabled}
            className={`w-full py-2 text-sm font-medium text-green-300 
            border border-emerald-500/40 rounded-lg
            transition-colors duration-200
            whitespace-normal break-words text-center
            ${btn.disabled
                ? "opacity-40 cursor-not-allowed"
                : "hover:bg-emerald-500/10"
              }`}
          >
            {btn.label}
          </button>
        ))}
      </div>
    </div>
  );
};

export default RightActionPanel;