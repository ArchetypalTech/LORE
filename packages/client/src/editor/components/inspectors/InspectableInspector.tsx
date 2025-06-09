import {
	type ActionMapInspectable,
	type Inspectable,
	inspectableActions,
} from "@/lib/dojo_bindings/typescript/models.gen";
import { ActionMapEditor, TextAreaArray, Toggle, Input } from "../FormComponents";
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
			action_map: (e, updatedObject) => {
				const newActionMap = e.target
					.value as unknown as ActionMapInspectable[];
				updatedObject.action_map = newActionMap;
			},
			already_shown: (e, updatedObject) => {
				updatedObject.already_shown = e.target.checked;
			},
			new_entry: (e, updatedObject) => {
				updatedObject.new_entry = e.target.value;
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
				id="already_shown"
				value={componentObject.already_shown}
				onChange={handleInputChange}
			/>
			<Input
				id="new_entry"
				value={componentObject.new_entry}
				onChange={handleInputChange}
			/>
			<Toggle
				id="is_visible"
				value={componentObject.is_visible}
				onChange={handleInputChange}
			/>
			<ActionMapEditor
				id="action_map"
				value={componentObject.action_map}
				onChange={handleInputChange}
				cairoEnum={inspectableActions}
			/>
		</Inspector>
	);
};
