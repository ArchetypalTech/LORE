import { ChangeEvent, useMemo } from "react";
import { Button } from "./ui/Button";
import { DeleteButton, Select } from "./FormComponents";
import { BigNumberish } from "starknet";
import { formatKeyAsDecimal } from "./FormComponents";

interface EffectSelectorProps {
  id: string;
  value: Array<[string, BigNumberish]>;
  onChange: (e: ChangeEvent<HTMLInputElement>) => void;
  dataPool: Map<BigNumberish, any>; // adjust type as needed
  readOnly?: boolean;
}

export const EffectSelector = ({
  id,
  value,
  onChange,
  dataPool,
  readOnly,
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
    return Array.from(dataPool.entries())
      .filter(([_, val]) => val.Entity?.name && val.Effect?.key)
      .map(([address, val]) => ({
        label: val.Entity.name,
        value: address,
      }));
  }, [dataPool]);

  const getEffectOptions = (entityId: string) => {
    const entity = dataPool.get(entityId);
    if (!entity || !entity.Effect) return [];
    return [
      {
        label: formatKeyAsDecimal(entity.Effect.key),
        value: entity.Effect.key.toString(),
      },
    ];
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
            { value: "__placeholder__", label: "Select entity"},
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