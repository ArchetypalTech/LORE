import {
	type RenderItemProps,
	SortableTree,
	type SortableTreeMove,
	type TreeItems,
} from "dnd-kit-tree";
import { HousePlus, LogIn, PersonStanding, SquarePen } from "lucide-react";
import { ChangeEvent, useEffect, useMemo, useRef, useState } from "react";
import type { BigNumberish } from "starknet";
import type { Entity } from "@/lib/dojo_bindings/typescript/models.gen";
import { bigintToHex, cn } from "@/lib/utils/utils";
import EditorData, { useEditorData } from "../data/editor.data";
import { componentData } from "../lib/components";
import type { EntityCollection } from "../lib/types";
import { Button } from "./ui/Button";
import { Select } from "./FormComponents";
import EditorStore, { useEditorPermissions } from "@/lib/stores/editor.store";

type TreeNodeData = {
	entity: EntityCollection,
	isEditable: boolean,
};
type TreeNode = {
	id: BigNumberish;
	data: TreeNodeData;
	children: TreeNode[];
	collapsed: boolean;
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
}: RenderItemProps<TreeNodeData>) => {
	const entity = node.data?.entity as EntityCollection;
	const isCollapsed = node.collapsed;
	const isEditable = node.data?.isEditable ?? false;
	const { selectedEntity } = useEditorData();
	const isSelected = selectedEntity === entity.Entity.inst;
	const isRoot = (entity.ChildToParent === undefined);
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
		<div ref={wrapperRef} id={`item_${bigintToHex(entity.Entity.inst)}`}>
			<div
				className={cn(
					"relative flex flex-row overflow-visible opacity-80",
					isRoot && ("border-1 rounded-sm" + (isEditable ? " border-solid" : " border-dashed")),
					isSelected && "font-bold opacity-100 bg-black/20",
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
									if (!isEditable) return;
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
								className={cn(
									"absolute top-0 left-0 h-7 w-full",
									isEditable ? "cursor-pointer" : "cursor-no-drop"
								)}
							/>

							{/* Highlight when selected */}
							{isSelected && (
								<div className="-left-1 -z-1 absolute top-0 h-[100%] w-[calc(100%+.5rem)] rotate-[.26deg]" />
							)}

							{/* Collapse toggle button */}
							{isCollapsible && (
								<button
									className="cursor-pointer z-20 text-xs"
									onClick={(e) => {
										EditorData().setEntityCollapsed(node.id, !isCollapsed);
										e.stopPropagation();
										onCollapse?.();
									}}
									type="button"
								>
									{!isCollapsed ? "▼" : "▶"}
								</button>
							)}

							{/* Entity name */}
							<div className={`flex-grow whitespace-nowrap ml-7`}>{entity.Entity.name}</div>

							{/* Icons */}
							<div className={`absolute right opacity-50 hover:opacity-100 ${isCollapsible?"ml-3":"ml-1"}`}>
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
		if (entity === undefined || entity.Entity === undefined || !EditorData().shouldDisplayEntity(entity)) return [];

		// Store unique entity
		uniqueEntities.set(instStr, entity);

		let children:TreeNode[] = entity.ParentToChildren?.children?.flatMap((child) => {
			return getNode(child.toString());
		}) ?? [];

		return [{
			id: inst,
			data: {
				entity: entity as { Entity: Entity },
				isEditable: EditorStore().canEditEntity(entity),
			},
			children,
			collapsed: EditorData().isEntityCollapsed(inst),
		}];
	};

	// construct the tree
	const tree = parents.flatMap((parent) =>
		getNode(parent!.Entity.inst),
	) as unknown as TreeItems<TreeNodeData>;

	return { tree };
};

export const HierarchyTree = () => {
	const { dataPool, isDirty, trailIdsFilter, selectedEntity } = useEditorData();
	const [data, setData] = useState(createTree().tree);

	useEffect(() => {
		dataPool;
		isDirty;
		setData(createTree().tree);
	}, [dataPool, isDirty, trailIdsFilter]);

	// scroll to selected entity
	const treeRef = useRef<HTMLDivElement>(null);
	useEffect(() => {
		if (selectedEntity && treeRef.current) {
			const selectedItem = treeRef.current.querySelector(`#item_${bigintToHex(selectedEntity)}`);
			if (selectedItem) {
				selectedItem.scrollIntoView({ behavior: "smooth", block: "nearest" });
			}
		}
	}, [selectedEntity, treeRef.current, data]);

	return (
		<div className="use-editor-styles flex h-full flex-col items-start justify-start gap-4">
			<HierarchyTreeMenu />
			<HierarchyTreeFilter />
			<div ref={treeRef} className="flex h-full max-h-[1500px] flex-col gap-1.25 overflow-y-scroll overflow-x-clip scrollbar-hide">
				<SortableTree
					removable={false}
					collapsible={true}
					value={data}
					onChange={(items: TreeItems<TreeNodeData>) => {
						// apply tree changes
						setData(items);
						// rebuild tree to revert unauthorized moves
						EditorData().setIsDirty();
					}}
					onMove={(action: SortableTreeMove) => {
						// get entity being moved
						const child = EditorData().getEntity(action.id);
						if (!child) throw new Error("Child not found");

						// get new parent
						const newParent = EditorData().getEntity(action.parentId!);
						if (!newParent) throw new Error("Parent not found");
						
						// check if new parent is editable
						if (EditorStore().canEditEntity(newParent)) {
							if (action.parentId === undefined) {
								// remove from current parent
								EditorData().removeParent(child);
							} else {
								// add to new parent
								EditorData().addToParent(child, newParent);
							}
						}
					}}
					renderItem={HierarchyTreeItem}
				/>
			</div>
		</div>
	);
};


const HierarchyTreeMenu = () => {
	const { selectedEntity } = useEditorData();
	const { isAdmin } = useEditorPermissions();

	const { hasPlayer, canCreateEntity } = useMemo(() => {
		const player = EditorData().getPlayerEntity();
		const canCreateEntity = selectedEntity ? EditorStore().canEditEntity(EditorData().getEntity(selectedEntity)) : false;
		return {
			hasPlayer: Boolean(player),
			canCreateEntity: canCreateEntity,
		};
	}, [selectedEntity]);

	if (isAdmin) {
		return (
			<>
				<Button variant={"hero"} disabled={!canCreateEntity} onClick={() => EditorData().newEntity()}>
					<SquarePen />
					New Entity
				</Button>
				<Button variant={"hero"} onClick={() => EditorData().newPlayer()}>
					<PersonStanding />
					{hasPlayer ? "Select Player" : "New Player"}
				</Button>
			</>
		);
	} else {
		return (
			<>
				<Button variant={"hero"} onClick={() => sendCommand("g_create_trail")}>
					<HousePlus /> Create Trail
				</Button>
				<Button variant={"hero"} disabled={!canCreateEntity} onClick={() => EditorData().newEntity()}>
					<SquarePen />
					New Entity
				</Button>
			</>
		);
	}
};

type HierarchyTreeFilterOptions = "all" | "orug" | "mine";

const HierarchyTreeFilter = () => {
	const { isAdmin } = useEditorPermissions();

	// TODO... get owned trail ids
	const ownedTrailIds: bigint[] = useMemo(() => [], []);

	const options = useMemo(() => (isAdmin ? [
		{ value: "orug", label: "Display ORug" },
		{ value: "all", label: "Display ORug + Players" },
	] : [
		{ value: "all", label: "Display Orug + Mine" },
		{ value: "orug", label: "Display ORug" },
		{ value: "mine", label: "Display Mine" },
	]), [isAdmin]);

	const [filter, setFilter] = useState<HierarchyTreeFilterOptions>(isAdmin ? "orug" : "all");
	const _onChange = (e: ChangeEvent<HTMLSelectElement>) => {
		setFilter(e.target.value as HierarchyTreeFilterOptions);
	};

	useEffect(() => {
		if (filter === "all") {
			EditorData().setTrailIdsFilter(isAdmin ? [] : [0n, ...ownedTrailIds]);
		} else if (filter === "orug") {
			EditorData().setTrailIdsFilter([0n]);
		} else if (filter === "mine") {
			EditorData().setTrailIdsFilter([...ownedTrailIds]);
		}
	}, [filter, ownedTrailIds]);

	return (
		<Select
			// ref={selectRef}
			id=""
			defaultValue={options?.[0]?.value || undefined}
			onChange={_onChange}
			options={options}
			disabled={options.length === 0}
		/>
	);
};
