import { useMemo, useRef } from "react";
import EditorData, { useEditorData } from "../data/editor.data";
import type {
	AnyObject,
	EntityComponents,
	EntityCollection,
	ComponentInspector,
} from "../lib/schemas";
import { DeleteButton, Header, PublishButton, Select } from "./FormComponents";
import { publishEntityCollection } from "../publisher";
import { componentData } from "../data/component.data";
import { formatColorHash } from "../editor.utils";
import { Notifications } from "../lib/notifications";

const AddComponents = ({ editedEntity }: { editedEntity: AnyObject }) => {
	const selectRef = useRef<HTMLSelectElement>(null);

	const options = useMemo(() => {
		const o = Object.entries(componentData)
			.filter(([key]) => {
				return editedEntity[key as keyof typeof editedEntity] === undefined;
			})
			.map(([key]) => ({ value: key, label: key }));
		return o;
	}, [editedEntity]);

	const handleAddComponent = async (_e: React.MouseEvent<HTMLButtonElement>) => {
		console.log(selectRef.current?.value);
		const key = selectRef.current?.value as keyof typeof componentData;
		const component = componentData[key];
		if (!component) {
			throw new Error(`Component not found: ${key}`);
		}
		const newComponent = component.creator(editedEntity.Entity!);
		EditorData().syncItem(newComponent as unknown as AnyObject);
	};

	return (
		<div className="w-full flex flex-row gap-2 items-end">
			<div className="flex grow items-center">
				<Select
					ref={selectRef}
					id=""
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
	const { selectedEntity: editedEntity } = useEditorData();

	if (!editedEntity?.Entity) {
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
						await Notifications().doLoggedAction(() =>
							publishEntityCollection(editedEntity as EntityCollection),
						);
					}}
				/>
			</Header>
			{Object.keys(editedEntity)
				.filter((key) => key in componentData)
				.sort((a, b) => {
					const orderA = componentData[a as keyof typeof componentData]?.order || 99;
					const orderB = componentData[b as keyof typeof componentData]?.order || 99;
					return orderB - orderA;
				})
				.map((k, i) => {
					const key = k as keyof EntityComponents;
					const Inspector = componentData[key as keyof typeof componentData]
						?.inspector as ComponentInspector<
						EntityComponents[keyof EntityComponents]
					>;
					if (!Inspector) return <div key={key}>{key}</div>;
					if (editedEntity[key] === undefined) return null;
					return (
						<Inspector
							key={i}
							componentObject={editedEntity[key]}
							componentName={key}
						/>
					);
				})}
			<AddComponents editedEntity={editedEntity} />
		</div>
	);
};
