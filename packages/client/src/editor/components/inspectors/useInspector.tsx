import EditorData from "@/editor/editor.data";
import type { AnyObject, WithStringEnums } from "@/editor/lib/schemas";
import { formatColorHash } from "@/editor/utils";
import type { ChangeEvent } from "react";
import type { BigNumberish } from "starknet";
import { debounce } from "ts-debounce";

type InputHandler<T> = (
	e: ChangeEvent<HTMLInputElement>,
	updatedObject: WithStringEnums<T>,
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
			} as AnyObject;
			if (!editorObject) {
				throw new Error("Editor object not found");
			}
			console.log(updatedObject, editorObject);
			Object.assign(editorObject, { [componentName]: updatedObject });
			EditorData().syncItem(editorObject);
			EditorData().selectEntity(entity.Entity.inst);
		},
	);

	const Inspector = ({ children }: React.PropsWithChildren) => {
		return (
			<div className="flex flex-col gap-2 border border-dotted border-black/20 p-2 rounded-md bg-black/1 shadow-xs">
				<h3 className="w-full text-right text-xs uppercase text-black/50 font-bold flex flex-row items-center justify-end gap-2">
					<div
						className="text-[7pt] text-black/20 hover:opacity-100 opacity-0"
						// biome-ignore lint/security/noDangerouslySetInnerHtml: <hey, sometimes, you have to live dangerously!>
						dangerouslySetInnerHTML={{
							__html: formatColorHash(componentObject.inst),
						}}
					/>
					<div>{componentName}</div>
				</h3>
				<div className="flex flex-col gap-2">{children}</div>
			</div>
		);
	};

	return { handleInputChange, Inspector };
};
