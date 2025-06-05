import {
  type Condition,
  operator,
  components,
} from "@/lib/dojo_bindings/typescript/models.gen";
import {
  Input,
  CairoEnumSelect,
  formatKeyAsDecimal,
} from "../FormComponents";
import type { ComponentInspector } from "./useInspector";
import { useInspector } from "./useInspector";
import { stringCairoEnum } from "@/editor/lib/schemas";

export const ConditionInspector: ComponentInspector<Condition> = ({
  componentObject,
  ...props
}) => {
  const { handleInputChange, Inspector } = useInspector<Condition>({
    componentObject,
    ...props,
    inputHandlers: {
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
        updatedObject.value = e.target.value;
      },
    },
  });

  if (!componentObject) return <div>Condition not found</div>;

  return (
    <Inspector>
      <Input id="inst" value={componentObject.inst.toString()} onChange={handleInputChange} readOnly={true} />
      <Input id="key" value={formatKeyAsDecimal(componentObject.key)} onChange={handleInputChange} readOnly={true} />
      <Input
        id="target"
        value={componentObject.target.toString()}
        onChange={handleInputChange}
      />
      <CairoEnumSelect
        id="component"
        onChange={handleInputChange}
        value={componentObject.component}
        enum={components}
      />
      <Input
        id="property"
        value={componentObject.property}
        onChange={handleInputChange}
      />
      <CairoEnumSelect
        id="operator"
        onChange={handleInputChange}
        value={componentObject.operator}
        enum={operator}
      />
      <Input
        id="value"
        value={componentObject.value.toString()}
        onChange={handleInputChange}
      />
    </Inspector>
  );
}