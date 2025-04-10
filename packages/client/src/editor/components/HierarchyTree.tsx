import type { Entity } from "@/lib/dojo_bindings/typescript/models.gen";
import { cn } from "@/lib/utils/utils";
import { HousePlus } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import type { BigNumberish } from "starknet";
import EditorData, { useEditorData } from "../data/editor.data";
import { Button } from "./ui/Button";
import {
	SortableTree,
	type RenderItemProps,
	type TreeItems,
} from "dnd-kit-tree";
import type { EntityCollection } from "../lib/types";
import { componentData } from "../lib/components";

type TreeNode = {
	id: BigNumberish;
	data: { entity: EntityCollection };
	children: TreeNode[];
};

export const HierarchyTreeItem = ({
	wrapperRef,
	depth,
	containerRef,
	containerStyle,
	isDragging,
	clone,
	handleProps,
	isCollapsible,
	onCollapse,
	node,
	childCount,
}: RenderItemProps<TreeNode["data"]>) => {
	const entity = node.data?.entity as EntityCollection;
	if (!entity) return null;
	const { selectedEntity } = useEditorData();
	const isSelected = selectedEntity === entity.Entity.inst;
	const [timer, setTimer] = useState<NodeJS.Timer>();

	// Extract onPointerDown from handleProps safely
	const { onPointerDown, ...otherHandleProps } = handleProps || {};

	const icons = useMemo(() => {
		return Object.entries(componentData)
			.filter(([key]) => {
				return entity[key as keyof typeof entity] !== undefined;
			})
			.sort((a, b) => a[1].order - b[1].order)
			.slice(0, 2);
	}, [entity]);

	return (
		<div ref={wrapperRef}>
			<div
				className={cn(
					"relative opacity-80 overflow-visible flex flex-row",
					isSelected && " text-white opacity-100 font-bold",
				)}
				style={{
					paddingLeft: `${depth * 1}rem`,
				}}
			>
				<div
					ref={containerRef}
					style={containerStyle}
					className={
						isDragging
							? cn(["relative rounded-xs bg-gray-800/10 w-40 h-4"])
							: cn("relative", {
									flex: !clone,
									"inline-flex": clone,
								})
					}
				>
					{!isDragging && (
						<>
							<button
								{...otherHandleProps}
								onPointerDown={(event) => {
									event.stopPropagation();

									EditorData().selectEntity(node.id.toString());
									const t = setTimeout(() => {
										onPointerDown?.(event);
										clearTimeout(timer);
										setTimer(undefined);
									}, 300);
									setTimer(t);
								}}
								onPointerUp={() => {
									clearTimeout(timer);
									setTimer(undefined);
								}}
								className="cursor-pointer absolute top-0 left-0 w-full h-full"
							/>
							{isSelected && (
								<div className="absolute top-0 -left-1 w-[calc(100%+.5rem)] h-[100%] bg-black/20 -z-1 rotate-[.26deg]" />
							)}
							{isCollapsible && (
								<button className="cursor-pointer p-1" onClick={onCollapse} type="button">
									XX
								</button>
							)}
							<div className="flex-grow-1">{entity.Entity.name} </div>
							<div className="absolute left-[100%] opacity-50 hover:opacity-100 ml-2">
								{icons.map(([key, value]) => {
									if (value.icon) {
										return (
											<span key={key} title={key}>
												{value.icon}
											</span>
										);
									}
								})}
							</div>
							{clone && childCount > 0 && (
								<div className="flex absolute items-center justify-center rounded-xs bg-black top-[-12px] right-[-12px] w-[25px] h-[25px] font-xs text-white rotate-[2deg]">
									{childCount}
								</div>
							)}
						</>
					)}
				</div>
			</div>
		</div>
	);
};

const createTree = () => {
	const entities = EditorData().getEntities();
	const parents = entities.filter((e) => !e!.ChildToParent);
	//recursively build tree
	const getNode = (inst: BigNumberish): TreeNode[] => {
		const entity = EditorData().getEntity(inst);
		if (entity === undefined || entity.Entity === undefined) return [];
		if ("ParentToChildren" in entity && entity.ParentToChildren !== undefined) {
			const children = entity.ParentToChildren?.children.flatMap((child) => {
				return getNode(child.toString());
			});
			return [{ id: inst, data: { entity: entity }, children: children || [] }];
		}
		return [
			{
				id: inst,
				data: { entity: entity as { Entity: Entity } },
				children: [],
			},
		];
	};

	// construct the tree
	const tree = parents.flatMap((parent) =>
		getNode(parent!.Entity.inst),
	) as unknown as TreeItems<TreeNode["data"]>;

	return { tree };
};

export const HierarchyTree = () => {
	const { dataPool, isDirty } = useEditorData();
	const [data, setData] = useState(createTree().tree);

	useEffect(() => {
		dataPool;
		isDirty;
		setData(createTree().tree);
	}, [dataPool, isDirty]);

	return (
		<div className="use-editor-styles h-full items-start flex flex-col gap-4 justify-start">
			<Button
				variant={"hero"}
				// className="w-full"
				onClick={() => EditorData().newEntity()}
			>
				<HousePlus />
				New Entity
			</Button>
			<div className="flex flex-col gap-1.25">
				<SortableTree
					removable={false}
					collapsible={false}
					value={data}
					onChange={setData}
					onMove={(action) => {
						const child = EditorData().getEntity(action.id);

						if (!child) throw new Error("Child not found");
						if (action.parentId === undefined) {
							EditorData().removeParent(child);
							return;
						}

						const parent = EditorData().getEntity(action.parentId!);
						if (!parent) throw new Error("Parent not found");
						EditorData().addToParent(child, parent);
						return;
					}}
					renderItem={HierarchyTreeItem}
				/>
			</div>
		</div>
	);
};
