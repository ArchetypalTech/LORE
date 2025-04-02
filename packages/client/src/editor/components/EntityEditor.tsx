import type { Entity } from "@/lib/dojo_bindings/typescript/models.gen";
import { useEffect, useState } from "react";
import { useEditorData, type AnyObject } from "../editor.data";
import {
	DeleteButton,
	Header,
	Input,
	PublishButton,
	TagInput,
} from "./FormComponents";

const EntityInspector = ({ entity }: { entity: Entity }) => {
	return (
		<div>
			<Input id="name" value={entity?.name} onChange={() => {}} />
		</div>
	);
};

export const EntityEditor = () => {
	const { selectedEntity } = useEditorData();
	const [editedEntity, setEditedEntity] = useState<AnyObject>();

	useEffect(() => {
		setEditedEntity(selectedEntity);
	}, [selectedEntity]);

	if (!selectedEntity) {
		return <div>Select an entity to edit</div>;
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
			<EntityInspector entity={editedEntity?.Entity} />
			<TagInput
				id="alt_names"
				value={editedEntity?.Entity.alt_names?.join(", ") || ""}
				onChange={() => {}}
			/>
		</div>
	);
};
