import React, { useState } from "react";
import type { ChangeEvent } from "react";
import type { CairoCustomEnum } from "starknet";
import { num, BigNumberish } from "starknet";
import { cn } from "@/lib/utils/utils";
import { useCairoEnum } from "../lib/schemas";
import type { ActionMap, ActionMapForReactable,OptionType } from "../lib/types";
import { MultiTextArea } from "./MultiTextArea";
import { TagInput as Tags } from "./TagInput";
import { Button } from "./ui/Button";
import { Input as UIInput } from "./ui/Input";
import { SelectInput, type SelectInputRef } from "./ui/Select";
import { Textarea as UITextarea } from "./ui/Textarea";

export const Header = ({
	title,
	subtitle,
	children,
}: {
	title: string;
	subtitle: React.ReactNode;
	children?: React.ReactNode;
}) => {
	return (
		<div className="flex flex-row items-center justify-between gap-2">
			<div className="relative flex flex-col">
				<div className="relative text-white">
					<h2 className="">{title}</h2>
					<div className="-left-4.5 -z-1 absolute top-0 h-[100%] w-[calc(100%+1.35rem)] rotate-[.26deg] bg-black pr-4 pl-5" />
					<div className="-left-3.5 absolute top-0 font-white">
						<h2>{">"}</h2>
					</div>
				</div>
				<div>{subtitle}</div>
			</div>
			<div className="grow" />
			{children}
		</div>
	);
};

export const DeleteButton = ({
	onClick,
	className,
}: {
	onClick: () => void;
	className?: string;
}) => {
	return (
		<Button
			size="icon"
			variant="destructive"
			title="Delete Entity"
			className={cn(className)}
			onClick={onClick}
		>
			❌
		</Button>
	);
};

export const PublishButton = ({
	onClick,
	className,
}: {
	onClick: () => void;
	className?: string;
}) => {
	return (
		<Button
			size="icon"
			variant={"hero"}
			title="Publish Entity"
			className={cn(className)}
			onClick={onClick}
		>
			🕊️
		</Button>
	);
};

export const Input = ({
	id,
	value,
	onChange,
	className,
	disabled,
	readOnly,
}: {
	id: string;
	value: string;
	onChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
	className?: string;
	disabled?: boolean;
	readOnly?: boolean;
}) => {
	return (
		<div className="form-group">
			<label htmlFor={id}>{id.replaceAll("_", " ")}</label>
			<UIInput
				id={id}
				defaultValue={value}
				onBlur={onChange}
				onSubmit={onChange}
				autoComplete="off"
				disabled={disabled}
				readOnly={readOnly}
				className={cn("bg-white", className)}
			/>
		</div>
	);
};

export const TagInput = ({
	id,
	value,
	onChange,
	className,
	description,
}: {
	id: string;
	value: string;
	onChange: (event: ChangeEvent<HTMLInputElement>) => void;
	className?: string;
	description?: string;
}) => {
	return (
		<div className="form-group">
			<label htmlFor={id}>{id.replaceAll("_", " ")}</label>
			<p className="mt-1 text-gray-500 text-xs">{description}</p>
			<Tags
				id={id}
				value={value.split(",")}
				onChange={onChange}
				className={className}
			/>
		</div>
	);
};

export const Textarea = ({
	id,
	value,
	onChange,
	rows,
	className,
	children,
}: {
	id: string;
	value: string;
	onChange: (e: React.ChangeEvent<HTMLTextAreaElement>) => void;
	rows: number;
	className?: string;
	children?: React.ReactNode;
}) => {
	return (
		<div className="form-group">
			<label htmlFor={id}>{id.replaceAll("_", " ")}</label>
			<UITextarea
				id={id}
				value={value}
				onChange={onChange}
				rows={rows}
				className={cn("bg-white", className)}
			/>
			{children}
		</div>
	);
};

export const TextAreaArray = ({
	id,
	value,
	rows,
	className,
	children,
	onChange,
	readOnly,
	disabled,
}: {
	id: string;
	value: string[];
	onChange: (e: React.ChangeEvent<HTMLTextAreaElement>) => void;
	rows: number;
	className?: string;
	children?: React.ReactNode;
	readOnly?: boolean;
	disabled?: boolean;
}) => {
	return (
		<div className="form-group">
			<label htmlFor={id}>{id}</label>
			<MultiTextArea
				id={id}
				value={value}
				rows={rows}
				className={className}
				onChange={onChange}
				readOnly={readOnly}
				disabled={disabled}
			/>
			{children}
		</div>
	);
};

