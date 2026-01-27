import { toast } from "sonner";
import { byteArray, num } from "starknet";
import {
	type Area,
	type ChildToParent,
	direction,
	type Entity,
	type Exit,
	exitActions,
	type Reactable,
	reactableActions,
	type DescriptionText,
	type InventoryItem,
	inventoryItemActions,
	type Container,
	containerActions,
	type Player,
	type Trigger,
	triggerType,
	type Condition,
	operator,
	componentType,
	type Effect,
	effectType,
	type Action,
	type ParentToChildren,
	type Hub,
	type Trail,
} from "@/lib/dojo_bindings/typescript/models.gen";
import { tick } from "@/lib/utils/utils";
import { type DesignerEntrypoints, SystemCalls } from "../lib/systemCalls";
import EditorData from "./data/editor.data";
import { Notifications } from "./lib/notifications";
import { toEnumIndex } from "./lib/schemas";
import type { EntityCollection } from "./lib/types";
import type { ChangeSet } from "./lib/types";
import { getPlayerAddress } from "./lib/components";

/**
 * Publishes a game configuration to the contract
 * @param config The game configuration to publish
 * @returns A promise that resolves when the publishing is complete
 */
export const publishConfigToContract = async (changes?: ChangeSet[]) => {
	try {
		await Notifications().startPublishing();
		await publishChangeset(changes);
		Notifications().finalizePublishing();
		// Wait for transaction to be processed
		await tick();
		// Sync data from contract after publishing
		await EditorData().syncEntities();
		console.log("Data pool after sync:", EditorData().dataPool);
		return true;
	} catch (error) {
		const errorMsg = error instanceof Error ? error.message : String(error);
		Notifications().showError(`Error publishing to contract: ${errorMsg}`);
		return false;
	}
};

const publishChangeset = async (changes?: ChangeSet[]) => {
	const preparedChanges = changes || EditorData().changeSet;
	for (const change of preparedChanges) {
		try {
			if (change.type === "update") {
				await publishEntityCollection(change.object as EntityCollection);
			}
			if (change.type === "delete") {
				await deleteCollection(change.object as EntityCollection);
			}
		} catch (error) {
			console.error("Error creating room:", error);
			toast.error(
				`Error creating ${Object.keys(change.object).join(",")}: ${error instanceof Error ? error.message : String(error)}`,
				{ richColors: true, duration: 4000, dismissible: true },
			);
		} finally {
			EditorData().set({
				changeSet: EditorData().changeSet.filter((x) => x !== change),
			});
			console.log("Publish ChangeSet", EditorData().changeSet);
			if (EditorData().changeSet.length > 0) {
				Notifications().needsToPublish();
			} else {
				toast.dismiss("editor-dirty");
			}
		}
	}
};

export const publishEntityCollection = async (collection: EntityCollection) => {
	if ("Entity" in collection && collection.Entity !== undefined) {
		await publishEntity(collection.Entity);
	}
	if ("Player" in collection && collection.Player !== undefined) {
		await publishPlayer(collection.Player);
	}
	if ("Reactable" in collection && collection.Reactable !== undefined) {
		await publishReactable(collection.Reactable);
	}
	if ("DescriptionText" in collection && collection.DescriptionText !== undefined) {
		await publishDescriptionText(collection.DescriptionText);
	}
	if ("Area" in collection && collection.Area !== undefined) {
		await publishArea(collection.Area);
	}
	if ("Hub" in collection && collection.Hub !== undefined) {
		await publishHub(collection.Hub);
	}
	if ("Trail" in collection && collection.Trail !== undefined) {
		await publishTrail(collection.Trail);
	}
	if ("Exit" in collection && collection.Exit !== undefined) {
		await publishExit(collection.Exit);
	}
	if ("InventoryItem" in collection && collection.InventoryItem !== undefined) {
		await publishInventoryItem(collection.InventoryItem);
	}
	if ("Container" in collection && collection.Container !== undefined) {
		await publishContainer(collection.Container);
	}
	if ("Trigger" in collection && collection.Trigger !== undefined) {
		await publishTrigger(collection.Trigger);
	}
	if ("Condition" in collection && collection.Condition !== undefined) {
		await publishCondition(collection.Condition);
	}
	if ("Effect" in collection && collection.Effect !== undefined) {
		await publishEffect(collection.Effect);
	}
	if ("Action" in collection && collection.Action !== undefined) {
		await publishAction(collection.Action);
	}
	if ("ChildToParent" in collection && collection.ChildToParent !== undefined) {
		await publishChildToParent(collection.ChildToParent);
	}
	if (
		"ParentToChildren" in collection &&
		collection.ParentToChildren !== undefined
	) {
		await publishParentToChildren(collection.ParentToChildren);
	}
};

