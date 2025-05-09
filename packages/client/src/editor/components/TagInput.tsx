import React from "react";
import type { ChangeEvent, FocusEvent, KeyboardEvent } from "react";
import { useState } from "react";
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
	const [tags, setTags] = useState(value);
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
		const values = tags.map((v) =>
			v.replaceAll(",", "").replaceAll(" ", "").trim(),
		);
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
		setTags(newTags);
		setInput("");
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
		setTags(newTags);
	};

	const handleBlur = () => {
		const syntheticEvent = {
			target: {
				id,
				name: id,
				value: tags,
				// Add other properties that might be accessed
				type: "text",
				checked: false,
			},
			currentTarget: {
				id,
				name: id,
				value: tags,
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
	};

	return (
		<React.Fragment key={id}>
			<Input
				key={id}
				id={id}
				list="tag_suggestion"
				onBlur={(e) => {
					handleInputEvent(e);
					handleBlur();
				}}
				onKeyDown={handleInputEvent}
				autoComplete="off"
				value={input}
				className={"bg-white"}
				onChange={(e) => setInput(e.target.value)}
			/>
			<div className="mt-2 flex flex-wrap">
				{tags.map((tag, index) => {
					if (tag === "") return null;
					return (
						<span
							key={tag}
							className="tag mr-2 mb-2 inline-block rounded-sm bg-gray-200 py-1 pl-1 pr-2 font-semibold text-gray-700 text-sm"
						>
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
							{tag}{" "}
						</span>
					);
				})}
			</div>
		</React.Fragment>
	);
};
