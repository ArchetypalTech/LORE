import {
  type DescriptionText
} from "@/lib/dojo_bindings/typescript/models.gen";
import { Input } from "../FormComponents";
import type { ComponentInspector } from "./useInspector";
import { useInspector } from "./useInspector";
import { CollapsibleComponent } from "../CollapsibleComponent";

export const DescriptionTextInspector: ComponentInspector<DescriptionText> = ({
  componentObject,
  ...props
}) => {
  const { handleInputChange, Inspector } = useInspector<DescriptionText>({
    componentObject,
    ...props,
    inputHandlers: {
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

  // const sortedComponents = componentsArray.length > 1 ? [...componentsArray].sort((a, b) => a.key - b.key) : componentsArray
  return (
    <>
      {componentsArray.map((componentObj, idx) => {
        return (
          <CollapsibleComponent
            key={`${componentObj.inst}-${componentObj.key}`}
            title={`Description - Key: ${componentObj.key}`}
          >
            <Inspector index={idx}>
              <Input
                id="description_text"
                value={componentObj.text}
                onChange={handleInputChange(idx)}
              />
            </Inspector>
          </CollapsibleComponent>
        );
      })}
    </>
  );
};
