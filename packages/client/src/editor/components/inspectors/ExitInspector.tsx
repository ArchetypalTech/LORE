import EditorData from "@/editor/data/editor.data";
import { stringCairoEnum } from "@/editor/lib/schemas";
import {
	type Exit,
	direction,
} from "@/lib/dojo_bindings/typescript/models.gen";
import { type ChangeEvent, useMemo } from "react";
import { CairoEnumSelect, Select, Toggle } from "../FormComponents";
import type { ComponentInspector } from "./useInspector";
import { useInspector } from "./useInspector";

export const ExitInspector: ComponentInspector<Exit> = ({
	componentObject,
	...props
}) => {
	// @dev: get available areas to link to
	const { area_value, area_options } = useMemo(() => {
		return {
			area_value: componentObject.leads_to.toString(),
			area_options: EditorData()
				.getEntities()
				.filter((e) => e.Area !== undefined)
				.map((e) => ({ value: e.Entity!.inst.toString(), label: e.Entity.name })),
		};
	}, [componentObject]);

	const { handleInputChange, Inspector } = useInspector<Exit>({
		componentObject,
		...props,
		inputHandlers: {
			is_exit: (e, updatedObject) => {
				const event = e as ChangeEvent<HTMLInputElement>;
				updatedObject.is_exit = event.target.checked;
			},
			is_enterable: (e, updatedObject) => {
				const event = e as ChangeEvent<HTMLInputElement>;
				updatedObject.is_enterable = event.target.checked;
			},
			leads_to: (e, updatedObject) => {
				updatedObject.leads_to = e.target.value;
			},
			direction_type: (e, updatedObject) => {
				updatedObject.direction_type = stringCairoEnum(e.target.value);
			},
		},
	});

	if (!componentObject) return <div>Exit not found</div>;

	return (
		<Inspector>
			<Toggle
				id="is_exit"
				value={componentObject.is_exit}
				onChange={handleInputChange}
			/>
			<Toggle
				id="is_enterable"
				value={componentObject.is_enterable}
				onChange={handleInputChange}
			/>
			<Select
				id="leads_to"
				defaultValue={area_value}
				onChange={handleInputChange}
				options={area_options}
			/>
			<CairoEnumSelect
				id="direction_type"
				onChange={handleInputChange}
				value={componentObject.direction_type}
				enum={direction}
			/>
		</Inspector>
	);
};
