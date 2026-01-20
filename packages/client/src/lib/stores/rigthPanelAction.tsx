import { sendCommand } from "@lib/terminalCommands/commandHandler";
import GameStore from "@/lib/stores/game.store";
import { queryPanelInfo } from "@/client/terminal/Terminal.uiPanel";

export const RightActionPanel = ({ horizontal }: { horizontal?: boolean }) => {
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

  return (
    <div className={`flex ${horizontal ? "flex-row" : "flex-col"} gap-3`}>
      <button className="btn-action" onClick={handleUpdatePanel}>Update Info Panel</button>
      <button className="btn-action" onClick={() => sendCommand("_toggleTrailer")}>Toggle Trailer</button>
      <button className="btn-action" onClick={() => sendCommand("help")}>Help</button>
      <button className="btn-action" onClick={() => sendCommand("_bugReport")}>Report Bug</button>
    </div>
  );
};