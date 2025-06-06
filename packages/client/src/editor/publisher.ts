import { toast } from "sonner";
import { byteArray, num } from "starknet";
import {
	type Area,
	type ChildToParent,
	direction,
	type Entity,
	type Exit,
	exitActions,
	type Inspectable,
	inspectableActions,
	type InventoryItem,
	inventoryItemActions,
	type Container,
	containerActions,
	type Player,
	type Trigger,
	triggerType,
	type Condition,
	operator,
	components,
	type Effect,
	type Action,
	type ParentToChildren,
} from "@/lib/dojo_bindings/typescript/models.gen";
import { tick } from "@/lib/utils/utils";
import { type DesignerCall, SystemCalls } from "../lib/systemCalls";
import EditorData from "./data/editor.data";
import { Notifications } from "./lib/notifications";
import { toEnumIndex } from "./lib/schemas";
import type { EntityCollection } from "./lib/types";
import type { ChangeSet } from "./lib/types";

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
			console.log(EditorData().changeSet);
			if (EditorData().changeSet.length > 0) {
				Notifications().needsToPublish();
			} else {
				toast.dismiss("editor-dirty");
			}
		}
	}
};

const publishEntityCollection = async (collection: EntityCollection) => {
	if ("Entity" in collection && collection.Entity !== undefined) {
		await publishEntity(collection.Entity);
	}
	if("Player" in collection && collection.Player !== undefined) {
		await publishPlayer(collection.Player);
	}
	if ("Inspectable" in collection && collection.Inspectable !== undefined) {
		await publishInspectable(collection.Inspectable);
	}
	if ("Area" in collection && collection.Area !== undefined) {
		await publishArea(collection.Area);
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
		byteArray.byteArrayFromString(entity.name),
		entity.alt_names.length > 0
			? entity.alt_names
					.filter((x) => x.length > 0)
					.map((x) => byteArray.byteArrayFromString(x))
			: 0,
		num.toBigInt(entity.actions_keys.toString()),
	];
	await dispatchDesignerCall("create_entity", [entityData]);
};

// @wip: publish player
const publishPlayer = async (player: Player) => {
	const playerData = [
		num.toBigInt(player.inst.toString()),
		player.is_player,
		byteArray.byteArrayFromString(player.address),
		player.use_debug,
	];
	await dispatchDesignerCall("create_player", [playerData]);
};

const publishInspectable = async (inspectable: Inspectable) => {
	const inspectableData = [
		num.toBigInt(inspectable.inst.toString()),
		inspectable.is_inspectable,
		inspectable.is_visible,
		inspectable.description.length > 0
			? inspectable.description
					.filter((x) => x.length > 0)
					.map((x) => byteArray.byteArrayFromString(x))
			: 0,
		inspectable.action_map.length > 0
			? inspectable.action_map.map((x) => [
					byteArray.byteArrayFromString(x.action),
					0,
					toEnumIndex(x.action_fn, inspectableActions),
				])
			: 0,
	];
	await dispatchDesignerCall("create_inspectable", [inspectableData]);
};

const publishArea = async (area: Area) => {
	const areaData = [
		num.toBigInt(area.inst.toString()),
		area.is_area,
	];
	await dispatchDesignerCall("create_area", [areaData]);
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
					0,
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
		num.toBigInt(inventoryItem.owner_id),
		inventoryItem.can_be_picked_up,
		inventoryItem.can_go_in_container,
		inventoryItem.action_map.length > 0
			? inventoryItem.action_map.map((x) => [
					byteArray.byteArrayFromString(x.action),
					0,
					toEnumIndex(x.action_fn, inventoryItemActions),
			  ])
			: 0,
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
		num.toBigInt(container.num_slots.toString()),
		container.action_map.length > 0
			? container.action_map.map((x) => [
					byteArray.byteArrayFromString(x.action),
					0,
					toEnumIndex(x.action_fn, containerActions),
			  ])
			: 0,
	];
	await dispatchDesignerCall("create_container", [containerData]);
};

