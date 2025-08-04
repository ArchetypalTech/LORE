import {
	type ActionMapReactable,
	type Reactable,
	reactableActions,
} from "@/lib/dojo_bindings/typescript/models.gen";
import { ReactableActionMapEditor, Toggle, Input, TextAreaArray } from "../FormComponents";
import type { ComponentInspector } from "./useInspector";
import { useInspector } from "./useInspector";
import { createDefaultDescriptionText } from "@/editor/lib/components";
import { Button } from "../ui/Button";
import { getEntity, updateComponent } from "@/editor/data/editor.data";

export const ReactableInspector: ComponentInspector<Reactable> = ({
	componentObject,
	...props
}) => {
	const { handleInputChange, Inspector } = useInspector<Reactable>({
		componentObject,
		...props,
		inputHandlers: {
			description_keys: (e, updatedObject) => {
				updatedObject.description = (
					e.target.value as unknown as string[]
				).filter((x) => x !== "");
			},
			is_visible: (e, updatedObject) => {
				updatedObject.is_visible = e.target.checked;
			},
			action_map: (e, updatedObject) => {
				const newActionMap = e.target
				.value as unknown as ActionMapReactable[];
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
				id="description_keys"
				disabled={true}
				rows={1}
				value={componentObject.description as string[]}
				onChange={handleInputChange}
				readOnly={true}
			/>
			<Button
				id="add_description"
				onClick={() => {
					const entity = getEntity(componentObject.inst);
					const newDescription = createDefaultDescriptionText( entity!.Entity, componentObject);
					const updatedDescriptions = [
						...(componentObject.description || []),
						newDescription.DescriptionText.key += 1 as any,
					];
					updateComponent(entity!.Entity.inst, "DescriptionText", newDescription.DescriptionText as any);

					handleInputChange({
						target: {
							id: "description_keys",
							value: updatedDescriptions,
						},
					} as any); 
				}}
			>
				Add description
			</Button>
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
			<ReactableActionMapEditor
				id="action_map"
				value={componentObject.action_map}
				onChange={handleInputChange}
				cairoEnum={reactableActions}
			/>
		</Inspector>
	);
};
