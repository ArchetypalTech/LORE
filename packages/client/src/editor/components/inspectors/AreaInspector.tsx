import { stringCairoEnum, type ComponentInspector } from "@/editor/lib/schemas";
import { CairoEnumSelect } from "../FormComponents";
import {
	direction,
	type Area,
} from "@/lib/dojo_bindings/typescript/models.gen";
import { useInspector } from "./useInspector";

export const AreaInspector: ComponentInspector<Area> = ({
	componentObject,
	componentName,
	handleEdit,
}) => {
	const { handleInputChange, Inspector } = useInspector<Area>({
		componentObject,
		componentName,
		handleEdit,
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
			<CairoEnumSelect
				id="direction"
				onChange={handleInputChange}
				value={componentObject.direction}
				enum={direction}
			/>
		</Inspector>
	);
};
