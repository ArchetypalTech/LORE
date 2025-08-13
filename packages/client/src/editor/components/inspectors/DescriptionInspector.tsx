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
	return (
		<>
			{componentObject.map((componentObj, idx) => {
				return (
					<Inspector index={idx} key={`${componentObj.inst}-${componentObj.key}`}>
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
				);
			})}
		</>
	);
};
