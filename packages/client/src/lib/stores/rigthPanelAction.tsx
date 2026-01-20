import { sendCommand } from "@lib/terminalCommands/commandHandler";
import GameStore from "@/lib/stores/game.store";
import { queryPanelInfo } from "@/client/terminal/Terminal.uiPanel";

export const RightActionPanel = () => {

  // Helper to safely get game ID as bigint | undefined
  const getGameID = (): bigint | undefined => {
    const gameId = GameStore().gameId;
    if (!gameId) return undefined;
    return BigInt(gameId);
  };

  // Handler for "Update Info Panel"
  const handleUpdatePanel = async () => {
    const gameId = getGameID();
    if (!gameId) return; // no game, do nothing
    await queryPanelInfo(gameId); // call async query
  };

  return (
    <div className="flex-none w-[80px] h-full flex justify-center items-start">
      <div className="flex flex-col gap-3 p-4 w-full
                      bg-black/60 border border-emerald-500/40
                      rounded-2xl shadow-xl text-green-300">
        {/* Buttons container */}
        {[
          { label: "Update Info Panel", onClick: handleUpdatePanel },
          { label: "Toggle Trailer", onClick: () => sendCommand("_toggleTrailer") },
          { label: "Help", onClick: () => sendCommand("help") },
          { label: "Report Bug", onClick: () => sendCommand("_bugReport") },
        ].map((btn, idx) => (
          <button
            key={idx}
            onClick={btn.onClick}
            className="w-full py-2 text-sm font-medium text-green-300 
                      border border-emerald-500/40 rounded-lg
                      hover:bg-emerald-500/10 transition-colors duration-200"
          >
            {btn.label}
          </button>
        ))}
      </div>
    </div>
  );
};

export default RightActionPanel;