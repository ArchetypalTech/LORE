import { useMemo } from "react";
import { cn } from "@/lib/utils/utils";
import { DeleteButton } from "./FormComponents";
import { Button } from "./ui/Button";
import { Textarea } from "./ui/Textarea";

export const MultiTextArea = ({
	id,
	value,
	onChange,
	rows,
	className,
	readOnly,
	disabled,
}: {
	id: string;
	value: string[];
	onChange: (e: React.ChangeEvent<HTMLTextAreaElement>) => void;
	rows: number;
	className?: string;
	readOnly?: boolean;
	disabled?: boolean;
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
				disabled: false,
			},
			currentTarget: {
				id,
				name: id,
				value: arrays,
				type: "array",
				checked: false,
				readOnly: false,
				disabled: false,
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
								disabled={disabled}
								className={cn("flex w-full bg-white", className)}
							/>
							<div className="absolute top-0 right-0 scale-50 opacity-50 grayscale-100 hover:opacity-100 hover:grayscale-0">
								<DeleteButton onClick={() => handleRemoveArray(i)} />
							</div>
						</div>
					);
				})}
			</div>
		</>
	);
};
