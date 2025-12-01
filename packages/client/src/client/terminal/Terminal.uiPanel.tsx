

interface UIBoxProps {
  location: string;
  exits: { id: number; name: string; direction: string; destination: string }[];
  puzzles: string[];
}


/**
* UI.Panel — a floating panel that overlays the Terminal.
* It auto-expands but never goes smaller than Terminal width.
*/
export default function UIPanel({ location, exits, puzzles }: UIBoxProps) {
  return (
    <div className="ui-panel w-full max-w-[900px] mx-auto mt-4 p-4">
      <div className="backdrop-blur-md bg-black/60 rounded-2xl border border-emerald-500/40 shadow-xl p-4 text-green-300 font-primary">
        <div className="grid grid-cols-3 gap-4">
          {/* Location */}
          <div>
            <h3 className="text-amber-300 font-bold mb-1">Location</h3>
            <p className="text-sm">{location}</p>
          </div>


          {/* Exits */}
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


          {/* Puzzles */}
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