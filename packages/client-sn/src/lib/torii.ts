import type { Entity } from "@dojoengine/torii-client";

// One model's data as it arrives inside an `Entity` / event message.
export type ModelData = Entity["models"][string];

// A model's contribution to its store: the key it's indexed by and its value.
export type Parse<T> = (model: ModelData) => [key: string, value: T] | undefined;

export interface ModelDef<T> {
	/** Store name — must match a field in the provider's typed model view. */
	store: string;
	/** Namespaced Dojo model tag. */
	tag: string;
	/** Turns a model into a `[key, value]` entry for its store. */
	parse: Parse<T>;
}

/** Live store maps, keyed by `ModelDef.store`. */
export type Stores = Record<string, Map<string, unknown>>;

/** A fresh, empty store map for every model in `models`. */
export const emptyStores = (models: readonly ModelDef<unknown>[]): Stores => {
	const stores: Stores = {};
	for (const m of models) stores[m.store] = new Map();
	return stores;
};

/** Namespaced Dojo model tag, e.g. `tag("lore_sn", "PermitTokenInfo")`. */
export const tag = (namespace: string, name: string): string =>
	`${namespace}-${name}`;

// A Dojo `Array<felt252>` field arrives as a Ty whose `value` is an array of
// primitive Tys; flatten it to the felt strings.
const parseFeltArray = (field: ModelData[string] | undefined): string[] =>
	Array.isArray(field?.value)
		? (field.value as { value: unknown }[]).map((item) => String(item.value))
		: [];

// ── Model parsers ─────────────────────────────────────────────────────────
// Pure, chain-agnostic functions that turn a raw model into a store entry.

/** Reward sent from L3 → L2. Emitted on the appchain world. */
export type AppchainMessageEvent = {
	uuid: number;
	callerAddress: string;
	fromAddress: string;
	toAddress: string;
	blockNumber: number;
	blockTimestamp: number;
	messageHash: string;
	messageType: string;
	/** Raw `Array<felt252>` payload, as decimal/hex felt strings — what
	 * `consume_message` on the L2 permit token expects back verbatim. */
	payload: string[];
};

// AppchainMessageEvent: keyed by uuid (decimal string) → the parsed event.
export const parseAppchainMessageEvent: Parse<AppchainMessageEvent> = (
	model,
) => {
	if (model?.uuid == null) return undefined;
	const uuid = Number(model.uuid.value);
	return [
		String(uuid),
		{
			uuid,
			callerAddress: String(model.caller_address?.value ?? ""),
			fromAddress: String(model.from_address?.value ?? ""),
			toAddress: String(model.to_address?.value ?? ""),
			blockNumber: Number(model.block_number?.value ?? 0),
			blockTimestamp: Number(model.block_timestamp?.value ?? 0),
			messageHash: String(model.message_hash?.value ?? ""),
			messageType: String(model.message_type?.value ?? ""),
			payload: parseFeltArray(model.payload),
		},
	];
};

/** Reward consumed on L2. Emitted on the Starknet world. */
export type MessageConsumedEvent = {
	uuid: number;
	blockNumber: number;
	blockTimestamp: number;
	messageHash: string;
	/** Token ids minted by consuming the message, as decimal felt strings. */
	tokenIds: string[];
};

// MessageConsumedEvent: keyed by uuid (decimal string) → the parsed event.
export const parseMessageConsumedEvent: Parse<MessageConsumedEvent> = (
	model,
) => {
	if (model?.uuid == null) return undefined;
	const uuid = Number(model.uuid.value);
	return [
		String(uuid),
		{
			uuid,
			blockNumber: Number(model.block_number?.value ?? 0),
			blockTimestamp: Number(model.block_timestamp?.value ?? 0),
			messageHash: String(model.message_hash?.value ?? ""),
			tokenIds: parseFeltArray(model.token_ids),
		},
	];
};

// PermitTokenInfo: keyed by permit id (decimal string) → is_used.
export const parsePermitTokenInfo: Parse<boolean> = (model) => {
	if (!model?.permit_id) return undefined;
	return [
		BigInt(String(model.permit_id.value)).toString(),
		Boolean(model.is_used?.value),
	];
};
