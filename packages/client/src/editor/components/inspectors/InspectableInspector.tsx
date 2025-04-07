import type { Inspectable } from "@/lib/dojo_bindings/typescript/models.gen";
import { TextAreaArray, Toggle } from "../FormComponents";
import type { ComponentInspector } from "./useInspector";
import { useInspector } from "./useInspector";

export const InspectableInspector: ComponentInspector<Inspectable> = ({
	componentObject,
	...props
}) => {
	const { handleInputChange, Inspector } = useInspector<Inspectable>({
		componentObject,
		...props,
		inputHandlers: {
			description: (e, updatedObject) => {
				updatedObject.description = e.target.value as unknown as string[];
			},
			is_visible: (e, updatedObject) => {
				updatedObject.is_visible = e.target.checked;
			},
		},
	});

	if (!componentObject) return <div>Inspectable not found</div>;

	return (
		<Inspector>
			<TextAreaArray
				id="description"
				value={componentObject.description}
				onChange={handleInputChange}
				rows={1}
			/>
			<Toggle
				id="is_visible"
				value={componentObject.is_visible}
				onChange={handleInputChange}
			/>
		</Inspector>
	);
};
