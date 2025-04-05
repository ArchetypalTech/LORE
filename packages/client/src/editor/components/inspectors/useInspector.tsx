import EditorData from "@/editor/data/editor.data";
import { formatColorHash } from "@/editor/editor.utils";
import type {
	AnyObject,
	EntityComponents,
	WithStringEnums,
} from "@/editor/lib/schemas";
import { useCallback, type ChangeEvent, type FC } from "react";
import type { BigNumberish } from "starknet";
import { DeleteButton } from "../FormComponents";

type InputHandler<T> = (
	e: ChangeEvent<HTMLInputElement>,
	updatedObject: WithStringEnums<T>,
) => void;

export type ComponentInspector<T> = FC<{
	componentObject: T;
	componentName: keyof NonNullable<EntityComponents>;
	handleEdit: (
		componentName: keyof EntityComponents,
		component: T,
	) => Promise<void>;
	handleRemove: (componentName: keyof EntityComponents, component: T) => void;
}>;

type InspectorProps<T extends { inst: BigNumberish }> = {
	componentObject: T;
	componentName: keyof EntityComponents;
	handleEdit: (
		componentName: keyof EntityComponents,
		component: T,
	) => Promise<void>;
	handleRemove: (componentName: keyof EntityComponents, component: T) => void;
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
	const handleInputChange = (
		e: ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLOptionElement>,
	) => {
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
			inputHandlers[id](
				e as unknown as ChangeEvent<HTMLInputElement>,
				updatedObject as WithStringEnums<T>,
			);
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
		console.log(updatedObject, editorObject);
		handleEdit(componentName, updatedObject);
	};

	const Inspector = useCallback(
		({ children }: React.PropsWithChildren) => {
			console.warn("trace", componentObject);
			return (
				<div className="flex flex-col gap-2 border border-dotted border-black/20 p-2 rounded-md bg-black/1 shadow-xs animate-scale-in">
					<h3 className="w-full text-right text-xs uppercase text-black/50 font-bold flex flex-row items-center justify-end gap-2">
						<div
							className="text-[7pt] text-black/20 hover:opacity-100 opacity-0"
							// biome-ignore lint/security/noDangerouslySetInnerHtml: <hey, sometimes, you have to live dangerously!>
							dangerouslySetInnerHTML={{
								__html: formatColorHash(componentObject.inst),
							}}
						/>
						<div>{componentName}</div>
						<DeleteButton onClick={() => handleRemove(componentName,componentObject)} className="" />
					</h3>
					<div className="flex flex-col gap-2">{children}</div>
				</div>
			);
		},
		[componentObject, componentName],
	);

	return { handleInputChange, Inspector };
};
