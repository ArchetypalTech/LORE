import {
	type RenderItemProps,
	SortableTree,
	type TreeItems,
} from "dnd-kit-tree";
import { HousePlus, PersonStanding } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import type { BigNumberish } from "starknet";
import type { Entity } from "@/lib/dojo_bindings/typescript/models.gen";
import { cn } from "@/lib/utils/utils";
import EditorData, { useEditorData } from "../data/editor.data";
import { componentData } from "../lib/components";
import type { EntityCollection } from "../lib/types";
import { Button } from "./ui/Button";
import { useEditorPermissions } from "@/lib/stores/editor.store";

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
	const isCollapsed = node.collapsed;
	const { selectedEntity } = useEditorData();
	const isSelected = selectedEntity === entity.Entity.inst;
	const [timer, setTimer] = useState<NodeJS.Timer>();

	// Extract onPointerDown from handleProps safely
	const { onPointerDown, ...otherHandleProps } = handleProps || {};

	const icons = useMemo(() => {
		return Object.entries(componentData)
			.filter(([key]) => entity[key as keyof typeof entity] !== undefined)
			.sort((a, b) => a[1].order - b[1].order)
			.slice(0, 2);
	}, [entity]);

	return (
		<div ref={wrapperRef}>
			<div
				className={cn(
					"relative flex flex-row overflow-visible opacity-80",
					isSelected && "font-bold text-white opacity-100",
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
							? cn(["relative h-4 w-40 rounded-xs bg-gray-800/10"])
							: cn("relative", {
									flex: !clone,
									"inline-flex": clone,
								})
					}
				>
					{!isDragging && (
						<>
							{/* Smaller drag handle (only left-side) */}
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
								className="absolute top-0 left-0 h-7 w-full cursor-pointer"
							/>

							{/* Highlight when selected */}
							{isSelected && (
								<div className="-left-1 -z-1 absolute top-0 h-[100%] w-[calc(100%+.5rem)] rotate-[.26deg] bg-black/20" />
							)}

							{/* Collapse toggle button */}
							{isCollapsible && (
								<button
									className="cursor-pointer z-20 text-xl"
									onClick={(e) => {
										e.stopPropagation();
										onCollapse?.();
									}}
									type="button"
								>
									{isCollapsed ? "▶" : "▼"}
								</button>
							)}

							{/* Entity name */}
							<div className="flex-grow ml-2">{entity.Entity.name}</div>

							{/* Icons */}
							<div className="absolute left-[100%] ml-2 opacity-50 hover:opacity-100">
								{icons.map(([key, value]) =>
									value.icon ? (
										<span key={key} title={key}>
											{value.icon}
										</span>
									) : null,
								)}
							</div>

							{/* Clone child count badge */}
							{clone && childCount > 0 && (
								<div className="absolute top-[-12px] right-[-12px] flex h-[25px] w-[25px] rotate-[2deg] items-center justify-center rounded-xs bg-black font-xs text-white">
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

	// Track unique entities by ID
	const uniqueEntities = new Map<string, EntityCollection>();
	const processedIds = new Set<string>();

	//recursively build tree
	const getNode = (inst: BigNumberish): TreeNode[] => {
		const instStr = inst.toString();

		// Skip if we've already processed this ID
		if (processedIds.has(instStr)) {
			return [];
		}
		processedIds.add(instStr);

		const entity = EditorData().getEntity(inst);
		if (entity === undefined || entity.Entity === undefined) return [];

		// Store unique entity
		uniqueEntities.set(instStr, entity);

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
	const { isAdmin } = useEditorPermissions();

	useEffect(() => {
		dataPool;
		isDirty;
		setData(createTree().tree);
	}, [dataPool, isDirty]);

	return (
		<div className="use-editor-styles flex h-full flex-col items-start justify-start gap-4">

			{isAdmin && (
				<>
					<Button variant={"hero"} onClick={() => EditorData().newEntity()}>
						<HousePlus />
						New Entity
					</Button>
					<Button variant={"hero"} onClick={() => EditorData().newPlayer()}>
						<PersonStanding />
						New Player
					</Button>
				</>
			)}

			{!isAdmin && (
				<>
					<Button variant={"hero"} onClick={() => {}}>
						<HousePlus />
						Your Trail
					</Button>
				</>
			)}

			<div className="flex h-full max-h-[1500px] flex-col gap-1.25 overflow-y-scroll overflow-x-clip scrollbar-hide">
				<SortableTree
					removable={false}
					collapsible={true}
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
