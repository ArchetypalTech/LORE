import { ReactNode, useState } from "react";

interface CollapsibleInspectorProps {
  children: ReactNode;
  title: string;
  defaultCollapsed?: boolean;
  style?: React.CSSProperties;
}

export const CollapsibleComponent = ({
  children,
  title,
  defaultCollapsed = false,
  style = { marginBottom: "8px" }
}: CollapsibleInspectorProps) => {
  const [isCollapsed, setIsCollapsed] = useState(defaultCollapsed);

  const toggleCollapse = () => {
    setIsCollapsed(!isCollapsed);
  };

  return (
    <div style={style}>
      <button
        onClick={toggleCollapse}
        aria-expanded={!isCollapsed}
        style={{
          background: "none",
          border: "none",
          cursor: "pointer",
          padding: "4px",
          fontSize: "inherit",
          color: "inherit"
        }}
      >
        {isCollapsed ? "▶" : "▼"} {title}
      </button>

      {!isCollapsed && (
        <div>
          {children}
        </div>
      )}
    </div>
  );
};