const publishEntity = async (entity: Entity) => {
	const entityData = [
		num.toBigInt(entity.inst.toString()),
		entity.is_entity,
		num.toBigInt(entity.trail_id?.toString() ?? "0"),
		byteArray.byteArrayFromString(entity.name),
		0n, // creator_address is managed on contract level
		entity.alt_names.length > 0
			? entity.alt_names
				.filter((x) => x.length > 0)
				.map((x) => byteArray.byteArrayFromString(x))
			: 0,
		entity.actions_keys.length > 0
			? entity.actions_keys.filter((x) => x !== num.toBigInt(0)).map((x) => num.toBigInt(x.toString()))
			: 0,
	];
	await dispatchDesignerCall("create_entity", [entityData]);
};

// @wip: publish player
const publishPlayer = async (player: Player) => {
	const playerData = [
		num.toBigInt((player.inst ?? getPlayerAddress()).toString()),
		player.is_player ?? true,
		player.address ? num.toBigInt(player.address.toString()) : num.toBigInt(getPlayerAddress().toString()),
		player.game_id ? num.toBigInt(player.game_id.toString()) : num.toBigInt("0"),
		player.location ? num.toBigInt(player.location.toString()) : num.toBigInt("0"),
		player.use_debug ?? false,
		player.is_dead ?? false,
	];
	await dispatchDesignerCall("create_player", [playerData]);
};

const publishReactable = async (reactable: Reactable) => {
	const reactableData = [
		num.toBigInt(reactable.inst.toString()),
		reactable.is_reactable,
		reactable.is_visible,
		reactable.description.map((x) => num.toBigInt(x.toString())),
		reactable.action_map.length > 0
			? reactable.action_map.map((x) => [
				byteArray.byteArrayFromString(x.action),
				num.toBigInt(x.inst ?? "0"),
				toEnumIndex(x.action_fn, reactableActions),
				num.toBigInt(x.entrypoints?.[0] ?? "0"),
				num.toBigInt(x.entrypoints?.[1] ?? "0"),
			])
			: 0,
		reactable.already_shown,
		byteArray.byteArrayFromString(reactable.new_entry.toString() ?? ""),
	];

	await dispatchDesignerCall("create_reactable", [reactableData]);
};

const publishDescriptionText = async (
	descriptions: DescriptionText | DescriptionText[]
) => {
	const array = Array.isArray(descriptions) ? descriptions : [descriptions];

	for (const description of array) {
		const preparedDescription = [
			num.toBigInt(description.inst.toString()),
			num.toBigInt(description.key.toString()),
			byteArray.byteArrayFromString(description.text),
		];

		await dispatchDesignerCall("create_description_text", [preparedDescription]);
	}
};

const publishArea = async (area: Area) => {
	const areaData = [
		num.toBigInt(area.inst.toString()),
		area.is_area,
		area.is_spawn_point,
		Number(area.progress_percentage ?? '0'),
		area.preserve_children ?? false,
	];
	await dispatchDesignerCall("create_area", [areaData]);
};

const publishHub = async (hub: Hub) => {
	const hubData = [
		num.toBigInt(hub.inst.toString()),
		hub.is_hub,
		hub.is_enabled,
		hub.trails_insts.map((x) => num.toBigInt(x.toString())),
		hub.grants_editor_access,
	];
	await dispatchDesignerCall("create_hub", [hubData]);
};

