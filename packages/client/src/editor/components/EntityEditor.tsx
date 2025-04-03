import { useEffect, useMemo, useState } from "react";
import EditorData, { useEditorData, type AnyObject } from "../editor.data";
import { DeleteButton, Header, PublishButton } from "./FormComponents";
import { EntityInspector } from "./inspectors/EntityInspector";
import { AreaInspector } from "./inspectors/AreaInspector";
import { InspectableInspector } from "./inspectors/InspectableInspector";
import { publishEntityCollection } from "../publisher";
import EditorStore from "../editor.store";

const inspectorMap = {
	Entity: {
		order: 0,
		component: EntityInspector,
	},
	Area: {
		order: 1,
		component: AreaInspector,
	},
	Inspectable: {
		order: 2,
		component: InspectableInspector,
	},
};

export const EntityEditor = () => {
	const { selectedEntity } = useEditorData();
	const [editedEntity, setEditedEntity] = useState<AnyObject>();

	useEffect(() => {
		if (!selectedEntity) return;
		console.log(Object.entries(selectedEntity));
		setEditedEntity(selectedEntity);
	}, [selectedEntity]);

	const keys = useMemo(() => {
		if (!selectedEntity) return [];

		return Object.keys(selectedEntity)
			.filter((key) => key in inspectorMap)
			.sort((a, b) => {
				const orderA = inspectorMap[a as keyof typeof inspectorMap]?.order || 99;
				const orderB = inspectorMap[b as keyof typeof inspectorMap]?.order || 99;
				return orderB - orderA;
			});
	}, [selectedEntity]);

	if (!editedEntity || !selectedEntity) {
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
						await EditorData().removeEntity(editedEntity.Entity);
					}}
				/>
				<PublishButton
					onClick={async () => {
						await EditorStore().notifications.doLoggedAction(() =>
							publishEntityCollection(editedEntity),
						);
					}}
				/>
			</Header>
			{keys.map((key) => {
				const Inspector = inspectorMap[key as keyof typeof inspectorMap].component;
				if (!Inspector) return <div key={key}>{key}</div>;
				if (editedEntity[key] === undefined) return null;
				return (
					<div
						key={key}
						className="flex flex-col gap-2 border border-dotted border-black/20 p-2 rounded-md bg-black/1 shadow-xs"
					>
						<h3 className="w-full text-right text-xs uppercase text-black/50 font-bold">
							{key}
						</h3>
						<Inspector key={key} entityObject={editedEntity[key]} />
					</div>
				);
			})}
		</div>
	);
};
