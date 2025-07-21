import {
	type DescriptionText
} from "@/lib/dojo_bindings/typescript/models.gen";
import { Input } from "../FormComponents";
import type { ComponentInspector } from "./useInspector";
import { useInspector } from "./useInspector";
import { BigNumberish } from "starknet";

export const DescriptionTextInspector: ComponentInspector<(DescriptionText)> = ({
	componentObject,
	...props
}) => {
	const { handleInputChange, Inspector } = useInspector<(DescriptionText)>({
		componentObject,
		...props,
		inputHandlers: {
      description_inst: (e, updatedObject) => {
        updatedObject.key = e.target.value as unknown as BigNumberish;
      },
			description_key: (e, updatedObject) => {
				updatedObject.key = e.target.value as unknown as BigNumberish;
			},
			description_text: (e, updatedObject) => {
				updatedObject.text = e.target.value as unknown as string;
			},
    },
  });

  if (!componentObject) return <div>Description not found</div>;
  
  return (
    <Inspector>
      <Input
        id="description_inst"
        value={componentObject.inst.toString()}
        onChange={handleInputChange}
        readOnly={true}
      />
      <Input
        id="description_key"
        value={componentObject.key.toString()}
        onChange={handleInputChange}
      />
      <Input
        id="description_text"
        value={componentObject.text}
        onChange={handleInputChange}
      />
    </Inspector>
)};