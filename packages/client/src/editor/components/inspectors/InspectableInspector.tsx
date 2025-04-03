import EditorData, { type AnyObject } from "@/editor/editor.data";
import type { ChangeEvent } from "react";
import { TextAreaArray, Toggle } from "../FormComponents";
import type { Inspectable } from "@/lib/dojo_bindings/typescript/models.gen";
import { tick } from "@/lib/utils/utils";

export const InspectableInspector = ({
	entityObject,
}: { entityObject: Inspectable }) => {
	const inspectable = entityObject;
	const handleInputChange = async (
		e:
			| ChangeEvent<
					(HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement) & {
						value: string[];
					}
			  >
			| ChangeEvent<HTMLInputElement>,
	) => {
		if (!inspectable || inspectable === undefined) return;

		const updatedObject = {
			...EditorData().getEntity(inspectable.inst)!.Inspectable,
		};
		if (!updatedObject || updatedObject === undefined) {
			throw new Error("Inspectable not found");
		}

		const { id, value } = e.target;
		switch (id) {
			case "description":
				updatedObject.description = value as string[];
				break;
			case "is_visible":
				const val = e.target.checked;
				updatedObject.is_visible = val as boolean;
				break;
		}

		const editorObject = {
			...EditorData().getItem(inspectable.inst),
		} as AnyObject;
		if (!editorObject) {
			throw new Error("Editor object not found");
		}
		Object.assign(editorObject, { Inspectable: updatedObject });
		console.log(editorObject);
		EditorData().syncItem(editorObject);
		await tick();
		EditorData().selectEntity(updatedObject.inst!.toString());
	};

	// const { direction_value, direction_options } = useMemo(() => {
	// 	const enum_options = direction.map((e) => {
	// 		return { value: e.toString(), label: e.toString() };
	// 	});
	// 	console.log(direction);
	// 	if (inspectable.direction.None)
	// 		return { direction_value: "None", direction_options: enum_options };
	// 	const converted = direction.find((e) => e === inspectable?.direction.Some);
	// 	return {
	// 		direction_value: converted?.toString(),
	// 		direction_options: enum_options,
	// 	};
	// }, [inspectable]);

	if (!inspectable) return <div>Inspectable not found</div>;

	return (
		<div className="flex flex-col gap-2">
			<TextAreaArray
				id="description"
				value={inspectable.description}
				onChange={handleInputChange}
				rows={1}
			/>
			<Toggle
				id="is_visible"
				value={inspectable.is_visible}
				onChange={handleInputChange}
			/>
		</div>
	);
};
