import { useEffect, useState, useRef } from "react";
import { 
  queryPlayerLocationPerGame,
  queryExitsPerGame,
  queryPuzzlesPerGame,
} from "../../lib/queriesPanel/uiPanelQueries";
import { Tooltip } from "../../lib/queriesPanel/tooltip";
import { useUIPanelStore } from "../../lib/stores/terminal.uiPanel.store";
import { Check, HelpCircle } from "lucide-react";


const spinner = ["▌","▀", "▐","▄"]

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
    // 1. Get the player's location
    const [location_name, location_inst, _playerInst] = await queryPlayerLocationPerGame(gameId);
    if (!location_name) return;
    
    // 2. Get the location's exits
    const exits = await queryExitsPerGame(gameId, location_inst!);
    // console.log("DEBUG: queryPanelInfo() exits: ", exits);
    
    // 3. Get the location's puzzles
    const puzzles = await queryPuzzlesPerGame(gameId, location_inst!);
    // console.log("DEBUG: queryPanelInfo() puzzles: ", puzzles);

    // 4. Update the store directly
    store.setLocation(location_name);
    if (exits) {
      store.setExits(exits);
    }
    if (puzzles) {
      store.setPuzzles(puzzles);
    }
  } catch (err) {
    console.error("Failed to query panel info:", err);
  } finally {
    store.setLoading(false);
  }
};

export const queryExitsInfo = async (gameId: bigint, locationInst: bigint) => {
  if (!gameId) return;
  const store = useUIPanelStore.getState();
  store.setLoadingE(true);

  try {
    // 1. Get the exits
    const exits = await queryExitsPerGame(gameId, locationInst);
    // console.log("DEBUG: queryExitsInfo() exits: ", exits);
    
    // 2. Update the store directly
    if (exits) {
      store.setExits(exits);
    }
  } catch (err) {
    console.error("Failed to query panel info:", err);
  } finally {
    store.setLoadingE(false);
  }
};

export const queryPuzzlesInfo = async (gameId: bigint, locationInst: bigint) => {
  if (!gameId) return;
  const store = useUIPanelStore.getState();
  store.setLoadingP(true);

  try {
    // 1. Get the puzzles
    const puzzles = await queryPuzzlesPerGame(gameId, locationInst);
    // console.log("DEBUG: queryPuzzlesInfo() puzzles: ", puzzles);
    
    // 2. Update the store directly
    if (puzzles) {
      store.setPuzzles(puzzles);
    }
  } catch (err) {
    console.error("Failed to query panel info:", err);
  } finally {
    store.setLoadingP(false);
  }
};

function PuzzleIconWithTooltip({
  executed,
  description,
}: {
  executed: boolean | undefined;
  description: string;
}) {
  const iconRef = useRef<HTMLSpanElement>(null);
  const [open, setOpen] = useState(false);

  return (
    <>
      <span
        ref={iconRef}
        tabIndex={0}
        className="ml-2"
        onMouseEnter={() => setOpen(true)}
        onMouseLeave={() => setOpen(false)}
        onFocus={() => setOpen(true)}
        onBlur={() => setOpen(false)}
      >
        {executed ? (
          <Check className="w-4 h-4 text-green-400 cursor-help" />
        ) : (
          <HelpCircle className="w-4 h-4 text-yellow-400 cursor-help" />
        )}
      </span>

      {open && (
        <Tooltip targetRef={iconRef}>
          {description}
        </Tooltip>
      )}
    </>
  );
}

// --- UIPanel component ---
export default function UIPanel() {
  const { location, exits, puzzles, loading, loadingE, loadingP } = useUIPanelStore((s) => s);
  let [tick, setTick] = useState(0)
  useEffect(() => {
      let interval = setInterval(() => setTick((prev) => prev += 1), 200);
      return () => clearInterval(interval)
    }, [])
  return (
    <div className="ui-panel w-full p-4 h-full">
      <div className="backdrop-blur-md bg-black/60 rounded-2xl border border-emerald-500/40 shadow-xl p-4 text-green-300 font-primary h-full flex flex-col">

        {/* Sticky Header */}
        <div className="grid grid-cols-[1fr_1.2fr_1.8fr] gap-4 sticky top-0 bg-black/60 backdrop-blur-md py-1 z-20 border-b border-emerald-500/30 items-center">
          <h3 className="text-amber-300 font-bold text-base">Current Location</h3>
          <h3 className="text-amber-300 font-bold text-base">Exits</h3>
          <h3 className="text-amber-300 font-bold text-base">Puzzles</h3>
        </div>

        {/* Scrollable Content */}
        <div className="grid grid-cols-[1fr_1.2fr_1.8fr] gap-4 overflow-y-auto mt-3 pr-2 no-scrollbar">
          
          {/* Location */}
          <div>
            <p className="text-sm">
              {loading ? (
                <span className="flex items-center gap-2 italic">
                  Updating...
                  <span>{spinner[tick % spinner.length]}</span>
                </span>
              ) : (
                location || "Unknown"
              )}
            </p>
          </div>

          {/* Exits */}
          <div>
            <ul className="space-y-1 text-sm">
              {loading || loadingE ? (
                <li className="flex items-center gap-2 italic text-green-200">
                  Updating...
                  <span>{spinner[tick % spinner.length]}</span>
                </li>
              ) : exits.length > 0 ? (
                exits.map((e) => (
                  <li
                    key={e.id}
                    className="border-b border-emerald-600/30 pb-1"
                  >
                    <span className="text-green-200">{e.name}</span>{" — "}
                    <span className="text-amber-300">{e.direction}</span>{" → "}
                    <span className="text-green-400">{e.destination}</span>
                  </li>
                ))
              ) : (
                <li className="italic text-green-200">No exits</li>
              )}
            </ul>
          </div>

          {/* Puzzles */}
          <div>
            <ul className={
              puzzles.length > 3
                ? "grid grid-cols-2 gap-2 text-sm"
                : "text-sm"
            }>
              {loading || loadingP ? (
                <li className="flex items-center gap-2 italic text-green-200">
                  Updating...
                  <span>{spinner[tick % spinner.length]}</span>
                </li>
              ) : puzzles.length > 0 ? (
                puzzles.map((p) => (
                  <li
                    key={p.name}
                    className="flex items-center justify-between border-b border-emerald-600/30 pb-1"
                  >
                    <span>{p.name}</span>

                    <PuzzleIconWithTooltip
                      executed={p.executed}
                      description={p.description}
                    />
                  </li>
                ))
              ) : (
                <li className="italic text-green-200">No puzzles</li>
              )}
            </ul>
          </div>

        </div>
      </div>
    </div>
  );
}