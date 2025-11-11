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

  const entityOptions = useMemo(() => {
    return Array.from(dataPool.entries())
      .filter(([_, val]) => val.Entity?.name && bigintEquals(val.Entity.trail_id, sourceEntity?.trail_id ?? 0))
      .map(([address, val]) => ({
        label: val.Entity.name as string,
        value: address,
      }));
  }, [dataPool]);

  const filteredOptions = useMemo(() => {
    if (!filter) return entityOptions;
    const lower = filter.toLowerCase();
    return entityOptions.filter((opt) =>
      String(opt.label).toLowerCase().startsWith(lower)
    );
  }, [entityOptions, filter]);

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
          ...filteredOptions.map((opt) => ({
            value: opt.value.toString(),
            label: String(opt.label),
          })),
        ]}
      />
    </div>
  );
};