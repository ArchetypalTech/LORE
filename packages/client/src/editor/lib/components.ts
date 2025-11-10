import {
	type Entity,
	type Reactable,
	type DescriptionText,
	type SchemaType,
	schema,
} from "@/lib/dojo_bindings/typescript/models.gen";
import { AreaInspector } from "../components/inspectors/AreaInspector";
import { EntityInspector } from "../components/inspectors/EntityInspector";
import { ExitInspector } from "../components/inspectors/ExitInspector";
import { InventoryItemInspector } from "../components/inspectors/InventoryItemInspector";
import { ReactableInspector } from "../components/inspectors/ReactableInspector";
import type { ComponentInspector } from "../components/inspectors/useInspector";
import { ContainerInspector } from "../components/inspectors/ContainerInspector";
import { PlayerInspector, PlayerStoryInspector } from "../components/inspectors/PlayerInspector";
import { TriggerInspector } from "../components/inspectors/TriggerInspector";
import { ConditionInspector } from "../components/inspectors/ConditionInspector";
import { EffectInspector } from "../components/inspectors/EffectInspector";
import { ActionInspector } from "../components/inspectors/ActionInspector";
import { DescriptionTextInspector } from "../components/inspectors/DescriptionInspector";
import { createRandomName, randomKey, generateNumericUniqueId } from "../editor.utils";
import type { EntityCollection, WithStringEnums } from "./types";
import WalletStore from "@/lib/stores/wallet.store"
import { BigNumberish, ec, shortString } from "starknet";
import { bigintToAddress } from "@/lib/utils/utils";
import { HubInspector } from "../components/inspectors/HubInspector";
import { TrailInspector } from "../components/inspectors/TrailInspector";

export const createDefaultEntity = (): WithStringEnums<
	Pick<SchemaType["lore"], "Entity">
> => ({
	Entity: {
		...schema.lore.Entity,
		inst: randomKey(),
		is_entity: true,
		trail_id: 0,
		name: createRandomName(),
		creator_address: bigintToAddress(getPlayerAddress()),
		alt_names: [],
		actions_keys: [],
	},
});

export const createPlayerEntity = (
	spawn_location?: BigNumberish
): WithStringEnums<Pick<SchemaType["lore"], "Entity" | "Player">> => {
	const playerInst = getPlayerSingletonInst(); // singleton
	const playerAddress = getPlayerAddress();
	const playerName = "Player";
	return {
		// Adding the Entity as we need to set the inst to be the address
		Entity: {
			...schema.lore.Entity,
			inst: playerInst,
			is_entity: true,
			name: playerName,
			alt_names: ["player", "me", "myself", "inventory"],
		},
		Player: {
			...schema.lore.Player,
			inst: playerInst,
			is_player: true,
			address: playerAddress,
			game_id: 0,
			location: spawn_location!.toString() || 0,
			use_debug: false,
		},
	};
};

export const createPlayerComponent = (
	_entity: Entity,
	_reactable?: Reactable,
	address?: string
): WithStringEnums<Pick<SchemaType["lore"], "Player">> => {
	const playerAddress = address || getPlayerAddress();
	return {
		Player: {
			...schema.lore.Player,
			inst: playerAddress,
			is_player: true,
			address: playerAddress,
			location: 0,
			use_debug: false,
		},
	};
};

