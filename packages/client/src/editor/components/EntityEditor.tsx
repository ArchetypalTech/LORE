import EditorData, { useEditorData } from "../data/editor.data";
import type { EntityCollection, EntityComponents } from "../lib/schemas";
import type { ComponentInspector } from "./inspectors/useInspector";
import { DeleteButton, Header, PublishButton } from "./FormComponents";
import { componentData } from "../lib/components";
import { formatColorHash } from "../editor.utils";
import { AddComponents } from "./AddComponents";
import type { BigNumberish } from "starknet";
import { useCallback, useEffect } from "react";
import { publishConfigToContract } from "../publisher";
import { NoEntity } from "./ui/NoEntity";

export const EntityEditor = ({ inst }: { inst: BigNumberish }) => {
	const { editedEntity, isDirty } = useEditorData();

	useEffect(() => {
		if (editedEntity === undefined && inst !== undefined) {
			EditorData().set({
				editedEntity: { ...EditorData().getEntity(inst)! },
			});
		}
	}, [inst, editedEntity]);

	const handleEditComponent = async <T extends keyof EntityComponents>(
		componentName: T,
		component: EntityComponents[T],
	) => {
		EditorData().set({
			editedEntity: EditorData().updateComponent(
				editedEntity!.Entity!.inst,
				componentName,
				component as EntityCollection[T],
			),
		});
	};

	const handleRemoveComponent = async (
		componentName: keyof EntityComponents,
	) => {
		EditorData().set({
			editedEntity: EditorData().removeComponent(
				editedEntity!.Entity.inst,
				componentName,
			),
		});
	};

	const allComponents = useCallback(() => {
		isDirty;
		if (!editedEntity) return [];
		const components = Object.keys(editedEntity);
		return Object.entries(componentData)
			.filter(([key]) => !(key in components))
			.sort((a, b) => {
				const orderA =
					componentData[a[0] as keyof typeof componentData]?.order || 99;
				const orderB =
					componentData[b[0] as keyof typeof componentData]?.order || 99;
				return orderB - orderA;
			})
			.map(([key, value]) => {
				const component = editedEntity[key as keyof typeof editedEntity];
				if (!component) return undefined;
				const Inspector = value.inspector as ComponentInspector<
					EntityComponents[keyof EntityComponents]
				>;
				if (!Inspector) return undefined;
				return {
					key: key as keyof EntityComponents,
					Inspector,
					componentObject: component as EntityComponents[keyof EntityComponents],
				};
			})
			.filter((x) => x !== undefined);
	}, [editedEntity, isDirty]);

	if (!editedEntity?.Entity) {
		return <NoEntity />;
	}

	return (
		<div className="editor-inspector mb-25">
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
						await EditorData().removeEntity(editedEntity);
					}}
				/>
				<PublishButton
					onClick={async () => {
						await publishConfigToContract(
							EditorData().changeSet.filter((x) => x.inst === inst),
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
						handleRemove={handleRemoveComponent}
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
