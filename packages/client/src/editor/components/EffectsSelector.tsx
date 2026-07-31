import { ChangeEvent, useMemo } from "react";
import { Button } from "./ui/Button";
import { DeleteButton, Select } from "./FormComponents";
import { BigNumberish } from "starknet";
import type { Entity, Effect } from "@/lib/dojo_bindings/typescript/models.gen";
import { bigintEquals } from "@/lib/utils/utils";

interface EffectSelectorProps {
  id: string;
  value: Array<[string, BigNumberish]>;
  onChange: (e: ChangeEvent<HTMLInputElement>) => void;
  dataPool: Map<BigNumberish, any>; // adjust type as needed
  readOnly?: boolean;
  sourceEntity: Entity | undefined;
}

export const EffectSelector = ({
  id,
  value,
  onChange,
  dataPool,
  readOnly,
  sourceEntity,
}: EffectSelectorProps) => {
  const handleUpdate = (updated: Array<[string, BigNumberish]>) => {
    const syntheticEvent = {
      target: {
        id,
        name: id,
        value: updated,
        type: "array",
      },
    } as unknown as ChangeEvent<HTMLInputElement>;
    onChange(syntheticEvent);
  };

  const handleChange = (i: number, j: 0 | 1, val: string) => {
    const updated = [...value];
    updated[i][j] = val;
    handleUpdate(updated);
  };

  const addRow = () => {
    handleUpdate([...value, ["", ""]]);
  };

  const removeRow = (i: number) => {
    const updated = [...value];
    updated.splice(i, 1);
    handleUpdate(updated);
  };

  const entityOptions = useMemo(() => {
    if (!sourceEntity) return [];

    return Array.from(dataPool.entries())
      .filter(([_, val]) => {
        const entity = val.Entity;
        if (!entity || !entity.name) return false;

        // must have effects
        if (!val.Effect) return false;

        return bigintEquals(entity.trail_id, sourceEntity.trail_id);
      })
      .map(([address, val]) => {
        const entity = val.Entity;
        return {
          label: entity.name,
          value: address,
        };
      });
  }, [dataPool, sourceEntity]);

  const getEffectOptions = (entityId: string) => {
    const entity = dataPool.get(entityId);
    if (!entity || !entity.Effect) return [];
    
    const effects = Array.isArray(entity.Effect)
    ? entity.Effect
    : [entity.Effect];

    return effects.map((effect: Effect) => ({
      label: effect.name.toString(),
      value: effect.key.toString(),
    }));
  };

  return (
    <div className="flex flex-col gap-2">
      {value.map(([entityId, effectKey], i) => (
        <div key={i} className="flex gap-2 items-center relative">
          <Select
            id={`effect-entity-${i}`}
            value={entityId}
            onChange={(e) => handleChange(i, 0, e.target.value)}
            disabled={readOnly}
            options={[
              { value: "__placeholder__", label: "Select entity" },
              ...entityOptions.map((opt) => ({
                value: opt.value.toString(),
                label: String(opt.label),
              })),
            ]}
          />

          <Select
            id={`effect-key-${i}`}
            value={effectKey?.toString() ?? ""}
            onChange={(e) => handleChange(i, 1, e.target.value)}
            disabled={readOnly || !entityId}
            options={[
              { value: "__placeholder__", label: "Select effect" },
              ...getEffectOptions(entityId),
            ]}
          />

          <div className="absolute right-0 top-0 scale-50 opacity-50 hover:opacity-100">
            <DeleteButton onClick={() => removeRow(i)} />
          </div>
        </div>
      ))}

      <Button variant="secondary" onClick={addRow}>
        Add {id}
      </Button>
    </div>
  );
}