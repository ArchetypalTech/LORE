import { useMemo, useRef } from "react";
import { componentData } from "../lib/components";
import type { AnyObject, EntityCollection } from "../lib/types";
import { Select } from "./FormComponents";
import { Button } from "./ui/Button";
import type { SelectInputRef } from "./ui/Select";

const ALWAYS_INCLUDE = ["DescriptionText", "Trigger", "Effect", "Condition", "Action" ] as const;
const ALWAYS_EXCLUDE = ["PlayerStory" ] as const;

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
				 // Always include if key is in ALWAYS_INCLUDE
				if (ALWAYS_INCLUDE.includes(key as typeof ALWAYS_INCLUDE[number])) {
					return true;
				}
				if (ALWAYS_EXCLUDE.includes(key as typeof ALWAYS_EXCLUDE[number])) {
					return false;
				}
				return (
					editedEntity[key as keyof typeof editedEntity] === undefined &&
					value.creator !== undefined
				);
			})
			.map(([key, value]) => ({ value: key, label: `${value.icon} ${key}` }));
		return o;
	}, [editedEntity]);

	const handleAddComponent = async (
		key: keyof EntityCollection | undefined = undefined,
	) => {
		if (key === undefined) {
			return;
		}
		const component = componentData[key];
		if (!component) {
			throw new Error(`Component not found: ${key}`);
		}
		if (!component.creator) {
			throw new Error(`Component has no creator: ${key}`);
		}

		let newComponent;
		if (key === "DescriptionText" && editedEntity.DescriptionText) {
			console.log("DescriptionText", editedEntity.DescriptionText);
			newComponent = component.creator(editedEntity.Entity!, editedEntity.DescriptionText);
		} else if (key === "Reactable" && editedEntity.DescriptionText) {
			console.log("Reactable", editedEntity.DescriptionText);
			newComponent = component.creator(editedEntity.Entity!, editedEntity.DescriptionText);
		} else {
			newComponent = component.creator(editedEntity.Entity!);
		}
		
		console.log(newComponent);
		handleEdit(
			key,
			newComponent[
				key as keyof typeof newComponent
			] as EntityCollection[keyof EntityCollection],
		);
	};

	return (
		<div className="flex flex-col gap-2">
			<div className="text-xs opacity-50 font-medium">add component</div>
			{options.length < 12 && (
				<div className="grid grid-cols-5 gap-5">
					{options.map((option) => (
						<div
							key={option.value}
							className="relative flex items-center justify-center text-center group"
						>
							<Button
								key={option.value}
								variant="outline"
								className="shrink rounded-full"
								title={`Add ${option.label} component`}
								onClick={() => {
									handleAddComponent(option.value as keyof EntityCollection);
								}}
							>
								{
									componentData[option.value as keyof typeof componentData]!
										.icon
								}
							</Button>
							<div className="absolute top-[105%] grayscale-100 hover:grayscale-0 text-[7pt] uppercase bg-black text-white px-0.75 group-hover:opacity-100 opacity-0 transition-all duration-150">
								{option.value}
							</div>
						</div>
					))}
				</div>
			)}

			{options.length > 12 && (
				<div className="flex w-full flex-row items-end gap-2">
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
						onClick={() =>
							handleAddComponent(
								selectRef.current?.getValue() as keyof EntityCollection,
							)
						}
						disabled={options.length === 0}
					>
						Add Component
					</Button>
				</div>
			)}
		</div>
	);
};