export const Select = React.forwardRef<
	SelectInputRef,
	{
		id: string;
		value?: string;
		defaultValue?: string;
		onChange: (e: React.ChangeEvent<HTMLSelectElement>) => void;
		options: Array<{ value: string; label: string }> | OptionType[];
		className?: string;
		disabled?: boolean;
		hideLabel?: boolean;
	}
>(({ id, className, hideLabel = false, ...props }, ref) => {
	return (
		<div className={cn("form-group w-full", className)}>
			{hideLabel ? null : <label htmlFor={id}>{id}</label>}
			<SelectInput ref={ref} id={id} {...props} />
		</div>
	);
});

export const CairoEnumSelect = React.forwardRef<
	{ getValue: () => string | undefined },
	{
		id: string;
		onChange: (e: React.ChangeEvent<HTMLSelectElement>) => void;
		className?: string;
		disabled?: boolean;
		value: CairoCustomEnum;
		enum: unknown[] | readonly unknown[];
		hideLabel?: boolean;
	}
>(({ value: original_value, enum: cairoEnum, ...props }, ref) => {
	const { value, options } = useCairoEnum(original_value, cairoEnum);
	return <Select ref={ref} value={value} {...props} options={options} />;
});

export const Toggle = ({
	id,
	value,
	onChange,
	className,
}: {
	id: string;
	value: boolean;
	onChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
	className?: string;
}) => {
	return (
		<div className="form-group flex items-center">
			<input
				type="checkbox"
				id={id}
				checked={value}
				onChange={onChange}
				className={cn(
					"h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500",
					className,
				)}
			/>
			<label htmlFor={id} className="ml-2 block text-xs ">
				{id.replaceAll("_", " ")}
			</label>
		</div>
	);
};

export const ActionMapInput = <T extends CairoCustomEnum>({
	actionMap,
	handleChange,
	cairoEnum,
	idx,
}: {
	actionMap: ActionMap<T>;
	handleChange: (a: ActionMap<T> | undefined, idx: number) => void;
	cairoEnum: readonly string[];
	idx: number;
}) => {
	const [input, setInput] = useState(actionMap.action as string);
	const [enumValue, setEnumValue] = useState(
		actionMap.action_fn as CairoCustomEnum,
	);
	const [entrypoint, setEntrypoint] = useState(actionMap.entrypoint as BigNumberish);

	const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
		const newValue = e.target.value;
		const newActionMap = {
			...actionMap,
			action: newValue,
		} as ActionMap<T>;
		setInput(newValue);
		return newActionMap;
	};

	const submit = (action: ActionMap<T>) => {
		handleChange(
			{
				action: action.action.trim(),
				inst: action.inst,
				action_fn: action.action_fn,
				entrypoint: action.entrypoint,
			},
			idx,
		);
	};

	const handleCairoEnumChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
		const newValue = e.target.value as unknown as CairoCustomEnum;
		const newActionMap = {
			...actionMap,
			action_fn: newValue,
		} as ActionMap<T>;
		setEnumValue(newValue);
		return newActionMap;
	};

	const handleEntrypointChange = (e: React.ChangeEvent<HTMLInputElement>) => {
		const newValue = e.target.value;
		const newActionMap = {
			...actionMap,
			entrypoint: newValue,
		} as ActionMap<T>;
		setEntrypoint(newValue);
		return newActionMap;
	};

	return (
		<div key={actionMap.action} className="grid md:grid-cols-[1fr_2fr_auto] grid-rows-3 md:grid-rows-none items-center gap-1">
			<UIInput
				id={actionMap.action}
				value={input}
				onBlur={(e) => {
					let a = handleInputChange(e);
					submit(a);
				}}
				onChange={handleInputChange}
				className="bg-white col-span-1 border-solid"
			/>
			<div className="flex flex-row gap-1">
				<CairoEnumSelect
					id={actionMap.action}
					value={enumValue}
					onChange={(e) => {
						let a = handleCairoEnumChange(e);
						submit(a);
					}}
					enum={cairoEnum}
					className="bg-white rounded-md flex-[0.3] min-w-[12rem]"
					hideLabel={true}
				/>
				<UIInput
					id={actionMap.entrypoint}
					value={entrypoint}
					onChange={(e) => {
						let a = handleEntrypointChange(e);
						submit(a);
					}}
					className="bg-white col-span-1 border-solid flex-1"
				/>
			</div>
				<DeleteButton
					className="text-xs"
					onClick={() => handleChange(undefined, idx)}
				/>
		</div>
	);
};

