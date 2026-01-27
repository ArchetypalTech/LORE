import type { Entity } from "@/lib/dojo_bindings/typescript/models.gen";
import { Input, TagInput, TextAreaArray, formatKeyAsDecimal, } from "../FormComponents";
import type { ComponentInspector } from "./useInspector";
import { useInspector } from "./useInspector";
import { num } from "starknet";

export const EntityInspector: ComponentInspector<Entity> = ({
	componentObject,
	...props
}) => {
	const { handleInputChange, Inspector } = useInspector<Entity>({
		componentObject,
		...props,
		inputHandlers: {
			name: (e, updatedObject) => {
				updatedObject.name = e.target.value;
			},
			inst: (e, updatedObject) => {
				updatedObject.inst = e.target.value;
			},
			creator_address: (e, updatedObject) => {
				updatedObject.creator_address = e.target.value;
			},
			alt_names: (e, updatedObject) => {
				updatedObject.alt_names = (
					e.target.value as unknown as string[]
				).filter((x) => x !== "");
			},
			actions_keys: (e, updatedObject) => {
				updatedObject.actions_keys = (
					e.target.value as unknown as string[]
				).filter((x) => x !== "");
			},
		},
	});

	if (!componentObject) return <div>Entity not found</div>;

	return (
		<Inspector>
			<Input
				id="name"
				value={componentObject.name}
				onChange={handleInputChange(undefined)}
			/>
			<Input
				id="inst"
				value={componentObject.inst.toString()}
				onChange={handleInputChange(undefined)}
				readOnly={true}
			/>
			<Input
				id="creator_address"
				value={componentObject.creator_address?.toString() ?? "0x0"}
				onChange={handleInputChange(undefined)}
				readOnly={true}
			/>
			<TagInput
				id="alt_names"
				value={componentObject.alt_names?.join(",") || ""}
				onChange={handleInputChange(undefined)}
			/>
			<TextAreaArray
				id="actions_keys"
				disabled={true}
				rows={1}
				value={componentObject.actions_keys.filter((v) => v !== num.toBigInt(0)).map((v) => formatKeyAsDecimal(v))}
				onChange={handleInputChange(undefined)}
				readOnly={true}
			/>
		</Inspector>
	);
};
