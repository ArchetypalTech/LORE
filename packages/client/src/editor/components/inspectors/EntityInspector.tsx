import type { Entity } from "@/lib/dojo_bindings/typescript/models.gen";
import { Input, TagInput } from "../FormComponents";
import type { ComponentInspector } from "./useInspector";
import { useInspector } from "./useInspector";

export const EntityInspector: ComponentInspector<Entity> = ({
	componentObject,
	...props
}) => {
	const { handleInputChange, Inspector } = useInspector<Entity>({
		componentObject,
		...props,
		inputHandlers: {
			name: (e, updatedObject) => {
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
