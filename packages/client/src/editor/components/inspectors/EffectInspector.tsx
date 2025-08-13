import { useEffect, useState } from "react";
import {
  type Effect,
  componentType,
} from "@/lib/dojo_bindings/typescript/models.gen";
import {
  Input,
  CairoEnumSelect,
  formatKeyAsDecimal,
  Select,
} from "../FormComponents";
import { TextAreaStringArray } from "../TextAreaStringArray";
import type { ComponentInspector } from "./useInspector";
import { useInspector } from "./useInspector";
import { stringCairoEnum } from "@/editor/lib/schemas";
import { syncPropertyRegistry } from "../../data/editor.data"; 
import { BigNumberish } from "starknet";

export const EffectInspector: ComponentInspector<Effect> = ({
  componentObject,
  ...props
}) => {
  const { handleInputChange, Inspector } = useInspector<Effect>({
    componentObject,
    ...props,
    inputHandlers: {
      name: (e, updatedObject) => {
        updatedObject.name = e.target.value as unknown as string;
      },
      target: (e, updatedObject) => {
        updatedObject.target = e.target.value;
      },
      component: (e, updatedObject) => {
        updatedObject.component = stringCairoEnum(e.target.value);
      },
      property: (e, updatedObject) => {
        updatedObject.property = e.target.value;
      },
      value: (e, updatedObject) => {
        const val = e.target.value as unknown as [string, string][];
        updatedObject.value = val.map(
          (([text, index]) => [text, index.toString()])
        ) as [string, BigNumberish][];
      },
    },
  });

  const [propertyNames, setPropertyNames] = useState<string[]>([]);

  useEffect(() => {
    const fetchProperties = async () => {
      if (!componentObject?.component) return;
      try {
        const properties = await syncPropertyRegistry(componentObject.component);
        setPropertyNames(properties!);
      } catch (error) {
        console.error("Failed to sync property registry:", error);
      }
    };

    fetchProperties();
  }, [componentObject?.component]);

  // Property options for dropdown
  const propertyOptions = propertyNames.map((name) => ({
    value: name,
    label: name,
  }));

  if (!componentObject) return <div>Effect not found</div>;
  const excludeComponent = ["Entity", "Action", "Trigger", "Condition", "Effect"];

  return (
		<>
			{componentObject.map((componentObj, idx) => {
				<Inspector key={`${componentObj.inst}-${componentObj.key}`} index={idx}>
					<Input id="inst" value={componentObj.inst.toString()} onChange={handleInputChange(idx)} readOnly={true} />
					<Input id="key" value={formatKeyAsDecimal(componentObj.key)} onChange={handleInputChange(idx)} readOnly={true} />
					<Input
						id="name"
						value={componentObj.name}
						onChange={handleInputChange(idx)}
					/>
					<Input
						id="target"
						value={componentObj.target.toString()}
						onChange={handleInputChange(idx)}
					/>
					<CairoEnumSelect
						id="component"
						onChange={handleInputChange(idx)}
						value={componentObj.component}
						enum={componentType.filter((x) => !excludeComponent.includes(x))}
					/>
					<Select
						id="property"
						value={componentObj.property.toString()}
						onChange={handleInputChange(idx)}
						options={propertyOptions}
					/>
					<TextAreaStringArray
						id="value"
						value={
							componentObj.value.map(([text, index]) => [text.toString(), index.toString()]) as [string, string][]
						}
						onChange={handleInputChange(idx)}
						rows={1}
						columns={2}
					/>
				</Inspector>
			})}
		</>
	);
}