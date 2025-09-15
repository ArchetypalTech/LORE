import { useEffect } from "react";
import { addAddressPadding, BigNumberish, num } from "starknet";
import { ClauseBuilder, StandardizedQueryResult, ToriiQueryBuilder } from "@dojoengine/sdk";
import { useWalletStore } from "./wallet.store";
import { sendCommand } from "../terminalCommands/commandHandler";
import { StoreBuilder } from "../utils/storebuilder";
import { InitDojo } from "../dojo";
import type { SchemaType } from "../dojo_bindings/typescript/models.gen";
import * as torii from "@dojoengine/torii-client";

const {
	get,
	set,
	useStore: useGameStore,
	createFactory,
} = StoreBuilder({
	// gameId specifically used in the terminal (0 for editor)
	editorGameId: undefined as bigint | undefined,
	// gameId attached to a player on-chain
	playerGameId: undefined as bigint | undefined,
	// resolved gameId to be used
	gameId: undefined as bigint | undefined,
});

/**
 * Factory function that returns all terminal store state and methods.
 * Can be used to access the terminal store outside of React components.
 * @returns {Object} The terminal store state and methods
 */
const GameStore = createFactory({
	setEditorGameId: (gameId: BigNumberish | undefined) => {
		let editorGameId = gameId ? num.toBigInt(gameId) : undefined;
		const isCurrent = (editorGameId !== undefined)
		set({ editorGameId });
		if (isCurrent) {
			set({ gameId: editorGameId });
		}
		console.log("GameStore.setEditorGameId:", gameId, isCurrent?"(CURRENT)":"");
	},
	setPlayerGameId: (gameId: BigNumberish | undefined) => {
		let playerGameId = gameId ? num.toBigInt(gameId) : undefined;
		const isCurrent = (playerGameId !== undefined && get().editorGameId === undefined)
		set({ playerGameId });
		if (isCurrent) {
			set({ gameId: playerGameId });
		}
		console.log("GameStore.setPlayerGameId:", gameId, isCurrent?"(CURRENT)":"");
	},
});

export const useSyncGameId = (inputGameId?: BigNumberish) => {
	const { gameId } = useGameStore();

	// set the editor game id, if provided
	useEffect(() => {
		GameStore().setEditorGameId(inputGameId == undefined ? undefined : num.toBigInt(inputGameId.toString()));
	}, [inputGameId]);

	// use game_id for the connected player
	const { walletAddress, isConnected } = useWalletStore();
	useEffect(() => {
		let _subscription: torii.Subscription | undefined;
		const _fetch = async (address: bigint) => {

			const builder = new ToriiQueryBuilder<SchemaType>();
			const query = builder
				.withCursor("")
				.withLimit(1)
				.includeHashedKeys()
				.withClause(
					new ClauseBuilder<SchemaType>().keys(
						["lore-PlayerAccount"],
						[addAddressPadding(address)]
					).build()
				)
				.withEntityModels(["lore-PlayerAccount"]);

			try {
				const { sub } = await InitDojo();
				const [initialEntities, subscription] = await sub((response: {
					data?: StandardizedQueryResult<SchemaType> | undefined;
					error?: Error;
				}) => {
					if (response.error) {
						console.error("useSyncGameId() sync error:", response.error);
						return;
					}
					for (const responseData of response?.data || []) {
						GameStore().setPlayerGameId(responseData.models?.lore?.PlayerAccount?.current_game_id);
						sendCommand("_current_game");
					}
				}, query);
				// store the subscription to cancel when unmounted
				_subscription = subscription;
				// store the player game id
				GameStore().setPlayerGameId(initialEntities?.getItems()[0]?.models?.lore?.PlayerAccount?.current_game_id);
			} catch (e) {
				// const status = {
				// 	status: "error",
				// 	error: (e as Error).message || "SYNC FAILURE",
				// } as DojoStatus;
				// setStatus(status);
				// sendCommand(`_fatal_error ${status.error}`);
				console.error("useSyncGameId() error for wallet:", walletAddress, e);
			}

		}
		// fetch the player game id
		const address = BigInt(walletAddress || 0);
		if (address != 0n && isConnected) {
			_fetch(address);
		}
		return () => {
			_subscription?.cancel();
		}
	}, [walletAddress, isConnected]);

	// return the current game id
	return gameId;
};


/**
 * Factory function that returns all terminal store state and methods.
 * Can be used to access the terminal store outside of React components.
 * @returns {Object} The terminal store state and methods
 */
export const useCurrentGameId = () => {
	const { gameId } = useGameStore();
	return gameId;
};


export default GameStore;
export { useGameStore };
