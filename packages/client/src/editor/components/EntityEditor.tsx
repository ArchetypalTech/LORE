import { useState } from "react";
import { useCallback, useEffect } from "react";
import type { BigNumberish } from "starknet";
import EditorData, { useEditorData } from "../data/editor.data";
import { formatColorHash } from "../editor.utils";
import { componentData } from "../lib/components";
import type { EntityCollection } from "../lib/types";
import { publishConfigToContract } from "../publisher";
import { AddComponents } from "./AddComponents";
import { DeleteButton, Header, PublishButton } from "./FormComponents";
import type { ComponentInspector } from "./inspectors/useInspector";
import { NoEntity } from "./ui/NoEntity";

export const EntityEditor = ({ inst }: { inst: BigNumberish }) => {
	const { editedEntity, isDirty } = useEditorData();

	 // State to track open/closed status per component key
  const [openComponents, setOpenComponents] = useState<Record<string, boolean>>({});

  // Toggle function for a single component
  const toggleComponent = (key: string) => {
    setOpenComponents((prev) => ({
      ...prev,
      [key]: !prev[key],
    }));
  };

	useEffect(() => {
		if (editedEntity === undefined && inst !== undefined) {
			EditorData().set({
				editedEntity: { ...EditorData().getEntity(inst)! },
			});
		}
	}, [inst, editedEntity]);

	const handleEditComponent = async <T extends keyof EntityCollection>(
		componentName: T,
		component: EntityCollection[T],
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
		componentName: keyof EntityCollection,
	) => {
		EditorData().set({
			editedEntity: EditorData().removeComponent(
				editedEntity!.Entity.inst,
				componentName,
			),
		});
	};

	const allComponents = useCallback(() => {
		if (!editedEntity) return [];

		return Object.entries(componentData)
			.map(([key, value]) => {
				const componentName = key as keyof EntityCollection;
				const Inspector = value.inspector as ComponentInspector<EntityCollection[keyof EntityCollection]>;

				const componentData = editedEntity[componentName];

				if (!componentData || !Inspector) return [];

				// Handle multi-instance components (stored as arrays)
				if (Array.isArray(componentData)) {
					return componentData.map((componentInstance, index) => ({
						key: componentName,
						Inspector,
						componentObject: componentInstance,
						index,
					}));
				}

				// Single-instance components
				return [{
					key: componentName,
					Inspector,
					componentObject: componentData,
					index: undefined,
				}];
			})
			.flat()
			.filter(Boolean);
	}, [editedEntity]);

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
			  <div className="flex flex-col gap-0 rounded-md shadow-xs">
        {allComponents().map(({ key, Inspector, componentObject, index }) => {
				const componentKey = `${key}-${index ?? "single"}`;
				const isOpen = openComponents[componentKey] ?? true;

				return (
					<div key={componentKey} className="border-b border-gray-300">
						<div
							className="flex items-center justify-between bg-gray-100 px-2 py-1 cursor-pointer select-none"
							onClick={() =>
								setOpenComponents((prev) => ({
									...prev,
									[componentKey]: !prev[componentKey],
								}))
							}
						>
							<span className="font-semibold">
								{key}
								{index !== undefined ? ` #${index + 1}` : ""}
							</span>
							<span className="text-xs">{isOpen ? "▼" : "▶"}</span>
						</div>

						{isOpen && (
							<Inspector
								componentObject={componentObject}
								componentName={key}
								handleEdit={async (name, updated) => {
									EditorData().updateComponent(inst, name, updated);
								}}
								handleRemove={async () => {
									EditorData().removeComponent(inst, key, index ?? (componentObject as any).key);
								}}
							/>
						)}
					</div>
				);
			})}
      </div>

      <AddComponents editedEntity={editedEntity} handleEdit={handleEditComponent} />
    </div>
  );
};