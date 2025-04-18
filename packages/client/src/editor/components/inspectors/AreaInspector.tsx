import { stringCairoEnum } from "@/editor/lib/schemas";
import {
	type Area,
	direction,
} from "@/lib/dojo_bindings/typescript/models.gen";
import { CairoEnumSelect } from "../FormComponents";
import type { ComponentInspector } from "./useInspector";
import { useInspector } from "./useInspector";

export const AreaInspector: ComponentInspector<Area> = ({
	componentObject,
	...props
}) => {
	const { handleInputChange, Inspector } = useInspector<Area>({
		componentObject,
		...props,
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
