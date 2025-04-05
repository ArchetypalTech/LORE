import { useRef, useMemo } from "react";
import EditorData from "../data/editor.data";
import { componentData } from "../lib/components";
import type { AnyObject, EntityComponents } from "../lib/schemas";
import { Select } from "./FormComponents";

export const AddComponents = ({
	editedEntity,
	handleEdit,
}: {
	editedEntity: AnyObject;
	handleEdit: (
		key: keyof EntityComponents,
		component: EntityComponents[keyof EntityComponents],
	) => Promise<void>;
}) => {
	const selectRef = useRef<HTMLSelectElement>(null);

	const options = useMemo(() => {
		const o = Object.entries(componentData)
			.filter(([key, value]) => {
				return (
					editedEntity[key as keyof typeof editedEntity] === undefined &&
					value.creator !== undefined
				);
			})
			.map(([key]) => ({ value: key, label: key }));
		return o;
	}, [editedEntity]);

	const handleAddComponent = async (_e: React.MouseEvent<HTMLButtonElement>) => {
		console.log(selectRef.current?.value);
		const key = selectRef.current?.value as keyof EntityComponents;
		const component = componentData[key];
		if (!component) {
			throw new Error(`Component not found: ${key}`);
		}
		if (!component.creator) {
			throw new Error(`Component has no creator: ${key}`);
		}
		const newComponent = component.creator(editedEntity.Entity!);
		console.log(newComponent);
		// EditorData().syncItem(newComponent as unknown as AnyObject);
		// EditorData().set({
		// 	isDirty: Date.now(),
		// });
		// EditorData().selectEntity(editedEntity.Entity!.inst);
		handleEdit(
			key,
			newComponent[
				key as keyof typeof newComponent
			] as EntityComponents[keyof EntityComponents],
		);
	};

	return (
		<div className="w-full flex flex-row gap-2 items-end">
			<div className="flex grow items-center">
				<Select
					ref={selectRef}
					id=""
					onChange={() => {}}
					options={options}
					disabled={options.length === 0}
				/>
			</div>
			<button
				className="btn btn-success btn-sm shrink"
				onClick={handleAddComponent}
				disabled={options.length === 0}
			>
				Add Component
			</button>
		</div>
	);
};
