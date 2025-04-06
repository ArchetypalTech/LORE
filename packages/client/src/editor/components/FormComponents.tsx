import { cn } from "@/lib/utils/utils";
import { TagInput as Tags } from "./TagInput";
import type { ChangeEvent } from "react";
import { MultiTextArea } from "./MultiTextArea";
import React from "react";
import type { OptionType } from "../lib/types";
import { useCairoEnum } from "../lib/schemas";
import type { CairoCustomEnum } from "starknet";
import { Button } from "./ui/Button";
import { SelectInput } from "./ui/Select";
import { Input as UIInput } from "./ui/Input";

export const Header = ({
	title,
	subtitle,
	children,
	onClickTitle,
}: {
	title: string;
	subtitle: React.ReactNode;
	children?: React.ReactNode;
	onClickTitle?: () => void;
}) => {
	return (
		<div className="flex justify-between flex-row gap-2 items-center">
			<div className="flex flex-col">
				<h2>{title}</h2>
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
}: { onClick: () => void; className?: string }) => {
	return (
		<Button
			size="icon"
			variant="destructive"
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
}: { onClick: () => void; className?: string }) => {
	return (
		<Button
			size="icon"
			variant={"hero"}
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
			<p className="mt-1 text-xs text-gray-500">{description}</p>
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
			<textarea
				id={id}
				value={value}
				onChange={onChange}
				rows={rows}
				autoComplete="off"
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
}: {
	id: string;
	value: string[];
	onChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
	rows: number;
	className?: string;
	children?: React.ReactNode;
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
			/>
			{children}
		</div>
	);
};

export const Select = React.forwardRef<
	{ getValue: () => string | undefined },
	{
		id: string;
		value?: string;
		defaultValue?: string;
		onChange: (e: React.ChangeEvent<HTMLSelectElement> | string) => void;
		options: Array<{ value: string; label: string }> | OptionType[];
		className?: string;
		disabled?: boolean;
	}
>(({ id, className, ...props }, ref) => {
	return (
		<div className={cn("form-group w-full", className)}>
			<label htmlFor={id}>{id}</label>
			<SelectInput ref={ref} id={id} {...props} />
		</div>
	);
});

export const CairoEnumSelect = React.forwardRef<
	{ getValue: () => string | undefined },
	{
		id: string;
		onChange: (e: React.ChangeEvent<HTMLSelectElement> | string) => void;
		className?: string;
		disabled?: boolean;
		value: CairoCustomEnum;
		enum: unknown[] | readonly unknown[];
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