// Standar Action Map Editor
export const ActionMapEditor = <T extends CairoCustomEnum>({
	id,
	value,
	onChange,
	cairoEnum,
}: {
	id: string;
	value: ActionMap<T>[];
	onChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
	className?: string;
	cairoEnum: readonly string[];
}) => {
	const handleChange = (a: ActionMap<T> | undefined, idx: number) => {
		const newActionMap = [...value];
		if (a === undefined) {
			newActionMap.splice(idx, 1);
		} else {
			newActionMap[idx] = a;
		}
		console.log(newActionMap, a);
		sendEvent(newActionMap);
	};

	const sendEvent = (actionMaps: ActionMap<T>[]) => {
		const syntheticEvent = {
			target: {
				id,
				name: id,
				value: actionMaps,
				type: "text",
				checked: false,
			},
			currentTarget: {
				id,
				name: id,
				value: actionMaps,
				type: "text",
				checked: false,
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

	const addNewMap = () => {
		const newActionMap = [...value];
		newActionMap.push({
			action: "",
			inst: 0,
			action_fn: cairoEnum[0],
			entrypoint: 0,
		});
		sendEvent(newActionMap);
	};

	return (
		<div
			id={id}
			className="flex flex-col gap-1 bg-[#E5E7EB] p-1 rounded-md shadow-xs border-gray-300 border"
		>
			<div className="text-xs opacity-50 font-medium px-1">actions</div>
			{value?.map((actionMap, idx) => {
				const id = idx.toString();
				return (
					<ActionMapInput
						key={actionMap.action + id}
						actionMap={actionMap}
						handleChange={handleChange}
						cairoEnum={cairoEnum}
						idx={idx}
					/>
				);
			})}
			<Button variant="secondary" onClick={addNewMap}>
				Add Action Map
			</Button>
		</div>
	);
};

// Reactable Action Map Editor
export const ReactableActionMapEditor = <T extends CairoCustomEnum>({
	id,
	value,
	onChange,
	cairoEnum,
}: {
	id: string;
	value: ActionMapForReactable<T>[];
	onChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
	className?: string;
	cairoEnum: readonly string[];
}) => {
	const handleChange = (a: ActionMapForReactable<T> | undefined, idx: number) => {
		const newActionMap = [...value];
		if (a === undefined) {
			newActionMap.splice(idx, 1);
		} else {
			newActionMap[idx] = a;
		}
		sendEvent(newActionMap);
	};

	const sendEvent = (actionMaps: ActionMapForReactable<T>[]) => {
		const syntheticEvent = {
			target: {
				id,
				name: id,
				value: actionMaps,
				type: "text",
				checked: false,
			},
			currentTarget: {
				id,
				name: id,
				value: actionMaps,
				type: "text",
				checked: false,
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

	const addNewMap = () => {
		const newActionMap = [...value];
		newActionMap.push({
			action: "",
			inst: 0,
			action_fn: cairoEnum[0],
			entrypoints: [0, 0],
		});
		sendEvent(newActionMap);
	};

	return (
		<div
			id={id}
			className="flex flex-col gap-2 bg-[#E5E7EB] p-2 rounded-md shadow-xs border-gray-300 border"
		>
			<div className="text-xs opacity-50 font-medium px-1">Actions</div>

			{/* Header Row */}
			<div className="hidden md:grid md:grid-cols-[1fr_2fr_auto] grid-rows-1 text-xs font-semibold text-gray-600 px-1">
				<div className="col-span-1">Action</div>
				<div className="flex gap-1 col-span-1">
					<span className="flex-[0.3] min-w-[12rem]">Type</span>
					<span className="flex-1">Idx 1</span>
					<span className="flex-1">Idx 2</span>
				</div>
				<div className="text-right">Remove</div>
			</div>

			{value?.map((actionMap, idx) => (
				<ActionMapReactableInput
					key={`${actionMap.action}-${idx}`}
					actionMap={actionMap}
					handleChange={handleChange}
					cairoEnum={cairoEnum}
					idx={idx}
				/>
			))}

			<Button variant="secondary" onClick={addNewMap}>
				Add Action Map
			</Button>
		</div>
	);
};

// Reactable Map Input
export const ActionMapReactableInput = <T extends CairoCustomEnum>({
	actionMap,
	handleChange,
	cairoEnum,
	idx,
}: {
	actionMap: ActionMapForReactable<T>;
	handleChange: (a: ActionMapForReactable<T> | undefined, idx: number) => void;
	cairoEnum: readonly string[];
	idx: number;
}) => {
	const [input, setInput] = useState(actionMap.action);
	const [enumValue, setEnumValue] = useState(actionMap.action_fn);
	const [entrypoint, setEntrypoint] = useState<[BigNumberish, BigNumberish]>(
		actionMap.entrypoints
	);

	const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
		const newValue = e.target.value;
		const newActionMap: ActionMapForReactable<T> = {
			...actionMap,
			action: newValue,
		};
		setInput(newValue);
		return newActionMap;
	};

	const submit = (action: ActionMapForReactable<T>) => {
		handleChange(
			{
				action: action.action.trim(),
				inst: action.inst,
				action_fn: action.action_fn,
				entrypoints: action.entrypoints,
			},
			idx
		);
	};

	const handleCairoEnumChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
		const newValue = e.target.value as unknown as CairoCustomEnum;
		const newActionMap: ActionMapForReactable<T> = {
			...actionMap,
			action_fn: newValue,
		};
		setEnumValue(newValue);
		return newActionMap;
	};

	const handleEntrypointChange = (
		i: 0 | 1,
		e: React.ChangeEvent<HTMLInputElement>
	) => {
		const newValue = e.target.value;
		const updated: [BigNumberish, BigNumberish] = [...entrypoint];
		updated[i] = newValue;
		const newActionMap: ActionMapForReactable<T> = {
			...actionMap,
			entrypoints: updated,
		};
		setEntrypoint(updated);
		return newActionMap;
	};

	return (
		<div className="grid md:grid-cols-[1fr_2fr_auto] grid-rows-3 md:grid-rows-none items-center gap-1 px-1">
			<UIInput
				id={`input-${idx}`}
				value={input}
				onBlur={(e) => {
					let a = handleInputChange(e);
					submit(a);
				}}
				onChange={handleInputChange}
				className="bg-white border-solid"
			/>
			<div className="flex flex-row gap-1">
				<CairoEnumSelect
					id={`enum-${idx}`}
					value={enumValue}
					onChange={(e) => {
						let a = handleCairoEnumChange(e);
						submit(a);
					}}
					enum={cairoEnum}
					className="bg-white rounded-md flex-[0.3] min-w-[12rem]"
					hideLabel={true}
				/>
				<UIInput
					id={`entry-0-${idx}`}
					value={entrypoint[0].toString()}
					onChange={(e) => {
						let a = handleEntrypointChange(0, e);
						submit(a);
					}}
					className="bg-white border-solid flex-1"
					placeholder="Idx 1"
				/>
				<UIInput
					id={`entry-1-${idx}`}
					value={entrypoint[1].toString()}
					onChange={(e) => {
						let a = handleEntrypointChange(1, e);
						submit(a);
					}}
					className="bg-white border-solid flex-1"
					placeholder="Idx 2"
				/>
			</div>
			<DeleteButton
				className="text-xs justify-self-end"
				onClick={() => handleChange(undefined, idx)}
			/>
		</div>
	);
};

export function encodeToFelt(value: string): BigNumberish {
    if (value === "true") return 1n;
    if (value === "false") return 0n;
    if (!isNaN(Number(value))) return BigInt(value);
    const truncated = value.slice(0, 31);
    return [...truncated]
      .map((char) => char.charCodeAt(0))
      .reduce((acc, curr) => (acc << 8n) + BigInt(curr), 0n);
}

export function decodeFromFelt(felt: BigNumberish): string {
  if (typeof felt === "string" && felt.startsWith("0x")) {
    return felt;
  }

  const num = BigInt(felt);

  if (num === 1n) return "true";
  if (num === 0n) return "false";

  const hex = num.toString(16).padStart(2, "0");
  const bytes: number[] = [];
  for (let i = 0; i < hex.length; i += 2) {
    bytes.push(parseInt(hex.slice(i, i + 2), 16));
  }

  const isPrintable = bytes.every((b) => b >= 32 && b <= 126);

  // Heuristic: decode only if it’s likely a packed string (e.g., at least 2 printable chars)
  if (isPrintable && bytes.length >= 2) {
    return String.fromCharCode(...bytes);
  }

  // If not printable or too short, return number string
  return "0x" + num.toString(16);
}

export const formatKeyAsDecimal = (key: string | BigNumberish): string => {
  const bigIntKey = num.toBigInt(key); // this handles strings, numbers, BigInt, etc.
  const decimalStr = bigIntKey.toString();
  return decimalStr.padStart(16, "0");
};