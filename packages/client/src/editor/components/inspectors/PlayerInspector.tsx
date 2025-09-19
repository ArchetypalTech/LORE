import { type ChangeEvent} from "react";
import {
		type Player,
		type PlayerStory,
} from "@/lib/dojo_bindings/typescript/models.gen";
import { Toggle, Input} from "../FormComponents";
import type { ComponentInspector } from "./useInspector";
import { useInspector } from "./useInspector";
import { BigNumberish } from "starknet";

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
				updatedObject.location = event.target.value as unknown as BigNumberish;
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
				onChange={handleInputChange(undefined)}
			/>
			<Input 
				id="game_id" 
				value={componentObject.game_id.toString()} 
				onChange={handleInputChange(undefined)} 
				readOnly={true}
			/>
			<Input 
				id="address" 
				value={componentObject.address} 
				onChange={handleInputChange(undefined)} 
				readOnly={true}
			/>
			<Input
				id="location"
				value={componentObject.location.toString()}
				onChange={handleInputChange(undefined)}
				//readOnly={true}
			/>
			<Toggle
				id="use_debug"
				value={componentObject.use_debug}
				onChange={handleInputChange(undefined)}
			/>
		</Inspector>
	);
};

export const PlayerStoryInspector: ComponentInspector<PlayerStory> = ({
	componentObject,
	...props
}) => {
	const { handleInputChange, Inspector } = useInspector<PlayerStory>({
		componentObject,
		...props,
		inputHandlers: {
			story_line: (e, updatedObject) => {
				const event = e as ChangeEvent<HTMLInputElement>;
				updatedObject.story_line = event.target.value;
			},
		},
	});

	if (!componentObject) return <div>PlayerStory not found</div>;

	return (
		<Inspector>
			<Input
				id="story_line"
				value={componentObject.story_line.toString()}
				onChange={handleInputChange(undefined)}
				readOnly={true}
			/>
		</Inspector>
	);
};