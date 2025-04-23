import {
	type Area,
} from "@/lib/dojo_bindings/typescript/models.gen";
import type { ComponentInspector } from "./useInspector";
import { useInspector } from "./useInspector";

export const AreaInspector: ComponentInspector<Area> = ({
	componentObject,
	...props
}) => {
	const { Inspector } = useInspector<Area>({
		componentObject,
		...props,
	});

	if (!componentObject) return <div>Area not found</div>;

	return (
		<Inspector>
		</Inspector>
	);
};
