import { ChangeEvent } from "react";
import { Button } from "./ui/Button";
import { Input } from "./ui/Input";
import { DeleteButton } from "./FormComponents";

export const MultiNumberArray = ({
  id,
  value,
  onChange,
  readOnly,
}: {
  id: string;
  value: Array<[string, string]>;
  onChange: (e: ChangeEvent<HTMLInputElement>) => void;
  readOnly?: boolean;
}) => {
  const handleUpdate = (updated: Array<[string, string]>) => {
    const syntheticEvent = {
      target: {
        id,
        name: id,
        value: updated,
        type: "array",
        readOnly: false,
      },
      currentTarget: {
        id,
        name: id,
        value: updated,
        type: "array",
        readOnly: false,
      },
      bubbles: true,
      cancelable: true,
      defaultPrevented: false,
      preventDefault: () => {},
      stopPropagation: () => {},
      isPropagationStopped: () => false,
      persist: () => {},
      nativeEvent: new Event("input"),
      type: "change",
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

  return (
    <div className="flex flex-col gap-2">
      {value.map(([v1, v2], i) => (
        <div key={i} className="flex gap-2 items-center relative">
          <Input
            value={v1}
            onChange={(e) => handleChange(i, 0, e.target.value)}
            readOnly={readOnly}
          />
          <Input
            value={v2}
            onChange={(e) => handleChange(i, 1, e.target.value)}
            readOnly={readOnly}
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