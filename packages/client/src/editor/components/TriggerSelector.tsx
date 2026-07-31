import { ChangeEvent, useMemo } from "react";
import { Button } from "./ui/Button";
import { DeleteButton, Select } from "./FormComponents";
import { BigNumberish } from "starknet";
import type { Trigger, Entity } from "@/lib/dojo_bindings/typescript/models.gen";
import { bigintEquals } from "@/lib/utils/utils";

interface TriggerSelectorProps {
  id: string;
  value: Array<[string, BigNumberish]>;
  onChange: (e: ChangeEvent<HTMLInputElement>) => void;
  dataPool: Map<BigNumberish, any>;
  readOnly?: boolean;
  sourceEntity: Entity | undefined;
}

export const TriggerSelector = ({
  id,
  value,
  onChange,
  dataPool,
  readOnly,
  sourceEntity,
}: TriggerSelectorProps) => {
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

  // Filter entities by same trail
  const entityOptions = useMemo(() => {
    if (!sourceEntity) return [];

    return Array.from(dataPool.entries())
      .filter(([_, val]) => {
        const entity = val.Entity;
        if (!entity || !entity.name) return false;

        // must have triggers
        if (!val.Trigger) return false;

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

  const getTriggerOptions = (entityId: string) => {
    const entity = dataPool.get(entityId);
    if (!entity || !entity.Trigger) return [];

    const triggers = Array.isArray(entity.Trigger)
      ? entity.Trigger
      : [entity.Trigger];

    return triggers.map((trigger: Trigger) => ({
      label: trigger.name.toString(),
      value: trigger.key.toString(),
    }));
  };

  return (
    <div className="flex flex-col gap-2">
      {value.map(([entityId, triggerKey], i) => (
        <div key={i} className="flex gap-2 items-center relative">
          <Select
            id={`trigger-entity-${i}`}
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
            id={`trigger-key-${i}`}
            value={triggerKey?.toString() ?? ""}
            onChange={(e) => handleChange(i, 1, e.target.value)}
            disabled={readOnly || !entityId}
            options={[
              { value: "__placeholder__", label: "Select trigger" },
              ...getTriggerOptions(entityId),
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
};