import type {
	Clause,
	Entity,
	KeysClause,
	Subscription,
} from "@dojoengine/torii-client";
import { useEffect, useState } from "react";
import { PROFILE } from "@/dojo/dojoConfig";
import { getToriiClientStarknet } from "@/dojo/torii";
import { bigintToHex } from "@/lib/utils";

const MODEL_TAG = `${PROFILE.namespace.starknet}-PermitTokenInfo`;

// Normalize any token/permit id (hex or decimal) to a decimal string so the
// fetched models can be looked up by the same key the caller holds.
const toKey = (id: string): string => BigInt(id).toString();

/**
 * Fetches the `PermitTokenInfo` model from Torii for each owned token id and
 * keeps it live via an entity subscription. Returns a map of permit id
 * (decimal string) → `is_used`.
 */
export function usePermitTokenInfos(tokenIds: string[]): Map<string, boolean> {
	const [infos, setInfos] = useState<Map<string, boolean>>(new Map());
	// Stable dependency: re-run only when the owned set actually changes.
	const key = tokenIds.join(",");

	useEffect(() => {
		const ids = key ? key.split(",") : [];
		if (ids.length === 0) {
			setInfos(new Map());
			return;
		}

		// permit id (decimal) -> is_used.
		const used = new Map<string, boolean>();
		let subscription: Subscription | undefined;
		let cancelled = false;

		// Match PermitTokenInfo for any of the owned permit ids (its single key).
		const clause: Clause = {
			Composite: {
				operator: "Or",
				clauses: ids.map(
					(id): Clause => ({
						Keys: {
							keys: [bigintToHex(BigInt(id))],
							pattern_matching: "FixedLen",
							models: [MODEL_TAG],
						} satisfies KeysClause,
					}),
				),
			},
		};

		const apply = (entity: Entity) => {
			const model = entity.models[MODEL_TAG];
			if (!model?.permit_id) return;
			used.set(
				toKey(String(model.permit_id.value)),
				Boolean(model.is_used?.value),
			);
		};

		const publish = () => setInfos(new Map(used));

		(async () => {
			const client = await getToriiClientStarknet();
			if (cancelled) return;

			let cursor: string | undefined;
			do {
				const page = await client.getEntities({
					world_addresses: [],
					pagination: {
						limit: 1000,
						cursor,
						direction: "Forward",
						order_by: [],
					},
					clause,
					no_hashed_keys: false,
					models: [MODEL_TAG],
					historical: false,
				});
				if (cancelled) return;
				page.items.forEach(apply);
				cursor = page.next_cursor;
			} while (cursor);
			publish();

			// Keep is_used live (e.g. a permit being consumed flips it to true).
			subscription = await client.onEntityUpdated(
				clause,
				undefined,
				(entity: Entity) => {
					apply(entity);
					publish();
				},
			);
			if (cancelled) subscription.cancel();
		})();

		return () => {
			cancelled = true;
			subscription?.cancel();
		};
	}, [key]);

	return infos;
}
