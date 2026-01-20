import { sendCommand } from "@lib/terminalCommands/commandHandler";
import GameStore from "@/lib/stores/game.store";
import { queryPanelInfo } from "@/client/terminal/Terminal.uiPanel";

export const RightActionPanel = () => {

  const getGameID = (): bigint | undefined => {
    const gameId = GameStore().gameId;
    if (!gameId) return undefined;
    return BigInt(gameId);
  };

  const handleUpdatePanel = async () => {
    const gameId = getGameID();
    if (!gameId) return;
    await queryPanelInfo(gameId);
  };

  const Testing = () => {
    console.log("TESTING");
  };

  const buttons = [
    { label: "Update Info Panel", onClick: handleUpdatePanel },
    { label: "Toggle Trailer", onClick: () => sendCommand("_toggleTrailer") },
    { label: "Toggle Printing Speed", onClick: () => Testing },
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
            className="w-full py-2 text-sm font-medium text-green-300 
                      border border-emerald-500/40 rounded-lg
                      hover:bg-emerald-500/10 transition-colors duration-200
                      whitespace-normal break-words text-center"
          >
            {btn.label}
          </button>
        ))}
      </div>
    </div>
  );
};

export default RightActionPanel;