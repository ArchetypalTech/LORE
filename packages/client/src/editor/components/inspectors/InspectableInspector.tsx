import {
	type ActionMapInspectable,
	type Inspectable,
	inspectableActions,
	type DescriptionText
} from "@/lib/dojo_bindings/typescript/models.gen";
import { ActionMapEditor, Toggle, Input } from "../FormComponents";
import type { ComponentInspector } from "./useInspector";
import { DescriptionEditor } from "../DescriptionManager";
import { useInspector } from "./useInspector";
import { BigNumberish } from "starknet";

export const InspectableInspector: ComponentInspector<(Inspectable & DescriptionText)> = ({
	componentObject,
	...props
}) => {
	const { handleInputChange, Inspector } = useInspector<(Inspectable & DescriptionText)>({
		componentObject,
		...props,
		inputHandlers: {
			description_key: (e, updatedObject) => {
				updatedObject.description = e.target.value as unknown as BigNumberish;
			},
			description_text: (e, updatedObject) => {
				updatedObject.text = e.target.value as unknown as string;
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

	const descriptionData = (componentObject.text as unknown as string[] || []).map((text, idx) => ({
    key: Number(componentObject.description?.[idx] ?? idx),
    text,
  }));

  const handleDescriptionChange = (updated: { key: number; text: string }[]) => {
    const keys = updated.map((d) => d.key.toString());
    const texts = updated.map((d) => d.text);

    handleInputChange({
      target: {
        id: "description_key",
        value: keys,
      },
    } as any as React.ChangeEvent<HTMLTextAreaElement>);

    handleInputChange({
      target: {
        id: "description_text",
        value: texts,
      },
    } as any as React.ChangeEvent<HTMLTextAreaElement>);
  };

	return (
		<Inspector>
			<DescriptionEditor 
				value={descriptionData} 
				onChange={handleDescriptionChange} />
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
