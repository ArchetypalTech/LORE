import { useCairoEnum, type ComponentInspector } from "@/editor/lib/schemas";
import { Select } from "../FormComponents";
import {
	direction,
	type Area,
} from "@/lib/dojo_bindings/typescript/models.gen";
import type { CairoCustomEnum } from "starknet";
import { useInspector } from "./useInspector";

export const AreaInspector: ComponentInspector<Area> = ({
	componentObject,
	componentName,
}) => {
	const { value: direction_value, options: direction_options } = useCairoEnum(
		componentObject?.direction,
		direction,
	);

	const { handleInputChange, Inspector } = useInspector<Area>({
		componentObject,
		componentName,
		inputHandlers: {
			direction: (e, updatedObject) => {
				console.log(e.target.value);
				updatedObject.direction = e.target.value as unknown as CairoCustomEnum;
			},
		},
	});

	if (!componentObject) return <div>Area not found</div>;

	return (
		<Inspector>
			<Select
				id="direction"
				defaultValue={direction_value}
				onChange={handleInputChange}
				options={direction_options}
			/>
		</Inspector>
	);
};
