import { type ChangeEvent } from "react";
import {
	type Trigger,
	triggerType,
} from "@/lib/dojo_bindings/typescript/models.gen";
import {
	Toggle,
	Input,
	CairoEnumSelect,
} from "../FormComponents";
import type { ComponentInspector } from "./useInspector";
import { useInspector } from "./useInspector";
import { stringCairoEnum } from "@/editor/lib/schemas";
import { CollapsibleComponent } from "../CollapsibleComponent";

export const TriggerInspector: ComponentInspector<Trigger> = ({
	componentObject,
	...props
}) => {
	const { handleInputChange, Inspector } = useInspector<Trigger>({
		componentObject,
		...props,
		inputHandlers: {
			name: (e, updatedObject) => {
				updatedObject.name = e.target.value as unknown as string;
			},
			trigger_type: (e, updatedObject) => {
				updatedObject.trigger_type = stringCairoEnum(e.target.value);
			},
			is_enabled: (e, updatedObject) => {
				const event = e as ChangeEvent<HTMLInputElement>;
				updatedObject.is_enabled = event.target.checked;
			},
			is_once: (e, updatedObject) => {
				const event = e as ChangeEvent<HTMLInputElement>;
				updatedObject.is_once = event.target.checked;
			},
			was_triggered: (e, updatedObject) => {
				const event = e as ChangeEvent<HTMLInputElement>;
				updatedObject.was_triggered = event.target.checked;
			},
		},
	});

	if (!componentObject) return <div>Trigger not found</div>;

	// Ensure componentObject is always an array
	const componentsArray = Array.isArray(componentObject)
		? componentObject
		: [componentObject];

	return (
		<>
			{componentsArray.map((triggerObj, idx) => (
				<CollapsibleComponent
					key={`${triggerObj.inst}-${triggerObj.key}`}
					title={`Trigger ${triggerObj?.name}`}
				>
					<Inspector key={`${triggerObj.inst}-${triggerObj.key}`} index={idx}>
						<Input
							id="name"
							value={triggerObj.name}
							onChange={handleInputChange(idx)}
						/>
						<Toggle
							id="is_enabled"
							value={triggerObj.is_enabled}
							onChange={handleInputChange(idx)}
						/>
						<CairoEnumSelect
							id="trigger_type"
							onChange={handleInputChange(idx)}
							value={triggerObj.trigger_type}
							enum={triggerType}
						/>
						<Toggle
							id="is_once"
							value={triggerObj.is_once}
							onChange={handleInputChange(idx)}
						/>
						<Toggle
							id="was_triggered"
							value={triggerObj.was_triggered}
							onChange={handleInputChange(idx)}
						/>
					</Inspector>
				</CollapsibleComponent>
			))}
		</>
	);
}