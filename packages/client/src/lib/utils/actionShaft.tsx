import "../../styles/actionShaft.css";

const BASE_CAP = 20;
const SHAFT_HEIGHT = 120;
const CART_HEIGHT = 20;

type Props = {
  actions: number;
};

export const ActionShaft = ({ actions }: Props) => {
  const base = Math.min(actions, BASE_CAP);
  const overflow = Math.max(actions - BASE_CAP, 0);

  const progress = base / BASE_CAP;
  const translateY =
    (1 - progress) * (SHAFT_HEIGHT - CART_HEIGHT);

  const low = base > 0 && base <= 5;
  const overflowActive = overflow > 0;

  return (
    <div className="flex flex-col items-center gap-1">
      <div
        className={`
          relative w-[32px] overflow-hidden rounded-lg
          bg-black/60 border
          ${low ? "border-amber-400/60" : "border-emerald-500/40"}
        `}
        style={{ height: SHAFT_HEIGHT }}
      >
        {/* Track lines */}
        <div className="absolute inset-0 flex flex-col justify-between opacity-20">
          {[...Array(6)].map((_, i) => (
            <div key={i} className="h-px bg-emerald-500/40" />
          ))}
        </div>

        {/* Cart */}
        <div
          className={`
            absolute left-1 right-1
            rounded-md border
            transition-transform duration-500 ease-out
            ${low
              ? "bg-amber-500/30 border-amber-400"
              : "bg-emerald-500/30 border-emerald-400"}
            ${low ? "cart-low-pulse" : ""}
            ${overflowActive ? "cart-overflow-glow" : ""}
          `}
          style={{
            height: CART_HEIGHT,
            transform: `translateY(${translateY}px)`,
          }}
        />
      </div>

      <span className="text-[10px] text-green-300 opacity-70">
        {base}/{BASE_CAP}
        {overflow > 0 && (
          <span className="text-emerald-400"> +{overflow}</span>
        )}
      </span>
    </div>
  );
};