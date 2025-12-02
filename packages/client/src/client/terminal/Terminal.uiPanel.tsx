import { useEffect } from "react";
import { useCurrentGameId } from "../../lib/stores/game.store"; 
import { queryPlayerLocationPerGame } from "../../editor/data/editor.data";
import { useUIPanelStore } from "../../lib/stores/terminal.uiPanel.store";

export default function UIPanel() {
  const { location, exits, puzzles, setLocation } = useUIPanelStore();
  const gameId = useCurrentGameId();

  useEffect(() => {
    if (!gameId) return;

    const fetchLocation = async () => {
      try {
        const loc = await queryPlayerLocationPerGame(BigInt(gameId));
        if (loc) {
          setLocation(loc);
        }
      } catch (err) {
        console.error("Failed to fetch player location:", err);
      }
    };

    fetchLocation();
  }, [gameId, setLocation]);

  return (
    <div className="ui-panel w-full p-4">
      <div className="backdrop-blur-md bg-black/60 rounded-2xl border border-emerald-500/40 shadow-xl p-4 text-green-300 font-primary">
        <div className="grid grid-cols-3 gap-4">
          
          <div>
            <h3 className="text-amber-300 font-bold mb-1">Location</h3>
            <p className="text-sm">{location || "Loading..."}</p>
          </div>

          <div>
            <h3 className="text-amber-300 font-bold mb-1">Exits</h3>
            <ul className="space-y-1 text-sm">
              {exits.map((e) => (
                <li key={e.id} className="border-b border-emerald-600/30 pb-1">
                  <span className="text-green-200">{e.name}</span>
                  {" — "}
                  <span className="text-amber-300">{e.direction}</span>
                  {" → "}
                  <span className="text-green-400">{e.destination}</span>
                </li>
              ))}
            </ul>
          </div>

          <div>
            <h3 className="text-amber-300 font-bold mb-1">Puzzles</h3>
            <ul className="space-y-1 text-sm">
              {puzzles.map((puzzle, idx) => (
                <li key={idx} className="border-b border-emerald-600/30 pb-1">
                  {puzzle}
                </li>
              ))}
            </ul>
          </div>

        </div>
      </div>
    </div>
  );
}