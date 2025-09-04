import { useEffect, useState } from "react";
import {
  type Effect,
  componentType,
  effectType,
} from "@/lib/dojo_bindings/typescript/models.gen";
import {
  Input,
  CairoEnumSelect,
  Select,
} from "../FormComponents";
import { TextAreaStringArray } from "../TextAreaStringArray";
import type { ComponentInspector } from "./useInspector";
import { useInspector } from "./useInspector";
import { stringCairoEnum } from "@/editor/lib/schemas";
import { syncPropertyRegistry } from "../../data/editor.data";
import { BigNumberish } from "starknet";
import { CollapsibleComponent } from "../CollapsibleComponent";

// Individual Effect Item Component
const EffectItem = ({
  effectObj,
  idx,
  handleInputChange,
  Inspector
}: {
  effectObj: Effect;
  idx: number;
  handleInputChange: (idx: number) => any;
  Inspector: any;
}) => {
  const [propertyNames, setPropertyNames] = useState<string[]>([]);
  const excludeComponent = ["Entity", "Action", "Trigger", "Condition", "Effect"];
  const excludeEffectTypes = ["AddItem", "RemoveItem", "MoveEntity", "SendMessage", "TriggerAction"];

  useEffect(() => {
    const fetchProperties = async () => {
      if (!effectObj?.component) return;
      try {
        const properties = await syncPropertyRegistry(effectObj.component);
        setPropertyNames(properties || []);
      } catch (error) {
        console.error("Failed to sync property registry:", error);
        setPropertyNames([]);
      }
    };

    fetchProperties();
  }, [effectObj?.component]);

  // Property options for dropdown
  const propertyOptions = propertyNames.map((name) => ({
    value: name,
    label: name,
  }));

  return (
    <CollapsibleComponent
      key={`${effectObj.inst}-${effectObj.key}`}
      // title={`Effect ${formatKeyAsDecimal(effectObj.key)}`}
      title={`Effect: ${effectObj?.name}`}
    >
      <Inspector index={idx}>
        <Input
          id="name"
          value={effectObj.name}
          onChange={handleInputChange(idx)}
        />
        <Input
          id="target"
          value={effectObj.target.toString()}
          onChange={handleInputChange(idx)}
        />
        <CairoEnumSelect
          id="effectType"
          onChange={handleInputChange(idx)}
          value={effectObj.effect_type}
          enum={effectType.filter((x) => !excludeEffectTypes.includes(x))}
        />
        <CairoEnumSelect
          id="component"
          onChange={handleInputChange(idx)}
          value={effectObj.component}
          enum={componentType.filter((x) => !excludeComponent.includes(x))}
        />
        <Select
          id="property"
          value={effectObj.property.toString()}
          onChange={handleInputChange(idx)}
          options={propertyOptions}
        />
        <TextAreaStringArray
          id="text_value"
          value={
            effectObj.value.map(([text, index]) => [text.toString(), index.toString()]) as [string, string][]
          }
          onChange={handleInputChange(idx)}
          rows={1}
          columns={2}
        />
        <Input
          id="numeric_value"
          value={effectObj.n_value.toString()}
          onChange={handleInputChange(idx)}
        />
        <Input
          id="hex_value"
          value={effectObj.hex_value.toString()}
          onChange={handleInputChange(idx)}
        />
      </Inspector>
    </CollapsibleComponent>
  );
};

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
      effectType: (e, updatedObject) => {
        updatedObject.effect_type = stringCairoEnum(e.target.value);
      },
      component: (e, updatedObject) => {
        updatedObject.component = stringCairoEnum(e.target.value);
      },
      property: (e, updatedObject) => {
        updatedObject.property = e.target.value;
      },
      text_value: (e, updatedObject) => {
        const val = e.target.value as unknown as [string, string][];
        updatedObject.value = val.map(
          (([text, index]) => [text, index.toString()])
        ) as [string, BigNumberish][];
      },
      numeric_value: (e, updatedObject) => {
        updatedObject.n_value = e.target.value;
      },
      hex_value: (e, updatedObject) => {
        updatedObject.hex_value = e.target.value;
      },
    },
  });

  if (!componentObject) return <div>Effect not found</div>;

  const componentsArray = Array.isArray(componentObject)
    ? componentObject
    : [componentObject];

  return (
    <>
      {componentsArray.map((effectObj, idx) => (
        <EffectItem
          key={`${effectObj.inst}-${effectObj.key}`}
          effectObj={effectObj}
          idx={idx}
          handleInputChange={handleInputChange}
          Inspector={Inspector}
        />
      ))}
    </>
  );
}