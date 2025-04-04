import { useEffect, useMemo, useRef, useState } from "react";
import EditorData, { useEditorData } from "../editor.data";
import {
	type AnyObject,
	type EntityComponents,
	type EntityCollection,
	type ComponentInspector,
	createDefaultAreaComponent,
	createDefaultEntity,
	createDefaultInspectableComponent,
	createDefaultExitComponent,
} from "../lib/schemas";
import { DeleteButton, Header, PublishButton, Select } from "./FormComponents";
import { EntityInspector } from "./inspectors/EntityInspector";
import { AreaInspector } from "./inspectors/AreaInspector";
import { InspectableInspector } from "./inspectors/InspectableInspector";
import { publishEntityCollection } from "../publisher";
import EditorStore from "../editor.store";
import { formatColorHash } from "../utils";
import type { Entity } from "@/lib/dojo_bindings/typescript/models.gen";
import type { BigNumberish } from "starknet";
import { ExitInspector } from "./inspectors/exitInspector";

export const componentData: {
	[K in keyof EntityCollection]: {
		order: number;
		inspector: ComponentInspector<NonNullable<EntityCollection[K]>>;
		icon?: string;
		creator: (entity: Entity) => {
			[K in keyof Partial<NonNullable<EntityCollection>>]: T extends {
				inst: BigNumberish;
			}
				? EntityCollection[K]
				: never;
		};
	};
} = {
	Entity: {
		order: 0,
		inspector: EntityInspector,
		creator: createDefaultEntity,
	},
	Area: {
		order: 1,
		inspector: AreaInspector,
		icon: "🥾",
		creator: createDefaultAreaComponent,
	},
	Inspectable: {
		order: 2,
		inspector: InspectableInspector,
		icon: "🔍",
		creator: createDefaultInspectableComponent,
	},
	Exit: {
		order: 3,
		inspector: ExitInspector,
		icon: "🚪",
		creator: createDefaultExitComponent,
	},
};

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

	const handleAddComponent = async (e: React.MouseEvent<HTMLButtonElement>) => {
		console.log(selectRef.current?.value);
		const key = selectRef.current?.value as keyof typeof componentData;
		const component = componentData[key];
		if (!component) {
			throw new Error(`Component not found: ${key}`);
		}
		EditorData().syncItem(component.creator(editedEntity.Entity!));
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
	const { selectedEntity } = useEditorData();
	const [editedEntity, setEditedEntity] = useState<AnyObject>();

	useEffect(() => {
		if (!selectedEntity) return;
		setEditedEntity(selectedEntity);
	}, [selectedEntity]);

	const keys = useMemo(() => {
		if (!selectedEntity) return [];

		return Object.keys(selectedEntity)
			.filter((key) => key in componentData)
			.sort((a, b) => {
				const orderA = componentData[a as keyof typeof componentData]?.order || 99;
				const orderB = componentData[b as keyof typeof componentData]?.order || 99;
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
				const key = k as keyof EntityComponents;
				const Inspector = componentData[key as keyof typeof componentData]
					?.inspector as ComponentInspector<
					EntityComponents[keyof EntityComponents]
				>;
				if (!Inspector) return <div key={key}>{key}</div>;
				if (editedEntity[key] === undefined) return null;
				return (
					<Inspector
						key={key}
						componentObject={editedEntity[key]}
						componentName={key}
					/>
				);
			})}
			<AddComponents editedEntity={editedEntity} />
		</div>
	);
};
