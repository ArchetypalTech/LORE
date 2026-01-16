import { useEffect } from "react";
import { addAddressPadding, BigNumberish } from "starknet";
import { ClauseBuilder, ToriiQueryBuilder } from "@dojoengine/sdk";
import { useWalletStore } from "./wallet.store";
import { sendCommand } from "../terminalCommands/commandHandler";
import { StoreBuilder } from "../utils/storebuilder";
import { getDojoSdk } from "./dojo.store";
import type { SchemaType, PlayerGame } from "../dojo_bindings/typescript/models.gen";
import { useMounted } from "../utils/useMounted";

const {
	get,
	set,
	useStore: useGameStore,
	createFactory,
} = StoreBuilder({
	// gameId specifically used in the terminal (0 for editor)
	editorGameId: undefined as number | undefined,
	// gameId attached to a player on-chain
	playerGameId: undefined as number | undefined,
	// resolved gameId to be used
	gameId: undefined as number | undefined,
});

/**
 * Factory function that returns all terminal store state and methods.
 * Can be used to access the terminal store outside of React components.
 * @returns {Object} The terminal store state and methods
 */
const GameStore = createFactory({
	setEditorGameId: (gameId: BigNumberish | undefined) => {
		const isCurrent = (gameId !== undefined)
		let editorGameId = (isCurrent ? Number(BigInt(gameId)) : undefined);
		set({ editorGameId });
		if (isCurrent) {
			set({ gameId: editorGameId });
		}
		console.log("GameStore.setEditorGameId:", gameId, isCurrent?"(CURRENT)":"");
	},
	setPlayerGameId: (gameId: BigNumberish | undefined) => {
		let playerGameId = (gameId ? Number(BigInt(gameId)) : undefined);
		const isCurrent = (playerGameId !== undefined && get().editorGameId === undefined)
		set({ playerGameId });
		if (isCurrent) {
			set({ gameId: playerGameId });
		}
		console.log("GameStore.setPlayerGameId:", gameId, isCurrent?"(CURRENT)":"");
	},
});


/**
 * Keeps the game id in sync with the player account.
 * use only once at a top-level component.
 */
export const useSyncGameId = (inputGameId?: BigNumberish) => {
	const { gameId } = useGameStore();
	const mounted = useMounted();

	// set the editor game id, if provided
	useEffect(() => {
		GameStore().setEditorGameId(inputGameId == undefined ? undefined : inputGameId);
	}, [inputGameId]);

	// use game_id for the connected player
	const { walletAddress, isConnected } = useWalletStore();
	useEffect(() => {
		const _fetch = async (address: BigNumberish) => {
			const builder = new ToriiQueryBuilder<SchemaType>();
			const query = builder
				.withCursor("")
				.withLimit(1)
				.includeHashedKeys()
				.withClause(
					new ClauseBuilder<SchemaType>().keys(
						["lore-PlayerGame"],
						[addAddressPadding(address)]
					).build()
				)
				.withEntityModels(["lore-PlayerGame"]);

			try {
				const sdk = getDojoSdk();
				const result = await sdk.getEntities({ query });
				const playerGame: PlayerGame | undefined = result.getItems()[0]?.models?.lore?.PlayerGame as PlayerGame;
				console.log("useSyncGameId() playerGame", playerGame);
				if (playerGame) {
					GameStore().setPlayerGameId(playerGame.current_game_id);
				} else {
					sendCommand(`create game`);
				}
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
		if (address != 0n && isConnected && inputGameId === undefined && mounted) {
			_fetch(address);
		}
	}, [walletAddress, isConnected, inputGameId, mounted]);

	// return the current game id
	return gameId;
};

/**
 * Returns the current game id.
 * @returns {number | undefined} The current game id
 */
export const useCurrentGameId = () => {
	const { gameId } = useGameStore();
	return gameId;
};


export default GameStore;
export { useGameStore };