const publishTrail = async (trail: Trail) => {
	const trailData = [
		num.toBigInt(trail.inst.toString()),
		trail.is_trail,
		num.toBigInt(trail.trail_id.toString()),
		num.toBigInt(trail.hub_inst.toString()),
		trail.is_published,
	];
	await dispatchDesignerCall("create_trail", [trailData]);
};

const publishExit = async (exit: Exit) => {
	const exitData = [
		num.toBigInt(exit.inst.toString()),
		exit.is_exit,
		exit.is_enterable,
		num.toBigInt(exit.leads_to.toString()),
		toEnumIndex(exit.direction_type, direction),
		exit.action_map.length > 0
			? exit.action_map.map((x) => [
				byteArray.byteArrayFromString(x.action),
				num.toBigInt((x.inst ?? 0).toString()),
				toEnumIndex(x.action_fn, exitActions),
			])
			: 0,
	];
	await dispatchDesignerCall("create_exit", [exitData]);
};

const publishInventoryItem = async (inventoryItem: InventoryItem) => {
	const inventoryItemData = [
		num.toBigInt(inventoryItem.inst.toString()),
		inventoryItem.is_inventory_item,
		inventoryItem.owner_id ? num.toBigInt(inventoryItem.owner_id.toString()) : num.toBigInt("0"),
		inventoryItem.can_be_picked_up,
		inventoryItem.can_go_in_container,
		num.toBigInt(inventoryItem.quantity.toString() ?? 0),
		inventoryItem.action_map.length > 0
			? inventoryItem.action_map.map((x) => [
				byteArray.byteArrayFromString(x.action),
				num.toBigInt((x.inst ?? "0").toString()),
				toEnumIndex(x.action_fn, inventoryItemActions),
			])
			: 0,
		inventoryItem.already_used,
		inventoryItem.multiple_use,
	];
	await dispatchDesignerCall("create_inventory_item", [inventoryItemData]);
};

const publishContainer = async (container: Container) => {
	const containerData = [
		num.toBigInt(container.inst.toString()),
		container.is_container,
		container.can_be_opened,
		container.can_receive_items,
		container.is_open,
		num.toBigInt(container.num_slots.toString() ?? 0),
		container.action_map.length > 0
			? container.action_map.map((x) => [
				byteArray.byteArrayFromString(x.action),
				num.toBigInt((x.inst ?? 0).toString()),
				toEnumIndex(x.action_fn, containerActions),
			])
			: 0,
	];
	await dispatchDesignerCall("create_container", [containerData]);
};

const publishTrigger = async (
	triggers: Trigger | Trigger[]
) => {
	const array = Array.isArray(triggers) ? triggers : [triggers];

	for (const trigger of array) {
		const preparedTrigger = [
			num.toBigInt(trigger.inst.toString()),
			num.toBigInt(trigger.key.toString()),
			byteArray.byteArrayFromString(trigger.name ?? ""),
			toEnumIndex(trigger.trigger_type, triggerType),
			trigger.is_enabled,
			trigger.is_once,
		];
		await dispatchDesignerCall("create_trigger", [preparedTrigger]);
	}
};

const publishCondition = async (
	conditions: Condition | Condition[]
) => {
	const array = Array.isArray(conditions) ? conditions : [conditions];

	for (const condition of array) {
		const preparedCondition = [
			num.toBigInt(condition.inst.toString()),
			num.toBigInt(condition.key.toString()),
			byteArray.byteArrayFromString(condition.name ?? ""),
			num.toBigInt(condition.target),
			toEnumIndex(condition.component, componentType),
			byteArray.byteArrayFromString(condition.property),
			toEnumIndex(condition.operator, operator),
			condition.value.map((v) => num.toBigInt(v ?? "0")),
		];
		await dispatchDesignerCall("create_condition", [preparedCondition]);
	}
};

