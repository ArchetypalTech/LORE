import { useEffect } from "react";
import { addAddressPadding, BigNumberish } from "starknet";
import { useWalletStore } from "./wallet.store";
import { StoreBuilder } from "../utils/storebuilder";
import { getDojoSdk } from "./dojo.store";
import * as torii from "@dojoengine/torii-client";
import { bigintEquals, isPositiveBigint } from "../utils/utils";
import { LORE_CONFIG } from "../config";
import { SubscriptionCallbackArgs } from "@dojoengine/sdk";

const {
	get,
	set,
	useStore: useTokenStore,
	createFactory,
} = StoreBuilder({
	ownedGameIds: [] as bigint[],
	ownedTrailIds: [] as bigint[],
});

/**
 * Factory function that returns all terminal store state and methods.
 * Can be used to access the terminal store outside of React components.
 * @returns {Object} The terminal store state and methods
 */
const TokenStore = createFactory({
	resetStore: () => {
		set({
			ownedGameIds: [],
			ownedTrailIds: [],
		});
	},
	playerOwnsGame: (token_id: BigNumberish): boolean => {
		return isPositiveBigint(token_id) ? get().ownedGameIds.includes(BigInt(token_id)) : false;
	},
	playerOwnsTrail: (token_id: BigNumberish): boolean => {
		return isPositiveBigint(token_id) ? get().ownedTrailIds.includes(BigInt(token_id)) : false;
	},
	processTokenBalances: (balances: torii.TokenBalance[]) => {
		// console.log("TokenStore().processTokenBalance() balances:", balances);
		balances.forEach((token) => {
			const tokenId = BigInt(token?.token_id ?? 0);
			if (tokenId > 0 && BigInt(token?.balance ?? 0) > 0) {
				// game tokens
				if (
					bigintEquals(token.contract_address, LORE_CONFIG.manifests.game_token.address) &&
					!get().ownedGameIds.includes(tokenId)
				) {
					set({
						ownedGameIds: [
							...get().ownedGameIds,
							BigInt(token.token_id ?? 0)],
					});
				}
				// trail tokens
				if (
					bigintEquals(token.contract_address, LORE_CONFIG.manifests.trail_token.address) &&
					!get().ownedTrailIds.includes(tokenId)
				) {
					set({
						ownedTrailIds: [
							...get().ownedTrailIds,
							BigInt(token.token_id ?? 0)],
					});
				}
			}
		});
	},
});


/**
 * Keeps the player owned token ids in sync
 * use only once at a top-level component.
 */
export const useSyncOwnedTokenIds = () => {
	const { walletAddress, isConnected } = useWalletStore();
	const { ownedGameIds, ownedTrailIds } = useTokenStore();

	useEffect(() => {
		let _sub: torii.Subscription | undefined = undefined;
		const _fetch = async (address: BigNumberish) => {
			TokenStore().resetStore();
			// 
			// get current tokens and subscribe to changes
			const sdk = getDojoSdk();
			const [balances, sub] = await sdk.subscribeTokenBalance({
				accountAddresses: [addAddressPadding(address)],
				callback: ({
					data,
					error,
				}: SubscriptionCallbackArgs<torii.TokenBalance>) => {
					if (error) {
						console.error(`useSyncOwnedTokenIds() SUB error:`, error);
					} else {
						console.log("useSyncOwnedTokenIds() SUB balances:", data);
						TokenStore().processTokenBalances([data]);
					}
				},
			});
			// update store with current balances
			console.log("useSyncOwnedTokenIds() current balances:", balances);
			TokenStore().processTokenBalances(balances.items);
			// keep sub pointer
			_sub = sub;
		}
		// fetch the player token balances
		if ( isPositiveBigint(walletAddress) && isConnected) {
			_fetch(walletAddress ?? 0);
		}
		// unsubscribe from changes when unmounted
		return () => {
			_sub?.cancel();
		};
	}, [walletAddress, isConnected]);

	useEffect(() => {
		console.log("useSyncOwnedTokenIds() ownedGameIds:", ownedGameIds);
		console.log("useSyncOwnedTokenIds() ownedTrailIds:", ownedTrailIds);
	}, [ownedGameIds, ownedTrailIds]);

	return {
		ownedGameIds,
		ownedTrailIds,
	};
};

/**
 * Returns the current game id.
 * @returns {number | undefined} The current game id
 */
export const useOwnedTokenIds = () => {
	const { ownedGameIds, ownedTrailIds } = useTokenStore();
	return {
		ownedGameIds,
		ownedTrailIds,
	};
};


export default TokenStore;
export { useTokenStore };
