import { useMemo } from "react";
import EditorData, { useEditorData } from "../editor.data";
import type { Entity } from "@/lib/dojo_bindings/typescript/models.gen";
import { cn } from "@/lib/utils/utils";
import type { BigNumberish } from "starknet";

type TreeNode = {
	id: BigNumberish;
	name: string;
	children: TreeNode[];
};

export const HierarchyTreeItem = ({
	node,
	depth,
}: { node: TreeNode; depth: number }) => {
	const { selectedEntity } = useEditorData();
	const isSelected = selectedEntity?.Entity!.inst === node.id;
	return (
		<div className={cn("pl-4 font-normal w-full", depth === 0 && "font-medium")}>
			<div
				className={cn(
					"relative opacity-80 overflow-visible",
					isSelected && " text-white opacity-100 font-bold",
				)}
				onClick={() => EditorData().selectEntity(node.id.toString())}
			>
				{isSelected && (
					<div className="absolute top-0 -left-4 w-[100%] h-[100%] bg-black -z-1 px-6" />
				)}
				{isSelected && (
					<div className="absolute top-0 -left-3 font-white">{">"}</div>
				)}
				{node.name}
			</div>
			{node.children.map((child: TreeNode) => (
				<HierarchyTreeItem key={child.name} node={child} depth={depth + 1} />
			))}
		</div>
	);
};

export const HierarchyTree = () => {
	const { dataPool } = useEditorData();

	const { tree } = useMemo(() => {
		dataPool;
		const entities = EditorData().getEntities();
		const parents = entities.filter((e) => !e!.ChildToParent);
		//recursively build tree
		const getNode = (inst: BigNumberish): TreeNode[] => {
			const entity = EditorData().getEntity(inst);
			if (entity === undefined || entity.Entity === undefined) return [];
			if ("ParentToChildren" in entity) {
				const children = entity.ParentToChildren?.children.flatMap((child) => {
					return getNode(child.toString());
				});
				return [{ id: inst, name: entity.Entity.name, children: children || [] }];
			}
			return [
				{
					id: inst,
					name: (entity as { Entity: Entity }).Entity.name,
					children: [],
				},
			];
		};

		// construct the tree
		const tree: TreeNode[] = parents.flatMap((parent) =>
			getNode(parent!.Entity.inst),
		);

		return { tree };
	}, [dataPool]);

	return (
		<div className="h-full items-start flex flex-col gap-2 justify-start">
			<button
				className="btn btn-sm btn-success"
				onClick={() => EditorData().newEntity({} as Entity)}
			>
				New Entity
			</button>
			{tree
				.sort((a, b) => a.id.toString().localeCompare(b.id.toString()))
				.map((node) => (
					<HierarchyTreeItem key={node.name + node.id} node={node} depth={0} />
				))}
		</div>
	);
};
