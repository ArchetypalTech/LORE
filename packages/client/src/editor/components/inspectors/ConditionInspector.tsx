import { useEffect, useState } from "react";
import {
  type Condition,
  operator,
  componentType,
} from "@/lib/dojo_bindings/typescript/models.gen";
import {
  Input,
  CairoEnumSelect,
  formatKeyAsDecimal,
  Select,
  encodeToFelt,
  decodeFromFelt,
} from "../FormComponents";
import { TextAreaStringArray } from "../TextAreaStringArray";
import type { ComponentInspector } from "./useInspector";
import { useInspector } from "./useInspector";
import { stringCairoEnum } from "@/editor/lib/schemas";
import { syncPropertyRegistry } from "../../data/editor.data";
import { CollapsibleComponent } from "../CollapsibleComponent"; 

// Individual Condition Item Component
const ConditionItem = ({ 
  conditionObj, 
  idx, 
  handleInputChange, 
  Inspector 
}: {
  conditionObj: Condition;
  idx: number;
  handleInputChange: (idx: number) => any;
  Inspector: any;
}) => {
  const [propertyNames, setPropertyNames] = useState<string[]>([]);
  const excludeComponent = ["Entity", "Action", "Trigger", "Condition", "Effect"];

  useEffect(() => {
    const fetchProperties = async () => {
      console.log(conditionObj, conditionObj?.component);
      if (!conditionObj?.component) return;
      try {
        const properties = await syncPropertyRegistry(conditionObj.component);
        console.log(properties);
        setPropertyNames(properties || []);
      } catch (error) {
        console.error("Failed to sync property registry:", error);
        setPropertyNames([]);
      }
    };

    fetchProperties();
  }, [conditionObj?.component]);

  // Property options for dropdown
  const propertyOptions = propertyNames.map((name) => ({
    value: name,
    label: name,
  }));

  return (
    <CollapsibleComponent
      key={`${conditionObj.inst}-${conditionObj.key}`}
      title={`Condition ${formatKeyAsDecimal(conditionObj.key.toString())}`}
    >
      <Inspector key={`${conditionObj.inst}-${conditionObj.key}`} index={idx}>
        <Input id="inst" value={conditionObj.inst.toString()} onChange={handleInputChange(idx)} readOnly={true} />
        <Input id="key" value={formatKeyAsDecimal(conditionObj.key)} onChange={handleInputChange(idx)} readOnly={true} />
        <Input
          id="name"
          value={conditionObj.name}
          onChange={handleInputChange(idx)}
        />
        <Input
          id="target"
          value={conditionObj.target.toString()}
          onChange={handleInputChange(idx)}
        />
        <CairoEnumSelect
          id="component"
          onChange={handleInputChange(idx)}
          value={conditionObj.component}
          enum={componentType.filter((x) => !excludeComponent.includes(x))}
        />
        <Select
          id="property"
          value={conditionObj.property.toString()}
          onChange={handleInputChange(idx)}
          options={propertyOptions}
        />
        <CairoEnumSelect
          id="operator"
          onChange={handleInputChange(idx)}
          value={conditionObj.operator}
          enum={operator}
        />
        <TextAreaStringArray
          id="value"
          value={conditionObj.value.map((v) => decodeFromFelt(v.toString()))}
          onChange={handleInputChange(idx)}
          rows={1}
          columns={1}
        />
      </Inspector>
    </CollapsibleComponent>
  );
};

export const ConditionInspector: ComponentInspector<Condition> = ({
  componentObject,
  ...props
}) => {
  const { handleInputChange, Inspector } = useInspector<Condition>({
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
      operator: (e, updatedObject) => {
        updatedObject.operator = stringCairoEnum(e.target.value);
      },
      value: (e, updatedObject) => {
        let value = e.target.value as unknown as string[];
        let encodedValues = value.map((v) => encodeToFelt(v));
        updatedObject.value = encodedValues;
      }
    },
  });

  if (!componentObject) return <div>Condition not found</div>;

  // Ensure componentObject is always an array
  const componentsArray = Array.isArray(componentObject)
  ? componentObject
  : [componentObject];

  return (
    <>
      {componentsArray.map((conditionObj, idx) => (
        <ConditionItem
          key={`${conditionObj.inst}-${conditionObj.key}`}
          conditionObj={conditionObj}
          idx={idx}
          handleInputChange={handleInputChange}
          Inspector={Inspector}
        />
      ))}
    </>
  );
}


