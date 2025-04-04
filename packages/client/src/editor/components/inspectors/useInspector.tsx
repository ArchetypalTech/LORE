import EditorData from "@/editor/editor.data";
import type { AnyObject } from "@/editor/lib/schemas";
import type { ChangeEvent } from "react";
import type { BigNumberish } from "starknet";
import { debounce } from "ts-debounce";

type InputHandler<T> = (
	e:
		| ChangeEvent<HTMLInputElement>
		| ChangeEvent<HTMLSelectElement>
		| ChangeEvent<HTMLOptionElement>,
	updatedObject: T,
) => void;

type InspectorProps<T extends { inst: BigNumberish }> = {
	componentObject: T;
	componentName: string;
	inputHandlers?: {
		[key: string]: InputHandler<T>;
	};
};

export const useInspector = <T extends { inst: BigNumberish }>({
	componentObject,
	componentName,
	inputHandlers = {},
}: InspectorProps<T>) => {
	const handleInputChange = debounce(
		(
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
			};

			const { id, value } = e.target;

			// Use custom handler if provided, otherwise use default behavior
			if (inputHandlers[id]) {
				inputHandlers[id](e, updatedObject);
			} else {
				// Default behavior: direct assignment
				(updatedObject as any)[id] = value;
			}

			const editorObject = {
				...entity,
			} as AnyObject;
			if (!editorObject) {
				throw new Error("Editor object not found");
			}

			Object.assign(editorObject, { [componentName]: updatedObject });
			EditorData().syncItem(editorObject);
			EditorData().selectEntity(entity.Entity.inst);
		},
	);

	return { handleInputChange };
};
