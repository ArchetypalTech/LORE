import { ChangeEvent, useMemo, useState } from "react";
import { Select } from "./FormComponents";
import { BigNumberish } from "starknet";
import type { Entity } from "@/lib/dojo_bindings/typescript/models.gen";
import { bigintEquals } from "@/lib/utils/utils";


interface EntitySelectorProps {
  id: string;
  value: string;
  onChange: (e: ChangeEvent<HTMLInputElement>) => void;
  dataPool: Map<BigNumberish, any>;
  readOnly?: boolean;
  sourceEntity: Entity | undefined;
}

export const EntitySelector = ({
  id,
  value,
  onChange,
  dataPool,
  readOnly,
  sourceEntity,
}: EntitySelectorProps) => {
  const [filter, setFilter] = useState("");

  const handleUpdate = (val: string) => {
    const syntheticEvent = {
      target: {
        id,
        name: id,
        value: val,
        type: "string",
      },
    } as unknown as ChangeEvent<HTMLInputElement>;

    onChange(syntheticEvent);
  };

  // ✅ Only entities from the same trail
  const entityOptions = useMemo(() => {
    if (!sourceEntity) return [];

    return Array.from(dataPool.entries())
      .filter(([_, val]) => {
        const entity = val.Entity;
        if (!entity || !entity.name) return false;

        return bigintEquals(entity.trail_id, sourceEntity.trail_id);
      })
      .map(([address, val]) => ({
        label: val.Entity.name as string,
        value: address,
      }));
  }, [dataPool, sourceEntity]);

  // ✅ Text filter
  const filteredOptions = useMemo(() => {
    if (!filter) return entityOptions;

    const lower = filter.toLowerCase();

    return entityOptions.filter((opt) =>
      String(opt.label).toLowerCase().startsWith(lower)
    );
  }, [entityOptions, filter]);

  // ✅ Ensure selected value doesn't disappear when filtering
  const finalOptions = useMemo(() => {
    const exists = filteredOptions.some(
      (opt) => opt.value.toString() === value
    );

    if (exists) return filteredOptions;

    const current = entityOptions.find(
      (opt) => opt.value.toString() === value
    );

    return current ? [current, ...filteredOptions] : filteredOptions;
  }, [filteredOptions, entityOptions, value]);

  return (
    <div className="flex flex-col gap-2">
      <input
        type="text"
        placeholder="Filter entities..."
        value={filter}
        onChange={(e) => setFilter(e.target.value)}
        className="border rounded p-1"
        disabled={readOnly}
      />

      <Select
        id={`entity-${id}`}
        value={value}
        onChange={(e) => handleUpdate(e.target.value)}
        disabled={readOnly}
        options={[
          { value: "__placeholder__", label: "Select entity" },
          ...finalOptions.map((opt) => ({
            value: opt.value.toString(),
            label: String(opt.label),
          })),
        ]}
      />
    </div>
  );
};