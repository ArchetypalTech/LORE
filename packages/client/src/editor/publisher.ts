import { toast } from "sonner";
import { byteArray, num, CallData, type RawArgsArray, Account, type Call, type BigNumberish } from "starknet";
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
	type ApprovedProposal,
} from "@/lib/dojo_bindings/typescript/models.gen";
import { tick } from "@/lib/utils/utils";
import { toCairoArray } from "@/editor/editor.utils";
import { type DesignerEntrypoints, SystemCalls } from "../lib/systemCalls";
import EditorData, { syncEntitiesByInsts, persistDraft } from "./data/editor.data";
import EditorStore from "@/lib/stores/editor.store";
import { Notifications } from "./lib/notifications";
import { toEnumIndex } from "./lib/schemas";
import type { EntityCollection, EditorCollection } from "./lib/types";
import type { ChangeSet } from "./lib/types";
import { getPlayerAddress } from "./lib/components";
import WalletStore from "@/lib/stores/wallet.store";
import { LORE_CONFIG } from "@/lib/config";
import TokenStore from "@/lib/stores/token.store";

/**
 * Publishes a game configuration to the contract
 * @param config The game configuration to publish
 * @returns A promise that resolves when the publishing is complete
 */
export const publishConfigToContract = async (changes?: ChangeSet[]) => {
	let preparedChanges: ChangeSet[];

	if (changes) {
		// Explicit override (e.g. the per-entity Publish button) — bypasses staging entirely
		preparedChanges = changes;
	} else {
		// Option D — publish only what's been explicitly staged, scoped to the active trail
		const activeTrailId = EditorData().get().activeTrailId;
		const allStaged = EditorData().get().stagedChanges;
		preparedChanges = activeTrailId
			? allStaged.filter((c) => {
				const entity = EditorData().getEntity(c.inst);
				return BigInt(entity?.Entity?.trail_id ?? 0) === activeTrailId;
			})
			: allStaged;

		if (preparedChanges.length === 0) {
			toast.info(
				activeTrailId
					? "Nothing staged for the active trail."
					: "Nothing staged to publish. Stage your changes first.",
			);
			return false;
		}
	}

	// Capture insts before publishChangeset drains the changeSet/stagedChanges in its finally block
	const publishedInsts = [...new Set(preparedChanges.map(c => c.inst))];

	try {
		await Notifications().startPublishing();
		await publishChangeset(preparedChanges);
		Notifications().finalizePublishing();
		// Wait for transaction to be processed
		await tick();
		// Re-sync only the entities that were just published — leaves other editors' work untouched
		await syncEntitiesByInsts(publishedInsts);
		await EditorData().syncEntities();
		console.log("Data pool after selective sync:", EditorData().dataPool);
		return true;
	} catch (error) {
		const errorMsg = error instanceof Error ? error.message : String(error);
		Notifications().showError(`Error publishing to contract: ${errorMsg}`);
		return false;
	}
};

