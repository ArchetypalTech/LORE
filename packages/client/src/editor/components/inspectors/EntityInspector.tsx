import EditorData from "@/editor/editor.data";
import type { AnyObject } from "@/editor/lib/schemas";
import type { ChangeEvent } from "react";
import { Input, TagInput } from "../FormComponents";
import type { Entity } from "@/lib/dojo_bindings/typescript/models.gen";

export const EntityInspector = ({ entityObject }: { entityObject: Entity }) => {
	const entity = entityObject;
	const handleInputChange = async (
		e:
			| ChangeEvent<
					(HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement) & {
						value: string[];
					}
			  >
			| ChangeEvent<HTMLInputElement>,
	) => {
		if (!entity || entity === undefined) return;

		const updatedObject = {
			...EditorData().getEntity(entity.inst)!.Entity,
		};
		if (!updatedObject || updatedObject === undefined) {
			throw new Error("Entity not found");
		}

		const { id, value } = e.target;
		switch (id) {
			case "name":
				updatedObject.name = value;
				break;
			case "alt_names":
				console.log(value);
				updatedObject.alt_names = value as string[];
				break;
		}

		const editorObject = {
			...EditorData().getEntity(entity.inst),
		} as AnyObject;
		if (!editorObject) {
			throw new Error("Editor object not found");
		}
		Object.assign(editorObject, { Entity: updatedObject });
		EditorData().syncItem(editorObject);
		EditorData().selectEntity(updatedObject.inst!.toString());
	};

	if (!entity) return <div>Entity not found</div>;

	return (
		<div className="flex flex-col gap-2">
			<Input id="name" value={entity?.name} onChange={handleInputChange} />
			<TagInput
				id="alt_names"
				value={entity.alt_names?.join(",") || ""}
				onChange={handleInputChange}
			/>
		</div>
	);
};
