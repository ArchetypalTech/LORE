import { useMemo } from "react";
import EditorData, { useEditorData } from "../editor.data";
import type { Entity } from "@/lib/dojo_bindings/typescript/models.gen";
import { cn } from "@/lib/utils/utils";

type TreeNode = {
	id: string;
	name: string;
	children: TreeNode[];
};

export const HierarchyTreeItem = ({
	node,
	depth,
}: { node: TreeNode; depth: number }) => {
	const { selectedEntity } = useEditorData();
	const isSelected = selectedEntity?.Entity.inst === node.id;
	const icon = isSelected ? "> " : " ";
	return (
		<div className={cn("pl-4 font-normal", depth === 0 && "font-medium")}>
			<div
				className={cn(
					"opacity-80",
					isSelected && "bg-amber-600/70 text-white opacity-100",
				)}
				onClick={() => EditorData().selectEntity(node.id.toString())}
			>
				{icon}
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
		console.log(entities, parents);

		//recursively build tree
		const getNode = (inst: string): TreeNode[] => {
			const entity = EditorData().getEntity(inst);
			if (entity === undefined) return [];
			if ("ParentToChildren" in entity) {
				const children = entity.ParentToChildren.children.flatMap((child) => {
					return getNode(child.toString());
				});
				return [{ id: inst, name: entity.Entity.name, children }];
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
			getNode(parent!.Entity.inst.toString()),
		);

		console.log(tree);

		return { tree };
	}, [dataPool]);

	return (
		<div className="h-full items-start flex flex-col gap-2 justify-start">
			<div>
				{tree.map((node) => (
					<HierarchyTreeItem key={node.name} node={node} depth={0} />
				))}
			</div>
		</div>
	);
};
