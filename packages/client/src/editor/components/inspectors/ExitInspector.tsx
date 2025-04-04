import {
	stringCairoEnum,
	useCairoEnum,
	type ComponentInspector,
} from "@/editor/lib/schemas";
import { useMemo } from "react";
import { Select, Toggle } from "../FormComponents";
import {
	direction,
	type Exit,
} from "@/lib/dojo_bindings/typescript/models.gen";
import { useInspector } from "./useInspector";
import EditorData from "@/editor/editor.data";

export const ExitInspector: ComponentInspector<Exit> = ({
	componentObject,
	componentName,
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

	// @dev: convert cairo enum
	const { value: direction_value, options: direction_options } = useCairoEnum(
		componentObject.direction_type,
		direction,
	);

	const { handleInputChange, Inspector } = useInspector<Exit>({
		componentObject,
		componentName,
		inputHandlers: {
			is_exit: (e, updatedObject) => {
				updatedObject.is_exit = e.target.checked;
			},
			is_enterable: (e, updatedObject) => {
				updatedObject.is_enterable = e.target.checked;
			},
			leads_to: (e, updatedObject) => {
				console.log(e, e.target.value);
				updatedObject.leads_to = e.target.value;
			},
			direction_type: (e, updatedObject) => {
				console.log(e.target.value);
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
				value={componentObject.is_exit}
				onChange={handleInputChange}
			/>
			<Select
				id="leads_to"
				defaultValue={area_value}
				onChange={handleInputChange}
				options={area_options}
			/>
			<Select
				id="direction_type"
				defaultValue={direction_value}
				onChange={handleInputChange}
				options={direction_options}
			/>
		</Inspector>
	);
};
