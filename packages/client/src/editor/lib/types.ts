import type { BigNumberish } from "starknet";
import type { EditorCollection } from "./schemas";

export interface OptionType {
	value: string;
	label: string;
	disabled?: boolean;
}

export type EditorAction = "update" | "delete";
export type ChangeSet = {
	type: EditorAction;
	object: EditorCollection;
	inst: BigNumberish;
};
