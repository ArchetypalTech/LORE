
import { useState } from "react";
import { type ChangeEvent } from "react";
import {
  type Action,
} from "@/lib/dojo_bindings/typescript/models.gen";
import {
  Input,
  TagInput,
  Toggle,
  TextAreaArray,
  formatKeyAsDecimal,
} from "../FormComponents";
import type { ComponentInspector } from "./useInspector";
import { useInspector } from "./useInspector";
import { TriggerSelector } from "../TriggerSelector";
import { ConditionSelector } from "../ConditionSelector";
import { EffectSelector } from "../EffectsSelector";
import { BigNumberish } from "starknet";
import { useEditorData } from "../../data/editor.data";
import { CollapsibleComponent } from "../CollapsibleComponent";

export const ActionInspector: ComponentInspector<Action> = ({
  componentObject,
  ...props
}) => {
  const { handleInputChange, Inspector } = useInspector<Action>({
    componentObject,
    ...props,
    inputHandlers: {
      name: (e, updatedObject) => {
        updatedObject.name = e.target.value;
      },
      description: (e, updatedObject) => {
        updatedObject.description = e.target.value;
      },
      is_enabled: (e, updatedObject) => {
        const event = e as ChangeEvent<HTMLInputElement>;
        updatedObject.is_enabled = event.target.checked;
      },
      triggers: (e, updatedObject) => {
        const val = e.target.value as unknown as Array<[string, BigNumberish]>;
        updatedObject.trigger = val
        .filter(([a, b]) => a !== "__placeholder__" && b !== "__placeholder__")
        .map(
          ([a, b]) => [(a), (b)]
        ) as [BigNumberish, BigNumberish][];
      },
      conditions: (e, updatedObject) => {
        const val = e.target.value as unknown as Array<[string, BigNumberish]>;
        updatedObject.conditions = val
        .filter(([a, b]) => a !== "__placeholder__" && b !== "__placeholder__")
        .map(
          ([a, b]) => [(a), (b)]
        ) as [BigNumberish, BigNumberish][];
      },
      effects: (e, updatedObject) => {
        const val = e.target.value as unknown as Array<[string, BigNumberish]>;
        updatedObject.effects = val
        .filter(([a, b]) => a !== "__placeholder__" && b !== "__placeholder__")
        .map(
          ([a, b]) => [(a), (b)]
        ) as [BigNumberish, BigNumberish][];
      },
      tags: (e, updatedObject) => {
        const val = e.target.value;
        let entries: string[];

        if (Array.isArray(val)) {
          entries = val.map((line) => line.trim()).filter((line) => line !== "");
        } else if (typeof val === "string") {
          entries = val
            .split("\n")
            .map((line) => line.trim())
            .filter((line) => line !== "");
        } else {
          entries = [];
        }

        updatedObject.tags = entries;
      },
      executed: (e, updatedObject) => {
        updatedObject.executed = e.target.checked;
      },
      failing_response: (e, updatedObject) => {
        const val = e.target.value as unknown as string[];
        updatedObject.failing_response = val;
      },
      success_response: (e, updatedObject) => {
        const val = e.target.value as unknown as string[];
        updatedObject.success_response = val;
      },
    },
  });
  
  const { dataPool } = useEditorData();
  
  if (!componentObject) return <div>Action not found</div>;

  // Ensure componentObject is always an array
  const componentsArray = Array.isArray(componentObject)
    ? componentObject
    : [componentObject];
  
  return (
    <>
      {componentsArray.map((componentObj, idx) => {
        return (
          <CollapsibleComponent key={`${componentObj.inst}-${componentObj.key}`} title={`Action ${formatKeyAsDecimal(componentObj.key)}`}>
            <Inspector index={idx}>
              <Input
                id="inst"
                value={componentObj.inst.toString()}
                onChange={handleInputChange(idx)}
                readOnly={true}
              />
              <Input
                id="key"
                value={formatKeyAsDecimal(componentObj.key)}
                onChange={handleInputChange(idx)}
                readOnly={true}
              />
              <Input
                id="name"
                value={componentObj.name}
                onChange={handleInputChange(idx)}
              />
              <Input
                id="description"
                value={componentObj.description}
                onChange={handleInputChange(idx)}
              />
              <Toggle
                id="is_enabled"
                value={componentObj.is_enabled}
                onChange={handleInputChange(idx)}
              />
              <TriggerSelector
                id="triggers"
                value={componentObj.trigger.map(([a, b]) => [a.toString(), b])}
                onChange={handleInputChange(idx)}
                dataPool={dataPool}
              />
              <ConditionSelector
                id="conditions"
                value={componentObj.conditions.map(([a, b]) => [a.toString(), b])}
                onChange={handleInputChange(idx)}
                dataPool={dataPool}
              />
              <EffectSelector
                id="effects"
                value={componentObj.effects.map(([a, b]) => [a.toString(), b])}
                onChange={handleInputChange(idx)}
                dataPool={dataPool}
              />
              <TextAreaArray
                id="failing_response"
                value={componentObj.failing_response}
                onChange={handleInputChange(idx)}
                rows={1}
              />
              <TextAreaArray
                id="success_response"
                value={componentObj.success_response}
                onChange={handleInputChange(idx)}
                rows={1}
              />
              <TagInput
                id="tags"
                value={componentObj.tags?.join(",") || ""}
                onChange={handleInputChange(idx)}
              />
              <Toggle
                id="executed"
                value={componentObj.executed}
                onChange={handleInputChange(idx)}
              />
            </Inspector>
          </CollapsibleComponent>
        );
      })}
    </>
  );
};