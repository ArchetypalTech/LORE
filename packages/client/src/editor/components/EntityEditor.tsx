import EditorData, { useEditorData } from "../data/editor.data";
import type {
	EntityComponents,
	EntityCollection,
	ComponentInspector,
} from "../lib/schemas";
import { DeleteButton, Header, PublishButton } from "./FormComponents";
import { publishEntityCollection } from "../publisher";
import { componentData } from "../lib/components";
import { formatColorHash } from "../editor.utils";
import { Notifications } from "../lib/notifications";
import { AddComponents } from "./AddComponents";
import type { BigNumberish } from "starknet";
import { useCallback, useEffect, useMemo, useState } from "react";
import { tick } from "@/lib/utils/utils";

export const EntityEditor = ({ inst }: { inst: BigNumberish }) => {
	const { editedEntity, isDirty } = useEditorData();

	useEffect(() => {
		if (editedEntity === undefined && inst !== undefined) {
			EditorData().set({
				editedEntity: { ...EditorData().getEntity(inst) },
			});
		}
	}, [inst, editedEntity]);

	const handleEditComponent = async (
		componentName: keyof EntityComponents,
		component: EntityComponents[keyof EntityComponents],
	) => {
		console.log(componentName, component);
		const edited = { ...EditorData().editedEntity! };
		edited[componentName] = component;
		console.log(edited);
		EditorData().syncItem(edited);
		EditorData().set({
			isDirty: Date.now(),
			editedEntity: edited,
		});
	};

	const allComponents = useCallback(() => {
		if (!editedEntity) return [];
		const components = Object.keys(editedEntity);
		console.log(Object.entries(componentData));
		return Object.entries(componentData)
			.filter(([key, value]) => !(key in components))
			.sort((a, b) => {
				const orderA =
					componentData[a[0] as keyof typeof componentData]?.order || 99;
				const orderB =
					componentData[b[0] as keyof typeof componentData]?.order || 99;
				return orderB - orderA;
			})
			.map(([key, value]) => {
				console.log(key, value);
				const component = editedEntity[key as keyof typeof editedEntity];
				if (!component) return undefined;
				const Inspector = value.inspector as ComponentInspector<
					EntityComponents[keyof EntityComponents]
				>;
				if (!Inspector) return undefined;
				return { key, Inspector, componentObject: component };
			})
			.filter((x) => x !== undefined);
	}, [editedEntity, isDirty]);

	if (!editedEntity?.Entity) {
		return <div className="uppercase">{"< "} Select an Entity</div>;
	}
	return (
		<div className="editor-inspector animate-scale-in">
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
			{allComponents().map(({ key, Inspector, componentObject }) => {
				if (!Inspector) return <div key={key}>{key}</div>;
				if (componentObject === undefined) return null;
				return (
					<Inspector
						key={key}
						componentObject={componentObject}
						componentName={key}
						handleEdit={handleEditComponent}
					/>
				);
			})}
			<AddComponents
				editedEntity={editedEntity}
				handleEdit={handleEditComponent}
			/>
		</div>
	);
};
