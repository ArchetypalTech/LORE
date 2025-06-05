import { Textarea } from "./ui/Textarea";
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
  }: {
  id: string;
  value: string[];
  onChange: (e: React.ChangeEvent<HTMLTextAreaElement>) => void;
  rows: number;
  className?: string;
  children?: React.ReactNode;
  readOnly?: boolean;
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
}: {
	id: string;
	value: string[];
	onChange: (e: React.ChangeEvent<HTMLTextAreaElement>) => void;
	rows: number;
	className?: string;
	readOnly?: boolean;
}) => {
	const handleNewValue = async (arrays: string[]) => {
		const syntheticEvent = {
			target: {
				id,
				name: id,
				value: arrays,
				// Add other properties that might be accessed
				type: "array",
				checked: false,
				readOnly: false,
			},
			currentTarget: {
				id,
				name: id,
				value: arrays,
				type: "array",
				checked: false,
				readOnly: false,
			},
			// Standard event properties
			bubbles: true,
			cancelable: true,
			defaultPrevented: false,
			preventDefault: () => {},
			stopPropagation: () => {},
			isPropagationStopped: () => false,
			persist: () => {},
			// Type info for TypeScript
			nativeEvent: new Event("input"),
			type: "change",
		} as unknown as React.ChangeEvent<HTMLTextAreaElement>; ;
		onChange(syntheticEvent);
	};

	const handleChange = async (e: React.ChangeEvent<HTMLTextAreaElement>) => {
		const newValue = [...value];
		newValue[parseInt(e.target.id)] = e.target.value;
		handleNewValue(newValue);
	};

	const handleAddArray = () => {
		handleNewValue([...value, " "]);
	};

	const handleRemoveArray = (i: number) => {
		const newValue = [...value];
		newValue.splice(i, 1);
		handleNewValue(newValue);
	};

	const textAreas = useMemo(() => {
		if (value.length > 0)
		return value
		return [""];
	}, [value]);

	return (
		<>
			<div className="flex flex-col gap-2">
				{textAreas.map((v, i) => {
					return (
						<div key={i} className="relative flex">
							<Textarea
								id={i.toString()}
								defaultValue={v}
								onBlur={handleChange}
								rows={rows}
								readOnly={readOnly}
								className={cn("flex w-full bg-white", className)}
							/>
							<div className="absolute top-0 right-0 scale-50 opacity-50 grayscale-100 hover:opacity-100 hover:grayscale-0">
								<DeleteButton onClick={() => handleRemoveArray(i)} />
							</div>
						</div>
					);
				})}
				<Button variant="secondary" onClick={handleAddArray}>
					Add {id}
				</Button>
			</div>
		</>
	);
};