export const createPlayerStoryComponent = (
	_entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "PlayerStory">> => {
	return { 
		PlayerStory: {
			...schema.lore.PlayerStory,
			game_id: 0,
			story_line: 0,
		}
	};
};

export const createDefaultAreaComponent = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "Area">> => ({
	Area: {
		...schema.lore.Area,
		inst: entity.inst,
		is_area: true,
		is_spawn_point: false,
		progress_percentage: 0,
	},
});

export const createDefaultHubComponent = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "Hub">> => ({
	Hub: {
		...schema.lore.Hub,
		inst: entity.inst,
		is_hub: true,
		grants_editor_access: false,
		trails_insts: [],
	},
});

export const createDefaultTrailComponent = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "Trail">> => ({
	Trail: {
		...schema.lore.Trail,
		inst: entity.inst,
		is_trail: true,
		trail_id: 0,
		hub_inst: 0,
		is_published: false,
	},
});

export const createDefaultReactableComponent = (
	entity: Entity,
	descriptions?: DescriptionText[],
	new_entry?: string,
): WithStringEnums<Pick<SchemaType["lore"], "Reactable">> => ({
	Reactable: {
		...schema.lore.Reactable,
		inst: entity.inst,
		is_reactable: true,
		is_visible: true,
		description: descriptions?.map(x => x.key) || [],
		action_map: [
			{ action: "look", inst: 0, action_fn: "ReadFirstDescription", entrypoints: [0, 0] },
			{ action: "stare", inst: 0, action_fn: "ReadRandomDescription", entrypoints: [0, 0] },
		],
		already_shown: false,
		new_entry: new_entry || "",
	},


});

export const createDefaultDescriptionText = (
	entity: Entity,
	descriptions?: DescriptionText[],
): WithStringEnums<Pick<SchemaType["lore"], "DescriptionText">> => {
	const existingKeys = (descriptions || []).map(x => Number(x.key));
	let nextKey = (existingKeys.length > 0 ? Math.max(...existingKeys) : 0) + 1;
	return {
		DescriptionText: {
			...schema.lore.DescriptionText,
			inst: entity.inst,
			key: nextKey,
			text: " ",
		},
	};
};

export const createDefaultExitComponent = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "Exit">> => ({
	Exit: {
		...schema.lore.Exit,
		inst: entity.inst,
		is_exit: true,
		is_enterable: true,
		direction_type: "North",
		action_map: [
			{ action: "go", inst: 0, action_fn: "UseExit" },
			{ action: "enter", inst: 0, action_fn: "UseExit" },
			{ action: "use", inst: 0, action_fn: "UseExit" },
		],
	},
});

export const createDefaultInventoryItemComponent = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "InventoryItem">> => ({
	InventoryItem: {
		...schema.lore.InventoryItem,
		inst: entity.inst,
		is_inventory_item: true,
		owner_id: entity.inst,
		can_be_picked_up: true,
		can_go_in_container: true,
		quantity: 1,
		action_map: [
			{ action: "pick", inst: 0, action_fn: "PickupItem" },
			{ action: "drop", inst: 0, action_fn: "DropItem" },
			{ action: "put", inst: 0, action_fn: "PutItem" },
			{ action: "take", inst: 0, action_fn: "TakeOutItem" },
			{ action: "use", inst: 0, action_fn: "UseItem" },
		],
		already_used: false,
		multiple_use: false,
	},
});

export const createDefaultContainerComponent = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "Container">> => ({
	Container: {
		...schema.lore.Container,
		inst: entity.inst,
		is_container: true,
		can_be_opened: true,
		can_receive_items: true,
		is_open: true,
		num_slots: 3,
		action_map: [
			{ action: "open", inst: 0, action_fn: "Open" },
			{ action: "close", inst: 0, action_fn: "Close" },
			{ action: "check", inst: 0, action_fn: "Check" },
		],
	},
});

export const createDefaultTriggerComponent = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "Trigger">> => ({
	Trigger: {
		...schema.lore.Trigger,
		inst: entity.inst,
		key: generateNumericUniqueId(),
		name: createRandomName(),
		trigger_type: "OnEnter",
		is_enabled: true,
		is_once: false,
		was_triggered: false,
	},
});

export const createDefaultConditionComponent = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "Condition">> => ({
	Condition: {
		...schema.lore.Condition,
		inst: entity.inst,
		key: generateNumericUniqueId(),
		name: createRandomName(),
		target: 0,
		component: "Area",
		property: "",
		operator: "Equals",
		value: [],
	},
});

export const createDefaultEffectComponent = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "Effect">> => ({
	Effect: {
		...schema.lore.Effect,
		inst: entity.inst,
		key: generateNumericUniqueId(),
		name: createRandomName(),
		target: 0,
		component: "Reactable",
		property: "already_shown",
		value: [],
	},
});

export const createDefaultActionComponent = (
	entity: Entity,
): WithStringEnums<Pick<SchemaType["lore"], "Action">> => ({
	Action: {
		...schema.lore.Action,
		inst: entity.inst,
		key: generateNumericUniqueId(),
		name: createRandomName(),
		description: "",
		is_enabled: true,
		trigger: [],
		conditions: [],
		effects: [],
		tags: [],
		executed: false,
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
		creator?: (entity: Entity, ...args: any[]) => WithStringEnums<Pick<EntityCollection, K>>;
	};
} = {
	Entity: {
		order: 0,
		inspector: EntityInspector,
		creator: createDefaultEntity,
	},
	Player: {
		order: 1,
		inspector: PlayerInspector,
		icon: "👤",
		creator: createPlayerComponent,
		},
	PlayerStory: {
		order: 1,
		inspector: PlayerStoryInspector,
		icon: "👤",
		creator: createPlayerStoryComponent,
	},
	Area: {
		order: 2,
		inspector: AreaInspector,
		icon: "🥾",
		creator: createDefaultAreaComponent,
	},
	Reactable: {
		order: 3,
		inspector: ReactableInspector,
		icon: "🔍",
		creator: createDefaultReactableComponent,
	},
	Exit: {
		order: 4,
		inspector: ExitInspector,
		icon: "🚪",
		creator: createDefaultExitComponent,
	},
	Hub: {
		order: 5,
		inspector: HubInspector,
		icon: "🚏",
		creator: createDefaultHubComponent,
	},
	Trail: {
		order: 6,
		inspector: TrailInspector,
		icon: "🛤️",
		creator: createDefaultTrailComponent,
	},
	InventoryItem: {
		order: 7,
		inspector: InventoryItemInspector,
		icon: "📦",
		creator: createDefaultInventoryItemComponent,
	},
	Container: {
		order: 8,
		inspector: ContainerInspector,
		icon: "🎒",
		creator: createDefaultContainerComponent,
	},
	Trigger: {
		order: 9,
		inspector: TriggerInspector,
		icon: "🛎️",
		creator: createDefaultTriggerComponent,
	},
	Condition: {
		order: 10,
		inspector: ConditionInspector,
		icon: "⚖️",
		creator: createDefaultConditionComponent,
	},
	Effect: {
		order: 11,
		inspector: EffectInspector,
		icon: "✨",
		creator: createDefaultEffectComponent,
	},
	Action: {
		order: 12,
		inspector: ActionInspector,
		icon: "📝",
		creator: createDefaultActionComponent,
	},
	DescriptionText: {
		order: 13,
		inspector: DescriptionTextInspector,
		icon: "🔍",
		creator: createDefaultDescriptionText,
	},
};

export const getPlayerAddress = (): string => {
	return WalletStore().walletAddress ?? "";
};

export const getPlayerUsername = (): string => {
	return WalletStore().username ?? 'Player';
};

export const getPlayerEntranceInst = (): bigint => {
	let entranceInst = 0n;
	const address = WalletStore().walletAddress;
	if (address) {
		entranceInst = ec.starkCurve.poseidonHashMany([
			BigInt(shortString.encodeShortString("Entrance")),
			BigInt(address),
		]);
	}
	return entranceInst;
};

export const getPlayerSingletonInst = (game_id?: string): string => {
	return getGameInst(shortString.encodeShortString("Player"), game_id);
};

export const getGameInst = (inst: string, game_id?: string): string => {
	return (!game_id ? inst : ec.starkCurve.poseidonHashMany([BigInt(inst), BigInt(game_id)]).toString());
};