const publishChangeset = async (changes?: ChangeSet[]) => {
	const myAddress = BigInt(getPlayerAddress());
	const isAdmin = EditorStore().isAdmin ?? false;
	const activeTrailId = EditorData().get().activeTrailId;
	const isActiveTrailOwner = activeTrailId !== undefined && TokenStore().playerOwnsTrail(activeTrailId);
	const preparedChanges = changes ?? EditorData().changeSet;

	// Separate ownership-validated changes into updates and deletes.
	// Skipped (unowned) changes are cleaned up immediately here.
	const validUpdates: ChangeSet[] = [];
	const validDeletes: ChangeSet[] = [];

	for (const change of preparedChanges) {
		if (!isAdmin) {
			const entity = EditorData().getEntity(change.inst);
			const creator = BigInt(entity?.Entity?.creator_address?.toString() ?? "0");
			const entityTrailId = BigInt(entity?.Entity?.trail_id?.toString() ?? "0");
			const isTrailOwner = entityTrailId > 0n && (
				TokenStore().playerOwnsTrail(entityTrailId) ||
				(isActiveTrailOwner && entityTrailId === activeTrailId)
			);
			const isOwned = creator === 0n || creator === myAddress || isTrailOwner;
			if (!isOwned) {
				toast.warning(
					`Skipped "${entity?.Entity?.name ?? String(change.inst)}": owned by another editor`,
					{ richColors: true, duration: 10000, dismissible: true },
				);
				EditorData().set({
					changeSet: EditorData().changeSet.filter((x) => x !== change),
					stagedChanges: EditorData().get().stagedChanges.filter((x) => x !== change),
				});
				persistDraft();
				continue;
			}
		}
		if (change.type === "update") validUpdates.push(change);
		else if (change.type === "delete") validDeletes.push(change);
	}

	// Pass 1: publish all entity data before any parent-child relationships.
	// This prevents 'TRAIL: Invalid child trail_id' when a parent's create_parent
	// references a child entity that hasn't been written to the chain yet.
	const pass1Succeeded = new Set<ChangeSet>();
	for (const change of validUpdates) {
		try {
			await publishEntityData(change.object as EntityCollection);
			pass1Succeeded.add(change);
		} catch (error) {
			console.error("Error publishing:", error);
			toast.error(
				`Error publishing ${Object.keys(change.object).join(",")}: ${error instanceof Error ? error.message : String(error)}`,
				{ richColors: true, duration: 10000, dismissible: true },
			);
			// Clean up now — this change won't run in pass 2.
			EditorData().set({
				changeSet: EditorData().changeSet.filter((x) => x !== change),
				stagedChanges: EditorData().get().stagedChanges.filter((x) => x !== change),
			});
			persistDraft();
		}
	}

	// Pass 2: publish relationships for all pass-1 successes, then deletes.
	for (const change of [...validUpdates, ...validDeletes]) {
		if (change.type === "update" && !pass1Succeeded.has(change)) continue; // already failed + cleaned
		try {
			if (change.type === "update") {
				await publishEntityRelationships(change.object as EntityCollection);
			} else {
				await deleteCollection(change.object as EntityCollection);
			}
		} catch (error) {
			console.error("Error publishing:", error);
			toast.error(
				`Error publishing ${Object.keys(change.object).join(",")}: ${error instanceof Error ? error.message : String(error)}`,
				{ richColors: true, duration: 10000, dismissible: true },
			);
		} finally {
			EditorData().set({
				changeSet: EditorData().changeSet.filter((x) => x !== change),
				stagedChanges: EditorData().get().stagedChanges.filter((x) => x !== change),
			});
			persistDraft();
			console.log("Publish ChangeSet", EditorData().changeSet, "Staged", EditorData().get().stagedChanges);
			if (EditorData().changeSet.length > 0 || EditorData().get().stagedChanges.length > 0) {
				Notifications().needsToPublish();
			} else {
				toast.dismiss("editor-dirty");
			}
		}
	}
};

export const publishEntityCollection = async (collection: EntityCollection) => {
	await publishEntityData(collection);
	await publishEntityRelationships(collection);
};

/** Publishes all components EXCEPT ChildToParent / ParentToChildren. */
const publishEntityData = async (collection: EntityCollection) => {
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
};

