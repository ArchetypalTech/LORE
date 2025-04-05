import {
	type EntityCollection,
	type ComponentInspector,
	type WithStringEnums,
	createDefaultEntity,
	createDefaultAreaComponent,
	createDefaultInspectableComponent,
	createDefaultExitComponent,
} from "@/editor/lib/schemas";
import type { Entity } from "@/lib/dojo_bindings/typescript/models.gen";
import { AreaInspector } from "../components/inspectors/AreaInspector";
import { EntityInspector } from "../components/inspectors/EntityInspector";
import { ExitInspector } from "../components/inspectors/ExitInspector";
import { InspectableInspector } from "../components/inspectors/InspectableInspector";

export const componentData: {
	[K in keyof EntityCollection]: {
		order: number;
		inspector?: ComponentInspector<NonNullable<EntityCollection[K]>>;
		icon?: string;
		creator?: (entity: Entity) => WithStringEnums<Pick<EntityCollection, K>>;
	};
} = {
	Entity: {
		order: 0,
		inspector: EntityInspector,
		creator: createDefaultEntity,
	},
	Player: {
		order: 1,
		icon: "👤",
	},
	Area: {
		order: 1,
		inspector: AreaInspector,
		icon: "🥾",
		creator: createDefaultAreaComponent,
	},
	Inspectable: {
		order: 2,
		inspector: InspectableInspector,
		icon: "🔍",
		creator: createDefaultInspectableComponent,
	},
	Exit: {
		order: 3,
		inspector: ExitInspector,
		icon: "🚪",
		creator: createDefaultExitComponent,
	},
};