const publishTrigger = async (trigger: Trigger) => {
	const triggerData = [
		num.toBigInt(trigger.inst.toString()),
		num.toBigInt(trigger.key.toString()),
		byteArray.byteArrayFromString(trigger.name),
		toEnumIndex(trigger.trigger_type, triggerType),
		trigger.parameters.map((x) => [
			byteArray.byteArrayFromString(x.name),
			num.toBigInt(x.value),
		]),
		trigger.is_enabled,
	];
	await dispatchDesignerCall("create_trigger", [triggerData]);
};

const publishCondition = async (condition: Condition) => {
	const conditionData = [
		num.toBigInt(condition.inst.toString()),
		num.toBigInt(condition.key),
		num.toBigInt(condition.target),
		toEnumIndex(condition.component, components),
		byteArray.byteArrayFromString(condition.property),
		toEnumIndex(condition.operator, operator),
		num.toBigInt(condition.value),
	];
	await dispatchDesignerCall("create_condition", [conditionData]);
};

const publishEffect = async (effect: Effect) => {
  const effectData = [
    num.toBigInt(effect.inst.toString()),
    num.toBigInt(effect.key.toString()),
    num.toBigInt(effect.target.toString()),
    toEnumIndex(effect.component, components),
    byteArray.byteArrayFromString(effect.property),
    effect.value.map((v) => byteArray.byteArrayFromString(v.toString())),
  ];
  await dispatchDesignerCall("create_effect", [effectData]);
}

const publishAction = async (action: Action) => {
	const actionData = [
		num.toBigInt(action.inst.toString()),
		num.toBigInt(action.key),
		byteArray.byteArrayFromString(action.name),
		byteArray.byteArrayFromString(action.description),
		action.is_enabled,
		action.trigger.map(([a, b]) => [num.toBigInt(a.toString()), num.toBigInt(b.toString())]),
		action.conditions.map(([a, b]) => [num.toBigInt(a.toString()), num.toBigInt(b.toString())]),
		action.effects.map(([a, b]) => [num.toBigInt(a.toString()), num.toBigInt(b.toString())]),
		action.tags.map((x) => byteArray.byteArrayFromString(x)),
	];

	await dispatchDesignerCall("create_action", [actionData]);
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
	if ("Inspectable" in model && model.Inspectable !== undefined) {
		await dispatchDesignerCall("delete_inspectable", [
			num.toBigInt(model.Inspectable!.inst),
		]);
	}
	if ("Area" in model && model.Area !== undefined) {
		await dispatchDesignerCall("delete_area", [num.toBigInt(model.Area!.inst)]);
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
		await dispatchDesignerCall("delete_trigger", [
			[num.toBigInt(model.Trigger!.inst), num.toBigInt(model.Trigger!.key)],
		]);
	}
	if ("Condition" in model && model.Condition !== undefined) {
		await dispatchDesignerCall("delete_condition", [
			[num.toBigInt(model.Condition!.inst), num.toBigInt(model.Condition!.key)],
		]);
	}
	if ("Effect" in model && model.Effect !== undefined) {
		await dispatchDesignerCall("delete_effect", [
			[num.toBigInt(model.Effect!.inst), num.toBigInt(model.Effect!.key)],
		]);
	}
	if ("Action" in model && model.Action !== undefined) {
		await dispatchDesignerCall("delete_action", [
			[num.toBigInt(model.Action!.inst), num.toBigInt(model.Action!.key)],
		]);
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

/**
 * Helper function to send designer call
 * @param call The designer call type
 * @param args The arguments for the call
 * @returns The response from the API
 */
export const dispatchDesignerCall = async (
	call: DesignerCall,
	args: unknown[],
) => {
	try {
		const response = await SystemCalls.execDesignerCall({ call, args });
		Notifications().addPublishingLog(
			new CustomEvent("designerCall", { detail: { call, args } }),
		);
		return response.json();
	} catch (error) {
		Notifications().addPublishingLog(
			new CustomEvent("error", {
				detail: { error: { message: (error as Error).message }, call, args },
			}),
		);
		if ((error as Error).message.includes("too many")) {
			console.error(
				"Torii && Katana might need a reset when it says too many connections",
			);
		}
		throw new Error(
			`Error sending designer call: ${(error as Error).message}, ${call}, ${args}`,
		);
	}
};
