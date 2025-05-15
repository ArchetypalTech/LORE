import { type ChangeEvent } from "react";
import {
	type ActionMapContainer,
	type Container,
	containerActions,
} from "@/lib/dojo_bindings/typescript/models.gen";
import { ActionMapEditor, Toggle, Input } from "../FormComponents";
import type { ComponentInspector } from "./useInspector";
import { useInspector } from "./useInspector";

export const ContainerInspector: ComponentInspector<Container> = ({
	componentObject,
	...props
}) => {
	const { handleInputChange, Inspector } = useInspector<Container>({
		componentObject,
		...props,
		inputHandlers: {
			is_container: (e, updatedObject) => {
				const event = e as ChangeEvent<HTMLInputElement>;
				updatedObject.is_container = event.target.checked;
			},
			can_be_opened: (e, updatedObject) => {
				updatedObject.can_be_opened = e.target.checked;
			},
			can_receive_items: (e, updatedObject) => {
				updatedObject.can_receive_items = e.target.checked;
			},
			is_open: (e, updatedObject) => {
				updatedObject.is_open = e.target.checked;
			},
			num_slots: (e, updatedObject) => {
				updatedObject.num_slots = e.target.value;
			},
			action_map: (e, updatedObject) => {
				const newActionMap = e.target.value as unknown as ActionMapContainer[];
				updatedObject.action_map = newActionMap;
			},
		},
	});

	if (!componentObject) return <div>Container not found</div>;

	return (
		<Inspector>
			<Toggle
				id="is_container"
				value={componentObject.is_container}
				onChange={handleInputChange}
			/>
			<Toggle
				id="can_be_opened"
				value={componentObject.can_be_opened}
				onChange={handleInputChange}
			/>
			<Toggle
				id="can_receive_items"
				value={componentObject.can_receive_items}
				onChange={handleInputChange}
			/>
			<Toggle
				id="is_open"
				value={componentObject.is_open}
				onChange={handleInputChange}
			/>
			<Input
				id="num_slots"
				value={componentObject.num_slots.toString()}
				onChange={handleInputChange}
			/>
			<ActionMapEditor
				id="action_map"
				value={componentObject.action_map}
				onChange={handleInputChange}
				cairoEnum={containerActions}
			/>
		</Inspector>
	);
};