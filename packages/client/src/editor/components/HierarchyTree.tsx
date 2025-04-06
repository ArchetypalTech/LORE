import { useMemo } from "react";
import EditorData, { useEditorData } from "../data/editor.data";
import type { Entity } from "@/lib/dojo_bindings/typescript/models.gen";
import { cn } from "@/lib/utils/utils";
import type { BigNumberish } from "starknet";
import { componentData } from "../lib/components";
import { Button } from "./ui/Button";
import { HousePlus } from "lucide-react";

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
	const isSelected = selectedEntity === node.id;

	const icons = useMemo(() => {
		const entity = EditorData().getEntity(node.id);
		return Object.entries(componentData)
			.filter(([key]) => {
				return entity?.[key as keyof typeof entity] !== undefined;
			})
			.sort((a, b) => a[1].order - b[1].order)
			.slice(0, 2);
	}, [node]);

	return (
		<div
			className={cn(
				"pl-4 font-normal w-full animate-scale-in",
				depth === 0 && "font-medium",
			)}
		>
			<div
				className={cn(
					"relative opacity-80 overflow-visible flex flex-row",
					isSelected && " text-white opacity-100 font-bold",
				)}
				onClick={() => EditorData().selectEntity(node.id.toString())}
			>
				<div className="relative flex">
					{isSelected && (
						<div className="absolute top-0 -left-4 w-[calc(100%+1.25rem)] h-[100%] bg-black/50 -z-1 pl-4 pr-4 rotate-[.26deg]" />
					)}
					{isSelected && (
						<div className="absolute top-0 -left-3 font-white">{">"}</div>
					)}
					{node.name}{" "}
				</div>
				<span className="opacity-50 hover:opacity-100 ml-2">
					{icons.map(([key, value]) => {
						if (value.icon) {
							return (
								<span key={key} title={key}>
									{value.icon}
								</span>
							);
						}
					})}
				</span>
			</div>
			{node.children.map((child: TreeNode) => (
				<HierarchyTreeItem key={child.name} node={child} depth={depth + 1} />
			))}
		</div>
	);
};

export const HierarchyTree = () => {
	const { dataPool, isDirty } = useEditorData();

	const { tree } = useMemo(() => {
		dataPool;
		isDirty;
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
	}, [dataPool, isDirty]);

	return (
		<div className="use-editor-styles h-full items-start flex flex-col gap-4 justify-start">
			<Button
				// className="w-full"
				onClick={() => EditorData().newEntity({} as Entity)}
			>
				<HousePlus />
				New Entity
			</Button>
			<div className="flex flex-col gap-1.25">
				{tree.map((node) => (
					<HierarchyTreeItem key={node.name + node.id} node={node} depth={0} />
				))}
			</div>
		</div>
	);
};