const publishEffect = async (
	effects: Effect | Effect[]
) => {
	const array = Array.isArray(effects) ? effects : [effects];

	for (const effect of array) {
		const preparedEffect = [
			num.toBigInt(effect.inst.toString()),
			num.toBigInt(effect.key.toString()),
			byteArray.byteArrayFromString(effect.name ?? ""),
			num.toBigInt(effect.target.toString()),
			toEnumIndex(effect.effect_type, effectType),
			toEnumIndex(effect.component, componentType),
			byteArray.byteArrayFromString(effect.property),
			effect.value.map(([v, i]) => [
				byteArray.byteArrayFromString(v.toString() ?? ""),
				num.toBigInt(i.toString() ?? 0),
			]),
			num.toBigInt(effect.n_value.toString() ?? 0),
			num.toBigInt(effect.hex_value?.toString() ?? num.toBigInt("0")),
		];
		await dispatchDesignerCall("create_effect", [preparedEffect]);
	}
}

const publishAction = async (
	actions: Action | Action[]
) => {
	const array = Array.isArray(actions) ? actions : [actions];

	for (const action of array) {
		const preparedAction = [
			num.toBigInt(action.inst.toString()),
			num.toBigInt(action.key),
			byteArray.byteArrayFromString(action.name ?? ""),
			byteArray.byteArrayFromString(action.description ?? ""),
			action.is_enabled,
			num.toBigInt(action.executor.toString()?? 0),
			action.trigger.map(([a, b]) => [
				num.toBigInt(a.toString()),
				num.toBigInt(b.toString()),
			]),
			action.conditions.map(([a, b]) => [
				num.toBigInt(a.toString()),
				num.toBigInt(b.toString()),
			]),
			action.effects.map(([a, b]) => [
				num.toBigInt(a.toString()),
				num.toBigInt(b.toString()),
			]),
			action.tags.map((x) => byteArray.byteArrayFromString(x)),
			action.failing_response.length > 0
				? action.failing_response
					.filter((x) => x.length > 0)
					.map((x) => byteArray.byteArrayFromString(x))
				: 0,
			action.success_response.length > 0
				? action.success_response
					.filter((x) => x.length > 0)
					.map((x) => byteArray.byteArrayFromString(x))
				: 0,
		];
		await dispatchDesignerCall("create_action", [preparedAction]);
	}
};

const publishChildToParent = async (childToParent: ChildToParent) => {
	const childToParentData = [
		num.toBigInt(childToParent.inst.toString()),
		childToParent.is_child,
		num.toBigInt(childToParent.parent),
	];
	await dispatchDesignerCall("create_child", [childToParentData]);
};

const publishParentToChildren = async (parentToChildren: ParentToChildren) => {
	const parentToChildrenData = [
		num.toBigInt(parentToChildren.inst.toString()),
		parentToChildren.is_parent,
		parentToChildren.children.length > 0
			? parentToChildren.children.map((x) => num.toBigInt(x))
			: 0,
	];
	await dispatchDesignerCall("create_parent", [parentToChildrenData]);
};

