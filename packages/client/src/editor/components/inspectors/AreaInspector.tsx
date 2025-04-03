import EditorData, { type AnyObject } from "@/editor/editor.data";
import { useMemo, type ChangeEvent } from "react";
import { Select } from "../FormComponents";
import {
	direction,
	type Area,
	type Direction,
} from "@/lib/dojo_bindings/typescript/models.gen";

export const AreaInspector = ({ entityObject }: { entityObject: Area }) => {
	const area = entityObject;
	const handleInputChange = async (
		e:
			| ChangeEvent<
					(HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement) & {
						value: string[];
					}
			  >
			| ChangeEvent<HTMLInputElement>,
	) => {
		if (!area || area === undefined) return;

		const updatedObject = {
			...EditorData().getEntity(area.inst.toString())!.Area,
		};
		if (!updatedObject || updatedObject === undefined) {
			throw new Error("Area not found");
		}

		const { id, value } = e.target;
		switch (id) {
			case "direction":
				updatedObject.direction = value as Direction;
				break;
		}

		const editorObject = {
			...EditorData().getItem(area.inst.toString()),
		} as AnyObject;
		if (!editorObject) {
			throw new Error("Editor object not found");
		}
		Object.assign(editorObject, { Area: updatedObject });
		EditorData().syncItem(editorObject);
		EditorData().selectEntity(updatedObject.inst!.toString());
	};

	const { direction_value, direction_options } = useMemo(() => {
		const enum_options = direction.map((e) => {
			return { value: e.toString(), label: e.toString() };
		});
		if (area.direction.None)
			return { direction_value: "None", direction_options: enum_options };
		const converted = direction.find((e) => e === area?.direction.Some);
		return {
			direction_value: converted?.toString(),
			direction_options: enum_options,
		};
	}, [area]);

	if (!area) return <div>Area not found</div>;

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
