import type { Subscription, TokenBalance } from "@dojoengine/torii-client";
import { useAccount } from "@starknet-react/core";
import { useEffect, useState } from "react";
import { addAddressPadding } from "starknet";
import { selectedProfileConfig } from "@/dojo/dojoConfig";
import { getToriiClient } from "@/dojo/torii";

const PERMIT_TOKEN_ADDRESS =
	selectedProfileConfig.contractAddresses.permit_token;

// Ascending numeric ordering of u256 token ids (delivered as hex strings).
const byTokenId = (a: string, b: string): number => {
	const x = BigInt(a);
	const y = BigInt(b);
	return x < y ? -1 : x > y ? 1 : 0;
};

/**
 * Fetches the permit_token (ERC-721) ids owned by the connected account on the
 * active profile's L2 world via Torii, then keeps them live with a token-balance
 * subscription (mint/transfer in or out). Returns the owned token ids, ascending.
 */
export function usePermitTokens(): string[] {
	const { address } = useAccount();
	const [tokenIds, setTokenIds] = useState<string[]>([]);

	useEffect(() => {
		if (!address) {
			setTokenIds([]);
			return;
		}

		const account = addAddressPadding(address);

		// token_id -> balance; a token is "owned" while its balance is > 0.
		const balances = new Map<string, bigint>();
		let subscription: Subscription | undefined;
		let cancelled = false;

		const apply = (b: TokenBalance) => {
			if (!b.token_id) return;
			if (BigInt(b.balance) > 0n) balances.set(b.token_id, BigInt(b.balance));
			else balances.delete(b.token_id);
		};

		const publish = () => setTokenIds([...balances.keys()].sort(byTokenId));

		(async () => {
			const client = await getToriiClient();
			if (cancelled) return;

			// Page through the player's current permit balances.
			let cursor: string | undefined;
			do {
				const page = await client.getTokenBalances({
					contract_addresses: [PERMIT_TOKEN_ADDRESS],
					account_addresses: [account],
					token_ids: [],
					pagination: {
						limit: 1000,
						cursor,
						direction: "Forward",
						order_by: [],
					},
				});
				if (cancelled) return;
				page.items.forEach(apply);
				cursor = page.next_cursor;
			} while (cursor);
			publish();

			// Subscribe to subsequent balance changes for this account.
			subscription = await client.onTokenBalanceUpdated(
				[PERMIT_TOKEN_ADDRESS],
				[account],
				undefined,
				(b: TokenBalance) => {
					apply(b);
					publish();
				},
			);
			// Effect may have been torn down while awaiting the subscription.
			if (cancelled) subscription.cancel();
		})();

		return () => {
			cancelled = true;
			subscription?.cancel();
		};
	}, [address]);

	return tokenIds;
}
