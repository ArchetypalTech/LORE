import { useEffect } from "react";
import { addAddressPadding, BigNumberish } from "starknet";
import { useWalletStore } from "./wallet.store";
import { StoreBuilder } from "../utils/storebuilder";
import { getDojoSdk } from "./dojo.store";
import * as torii from "@dojoengine/torii-client";
import { bigintEquals, bigintToAddress, feltToString, isPositiveBigint } from "../utils/utils";
import { LORE_CONFIG } from "../config";
import { ClauseBuilder, SubscriptionCallbackArgs, ToriiQueryBuilder } from "@dojoengine/sdk";
import { type SchemaType } from "../dojo_bindings/typescript/models.gen";

const SPECIAL_ROLES = new Set(["ROLE_ADMIN", "ROLE_EDITOR", "ROLE_COLLABORATOR", "DEFAULT_ADMIN_ROLE"]);

const {
	get,
	set,
	useStore: useTokenStore,
	createFactory,
} = StoreBuilder({
	ownedGameIds: [] as bigint[],
	ownedTrailIds: [] as bigint[],
	collaboratedTrailIds: [] as bigint[],
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
			collaboratedTrailIds: [],
		});
	},
	playerOwnsGame: (token_id: BigNumberish): boolean => {
		return isPositiveBigint(token_id) ? get().ownedGameIds.includes(BigInt(token_id)) : false;
	},
	playerOwnsTrail: (token_id: BigNumberish): boolean => {
		return isPositiveBigint(token_id) ? get().ownedTrailIds.includes(BigInt(token_id)) : false;
	},
	syncCollaboratedTrails: async (address: string) => {
		try {
			const sdk = getDojoSdk();
			const query = new ToriiQueryBuilder<SchemaType>()
				.withCursor("")
				.withLimit(1000)
				.includeHashedKeys()
				.withClause(
					new ClauseBuilder<SchemaType>().keys(
						["lore-AccessGrantedEvent"],
						[bigintToAddress(address), undefined],
					).build(),
				)
				.withEntityModels(["lore-AccessGrantedEvent"]);
			const result = await sdk.getEventMessages({ query });
			const collaboratedTrailIds = result?.getItems()
				?.filter((item) => item.models?.lore?.AccessGrantedEvent?.granted as boolean)
				?.map((item) => item.models?.lore?.AccessGrantedEvent?.role as BigNumberish)
				?.filter((role) => {
					const s = feltToString(role);
					return !SPECIAL_ROLES.has(s) && s !== "";
				})
				?.map((role) => {
					try { return BigInt(role); } catch { return null; }
				})
				?.filter((id): id is bigint => id !== null && id > 0n) ?? [];
			set({ collaboratedTrailIds });
		} catch (error) {
			console.error("syncCollaboratedTrails() error:", error);
		}
	},
	processTokenBalances: (balances: torii.TokenBalance[]) => {
		// console.log("TokenStore().processTokenBalance() balances:", balances);
		balances.forEach((token) => {
			const tokenId = BigInt(token?.token_id ?? 0);
			if (tokenId > 0 && BigInt(token?.balance ?? 0) > 0) {
				// game tokens
				if (
					bigintEquals(token.contract_address, LORE_CONFIG.contractAddresses.game_token) &&
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
					bigintEquals(token.contract_address, LORE_CONFIG.contractAddresses.trail_token) &&
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
 * Fetches trail IDs the player has been granted collaboration access to.
 * Runs once on wallet connect — player needs to reload if a new grant arrives mid-session.
 * Use only once at a top-level component.
 */
export const useSyncCollaboratedTrails = () => {
	const { walletAddress, isConnected } = useWalletStore();
	useEffect(() => {
		if (isPositiveBigint(walletAddress) && isConnected) {
			TokenStore().syncCollaboratedTrails(bigintToAddress(walletAddress!));
		}
	}, [walletAddress, isConnected]);
};

export const useOwnedTokenIds = () => {
	const { ownedGameIds, ownedTrailIds, collaboratedTrailIds } = useTokenStore();
	return {
		ownedGameIds,
		ownedTrailIds,
		collaboratedTrailIds,
	};
};


export default TokenStore;
export { useTokenStore };
