import "../../styles/actionShaft.css";

const ACTIONS_PER_SHAFT = 20;
const SHAFT_HEIGHT = 120;
const CART_HEIGHT = 20;

type Props = {
  value: number;
  isLast: boolean;
};

export const ActionShaft = ({ value, isLast }: Props) => {
  const clamped = Math.max(0, Math.min(value, ACTIONS_PER_SHAFT));
  const progress = clamped / ACTIONS_PER_SHAFT;

  const translateY =
    (1 - progress) * (SHAFT_HEIGHT - CART_HEIGHT);

  const low = clamped <= 5;
  const empty = clamped === 0;

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
              ? "bg-amber-500/30 border-amber-400 shadow-amber-400/60"
              : "bg-emerald-500/30 border-emerald-400 shadow-emerald-400/60"}
            ${empty && isLast ? "cart-shake" : ""}
          `}
          style={{
            height: CART_HEIGHT,
            transform: `translateY(${translateY}px)`,
          }}
        />
      </div>

      <span className="text-[10px] text-green-300 opacity-70">
        {clamped}/{ACTIONS_PER_SHAFT}
      </span>
    </div>
  );
};