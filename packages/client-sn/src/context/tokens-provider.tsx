import type { Subscription, TokenBalance } from "@dojoengine/torii-client";
import { useAccount } from "@starknet-react/core";
import {
	createContext,
	type PropsWithChildren,
	useContext,
	useEffect,
	useState,
} from "react";
import { addAddressPadding } from "starknet";
import { PROFILE } from "@/dojo/dojoConfig";
import { getToriiClientStarknet } from "@/dojo/torii";

const PERMIT_TOKEN_ADDRESS = PROFILE.contractAddresses.starknet.permit_token;

// Ascending numeric ordering of u256 token ids (delivered as hex strings).
const byTokenId = (a: string, b: string): number => {
	const x = BigInt(a);
	const y = BigInt(b);
	return x < y ? -1 : x > y ? 1 : 0;
};

interface TokensContextValue {
	/** permit_token (ERC-721) ids owned by the connected account, ascending. */
	permitTokenIds: string[];
}

const TokensContext = createContext<TokensContextValue | undefined>(undefined);

/**
 * Owns the single Torii subscription to the connected account's permit_token
 * (ERC-721) balances on the active profile's L2 world. Fetches the current
 * balances, keeps them live (mint/transfer in or out), and serves the owned
 * token ids to any page via {@link useTokensContext}.
 */
export function TokensProvider({ children }: PropsWithChildren) {
	const { address } = useAccount();
	const [permitTokenIds, setPermitTokenIds] = useState<string[]>([]);

	useEffect(() => {
		if (!address) {
			setPermitTokenIds([]);
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

		const publish = () =>
			setPermitTokenIds([...balances.keys()].sort(byTokenId));

		(async () => {
			const client = await getToriiClientStarknet();
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

	return (
		<TokensContext.Provider value={{ permitTokenIds }}>
			{children}
		</TokensContext.Provider>
	);
}

/**
 * Access the tokens served by {@link TokensProvider}. Throws if used outside a
 * `<TokensProvider>`.
 */
export function useTokensContext(): TokensContextValue {
	const ctx = useContext(TokensContext);
	if (ctx === undefined) {
		throw new Error("useTokensContext must be used within a <TokensProvider>");
	}
	return ctx;
}

/**
 * Returns the permit_token (ERC-721) ids owned by the connected account on the
 * active profile's L2 world, ascending. Backed by the single subscription in
 * {@link TokensProvider}; must be used under a `<TokensProvider>`.
 */
export function usePermitTokens(): string[] {
	return useTokensContext().permitTokenIds;
}
