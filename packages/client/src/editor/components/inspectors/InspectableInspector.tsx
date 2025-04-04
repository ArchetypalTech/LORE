import type { ComponentInspector } from "@/editor/lib/schemas";
import type { ChangeEvent } from "react";
import { TextAreaArray, Toggle } from "../FormComponents";
import type { Inspectable } from "@/lib/dojo_bindings/typescript/models.gen";
import { useInspector } from "./useInspector";

export const InspectableInspector: ComponentInspector<Inspectable> = ({
	componentObject,
	componentName,
}) => {
	const { handleInputChange } = useInspector<Inspectable>({
		componentObject,
		componentName,
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
		<div className="flex flex-col gap-2">
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
		</div>
	);
};
