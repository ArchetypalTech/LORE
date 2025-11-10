import { useMemo } from "react";
import {
	type Trail,
} from "@/lib/dojo_bindings/typescript/models.gen";
import type { ComponentInspector } from "./useInspector";
import { useInspector } from "./useInspector";
import { Input, Select, Toggle } from "../FormComponents";
import { bigintToAddress } from "@/lib/utils/utils";
import EditorData from "@/editor/data/editor.data";

export const TrailInspector: ComponentInspector<Trail> = ({
	componentObject,
	...props
}) => {
	const { area_value, area_options } = useMemo(() => {
		return {
			area_value: bigintToAddress(componentObject.hub_inst),
			area_options: EditorData()
				.getEntities()
				.filter((e) => e.Hub !== undefined && e.Hub.is_enabled)
				.map((e) => ({
					value: bigintToAddress(e.Entity!.inst),
					label: e.Entity.name,
				})),
		};
	}, [componentObject]);

	const { Inspector, handleInputChange } = useInspector<Trail>({
		componentObject,
		...props,
		inputHandlers: {
			hub_inst: (e, updatedObject) => {
				updatedObject.hub_inst = e.target.value;
			},
			is_published: (e, updatedObject) => {
				const event = e as React.ChangeEvent<HTMLInputElement>;
				updatedObject.is_published = event.target.checked;
			},
		},
	});

	if (!componentObject) return <div>Trail not found</div>;

	return (
		<Inspector>
			<Input
				id="trail_id"
				value={componentObject.trail_id?.toString() ?? "0"}
				onChange={handleInputChange(undefined)}
				readOnly={true}
			/>
			<Select
				id="hub_inst"
				defaultValue={area_value}
				onChange={handleInputChange(undefined)}
				options={area_options}
			/>
			<Toggle
				id="is_published"
				value={componentObject.is_published}
				onChange={handleInputChange(undefined)}
			/>
		</Inspector>
	);
};
