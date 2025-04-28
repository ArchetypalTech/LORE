import { type ChangeEvent } from "react";
import EditorData from "@/editor/data/editor.data";
import {
	type ActionMapInventoryItem,
	type InventoryItem,
	inventoryItemActions,
} from "@/lib/dojo_bindings/typescript/models.gen";
import {
	ActionMapEditor,
	Select,
	Toggle,
} from "../FormComponents";
import type { ComponentInspector } from "./useInspector";
import { useInspector } from "./useInspector";

export const InventoryItemInspector: ComponentInspector<InventoryItem> = ({
	componentObject,
	...props
}) => {
  const { handleInputChange, Inspector } = useInspector<InventoryItem>({
    componentObject,
    ...props,
    inputHandlers: {
      is_inventory_item: (e, updatedObject) => {
        const event = e as ChangeEvent<HTMLInputElement>;
        updatedObject.is_inventory_item = event.target.checked;
      },
      owner_id: (e, updatedObject) => {
        updatedObject.owner_id = e.target.value;
      },
      can_be_picked_up: (e, updatedObject) => {
        updatedObject.can_be_picked_up = e.target.checked;
      },
      can_go_in_container: (e, updatedObject) => {
        updatedObject.can_go_in_container = e.target.checked;
      },
      action_map: (e, updatedObject) => {
        const newActionMap = e.target.value as unknown as ActionMapInventoryItem[];
        updatedObject.action_map = newActionMap;
      },
    },
	});

	if (!componentObject) return <div>InventoryItem not found</div>;

	return (
		<Inspector>
			<Toggle
				id="is_inventory_item"
				value={componentObject.is_inventory_item}
				onChange={handleInputChange}
			/>
			<Select
				id="owner_id"
				defaultValue={componentObject.owner_id.toString()}
				onChange={handleInputChange}
				options={EditorData()
					.getEntities()
					.filter((e) => e.Entity !== undefined)
					.map((e) => ({
						value: e.Entity!.inst.toString(),
						label: e.Entity.name,
					}))}
			/>
			<Toggle
				id="can_be_picked_up"
				value={componentObject.can_be_picked_up}
				onChange={handleInputChange}
			/>
			<Toggle
				id="can_go_in_container"
				value={componentObject.can_go_in_container}
				onChange={handleInputChange}
			/>
			<ActionMapEditor
				id="action_map"
				value={componentObject.action_map}
				onChange={handleInputChange}
				cairoEnum={inventoryItemActions}
			/>
		</Inspector>
	);
}