import { useState } from "react";
import { useCallback, useEffect } from "react";
import type { BigNumberish } from "starknet";
import { useCanEditEntity } from "@/lib/stores/editor.store";
import EditorData, { useEditorData } from "../data/editor.data";
import { formatColorHash } from "../editor.utils";
import { componentData } from "../lib/components";
import type { EntityCollection } from "../lib/types";
import { publishConfigToContract } from "../publisher";
import { AddComponents } from "./AddComponents";
import { DeleteButton, Header, PublishButton } from "./FormComponents";
import type { ComponentInspector } from "./inspectors/useInspector";
import { NoEntity } from "./ui/NoEntity";
import { cn } from "@/lib/utils/utils";

export const EntityEditor = ({ inst }: { inst: BigNumberish }) => {
	const { editedEntity, isDirty } = useEditorData();
	const { canEdit } = useCanEditEntity(editedEntity);

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
		index?: BigNumberish,
	) => {
		EditorData().set({
			editedEntity: EditorData().removeComponent(
				editedEntity!.Entity.inst,
				componentName,
				index,
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
                    EntityCollection[keyof EntityCollection]
                >;
                if (!Inspector) return undefined;

                // Ensure multikey components are always arrays
                const isMultiKey = [
                    "Action",
                    "Effect", 
                    "Trigger",
                    "Condition",
                    "DESCRIPTIONTEXT",
                    "DescriptionText",
                ].includes(key);

                let componentObject = component as EntityCollection[keyof EntityCollection];

                // If it's a multikey component but not an array, wrap it in an array
                if (isMultiKey && !Array.isArray(componentObject)) {
                    componentObject = [componentObject] as any;
                }

                return {
                    key: key as keyof EntityCollection,
                    Inspector,
                    componentObject,
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
				<DeleteButton disabled={!canEdit}
					onClick={async () => {
						await EditorData().removeEntity(editedEntity);
					}}
				/>
				<PublishButton disabled={!canEdit}
					onClick={async () => {
						await publishConfigToContract(
							EditorData().changeSet.filter((x) => x.inst === inst),
						);
					}}
				/>
			</Header>
			  <div className="flex flex-col gap-0 rounded-md shadow-xs">
        {allComponents().map(({ key, Inspector, componentObject }) => {
          if (!Inspector) return <div key={key}>{key}</div>;
          if (componentObject === undefined) return null;

          const isOpen = openComponents[key as string] ?? true; // default open

          return (
            <div key={key} className={cn("border-b border-gray-300", !canEdit && "pointer-events-none opacity-50")}>
              {/* Header with toggle button */}
              <div
								className="flex items-center justify-between bg-gray-100 px-2 py-1 cursor-pointer select-none"
								onClick={() => toggleComponent(key as string)}
								aria-expanded={isOpen}
								role="button"
								tabIndex={0}
								onKeyDown={(e) => {
									if (e.key === "Tab" || e.key === " ") {
										e.preventDefault();
										toggleComponent(key as string);
									}
								}}
							>
								<span className="font-semibold">{key}</span>
								<span className="text-xs">{isOpen ? "▼" : "▶"}</span>
							</div>

              {/* Conditionally render the inspector */}
              {isOpen && (
                <Inspector
                  componentObject={componentObject}
                  componentName={key}
                  handleEdit={handleEditComponent}
                  handleRemove={handleRemoveComponent}
                />
              )}
            </div>
          );
        })}
      </div>

      { canEdit &&
				<AddComponents editedEntity={editedEntity} handleEdit={handleEditComponent} />
			}
    </div>
  );
};