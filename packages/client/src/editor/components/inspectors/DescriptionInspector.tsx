import { useState } from "react";
import {
	type DescriptionText
} from "@/lib/dojo_bindings/typescript/models.gen";
import { Input } from "../FormComponents";
import type { ComponentInspector } from "./useInspector";
import { useInspector } from "./useInspector";

export const DescriptionTextInspector: ComponentInspector<DescriptionText> = ({
	componentObject,
	...props
}) => {
	const { handleInputChange, Inspector } = useInspector<DescriptionText>({
		componentObject,
		...props,
		inputHandlers: {
      description_inst: (e, updatedObject) => {
        updatedObject.inst = Number(e.target.value);
      },
			description_key: (e, updatedObject) => {
				updatedObject.key = Number(e.target.value);
			},
			description_text: (e, updatedObject) => {
				updatedObject.text = e.target.value as unknown as string;
			},
    },
  });

	if (!componentObject) return <div>Description not found</div>;

	// console.log(componentObject);

	// Ensure componentObject is always an array
	  const componentsArray = Array.isArray(componentObject)
    ? componentObject
    : [componentObject];

  // Track which items are collapsed
  const [collapsedIndices, setCollapsedIndices] = useState<Set<number>>(new Set());

  const toggleCollapse = (idx: number) => {
    const newSet = new Set(collapsedIndices);
    if (collapsedIndices.has(idx)) newSet.delete(idx);
    else newSet.add(idx);
    setCollapsedIndices(newSet);
  };

  return (
    <>
      {componentsArray.map((componentObj, idx) => {
        const isCollapsed = collapsedIndices.has(idx);
        return (
          <div key={`${componentObj.inst}-${componentObj.key}`} style={{ marginBottom: "8px" }}>
            <button onClick={() => toggleCollapse(idx)}>
              {isCollapsed ? "▶" : "▼"} Description {componentObj.key}
            </button>

            {!isCollapsed && (
              <Inspector index={idx}>
                <Input
                  id="description_inst"
                  value={componentObj.inst.toString()}
                  onChange={handleInputChange(idx)}
                  readOnly={true}
                />
                <Input
                  id="description_key"
                  value={componentObj.key}
                  onChange={handleInputChange(idx)}
                />
                <Input
                  id="description_text"
                  value={componentObj.text}
                  onChange={handleInputChange(idx)}
                />
              </Inspector>
            )}
          </div>
        );
      })}
    </>
  );
};
