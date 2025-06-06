import { type ChangeEvent } from "react";
import {
	type Trigger,
  triggerType,
} from "@/lib/dojo_bindings/typescript/models.gen";
import {
	Toggle,
  Input,
  CairoEnumSelect,
  formatKeyAsDecimal
} from "../FormComponents";
import type { ComponentInspector } from "./useInspector";
import { useInspector } from "./useInspector";
import { stringCairoEnum } from "@/editor/lib/schemas";

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
    },
	});

	if (!componentObject) return <div>Trigger not found</div>;

	return (
		<Inspector>
      <Input id= "inst" value={componentObject.inst.toString()} onChange={handleInputChange} readOnly={true} />
      <Input id="key" value={formatKeyAsDecimal(componentObject.key)}  onChange={handleInputChange} readOnly={true} />
      <Input
				id="name"
				value={componentObject.name}
				onChange={handleInputChange}
			/>
			<Toggle
				id="is_enabled"
				value={componentObject.is_enabled}
				onChange={handleInputChange}
			/>
			<CairoEnumSelect
				id="trigger_type"
        onChange={handleInputChange}
				value={componentObject.trigger_type}
				enum={triggerType}
			/>
		</Inspector>
	);
}