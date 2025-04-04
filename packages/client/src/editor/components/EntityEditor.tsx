import { useEffect, useMemo, useRef, useState } from "react";
import EditorData, { useEditorData } from "../editor.data";
import type { AnyObject, EntityCollection } from "../lib/schemas";
import { DeleteButton, Header, PublishButton, Select } from "./FormComponents";
import { EntityInspector } from "./inspectors/EntityInspector";
import { AreaInspector } from "./inspectors/AreaInspector";
import { InspectableInspector } from "./inspectors/InspectableInspector";
import { publishEntityCollection } from "../publisher";
import EditorStore from "../editor.store";
import { formatColorHash } from "../utils";

const inspectorMap = {
	Entity: {
		order: 0,
		inspector: EntityInspector,
	},
	Area: {
		order: 1,
		inspector: AreaInspector,
	},
	Inspectable: {
		order: 2,
		inspector: InspectableInspector,
	},
};

const AddComponents = ({ editedEntity }: { editedEntity: AnyObject }) => {
	const selectRef = useRef<HTMLSelectElement>(null);

	const options = useMemo(() => {
		const o = Object.entries(inspectorMap)
			.filter(([key]) => {
				return editedEntity[key as keyof typeof editedEntity] === undefined;
			})
			.map(([key]) => ({ value: key, label: key }));
		return o;
	}, [editedEntity]);

	const handleAddComponent = async (e: React.MouseEvent<HTMLButtonElement>) => {
		console.log(selectRef.current?.value);
	};

	return (
		<div className="w-full flex flex-row gap-2 items-end">
			<div className="flex grow items-center">
				<Select
					ref={selectRef}
					id=""
					value="Entity"
					onChange={() => {}}
					options={options}
					disabled={options.length === 0}
				/>
			</div>
			<button
				className="btn btn-success btn-sm shrink"
				onClick={handleAddComponent}
				disabled={options.length === 0}
			>
				Add Component
			</button>
		</div>
	);
};

export const EntityEditor = () => {
	const { selectedEntity } = useEditorData();
	const [editedEntity, setEditedEntity] = useState<AnyObject>();

	useEffect(() => {
		if (!selectedEntity) return;
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
			<Header
				title={editedEntity?.Entity.name || "Entity"}
				subtitle={
					<div
						className="text-[7pt] text-black/20"
						// biome-ignore lint/security/noDangerouslySetInnerHtml: <explanation>
						dangerouslySetInnerHTML={{
							__html: formatColorHash(editedEntity.Entity!.inst),
						}}
					/>
				}
			>
				<DeleteButton
					onClick={async () => {
						await EditorData().removeEntity(editedEntity.Entity!);
					}}
				/>
				<PublishButton
					onClick={async () => {
						await EditorStore().notifications.doLoggedAction(() =>
							publishEntityCollection(editedEntity as EntityCollection),
						);
					}}
				/>
			</Header>
			{keys.map((k) => {
				const key = k as keyof typeof editedEntity;
				const Inspector = inspectorMap[key as keyof typeof inspectorMap].inspector;
				if (!Inspector) return <div key={key}>{key}</div>;
				if (editedEntity[key] === undefined) return null;
				return (
					<div
						key={key}
						className="flex flex-col gap-2 border border-dotted border-black/20 p-2 rounded-md bg-black/1 shadow-xs"
					>
						<h3 className="w-full text-right text-xs uppercase text-black/50 font-bold flex flex-row items-center justify-end gap-2">
							<div
								className="text-[7pt] text-black/20 hover:opacity-100 opacity-0"
								// biome-ignore lint/security/noDangerouslySetInnerHtml: <explanation>
								dangerouslySetInnerHTML={{
									__html: formatColorHash(editedEntity[key].inst),
								}}
							/>
							<div>{key}</div>
						</h3>
						<Inspector key={key} entityObject={editedEntity[key]} />
					</div>
				);
			})}
			<AddComponents editedEntity={editedEntity} />
		</div>
	);
};
