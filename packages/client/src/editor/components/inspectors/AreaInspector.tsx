import {
	stringCairoEnum,
	useCairoEnum,
	type ComponentInspector,
} from "@/editor/lib/schemas";
import { Select } from "../FormComponents";
import {
	direction,
	type Area,
} from "@/lib/dojo_bindings/typescript/models.gen";
import { useInspector } from "./useInspector";

export const AreaInspector: ComponentInspector<Area> = ({
	componentObject,
	componentName,
}) => {
	// @dev: convert cairo enum
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
				updatedObject.direction = stringCairoEnum(e.target.value);
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
