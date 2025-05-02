import { type ChangeEvent } from "react";
import {
		type Player,
} from "@/lib/dojo_bindings/typescript/models.gen";
import { ActionMapEditor, Toggle, Input } from "../FormComponents";
import type { ComponentInspector } from "./useInspector";
import { useInspector } from "./useInspector";

export const PlayerInspector: ComponentInspector<Player> = ({
	componentObject,
	...props
}) => {
	const { handleInputChange, Inspector } = useInspector<Player>({
		componentObject,
		...props,
		inputHandlers: {
			is_player: (e, updatedObject) => {
				const event = e as ChangeEvent<HTMLInputElement>;
				updatedObject.is_player = event.target.checked;
			},
			address: (e, updatedObject) => {
				const event = e as ChangeEvent<HTMLInputElement>;
				updatedObject.address = event.target.value;
			},
			location: (e, updatedObject) => {
				const event = e as ChangeEvent<HTMLInputElement>;
				updatedObject.location = event.target.value;
			},
			use_debug: (e, updatedObject) => {
				const event = e as ChangeEvent<HTMLInputElement>;
				updatedObject.use_debug = event.target.checked;
			},
		},
	});

	if (!componentObject) return <div>Player not found</div>;

	return (
		<Inspector>
			<Toggle
				id="is_player"
				value={componentObject.is_player}
				onChange={handleInputChange}
			/>
			<Input
				id="location"
				value={componentObject.location.toString()}
				onChange={handleInputChange}
			/>
			<Toggle
				id="use_debug"
				value={componentObject.use_debug}
				onChange={handleInputChange}
			/>
		</Inspector>
	);
};