const deleteCollection = async (model: EntityCollection) => {
	if ("Entity" in model && model.Entity !== undefined) {
		await dispatchDesignerCall("delete_entity", [
			num.toBigInt(model.Entity!.inst),
		]);
	}
	if ("Player" in model && model.Player !== undefined) {
		await dispatchDesignerCall("delete_player", [
			num.toBigInt(model.Player!.inst),
		]);
	}
	if ("Reactable" in model && model.Reactable !== undefined) {
		await dispatchDesignerCall("delete_reactable", [
			num.toBigInt(model.Reactable!.inst),
		]);
	}
	if ("DescriptionText" in model && model.DescriptionText !== undefined) {
		const array = Array.isArray(model.DescriptionText) ? model.DescriptionText : [model.DescriptionText];
		await dispatchDesignerCall(
			"delete_description_text",
			array.map((x) => [num.toBigInt(x.inst), num.toBigInt(x.key)])
		);
	}
	if ("Area" in model && model.Area !== undefined) {
		await dispatchDesignerCall("delete_area", [num.toBigInt(model.Area!.inst)]);
	}
	if ("Hub" in model && model.Hub !== undefined) {
		await dispatchDesignerCall("delete_hub", [num.toBigInt(model.Hub!.inst)]);
	}
	if ("Trail" in model && model.Trail !== undefined) {
		await dispatchDesignerCall("delete_trail", [num.toBigInt(model.Trail!.inst)]);
	}
	if ("Exit" in model && model.Exit !== undefined) {
		await dispatchDesignerCall("delete_exit", [num.toBigInt(model.Exit!.inst)]);
	}
	if ("InventoryItem" in model && model.InventoryItem !== undefined) {
		await dispatchDesignerCall("delete_inventory_item", [
			num.toBigInt(model.InventoryItem!.inst),
		]);
	}
	if ("Container" in model && model.Container !== undefined) {
		await dispatchDesignerCall("delete_container", [
			num.toBigInt(model.Container!.inst),
		]);
	}
	if ("Trigger" in model && model.Trigger !== undefined) {
		const array = Array.isArray(model.Trigger) ? model.Trigger : [model.Trigger];
		await dispatchDesignerCall("delete_trigger",
			array.map((x) => [num.toBigInt(x.inst), num.toBigInt(x.key)])
		);
	}
	if ("Condition" in model && model.Condition !== undefined) {
		const array = Array.isArray(model.Condition) ? model.Condition : [model.Condition];
		await dispatchDesignerCall("delete_condition",
			array.map((x) => [num.toBigInt(x.inst), num.toBigInt(x.key)])
		);
	}
	if ("Effect" in model && model.Effect !== undefined) {
		const array = Array.isArray(model.Effect) ? model.Effect : [model.Effect];
		await dispatchDesignerCall("delete_effect",
			array.map((x) => [num.toBigInt(x.inst), num.toBigInt(x.key)])
		);
	}
	if ("Action" in model && model.Action !== undefined) {
		const array = Array.isArray(model.Action) ? model.Action : [model.Action];
		await dispatchDesignerCall("delete_action",
			array.map((x) => [num.toBigInt(x.inst), num.toBigInt(x.key)])
		);
	}
	if ("ChildToParent" in model && model.ChildToParent !== undefined) {
		await dispatchDesignerCall("delete_child", [
			num.toBigInt(model.ChildToParent!.inst),
		]);
	}
	if ("ParentToChildren" in model && model.ParentToChildren !== undefined) {
		await dispatchDesignerCall("delete_parent", [
			num.toBigInt(model.ParentToChildren!.inst),
		]);
	}
};

export const registerPropertyRegistry = async () => {
	try {
		await Notifications().startPublishing();
		await publishRegisterPropertyRegistry();
		Notifications().finalizePublishing();
		// Wait for transaction to be processed
		await tick();
		console.log("Properties of components have been registered");
		return true;
	} catch (error) {
		const errorMsg = error instanceof Error ? error.message : String(error);
		Notifications().showError(`Error publishing to contract: ${errorMsg}`);
		return false;
	}
};

const publishRegisterPropertyRegistry = async () => {
		let done = true;
		await dispatchDesignerCall("register_property_registry", [done]);
};

/**
 * Helper function to send designer call
 * @param call The designer call type
 * @param args The arguments for the call
 * @returns The response from the API
 */
export const dispatchDesignerCall = async (
	entrypoint: DesignerEntrypoints,
	args: unknown[],
) => {
	try {
		await SystemCalls.execDesignerCall({ entrypoint, args });
		Notifications().addPublishingLog(
			new CustomEvent("designerCall", { detail: { entrypoint, args } }),
		);
	} catch (error) {
		Notifications().addPublishingLog(
			new CustomEvent("error", {
				detail: { error: { message: (error as Error).message }, entrypoint, args },
			}),
		);
		if ((error as Error).message.includes("too many")) {
			console.error(
				"Torii && Katana might need a reset when it says too many connections",
			);
		}
		throw new Error(
			`Error sending designer call: ${entrypoint}, ${args}: ${(error as Error).message}`,
		);
	}
};
