import { type ChangeEvent, useMemo } from "react";
import EditorData, { getEntity } from "@/editor/data/editor.data";
import { stringCairoEnum } from "@/editor/lib/schemas";
import {
	type ActionMapExit,
	direction,
	Entity,
	type Exit,
	exitActions,
} from "@/lib/dojo_bindings/typescript/models.gen";
import {
	ActionMapEditor,
	CairoEnumSelect,
	Select,
	Toggle,
} from "../FormComponents";
import type { ComponentInspector } from "./useInspector";
import { useInspector } from "./useInspector";
import { bigintEquals, bigintToAddress } from "@/lib/utils/utils";

export const ExitInspector: ComponentInspector<Exit> = ({
	componentObject,
	...props
}) => {
  const entity = useMemo(() => getEntity(componentObject.inst)?.Entity, [componentObject]);
	
	// @dev: get available areas to link to
	const { area_value, area_options } = useMemo(() => {
		return {
			area_value: bigintToAddress(componentObject.leads_to),
			area_options: EditorData()
				.getEntities()
				.filter((e) => e.Area !== undefined)
				.filter((e) => bigintEquals(e.Entity.trail_id, entity?.Entity.trail_id))
				.map((e) => ({
					value: bigintToAddress(e.Entity!.inst),
					label: e.Entity.name,
				})),
		};
	}, [componentObject]);

	const { handleInputChange, Inspector } = useInspector<Exit>({
		componentObject,
		...props,
		inputHandlers: {
			is_enterable: (e, updatedObject) => {
				const event = e as ChangeEvent<HTMLInputElement>;
				updatedObject.is_enterable = event.target.checked;
			},
			leads_to: (e, updatedObject) => {
				updatedObject.leads_to = e.target.value;
			},
			direction_type: (e, updatedObject) => {
				updatedObject.direction_type = stringCairoEnum(e.target.value);
			},
			action_map: (e, updatedObject) => {
				const newActionMap = e.target.value as unknown as ActionMapExit[];
				updatedObject.action_map = newActionMap;
			},
		},
	});

	if (!componentObject) return <div>Exit not found</div>;

	return (
		<Inspector>
			<Toggle
				id="is_enterable"
				value={componentObject.is_enterable}
				onChange={handleInputChange(undefined)}
			/>
			<Select
				id="leads_to"
				defaultValue={area_value}
				onChange={handleInputChange(undefined)}
				options={area_options}
			/>
			<CairoEnumSelect
				id="direction_type"
				onChange={handleInputChange(undefined)}
				value={componentObject.direction_type}
				enum={direction}
			/>
			<ActionMapEditor
				id="action_map"
				value={componentObject.action_map}
				onChange={handleInputChange(undefined)}
				cairoEnum={exitActions}
			/>
		</Inspector>
	);
};
