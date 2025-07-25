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
<<<<<<< HEAD
  const excludeComponent = ["Entity", "Action", "Trigger", "Condition", "Effect"];
=======
  const excludeComponent = ["Entiy", "Action", "Trigger", "Condition", "Effect"];
>>>>>>> 8eb73a2 (chore: finish updating new variables on conditions and effects)

  return (
    <Inspector>
      <Input id="inst" value={componentObject.inst.toString()} onChange={handleInputChange} readOnly={true} />
      <Input id="key" value={formatKeyAsDecimal(componentObject.key)} onChange={handleInputChange} readOnly={true} />
      <Input
				id="name"
				value={componentObject.name}
				onChange={handleInputChange}
			/>
      <Input
        id="target"
        value={componentObject.target.toString()}
        onChange={handleInputChange}
      />
      <CairoEnumSelect
        id="component"
        onChange={handleInputChange}
        value={componentObject.component}
<<<<<<< HEAD
<<<<<<< HEAD
        enum={componentType.filter((x) => !excludeComponent.includes(x))}
=======
        enum={componentType}
>>>>>>> da71536 (chore: implemented names variable for action system and adjusted dropdown key list)
=======
        enum={componentType.filter((x) => !excludeComponent.includes(x))}
>>>>>>> 8eb73a2 (chore: finish updating new variables on conditions and effects)
      />
      <Select
        id="property"
        value={componentObject.property.toString()}
        onChange={handleInputChange}
        options={propertyOptions}
      />
      <TextAreaStringArray
        id="value"
        value={
          componentObject.value.map(([text, index]) => [text.toString(), index.toString()]) as [string, string][]
        }
        onChange={handleInputChange}
        rows={1}
        columns={2}
      />
    </Inspector>
  );
}