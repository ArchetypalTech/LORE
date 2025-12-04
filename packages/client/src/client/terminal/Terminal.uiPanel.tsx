import { 
  queryPlayerLocationPerGame,
  queryExitsPerGame,
} from "../../lib/queriesPanel/uiPanelQueries";
import { useUIPanelStore } from "../../lib/stores/terminal.uiPanel.store";



/**
 * Fetches the current player's location for a given gameId
 * and updates the UIPanel store.
 * @param gameId The game ID to query
 */
export const queryPanelInfo = async (gameId: bigint) => {
  if (!gameId) return;
  const store = useUIPanelStore.getState();
  store.setLoading(true);

  try {
    const [location_name, location_inst] = await queryPlayerLocationPerGame(gameId);
    if (!location_name) return;
    const exits = await queryExitsPerGame(gameId, location_inst!);
    console.log("DEBUG: queryPanelInfo() exits: ", exits);

    // update the store directly
    useUIPanelStore.getState().setLocation(location_name);
    if (exits) {
      useUIPanelStore.getState().setExits(exits);
    }    
  } catch (err) {
    console.error("Failed to query panel info:", err);
  } finally {
    store.setLoading(false);
  }
};

// --- UIPanel component ---
export default function UIPanel() {
  const { location, exits, puzzles, loading } = useUIPanelStore((s) => s);

  return (
    <div className="ui-panel w-full p-4">
      <div className="backdrop-blur-md bg-black/60 rounded-2xl border border-emerald-500/40 shadow-xl p-4 text-green-300 font-primary">
        <div className="grid grid-cols-3 gap-4">

          {/* Location */}
          <div>
            <h3 className="text-amber-300 font-bold mb-1">Location</h3>
            <p className="text-sm">
              {loading ? <span className="italic">Updating...</span> : location || "Unknown"}
            </p>
          </div>

          {/* Exits */}
          <div>
            <h3 className="text-amber-300 font-bold mb-1">Exits</h3>
            <ul className="space-y-1 text-sm">
              {loading ? (
                <li className="text-sm italic text-green-200">Updating...</li>
              ) : exits.length > 0 ? (
                exits.map((e) => (
                  <li key={e.id} className="border-b border-emerald-600/30 pb-1">
                    <span className="text-green-200">{e.name}</span>
                    {" — "}
                    <span className="text-amber-300">{e.direction}</span>
                    {" → "}
                    <span className="text-green-400">{e.destination}</span>
                  </li>
                ))
              ) : (
                <li className="text-sm italic text-green-200">No exits</li>
              )}
            </ul>
          </div>

          {/* Puzzles */}
          <div>
            <h3 className="text-amber-300 font-bold mb-1">Puzzles</h3>
            <ul className="space-y-1 text-sm">
              {loading ? (
                <li className="text-sm italic text-green-200">Updating...</li>
              ) : puzzles.length > 0 ? (
                puzzles.map((e) => (
                  <li key={e.name} className="border-b border-emerald-600/30 pb-1">
                    {e.name}
                  </li>
                ))
              ) : (
                <li className="text-sm italic text-green-200">No puzzles</li>
              )}
            </ul>
          </div>

        </div>
      </div>
    </div>
  );
}