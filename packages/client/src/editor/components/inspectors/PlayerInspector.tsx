import { type ChangeEvent, useMemo } from "react";
import EditorData from "@/editor/data/editor.data";
import {
		type Player,
} from "@/lib/dojo_bindings/typescript/models.gen";
import { Toggle, Input, Select } from "../FormComponents";
import type { ComponentInspector } from "./useInspector";
import { useInspector } from "./useInspector";


export const PlayerInspector: ComponentInspector<Player> = ({
	componentObject,
	...props
}) => {
	const {area_value, area_options} = useMemo(() => {
		return {
			area_value: componentObject.location.toString(),
			area_options: EditorData()
				.getEntities()
				.filter((e) => e.Area !== undefined)
				.map((e) => ({
					value: e.Entity!.inst.toString(),
					label: e.Entity.name,
				})),
		};
	}, [componentObject]);

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
				id="address" 
				value={componentObject.address} 
				onChange={handleInputChange} />
			<Select
				id="location"
				value={componentObject.location.toString()}
				onChange={handleInputChange}
				options={area_options}
			/>
			<Toggle
				id="use_debug"
				value={componentObject.use_debug}
				onChange={handleInputChange}
			/>
		</Inspector>
	);
};