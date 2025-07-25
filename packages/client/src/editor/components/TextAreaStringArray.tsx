import { Textarea } from "./ui/Textarea";
import { Input } from "./ui/Input";
import { Button } from "./ui/Button";
import { DeleteButton } from "./FormComponents";
import { cn } from "@/lib/utils/utils";
import { useMemo } from "react";

export const TextAreaStringArray = ({
  id,
  value,
  rows,
  className,
  children,
  onChange,
  readOnly,
  columns = 1, // New prop for number of columns
}: {
  id: string;
  value: string[] | [string, string][]; // 1D or 2D string tuples
  onChange: (e: React.ChangeEvent<HTMLTextAreaElement>) => void;
  rows: number;
  className?: string;
  children?: React.ReactNode;
  readOnly?: boolean;
  columns?: number;
}) => {
  return (
    <div className="form-group">
      <label htmlFor={id}>{id}</label>
      <MultiTextStringArea
        id={id}
        value={value}
        rows={rows}
        className={className}
        onChange={onChange}
        readOnly={readOnly}
        columns={columns}
      />
      {children}
    </div>
  );
};

export const MultiTextStringArea = ({
  id,
  value,
  onChange,
  rows,
  className,
  readOnly,
  columns = 1,
}: {
  id: string;
  value: string[] | [string, string][];
  onChange: (e: React.ChangeEvent<HTMLTextAreaElement>) => void;
  rows: number;
  className?: string;
  readOnly?: boolean;
  columns?: number;
}) => {
  const handleNewValue = (arrays: typeof value) => {
    const syntheticEvent = {
      target: {
        id,
        name: id,
        value: arrays,
      },
      currentTarget: {
        id,
        name: id,
        value: arrays,
      },
      preventDefault: () => {},
      stopPropagation: () => {},
      isPropagationStopped: () => false,
      persist: () => {},
      nativeEvent: new Event("input"),
      type: "change",
    } as unknown as React.ChangeEvent<HTMLTextAreaElement>;
    onChange(syntheticEvent);
  };

  const handleChange = (i: number, col: number, val: string) => {
		let newValue: [string, string][] | string[];

		if (columns === 2) {
			newValue = [...(value as [string, string][])];
			const oldRow = newValue[i] ?? ["", ""];
			const row: [string, string] = [oldRow[0], oldRow[1]];
			row[col] = val;
			newValue[i] = row;
		} else {
			newValue = [...(value as string[])];
			newValue[i] = val;
		}

		handleNewValue(newValue);
	};


  const handleAddArray = () => {
    const newItem = columns === 2 ? ["", ""] : "";
    handleNewValue([...(value as any[]), newItem]);
  };

  const handleRemoveArray = (i: number) => {
    const newValue = [...(value as any[])];
    newValue.splice(i, 1);
    handleNewValue(newValue);
  };

  const rowsToRender = useMemo(() => {
    if (value.length > 0) return value;
    return columns === 2 ? [["", ""]] : [""];
  }, [value, columns]);

  return (
    <div className="flex flex-col gap-2">
      {rowsToRender.map((v, i) => (
        <div key={i} className="relative flex items-center gap-2">
          {columns === 2 ? (
            <>
              <Textarea
                id={`${i}-0`}
                defaultValue={(v as [string, string])[0]}
                onBlur={(e) => handleChange(i, 0, e.target.value)}
                rows={rows}
                readOnly={readOnly}
                className={cn("w-1/2 bg-white", className)}
              />
              <Input
                id={`${i}-1`}
                type="number"
                defaultValue={(v as [string, string])[1]}
                onBlur={(e) => handleChange(i, 1, e.target.value)}
                readOnly={readOnly}
                className={cn("w-1/4 bg-white", className)}
              />
            </>
          ) : (
            <Textarea
              id={i.toString()}
              defaultValue={v as string}
              onBlur={(e) => handleChange(i, 0, e.target.value)}
              rows={rows}
              readOnly={readOnly}
              className={cn("flex w-full bg-white", className)}
            />
          )}

          <div className="absolute top-0 right-0 scale-50 opacity-50 hover:opacity-100">
            <DeleteButton onClick={() => handleRemoveArray(i)} />
          </div>
        </div>
      ))}
      <Button variant="secondary" onClick={handleAddArray}>
        Add {id}
      </Button>
    </div>
  );
};