/** Publishes only ChildToParent / ParentToChildren (parent-child linking). */
const publishEntityRelationships = async (collection: EntityCollection) => {
	if ("ChildToParent" in collection && collection.ChildToParent !== undefined) {
		await publishChildToParent(collection.ChildToParent);
	}
	if ("ParentToChildren" in collection && collection.ParentToChildren !== undefined) {
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
		hub.grants_trail_access,
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

// ─── Collab: submit for review / publish approved ─────────────────────────────

// Build helpers — mirror the per-type serialization in the publish* functions above
// but return the raw data array instead of dispatching a call.

const buildEntityData = (e: Entity) => [
	num.toBigInt(e.inst.toString()), e.is_entity,
	num.toBigInt(e.trail_id?.toString() ?? "0"),
	byteArray.byteArrayFromString(e.name), 0n,
	e.alt_names.length > 0 ? e.alt_names.filter(x => x.length > 0).map(x => byteArray.byteArrayFromString(x)) : 0,
	e.actions_keys.length > 0 ? e.actions_keys.filter(x => x !== num.toBigInt(0)).map(x => num.toBigInt(x.toString())) : 0,
];

const buildReactableData = (r: Reactable) => [
	num.toBigInt(r.inst.toString()), r.is_reactable, r.is_visible,
	r.description.map(x => num.toBigInt(x.toString())),
	r.action_map.length > 0
		? r.action_map.map(x => [byteArray.byteArrayFromString(x.action), num.toBigInt(x.inst ?? "0"), toEnumIndex(x.action_fn, reactableActions), num.toBigInt(x.entrypoints?.[0] ?? "0"), num.toBigInt(x.entrypoints?.[1] ?? "0")])
		: 0,
	r.already_shown, byteArray.byteArrayFromString(r.new_entry.toString() ?? ""),
];

const buildAreaData = (a: Area) => [
	num.toBigInt(a.inst.toString()), a.is_area, a.is_spawn_point,
	Number(a.progress_percentage ?? "0"), a.preserve_children ?? false,
];

const buildExitData = (e: Exit) => [
	num.toBigInt(e.inst.toString()), e.is_exit, e.is_enterable,
	num.toBigInt(e.leads_to.toString()), toEnumIndex(e.direction_type, direction),
	e.action_map.length > 0
		? e.action_map.map(x => [byteArray.byteArrayFromString(x.action), num.toBigInt((x.inst ?? 0).toString()), toEnumIndex(x.action_fn, exitActions)])
		: 0,
];

const buildHubData = (h: Hub) => [
	num.toBigInt(h.inst.toString()), h.is_hub, h.is_enabled,
	h.trails_insts.map(x => num.toBigInt(x.toString())),
	h.grants_editor_access, h.grants_trail_access,
];

const buildDescriptionTextData = (dt: DescriptionText) => [
	num.toBigInt(dt.inst.toString()), num.toBigInt((dt.key ?? 0).toString()),
	byteArray.byteArrayFromString(dt.text ?? ""),
];

const buildInventoryItemData = (item: InventoryItem) => [
	num.toBigInt(item.inst.toString()), item.is_inventory_item,
	item.owner_id ? num.toBigInt(item.owner_id.toString()) : 0n,
	item.can_be_picked_up, item.can_go_in_container,
	num.toBigInt(item.quantity.toString() ?? 0),
	item.action_map.length > 0
		? item.action_map.map(x => [byteArray.byteArrayFromString(x.action), num.toBigInt((x.inst ?? "0").toString()), toEnumIndex(x.action_fn, inventoryItemActions)])
		: 0,
	item.already_used, item.multiple_use,
];

const buildContainerData = (c: Container) => [
	num.toBigInt(c.inst.toString()), c.is_container, c.can_be_opened,
	c.can_receive_items, c.is_open, num.toBigInt(c.num_slots.toString() ?? 0),
	c.action_map.length > 0
		? c.action_map.map(x => [byteArray.byteArrayFromString(x.action), num.toBigInt((x.inst ?? 0).toString()), toEnumIndex(x.action_fn, containerActions)])
		: 0,
];

const buildTrailData = (t: Trail) => [
	num.toBigInt(t.inst.toString()), t.is_trail,
	num.toBigInt(t.trail_id.toString()), num.toBigInt(t.hub_inst.toString()), t.is_published,
];

const buildTriggerData = (t: Trigger) => [
	num.toBigInt(t.inst.toString()), num.toBigInt(t.key.toString()),
	byteArray.byteArrayFromString(t.name ?? ""), toEnumIndex(t.trigger_type, triggerType),
	t.is_enabled, t.is_once,
];

const buildConditionData = (c: Condition) => [
	num.toBigInt(c.inst.toString()), num.toBigInt(c.key.toString()),
	byteArray.byteArrayFromString(c.name ?? ""), num.toBigInt(c.target),
	toEnumIndex(c.component, componentType), byteArray.byteArrayFromString(c.property),
	toEnumIndex(c.operator, operator), c.value.map(v => num.toBigInt(v ?? "0")),
];

const buildEffectData = (e: Effect) => [
	num.toBigInt(e.inst.toString()), num.toBigInt(e.key.toString()),
	byteArray.byteArrayFromString(e.name ?? ""), num.toBigInt(e.target.toString()),
	toEnumIndex(e.effect_type, effectType), toEnumIndex(e.component, componentType),
	byteArray.byteArrayFromString(e.property),
	e.value.map(([v, i]) => [byteArray.byteArrayFromString(v.toString() ?? ""), num.toBigInt(i.toString() ?? 0)]),
	num.toBigInt(e.n_value.toString() ?? 0),
	num.toBigInt(e.hex_value?.toString() ?? num.toBigInt("0")),
];

const buildActionData = (a: Action) => [
	num.toBigInt(a.inst.toString()), num.toBigInt(a.key),
	byteArray.byteArrayFromString(a.name ?? ""), byteArray.byteArrayFromString(a.description ?? ""),
	a.is_enabled, num.toBigInt(a.executor.toString() ?? 0),
	a.trigger.map(([x, y]) => [num.toBigInt(x.toString()), num.toBigInt(y.toString())]),
	a.conditions.map(([x, y]) => [num.toBigInt(x.toString()), num.toBigInt(y.toString())]),
	a.effects.map(([x, y]) => [num.toBigInt(x.toString()), num.toBigInt(y.toString())]),
	a.tags.map(x => byteArray.byteArrayFromString(x)),
	a.failing_response.length > 0 ? a.failing_response.filter(x => x.length > 0).map(x => byteArray.byteArrayFromString(x)) : 0,
	a.success_response.length > 0 ? a.success_response.filter(x => x.length > 0).map(x => byteArray.byteArrayFromString(x)) : 0,
];

const buildParentToChildrenData = (p: ParentToChildren) => [
	num.toBigInt(p.inst.toString()), p.is_parent,
	p.children.length > 0 ? p.children.map(x => num.toBigInt(x)) : 0,
];

const buildChildToParentData = (c: ChildToParent) => [
	num.toBigInt(c.inst.toString()), c.is_child, num.toBigInt(c.parent),
];

// felt252 list membership checks — mirror contains_inst / contains_pair from the Cairo contract.
const containsInst = (list: bigint[], inst: bigint) => list.some(x => x === inst);
const containsPair = (list: bigint[], inst: bigint, key: bigint) => {
	for (let i = 0; i + 1 < list.length; i += 2) {
		if (list[i] === inst && list[i + 1] === key) return true;
	}
	return false;
};

type MultiKeyed = { inst: BigNumberish; key: BigNumberish };
const filterApprovedMulti = (list: bigint[], items: MultiKeyed | MultiKeyed[] | undefined): MultiKeyed[] => {
	if (!items) return [];
	const arr = Array.isArray(items) ? items : [items];
	return arr.filter(x => containsPair(list, BigInt(x.inst.toString()), BigInt(x.key.toString())));
};

// Serialize a component data array to a Cairo Array<T> calldata fragment:
// toCairoArray([d1, d2]) → [2, ...d1_flat, ...d2_flat]
const flatCairo = (data: unknown[]) => (toCairoArray(data) as unknown[]).flat() as unknown[];

/**
 * Bundles all staged changes for a trail into a single submit_for_review call.
 * Nothing is written to chain — the contract emits a CollabProposalEvent only.
 * The collaborator pays for this cheap event-only transaction.
 */
export const submitForReview = async (trailId: bigint): Promise<boolean> => {
	if (!WalletStore().isConnected) return false;

	const staged = EditorData().get().stagedChanges.filter(c => {
		const entity = EditorData().getEntity(c.inst);
		return BigInt(entity?.Entity?.trail_id ?? 0) === trailId;
	});

	if (staged.length === 0) {
		toast.info("Nothing staged for this trail.");
		return false;
	}

	const entitiesData: unknown[][] = [];
	const reactablesData: unknown[][] = [];
	const areasData: unknown[][] = [];
	const exitsData: unknown[][] = [];
	const hubsData: unknown[][] = [];
	const descriptionTextsData: unknown[][] = [];
	const inventoryItemsData: unknown[][] = [];
	const containersData: unknown[][] = [];
	const trailsData: unknown[][] = [];
	const triggersData: unknown[][] = [];
	const conditionsData: unknown[][] = [];
	const effectsData: unknown[][] = [];
	const actionsData: unknown[][] = [];
	const parentsData: unknown[][] = [];
	const childrenData: unknown[][] = [];
	const deletedEntityInsts: bigint[] = [];
	const deletedReactableInsts: bigint[] = [];
	const deletedAreaInsts: bigint[] = [];
	const deletedExitInsts: bigint[] = [];
	const deletedContainerInsts: bigint[] = [];
	const deletedInventoryItemInsts: bigint[] = [];
	const deletedHubInsts: bigint[] = [];
	const deletedTrailInsts: bigint[] = [];
	const deletedParentInsts: bigint[] = [];
	const deletedChildInsts: bigint[] = [];
	const deletedDescriptionTextKeys: bigint[] = [];
	const deletedTriggerKeys: bigint[] = [];
	const deletedConditionKeys: bigint[] = [];
	const deletedEffectKeys: bigint[] = [];
	const deletedActionKeys: bigint[] = [];

	const pushPair = (target: bigint[], inst: unknown, key: unknown) => {
		target.push(num.toBigInt(inst!.toString()));
		target.push(num.toBigInt((key ?? 0).toString()));
	};

	for (const change of staged) {
		const col = change.object as EntityCollection;
		if (change.type === "update") {
			if (col.Entity)           entitiesData.push(buildEntityData(col.Entity));
			if (col.Reactable)        reactablesData.push(buildReactableData(col.Reactable));
			if (col.Area)             areasData.push(buildAreaData(col.Area));
			if (col.Exit)             exitsData.push(buildExitData(col.Exit));
			if (col.Hub)              hubsData.push(buildHubData(col.Hub));
			if (col.InventoryItem)    inventoryItemsData.push(buildInventoryItemData(col.InventoryItem));
			if (col.Container)        containersData.push(buildContainerData(col.Container));
			if (col.Trail)            trailsData.push(buildTrailData(col.Trail));
			if (col.ParentToChildren) parentsData.push(buildParentToChildrenData(col.ParentToChildren));
			if (col.ChildToParent)    childrenData.push(buildChildToParentData(col.ChildToParent));
			if (col.DescriptionText) {
				const arr = Array.isArray(col.DescriptionText) ? col.DescriptionText : [col.DescriptionText];
				for (const dt of arr) descriptionTextsData.push(buildDescriptionTextData(dt));
			}
			for (const t of (Array.isArray(col.Trigger) ? col.Trigger : col.Trigger ? [col.Trigger] : []))
				triggersData.push(buildTriggerData(t));
			for (const c of (Array.isArray(col.Condition) ? col.Condition : col.Condition ? [col.Condition] : []))
				conditionsData.push(buildConditionData(c));
			for (const e of (Array.isArray(col.Effect) ? col.Effect : col.Effect ? [col.Effect] : []))
				effectsData.push(buildEffectData(e));
			for (const a of (Array.isArray(col.Action) ? col.Action : col.Action ? [col.Action] : []))
				actionsData.push(buildActionData(a));
		} else if (change.type === "delete") {
			if (col.Entity)           deletedEntityInsts.push(num.toBigInt(col.Entity.inst));
			if (col.Reactable)        deletedReactableInsts.push(num.toBigInt(col.Reactable.inst));
			if (col.Area)             deletedAreaInsts.push(num.toBigInt(col.Area.inst));
			if (col.Exit)             deletedExitInsts.push(num.toBigInt(col.Exit.inst));
			if (col.Container)        deletedContainerInsts.push(num.toBigInt(col.Container.inst));
			if (col.InventoryItem)    deletedInventoryItemInsts.push(num.toBigInt(col.InventoryItem.inst));
			if (col.Hub)              deletedHubInsts.push(num.toBigInt(col.Hub.inst));
			if (col.Trail)            deletedTrailInsts.push(num.toBigInt(col.Trail.inst));
			if (col.ParentToChildren) deletedParentInsts.push(num.toBigInt(col.ParentToChildren.inst));
			if (col.ChildToParent)    deletedChildInsts.push(num.toBigInt(col.ChildToParent.inst));
			if (col.DescriptionText) {
				const arr = Array.isArray(col.DescriptionText) ? col.DescriptionText : [col.DescriptionText];
				for (const dt of arr) pushPair(deletedDescriptionTextKeys, dt.inst, dt.key);
			}
			for (const t of (Array.isArray(col.Trigger) ? col.Trigger : col.Trigger ? [col.Trigger] : []))
				pushPair(deletedTriggerKeys, t.inst, t.key);
			for (const c of (Array.isArray(col.Condition) ? col.Condition : col.Condition ? [col.Condition] : []))
				pushPair(deletedConditionKeys, c.inst, c.key);
			for (const e of (Array.isArray(col.Effect) ? col.Effect : col.Effect ? [col.Effect] : []))
				pushPair(deletedEffectKeys, e.inst, e.key);
			for (const a of (Array.isArray(col.Action) ? col.Action : col.Action ? [col.Action] : []))
				pushPair(deletedActionKeys, a.inst, a.key);
		}
	}

	// submit_for_review(trail_id, entities, reactables, areas, exits, hubs,
	//   description_texts, inventory_items, containers, trails,
	//   triggers, conditions, effects, actions, parents, children,
	//   deleted_entity_insts, deleted_reactable_insts, deleted_area_insts, deleted_exit_insts,
	//   deleted_container_insts, deleted_inventory_item_insts, deleted_hub_insts,
	//   deleted_trail_insts, deleted_parent_insts, deleted_child_insts,
	//   deleted_description_text_keys, deleted_trigger_keys, deleted_condition_keys,
	//   deleted_effect_keys, deleted_action_keys)
	const calldata = CallData.compile([
		trailId,
		...flatCairo(entitiesData),
		...flatCairo(reactablesData),
		...flatCairo(areasData),
		...flatCairo(exitsData),
		...flatCairo(hubsData),
		...flatCairo(descriptionTextsData),
		...flatCairo(inventoryItemsData),
		...flatCairo(containersData),
		...flatCairo(trailsData),
		...flatCairo(triggersData),
		...flatCairo(conditionsData),
		...flatCairo(effectsData),
		...flatCairo(actionsData),
		...flatCairo(parentsData),
		...flatCairo(childrenData),
		...flatCairo(deletedEntityInsts),
		...flatCairo(deletedReactableInsts),
		...flatCairo(deletedAreaInsts),
		...flatCairo(deletedExitInsts),
		...flatCairo(deletedContainerInsts),
		...flatCairo(deletedInventoryItemInsts),
		...flatCairo(deletedHubInsts),
		...flatCairo(deletedTrailInsts),
		...flatCairo(deletedParentInsts),
		...flatCairo(deletedChildInsts),
		...flatCairo(deletedDescriptionTextKeys),
		...flatCairo(deletedTriggerKeys),
		...flatCairo(deletedConditionKeys),
		...flatCairo(deletedEffectKeys),
		...flatCairo(deletedActionKeys),
	] as RawArgsArray);

	const account = WalletStore().account as Account;
	const call: Call = {
		contractAddress: LORE_CONFIG.contractAddresses.designer,
		entrypoint: "submit_for_review",
		calldata,
	};

	try {
		await Notifications().startPublishing();
		const response = await account.execute([call], { tip: 0 });
		if (response) {
			await account.waitForTransaction(response.transaction_hash, { retryInterval: 200 });
		}
		Notifications().finalizePublishing();
		toast.success("Changes submitted for review.");
		return true;
	} catch (error) {
		const errorMsg = error instanceof Error ? error.message : String(error);
		Notifications().showError(`Error submitting for review: ${errorMsg}`);
		return false;
	}
};

/**
 * Publishes only the components from staged changes that the trail owner approved.
 * Skips the creator_address ownership check — the contract's approval gate enforces access.
 */
export const publishApproved = async (trailId: bigint, approval: ApprovedProposal): Promise<boolean> => {
	const toBigInts = (list: BigNumberish[]) => list.map(x => BigInt(x.toString()));
	const wSingle  = toBigInts(approval.w_single_keys);
	const wDesc    = toBigInts(approval.w_description_texts);
	const wMulti   = toBigInts(approval.w_multi_keys);
	const dSingle  = toBigInts(approval.d_single_keys);
	const dDesc    = toBigInts(approval.d_description_texts);
	const dMulti   = toBigInts(approval.d_multi_keys);

	const staged = EditorData().get().stagedChanges.filter(c => {
		const entity = EditorData().getEntity(c.inst);
		return BigInt(entity?.Entity?.trail_id ?? 0) === trailId;
	});

	if (staged.length === 0) {
		toast.info("Nothing staged for this trail.");
		return false;
	}

	// Track original references alongside the filtered copies so pass-2 cleanup can use
	// reference equality to remove the right entries from stagedChanges/changeSet.
	type ApprovedEntry = { original: ChangeSet; filtered: ChangeSet };
	const approvedChanges: ApprovedEntry[] = [];

	for (const change of staged) {
		const col = change.object; // EditorCollection — enum fields are already string-typed
		const inst = BigInt(change.inst.toString());

		const buildFiltered = (singleList: bigint[], descList: bigint[], multiList: bigint[]): EditorCollection => {
			const out: EditorCollection = {};
			if (col.Entity           && containsInst(singleList, inst)) out.Entity = col.Entity;
			if (col.Reactable        && containsInst(singleList, inst)) out.Reactable = col.Reactable;
			if (col.Area             && containsInst(singleList, inst)) out.Area = col.Area;
			if (col.Exit             && containsInst(singleList, inst)) out.Exit = col.Exit;
			if (col.Hub              && containsInst(singleList, inst)) out.Hub = col.Hub;
			if (col.InventoryItem    && containsInst(singleList, inst)) out.InventoryItem = col.InventoryItem;
			if (col.Container        && containsInst(singleList, inst)) out.Container = col.Container;
			if (col.Trail            && containsInst(singleList, inst)) out.Trail = col.Trail;
			if (col.ParentToChildren && containsInst(singleList, inst)) out.ParentToChildren = col.ParentToChildren;
			if (col.ChildToParent    && containsInst(singleList, inst)) out.ChildToParent = col.ChildToParent;
			if (col.DescriptionText) {
				const ok = filterApprovedMulti(descList, (Array.isArray(col.DescriptionText) ? col.DescriptionText : [col.DescriptionText]) as MultiKeyed[]);
				if (ok.length > 0) out.DescriptionText = ok as DescriptionText[];
			}
			const applyMulti = <T extends MultiKeyed>(src: T | T[] | undefined, key: "Trigger" | "Condition" | "Effect" | "Action") => {
				const ok = filterApprovedMulti(multiList, src as MultiKeyed | MultiKeyed[] | undefined) as T[];
				if (ok.length > 0) (out as Record<string, unknown>)[key] = ok.length === 1 ? ok[0] : ok;
			};
			applyMulti(col.Trigger as Trigger | Trigger[] | undefined, "Trigger");
			applyMulti(col.Condition as Condition | Condition[] | undefined, "Condition");
			applyMulti(col.Effect as Effect | Effect[] | undefined, "Effect");
			applyMulti(col.Action as Action | Action[] | undefined, "Action");
			return out;
		};

		const filtered = change.type === "delete"
			? buildFiltered(dSingle, dDesc, dMulti)
			: buildFiltered(wSingle, wDesc, wMulti);

		if (Object.keys(filtered).length > 0) {
			approvedChanges.push({ original: change, filtered: { ...change, object: filtered } });
		}
	}

	if (approvedChanges.length === 0) {
		toast.info("No approved changes to publish.");
		return false;
	}

	const publishedInsts = [...new Set(approvedChanges.map(e => e.original.inst))];

	try {
		await Notifications().startPublishing();

		// Pass 1: entity data (no parent-child relationships).
		// All entities must exist on-chain before any ChildToParent is written,
		// regardless of the order they appear in stagedChanges.
		for (const { filtered } of approvedChanges) {
			if (filtered.type === "update") {
				await publishEntityData(filtered.object as EntityCollection);
			}
		}

		// Pass 2: parent-child relationships + deletes + cleanup.
		for (const { original, filtered } of approvedChanges) {
			if (filtered.type === "update") {
				await publishEntityRelationships(filtered.object as EntityCollection);
			} else {
				await deleteCollection(filtered.object as EntityCollection);
			}
			EditorData().set({
				changeSet: EditorData().changeSet.filter(x => x !== original),
				stagedChanges: EditorData().get().stagedChanges.filter(x => x !== original),
			});
			persistDraft();
		}

		Notifications().finalizePublishing();

		// Remove the published approval so the "Approved by trail owner" banner disappears.
		const norm = (addr: string) => addr.replace(/^0x0+/, "0x").toLowerCase();
		const proposerNorm = norm(approval.proposer);
		EditorData().set({
			currentApprovals: EditorData().get().currentApprovals.filter(
				(a) => !(BigInt(a.trail_id) === trailId && norm(a.proposer) === proposerNorm)
			),
		});

		await tick();
		await syncEntitiesByInsts(publishedInsts);
		return true;
	} catch (error) {
		const errorMsg = error instanceof Error ? error.message : String(error);
		Notifications().showError(`Error publishing approved changes: ${errorMsg}`);
		return false;
	}
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
		console.log("dispatch: entrypoint:", entrypoint);
		console.log("dispatch: args:", args);

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
