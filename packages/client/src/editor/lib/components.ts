import {
	type Entity,
	type SchemaType,
	schema,
} from "@/lib/dojo_bindings/typescript/models.gen";
import randomName from "@scaleway/random-name";
import { AreaInspector } from "../components/inspectors/AreaInspector";
import { EntityInspector } from "../components/inspectors/EntityInspector";
import { ExitInspector } from "../components/inspectors/ExitInspector";
import { InspectableInspector } from "../components/inspectors/InspectableInspector";
import type { ComponentInspector } from "../components/inspectors/useInspector";
import { createRandomName, randomKey } from "../editor.utils";
import type { EntityCollection, WithStringEnums } from "./types";

export const createDefaultEntity = (): WithStringEnums<
	Pick<SchemaType["lore"], "Entity">
> => ({
	Entity: {
		...schema.lore.Entity,
		inst: randomKey(),
		is_entity: true,
		name: createRandomName(),
		alt_names: [],
	},
});

export const createDefaultAreaComponent = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "Area">> => ({
	Area: {
		...schema.lore.Area,
		inst: entity.inst,
		is_area: true,
		direction: "None",
	},
});

export const createDefaultInspectableComponent = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "Inspectable">> => ({
	Inspectable: {
		...schema.lore.Inspectable,
		inst: entity.inst,
		is_inspectable: true,
		description: [],
		action_map: [],
	},
});

export const createDefaultExitComponent = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "Exit">> => ({
	Exit: {
		...schema.lore.Exit,
		inst: entity.inst,
		is_exit: true,
		is_enterable: true,
		direction_type: "None",
		action_map: [
			{ action: "go", inst: 0, action_fn: "UseExit" },
			{ action: "enter", inst: 0, action_fn: "UseExit" },
			{ action: "use", inst: 0, action_fn: "UseExit" },
		],
	},
});

export const createDefaultChildToParentComponent = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "ChildToParent">> => ({
	ChildToParent: {
		...schema.lore.ChildToParent,
		inst: entity.inst,
		is_child: true,
		parent: 0,
	},
});

export const createDefaultParentToChildrenComponent = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "ParentToChildren">> => ({
	ParentToChildren: {
		...schema.lore.ParentToChildren,
		inst: entity.inst,
		is_parent: true,
		children: [],
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
