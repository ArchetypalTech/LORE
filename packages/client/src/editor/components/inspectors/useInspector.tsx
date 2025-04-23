import JSONbig from "json-bigint";
import { Trash2 } from "lucide-react";
import { type ChangeEvent, type FC, useCallback } from "react";
import type { BigNumberish } from "starknet";
import EditorData from "@/editor/data/editor.data";
import { formatColorHash } from "@/editor/editor.utils";
import { componentData } from "@/editor/lib/components";
import type {
	AnyObject,
	EntityCollection,
	WithStringEnums,
} from "@/editor/lib/types";
import { Button } from "../ui/Button";

// Using a type union to handle different HTML element types
type InputEvent =
	| ChangeEvent<HTMLInputElement>
	| ChangeEvent<HTMLSelectElement>
	| ChangeEvent<HTMLTextAreaElement>;

type InputHandler<T> = (
	e: InputEvent,
	updatedObject: WithStringEnums<T>,
) => void;

export type ComponentInspector<T> = FC<{
	componentObject: T;
	componentName: keyof NonNullable<EntityCollection>;
	handleEdit: (
		componentName: keyof EntityCollection,
		component: T,
	) => Promise<void>;
	handleRemove: (componentName: keyof EntityCollection) => void;
}>;

type InspectorProps<T extends { inst: BigNumberish }> = {
	componentObject: T;
	componentName: keyof EntityCollection;
	handleEdit: (
		componentName: keyof EntityCollection,
		component: T,
	) => Promise<void>;
	handleRemove: (componentName: keyof EntityCollection) => void;
	inputHandlers?: {
		[key: string]: InputHandler<T>;
	};
};

export const useInspector = <T extends { inst: BigNumberish }>({
	componentObject,
	componentName,
	handleEdit,
	handleRemove,
	inputHandlers = {},
}: InspectorProps<T>) => {
	const handleInputChange = (e: InputEvent) => {
		if (!componentObject) return;

		const entity = EditorData().getEntity(componentObject.inst);
		if (!entity) {
			throw new Error("Entity not found");
		}
		const component = entity[componentName as keyof typeof entity];
		if (!component) {
			throw new Error(`${componentName} not found`);
		}

		const updatedObject = {
			...component,
		} as unknown as T;

		const { id, value } = e.target;

		// Use custom handler if provided, otherwise use default behavior
		if (inputHandlers[id]) {
			inputHandlers[id](e, updatedObject as WithStringEnums<T>);
		} else {
			// Default behavior: direct assignment
			updatedObject[id as keyof T] = value as unknown as T[keyof T];
		}

		const editorObject = {
			...entity,
			[componentName]: updatedObject,
		} as AnyObject;
		if (!editorObject) {
			throw new Error("Editor object not found");
		}
		// @dev: check if we have any changes- if not we don't blur the inputs; if we don't do this, we can't use tab to select different fields (as react updates whole entity inspector)
		if (JSONbig.stringify(editorObject) !== JSONbig.stringify(entity)) {
			handleEdit(componentName, updatedObject);
		}
	};

	const Inspector = useCallback(
		({ children }: React.PropsWithChildren) => {
			return (
				<div className="component-inspector">
					<div className="relative flex w-full flex-row items-center justify-end gap-2 text-right font-bold text-black/50 text-xs uppercase">
						<h6>
							{`${componentData[componentName]?.icon || ""} `}
							{componentName}
						</h6>
						<div
							className="text-[7pt] text-black/20 opacity-0 hover:opacity-100"
							// biome-ignore lint/security/noDangerouslySetInnerHtml: <hey, sometimes, you have to live dangerously!>
							dangerouslySetInnerHTML={{
								__html: formatColorHash(componentObject.inst),
							}}
						/>
						<div className="flex grow" />
						{componentName !== "Entity" && (
							<Button
								title={`Remove ${componentName} component`}
								variant={"ghost"}
								size="sm"
								onClick={() => handleRemove(componentName)}
								className="h-2 w-2 opacity-50 hover:opacity-100"
							>
								<Trash2 />
							</Button>
						)}
					</div>
					<div className="flex flex-col gap-2">{children}</div>
				</div>
			);
		},
		[componentObject, componentName, handleRemove],
	);

	return { handleInputChange, Inspector };
};
