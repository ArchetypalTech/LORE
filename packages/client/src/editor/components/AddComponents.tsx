import { useMemo, useRef } from "react";
import { componentData } from "../lib/components";
import type { AnyObject, EntityCollection } from "../lib/schemas";
import { Select } from "./FormComponents";
import { Button } from "./ui/Button";
import type { SelectInputRef } from "./ui/Select";

export const AddComponents = ({
	editedEntity,
	handleEdit,
}: {
	editedEntity: AnyObject;
	handleEdit: (
		key: keyof EntityCollection,
		component: EntityCollection[keyof EntityCollection],
	) => Promise<void>;
}) => {
	const selectRef = useRef<SelectInputRef>(null!);

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
		const key = selectRef.current?.getValue() as keyof EntityCollection;
		const component = componentData[key];
		if (!component) {
			throw new Error(`Component not found: ${key}`);
		}
		if (!component.creator) {
			throw new Error(`Component has no creator: ${key}`);
		}
		const newComponent = component.creator(editedEntity.Entity!);
		console.log(newComponent);
		handleEdit(
			key,
			newComponent[
				key as keyof typeof newComponent
			] as EntityCollection[keyof EntityCollection],
		);
	};

	return (
		<div className="w-full flex flex-row gap-2 items-end">
			<div className="flex grow items-center">
				<Select
					ref={selectRef}
					id=""
					defaultValue={options?.[0]?.value || undefined}
					onChange={() => {}}
					options={options}
					disabled={options.length === 0}
				/>
			</div>
			<Button
				variant={"hero"}
				className="shrink"
				onClick={handleAddComponent}
				disabled={options.length === 0}
			>
				Add Component
			</Button>
		</div>
	);
};
