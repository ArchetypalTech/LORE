import { useMemo } from "react";
import {
	type Hub,
} from "@/lib/dojo_bindings/typescript/models.gen";
import type { ComponentInspector } from "./useInspector";
import { useInspector } from "./useInspector";
import { TextAreaArray, Toggle } from "../FormComponents";
import { CollapsibleComponent } from "../CollapsibleComponent";
import { getEntity } from "@/editor/data/editor.data";

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
			grants_trail_access: (e, updatedObject) => {
				const event = e as React.ChangeEvent<HTMLInputElement>;
				updatedObject.grants_trail_access = event.target.checked;
			},
		},
	});

	const trailNames = useMemo(() => {
		return componentObject.trails_insts.map((inst) => {
			return getEntity(inst)?.Entity.name ?? inst.toString();
		});
	}, [componentObject.trails_insts]);
	// console.log("HUB TRAILS>>>", trailNames);

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
			<Toggle
				id="grants_trail_access"
				value={componentObject.grants_trail_access ?? false}
				onChange={handleInputChange(undefined)}
			/>
			<CollapsibleComponent title="Trails">
				<div style={{ marginTop: "4px" }}>
					<TextAreaArray
						id="trails_insts"
						disabled={true}
						rows={1}
						value={trailNames}
						onChange={(e) => {}}
						readOnly={true}
						// className="text-sm"
					/>
				</div>
			</CollapsibleComponent>
		</Inspector>
	);
};
