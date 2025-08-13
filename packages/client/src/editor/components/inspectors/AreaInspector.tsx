import {
	type Area,
} from "@/lib/dojo_bindings/typescript/models.gen";
import type { ComponentInspector } from "./useInspector";
import { useInspector } from "./useInspector";
import { Toggle } from "../FormComponents";

export const AreaInspector: ComponentInspector<Area> = ({
	componentObject,
	...props
}) => {
	const { Inspector, handleInputChange } = useInspector<Area>({
		componentObject,
		...props,
		inputHandlers: {
			is_spawn_point: (e, updatedObject) => {
				const event = e as React.ChangeEvent<HTMLInputElement>;
				updatedObject.is_spawn_point = event.target.checked;
			},
		},
	});

	if (!componentObject) return <div>Area not found</div>;

	return (
		<Inspector>
			<Toggle
				id="is_spawn_point"
				value={componentObject.is_spawn_point}
				onChange={handleInputChange(undefined)}
			/>
		</Inspector>
	);
};
