import { useRef, useState } from "react";
import type { ChangeEvent, FocusEvent, KeyboardEvent } from "react";
import { Button } from "./ui/Button";
import { Input } from "./ui/Input";

interface TagInputProps {
	id: string;
	value: string[];
	onChange: (event: ChangeEvent<HTMLInputElement>) => void;
	className?: string;
}

export const TagInput = ({ id, value, onChange }: TagInputProps) => {
	const [input, setInput] = useState("");
	const inputRef = useRef<HTMLInputElement>(null);
	// Handles keyboard events and blur to add new tags
	const handleInputEvent = (
		event: FocusEvent<HTMLInputElement> | KeyboardEvent<HTMLInputElement>,
	) => {
		// Check if conditions are met to add a tag
		if (
			event.type !== "blur" &&
			(event as KeyboardEvent<HTMLInputElement>).key !== " " &&
			(event as KeyboardEvent<HTMLInputElement>).key !== "," &&
			(event as KeyboardEvent<HTMLInputElement>).key !== "Enter"
		) {
			return;
		}

		// Clean the remaining comma in input
		const cleanedInput = input.replaceAll(",", "").replaceAll(" ", "").trim();
		const values = value.map((v) =>
			v.replaceAll(",", "").replaceAll(" ", "").trim(),
		);
		console.log(cleanedInput, value);
		// Don't add if empty or already exists
		if (
			cleanedInput === "" ||
			cleanedInput.match(/^\s*$/) ||
			values.includes(cleanedInput)
		) {
			setInput("");
			return;
		}

		// Add the new tag
		const newTags = [...values, cleanedInput];

		// Need to create a synthetic event that follows the ChangeEvent interface
		const syntheticEvent = {
			target: {
				id,
				name: id,
				value: newTags,
				// Add other properties that might be accessed
				type: "text",
				checked: false,
			},
			currentTarget: {
				id,
				name: id,
				value: newTags,
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

		// Pass the synthetic event to onChange
		onChange(syntheticEvent);
		setInput("");
		setTimeout(() => {
			inputRef.current?.focus();
		}, 250);
	};

	// Removes a tag at the specified index
	const handleRemoveTag = (idx: number) => {
		const newTags = [...value];
		newTags.splice(idx, 1);

		// Create a proper synthetic event for removal as well
		const syntheticEvent = {
			target: {
				id,
				name: id,
				value: newTags,
				type: "text",
				checked: false,
			},
			currentTarget: {
				id,
				name: id,
				value: newTags,
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

	return (
		<>
			<Input
				key={id}
				ref={inputRef}
				id={id}
				list="tag_suggestion"
				onBlur={handleInputEvent}
				onKeyUp={handleInputEvent}
				autoComplete="off"
				value={input}
				className={"bg-white"}
				onChange={(e) => setInput(e.target.value)}
			/>
			<div className="flex flex-wrap mt-2">
				{value.map((tag, index) => {
					if (tag === "") return null;
					return (
						<span
							key={index}
							className="tag inline-block bg-gray-200 pl-2 pr-1 py-1 text-sm font-semibold text-gray-700 mr-2 mb-2 rounded-sm"
						>
							{tag}{" "}
							<Button
								variant="ghost"
								size="none"
								className="tag-handler text-black no-underline"
								onClick={(e) => {
									e.preventDefault();
									handleRemoveTag(index);
								}}
							>
								⨉
							</Button>
						</span>
					);
				})}
			</div>
		</>
	);
};
