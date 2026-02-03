import { createPortal } from "react-dom";
import { useEffect, useState } from "react";

export function Tooltip({
  targetRef,
  children,
}: {
  targetRef: React.RefObject<HTMLElement>;
  children: React.ReactNode;
}) {
  const [style, setStyle] = useState<React.CSSProperties | null>(null);

  useEffect(() => {
    if (!targetRef.current) return;

    const rect = targetRef.current.getBoundingClientRect();
    const padding = 8;
    const tooltipWidth = 220;
    const tooltipHeight = 40;

    let top = rect.top - padding;
    let left = rect.left + rect.width / 2;

    // 🔼 Flip below if not enough space above
    if (rect.top < tooltipHeight + padding) {
      top = rect.bottom + padding;
    }

    // ⬅️➡️ Clamp horizontally to viewport
    left = Math.max(
      tooltipWidth / 2 + padding,
      Math.min(window.innerWidth - tooltipWidth / 2 - padding, left)
    );

    setStyle({
      top,
      left,
      transform: "translate(-50%, -100%)",
    });
  }, [targetRef]);

  if (!style) return null;

  return createPortal(
    <div
      className="
        fixed z-[9999]
        max-w-[220px]
        rounded bg-emerald-900 px-2 py-1
        text-xs text-green-100 shadow-lg
        pointer-events-none
        transition-opacity duration-150
      "
      style={style}
    >
      {children}
    </div>,
    document.body
  );
}