import type { EntityCollection, WithStringEnums } from "@/editor/lib/schemas";
import type {
	Entity,
	SchemaType,
} from "@/lib/dojo_bindings/typescript/models.gen";
import randomName from "@scaleway/random-name";
import { AreaInspector } from "../components/inspectors/AreaInspector";
import { EntityInspector } from "../components/inspectors/EntityInspector";
import { ExitInspector } from "../components/inspectors/ExitInspector";
import { InspectableInspector } from "../components/inspectors/InspectableInspector";
import type { ComponentInspector } from "../components/inspectors/useInspector";
import { randomKey } from "../editor.utils";

export const createDefaultEntity = (): WithStringEnums<
	Pick<SchemaType["lore"], "Entity">
> => ({
	Entity: {
		inst: randomKey(),
		is_entity: true,
		name: randomName(),
		alt_names: [],
	},
});

export const createDefaultAreaComponent = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "Area">> => ({
	Area: {
		inst: entity.inst,
		is_area: true,
		direction: "None",
	},
});

export const createDefaultInspectableComponent = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "Inspectable">> => ({
	Inspectable: {
		inst: entity.inst,
		is_inspectable: true,
		is_visible: true,
		description: [],
		action_map: [],
	},
});

export const createDefaultExitComponent = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "Exit">> => ({
	Exit: {
		inst: entity.inst,
		is_exit: true,
		is_enterable: true,
		leads_to: 0,
		direction_type: "None",
		action_map: [],
	},
});

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
