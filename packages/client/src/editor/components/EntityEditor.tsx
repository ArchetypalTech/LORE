import type { Entity } from "@/lib/dojo_bindings/typescript/models.gen";
import { useEffect, useState, type ChangeEvent } from "react";
import EditorData, { useEditorData, type AnyObject } from "../editor.data";
import {
	DeleteButton,
	Header,
	Input,
	PublishButton,
	TagInput,
} from "./FormComponents";
import { tick } from "@/lib/utils/utils";

const EntityInspector = ({ entity }: { entity: Entity }) => {
	const handleInputChange = async (
		e:
			| ChangeEvent<
					(HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement) & {
						value: string[];
					}
			  >
			| ChangeEvent<HTMLInputElement>,
	) => {
		if (!entity) return;

		const updatedObject: Entity = {
			...EditorData().getEntity(entity.inst.toString())!.Entity,
		};

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

		const editorObject = { ...EditorData().getItem(entity.inst.toString()) };
		if (!editorObject) {
			throw new Error("Editor object not found");
		}
		Object.assign(editorObject, { Entity: updatedObject });
		console.log(editorObject);
		EditorData().syncItem(editorObject);
		EditorData().selectEntity(updatedObject.inst.toString());
	};
	return (
		<div>
			<Input id="name" value={entity?.name} onChange={handleInputChange} />
			<TagInput
				id="alt_names"
				value={entity.alt_names?.join(", ") || ""}
				onChange={handleInputChange}
			/>
		</div>
	);
};

export const EntityEditor = () => {
	const { selectedEntity } = useEditorData();
	const [editedEntity, setEditedEntity] = useState<AnyObject>();

	useEffect(() => {
		setEditedEntity(selectedEntity);
	}, [selectedEntity]);

	if (!editedEntity) {
		return <div>Select an entity to edit</div>;
	}

	if (!editedEntity.Entity) {
		return <div>Entity has errors</div>;
	}

	return (
		<div className="editor-inspector">
			<Header title={editedEntity?.Entity.name || "Entity"}>
				<DeleteButton
					onClick={async () => {
						// await useEditorData().deleteItem(editedEntity.Entity.inst);
						// setEditedEntity(undefined);
					}}
				/>
				<PublishButton
					onClick={async () => {
						// await useEditorData().publishItem(editedEntity);
						// setEditedEntity(undefined);
					}}
				/>
			</Header>
			<EntityInspector entity={editedEntity.Entity} />
		</div>
	);
};
