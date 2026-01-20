import { sendCommand } from "@lib/terminalCommands/commandHandler";
import GameStore from "@/lib/stores/game.store";
import { queryPanelInfo } from "@/client/terminal/Terminal.uiPanel";

const RightActionPanel = () => {

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
        {/* Button 1 — Update Info Panel */}
        <button
          className="btn-action"
          onClick={handleUpdatePanel}
        >
          Update Info Panel
        </button>

        {/* Button 2 — Toggle trailer */}
        <button
          className="btn-action"
          onClick={() => sendCommand("_toggleTrailer")}
        >
          Toggle Trailer
        </button>

        {/* Button 3 — Help */}
        <button
          className="btn-action"
          onClick={() => sendCommand("help")}
        >
          Help
        </button>

        {/* Button 4 — Report Bug */}
        <button
          className="btn-action"
          onClick={() => sendCommand("_bugReport")}
        >
          Report Bug
        </button>
      </div>
    </div>
  );
};

export default RightActionPanel;