import { useMemo, type ChangeEvent } from "react";
import {
	type ActionMapInventoryItem,
	type InventoryItem,
	inventoryItemActions,
	Entity,
} from "@/lib/dojo_bindings/typescript/models.gen";
import {
	ActionMapEditor,
	Toggle,
	Input,
} from "../FormComponents";
import type { ComponentInspector } from "./useInspector";
import { useInspector } from "./useInspector";
import { EntitySelector } from "../EntitySelector";
import { getEntity, useEditorData } from "../../data/editor.data";

export const InventoryItemInspector: ComponentInspector<InventoryItem> = ({
	componentObject,
	...props
}) => {
  const entity = useMemo(() => getEntity(componentObject.inst)?.Entity, [componentObject]);

	const { handleInputChange, Inspector } = useInspector<InventoryItem>({
		componentObject,
		...props,
		inputHandlers: {
			is_inventory_item: (e, updatedObject) => {
				const event = e as ChangeEvent<HTMLInputElement>;
				updatedObject.is_inventory_item = event.target.checked;
			},
			can_be_picked_up: (e, updatedObject) => {
				updatedObject.can_be_picked_up = e.target.checked;
			},
			can_go_in_container: (e, updatedObject) => {
				updatedObject.can_go_in_container = e.target.checked;
			},
			quantity: (e, updatedObject) => {
				updatedObject.quantity = e.target.value;
			},
			action_map: (e, updatedObject) => {
				const newActionMap = e.target.value as unknown as ActionMapInventoryItem[];
				updatedObject.action_map = newActionMap;
			},
			alread_used: (e, updatedObject) => {
				updatedObject.already_used = e.target.checked;
			},
			multiple_use: (e, updatedObject) => {
				updatedObject.multiple_use = e.target.checked;
			},
		},
	});

	if (!componentObject) return <div>InventoryItem not found</div>;

	const { dataPool } = useEditorData();

	return (
		<Inspector>
			<Toggle
				id="is_inventory_item"
				value={componentObject.is_inventory_item}
				onChange={handleInputChange(undefined)}
			/>
			<Toggle
				id="can_be_picked_up"
				value={componentObject.can_be_picked_up}
				onChange={handleInputChange(undefined)}
			/>
			<Toggle
				id="can_go_in_container"
				value={componentObject.can_go_in_container}
				onChange={handleInputChange(undefined)}
			/>
			<Input
				id="quantity"
				value={componentObject.quantity.toString()}
				onChange={handleInputChange(undefined)}
			/>
			<EntitySelector
				id="owner_id"
				value={componentObject.owner_id.toString()}
				onChange={handleInputChange(undefined)}
				dataPool={dataPool}
				//readOnly={true}
				sourceEntity={entity}
			/>
			<ActionMapEditor
				id="action_map"
				value={componentObject.action_map}
				onChange={handleInputChange(undefined)}
				cairoEnum={inventoryItemActions}
			/>
			<Toggle
				id="alread_used"
				value={componentObject.already_used}
				onChange={handleInputChange(undefined)}
			/>
			<Toggle
				id="multiple_use"
				value={componentObject.multiple_use}
				onChange={handleInputChange(undefined)}
			/>
		</Inspector>
	);
}