import type { ComponentInspector } from "@/editor/lib/schemas";
import { useMemo, type ChangeEvent } from "react";
import { Select, TextAreaArray, Toggle } from "../FormComponents";
import type { Exit } from "@/lib/dojo_bindings/typescript/models.gen";
import { useInspector } from "./useInspector";
import EditorData from "@/editor/editor.data";

export const ExitInspector: ComponentInspector<Exit> = ({
	componentObject,
	componentName,
}) => {
	const allAreas = useMemo(() => {
		const areas = EditorData()
			.getEntities()
			.filter((e) => e.Area !== undefined)
			.map((e) => ({ value: e.Entity!.inst.toString(), label: e.Entity.name }));
		return areas;
	}, [componentObject]);

	const { handleInputChange } = useInspector<Exit>({
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
		},
	});

	if (!componentObject) return <div>Exit not found</div>;

	return (
		<div className="flex flex-col gap-2">
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
				defaultValue={componentObject.leads_to.toString()}
				onChange={handleInputChange}
				options={allAreas}
			/>
		</div>
	);
};
