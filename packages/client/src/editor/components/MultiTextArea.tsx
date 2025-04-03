import { cn } from "@/lib/utils/utils";
import type { ChangeEvent } from "react";
import { DeleteButton } from "./FormComponents";

export const MultiTextArea = ({
	id,
	value,
	onChange,
	rows,
	className,
}: {
	id: string;
	value: string[];
	onChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
	rows: number;
	className?: string;
}) => {
	const handleNewValue = async (arrays: string[]) => {
		const syntheticEvent = {
			target: {
				id,
				name: id,
				value: arrays,
				// Add other properties that might be accessed
				type: "text",
				checked: false,
			},
			currentTarget: {
				id,
				name: id,
				value: arrays,
				type: "text",
				checked: false,
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
		} as unknown as ChangeEvent<HTMLInputElement>;
		onChange(syntheticEvent);
	};

	const handleChange = async (e: React.ChangeEvent<HTMLTextAreaElement>) => {
		const newValue = [...value];
		newValue[parseInt(e.target.id)] = e.target.value;
		console.log(e);
		handleNewValue(newValue);
	};

	const handleAddArray = () => {
		handleNewValue([...value, ""]);
	};

	const handleRemoveArray = (i: number) => {
		const newValue = [...value];
		newValue.splice(i, 1);
		handleNewValue(newValue);
	};

	return (
		<>
			<div className="flex flex-col gap-2">
				{value.map((v, i) => {
					return (
						<div key={i} className="flex relative">
							<textarea
								id={i.toString()}
								value={v}
								onChange={handleChange}
								rows={rows}
								className={cn("flex w-full", className)}
							/>
							<div className="absolute top-0 right-0 scale-50">
								<DeleteButton onClick={() => handleRemoveArray(i)} />
							</div>
						</div>
					);
				})}
				<button className="btn btn-success btn-sm" onClick={handleAddArray}>
					Add {id}
				</button>
			</div>
		</>
	);
};
