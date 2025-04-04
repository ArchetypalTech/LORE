import EditorData from "@/editor/editor.data";
import type { AnyObject, ComponentInspector } from "@/editor/lib/schemas";
import { useMemo, type ChangeEvent } from "react";
import { Select } from "../FormComponents";
import {
	direction,
	type Area,
} from "@/lib/dojo_bindings/typescript/models.gen";
import type { CairoCustomEnum } from "starknet";
import { useInspector } from "./useInspector";

export const AreaInspector: ComponentInspector<Area> = ({
	componentObject,
	componentName,
}) => {
	const { direction_value, direction_options } = useMemo(() => {
		const enum_options = direction.map((e) => {
			return { value: e.toString(), label: e.toString() };
		});
		if (componentObject.direction.None)
			return { direction_value: "None", direction_options: enum_options };
		const converted = direction.find((e) => e === componentObject?.direction);
		return {
			direction_value: converted?.toString(),
			direction_options: enum_options,
		};
	}, [componentObject]);

	const { handleInputChange } = useInspector<Area>({
		componentObject,
		componentName,
		inputHandlers: {
			direction: (e, updatedObject) => {
				updatedObject.direction = e.target.value as unknown as CairoCustomEnum;
			},
		},
	});

	if (!componentObject) return <div>Area not found</div>;

	return (
		<div className="flex flex-col gap-2">
			<Select
				id="direction"
				value={direction_value}
				onChange={handleInputChange}
				options={direction_options}
			/>
		</div>
	);
};
