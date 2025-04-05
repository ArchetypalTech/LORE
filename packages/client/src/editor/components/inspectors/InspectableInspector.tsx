import type { ComponentInspector } from "@/editor/lib/schemas";
import { TextAreaArray, Toggle } from "../FormComponents";
import type { Inspectable } from "@/lib/dojo_bindings/typescript/models.gen";
import { useInspector } from "./useInspector";

export const InspectableInspector: ComponentInspector<Inspectable> = ({
	componentObject,
	componentName,
	handleEdit,
}) => {
	const { handleInputChange, Inspector } = useInspector<Inspectable>({
		componentObject,
		componentName,
		handleEdit,
		inputHandlers: {
			description: (e, updatedObject) => {
				console.log(e.target.value);
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
