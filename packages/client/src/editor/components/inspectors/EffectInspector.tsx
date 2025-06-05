import {
  type Effect,
  components,
} from "@/lib/dojo_bindings/typescript/models.gen";
import {
  Input,
  CairoEnumSelect,
  formatKeyAsDecimal,
} from "../FormComponents";
import { TextAreaStringArray } from "../TextAreaStringArray";
import type { ComponentInspector } from "./useInspector";
import { useInspector } from "./useInspector";
import { stringCairoEnum } from "@/editor/lib/schemas";

export const EffectInspector: ComponentInspector<Effect> = ({
  componentObject,
  ...props
}) => {
  const { handleInputChange, Inspector } = useInspector<Effect>({
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
      value: (e, updatedObject) => {
        updatedObject.value =  e.target.value as unknown as string[]
      },
    },
  });
  if (!componentObject) return <div>Effect not found</div>;

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
      <TextAreaStringArray
        id="value"
        value={componentObject.value.map((v) => v.toString())}
        onChange={handleInputChange}
        rows={1}
      />
    </Inspector>
  );
}