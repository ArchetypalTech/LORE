import "../../styles/actionShaft.css";

type Props = {
  value: number;
  max: number;
  height?: number;
  cartHeight?: number;
};

export const ActionShaft = ({
  value,
  max,
  height = 120,
  cartHeight = 20,
}: Props) => {
  const safeValue = Math.max(0, value);

  const base = Math.min(safeValue, max);
  const overflow = Math.max(safeValue - max, 0);

  const progress = base / max;
  const translateY =
    (1 - progress) * (height - cartHeight);

  const isEmpty = base === 0;
  const isLow = base > 0 && base <= Math.ceil(max * 0.25);
  const overflowActive = overflow > 0;

  const displayValue = overflowActive ? safeValue : base;
  const displayMax = overflowActive ? safeValue : max;

  return (
    <div className="flex flex-col items-center gap-1">
      <div
        className={`
          relative w-[32px] overflow-hidden rounded-lg
          bg-black/60 border
          ${isEmpty
            ? "border-red-500/70 border-empty-pulse"
            : isLow
            ? "border-amber-400/70 border-low-pulse"
            : "border-emerald-500/40"}
        `}
        style={{ height }}
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
            ${isEmpty
              ? "bg-red-500/20 border-red-400"
              : isLow
              ? "bg-amber-500/30 border-amber-400"
              : "bg-emerald-500/30 border-emerald-400"}
            ${isLow ? "cart-low-pulse" : ""}
            ${overflowActive ? "cart-overflow-glow" : ""}
          `}
          style={{
            height: cartHeight,
            transform: `translateY(${translateY}px)`,
          }}
        />
      </div>

      <span className="text-[10px] text-green-300 opacity-70">
        {displayValue}/{displayMax}
      </span>
    </div>
  );
};