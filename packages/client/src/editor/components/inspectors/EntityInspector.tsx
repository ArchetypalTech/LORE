import type { ComponentInspector } from "@/editor/lib/schemas";
import { Input, TagInput } from "../FormComponents";
import type { Entity } from "@/lib/dojo_bindings/typescript/models.gen";
import { useInspector } from "./useInspector";

export const EntityInspector: ComponentInspector<Entity> = ({
	componentObject,
	componentName,
	handleEdit,
}) => {
	const { handleInputChange, Inspector } = useInspector<Entity>({
		componentObject,
		componentName,
		handleEdit,
		inputHandlers: {
			name: (e, updatedObject) => {
				console.log(e, e.target.value);
				updatedObject.name = e.target.value;
			},
			alt_names: (e, updatedObject) => {
				updatedObject.alt_names = (e.target.value as unknown as string[]).filter(
					(x) => x !== "",
				);
			},
		},
	});

	if (!componentObject) return <div>Entity not found</div>;

	return (
		<Inspector>
			<Input id="name" value={componentObject.name} onChange={handleInputChange} />
			<TagInput
				id="alt_names"
				value={componentObject.alt_names?.join(",") || ""}
				onChange={handleInputChange}
			/>
		</Inspector>
	);
};
