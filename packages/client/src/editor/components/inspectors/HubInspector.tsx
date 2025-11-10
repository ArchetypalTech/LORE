import {
	type Hub,
} from "@/lib/dojo_bindings/typescript/models.gen";
import type { ComponentInspector } from "./useInspector";
import { useInspector } from "./useInspector";
import { Input, Toggle } from "../FormComponents";

export const HubInspector: ComponentInspector<Hub> = ({
	componentObject,
	...props
}) => {
	const { Inspector, handleInputChange } = useInspector<Hub>({
		componentObject,
		...props,
		inputHandlers: {
			is_enabled: (e, updatedObject) => {
				const event = e as React.ChangeEvent<HTMLInputElement>;
				updatedObject.is_enabled = event.target.checked;
			},
			grants_editor_access: (e, updatedObject) => {
				const event = e as React.ChangeEvent<HTMLInputElement>;
				updatedObject.grants_editor_access = event.target.checked;
			},
		},
	});

	if (!componentObject) return <div>Hub not found</div>;

	return (
		<Inspector>
			<Toggle
				id="is_enabled"
				value={componentObject.is_enabled}
				onChange={handleInputChange(undefined)}
			/>
			<Toggle
				id="grants_editor_access"
				value={componentObject.grants_editor_access ?? false}
				onChange={handleInputChange(undefined)}
			/>
			{/* <CollapsibleComponent title="Description Keys">
				<div style={{ marginTop: "4px" }}>
					<TextAreaArray
						id="description_keys"
						disabled={true}
						rows={1}
						value={componentObject.description as string[]}
						onChange={(e) => {
							const newDescriptionKeys = (
								e.target.value as unknown as string[]
							).filter((x) => x !== "");
							const currentKeys = componentObject.description || [];
							const removedIndex = currentKeys.findIndex(
								(key) => !newDescriptionKeys.includes(key)
							);

							const entity = getEntity(componentObject.inst);
							if (entity && entity.DescriptionText) {
								removeComponent(entity.Entity.inst, "DescriptionText", removedIndex, true);
							}

							handleInputChange(undefined)({
								target: {
									id: "description_keys",
									value: newDescriptionKeys,
								},
							} as any);
						}}
						readOnly={true}
					/>
					<Button
						id="add_description"
						onClick={() => {
							const entity = getEntity(componentObject.inst);
							const newDescription = createDefaultDescriptionText(
								entity!.Entity,
								entity?.DescriptionText
							);
							const newDescriptionKey = newDescription.DescriptionText.key;

							const updatedDescriptions = [
								...(componentObject.description || []),
								newDescriptionKey,
							];

							updateComponent(
								entity!.Entity.inst,
								"DescriptionText",
								newDescription.DescriptionText as any,
								true
							);

							handleInputChange(undefined)({
								target: {
									id: "description_keys",
									value: updatedDescriptions,
								},
							} as any);
						}}
					>
						Add description
					</Button>
				</div>
			</CollapsibleComponent> */}
		</Inspector>
	);
};
