import { useEffect, useRef } from "react";
import { addAddressPadding, BigNumberish } from "starknet";
import { ClauseBuilder, ToriiQueryBuilder } from "@dojoengine/sdk";
import { useWalletStore } from "./wallet.store";
import { sendCommand } from "../terminalCommands/commandHandler";
import { StoreBuilder } from "../utils/storebuilder";
import { getDojoSdk } from "./dojo.store";
import type { SchemaType, PlayerAccount } from "../dojo_bindings/typescript/models.gen";
import { useMounted } from "../utils/useMounted";
import * as torii from "@dojoengine/torii-client";

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
 * Performs an initial fetch then subscribes so any subsequent switch_game_id
 * (from "create game" or "load game") updates the store automatically.
 * Use only once at a top-level component.
 */
export const useSyncGameId = (inputGameId?: BigNumberish) => {
	const { gameId } = useGameStore();
	const mounted = useMounted();
	const subRef = useRef<torii.Subscription | undefined>(undefined);

	// set the editor game id, if provided
	useEffect(() => {
		GameStore().setEditorGameId(inputGameId == undefined ? undefined : inputGameId);
	}, [inputGameId]);

	// use game_id for the connected player
	const { walletAddress, isConnected } = useWalletStore();
	useEffect(() => {
		const address = BigInt(walletAddress || 0);
		if (address === 0n || !isConnected || inputGameId !== undefined || !mounted) return;

		const query = new ToriiQueryBuilder<SchemaType>()
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

		const handlePlayerAccount = (playerAccount: PlayerAccount | undefined) => {
			console.log("useSyncGameId() playerGame", playerAccount);
			if (playerAccount?.current_game_id) {
				GameStore().setPlayerGameId(playerAccount.current_game_id);
			} else {
				sendCommand(`create game`);
			}
		};

		const _setup = async () => {
			try {
				const sdk = getDojoSdk();

				// Initial fetch — handles existing players immediately
				const result = await sdk.getEntities({ query });
				const playerAccount = result.getItems()[0]?.models?.lore?.PlayerAccount as PlayerAccount | undefined;
				handlePlayerAccount(playerAccount);

				// Subscribe — picks up switch_game_id writes from "create game" / "load game"
				subRef.current = await sdk.subscribeEntityQuery({
					query,
					callback: ({ data, error }) => {
						if (error) {
							console.error("useSyncGameId() SUB error:", error);
							return;
						}
						const updated = data?.getItems()[0]?.models?.lore?.PlayerAccount as PlayerAccount | undefined;
						if (updated?.current_game_id) {
							GameStore().setPlayerGameId(updated.current_game_id);
						}
					},
				});
			} catch (e) {
				console.error("useSyncGameId() error for wallet:", walletAddress, e);
			}
		};

		_setup();

		return () => {
			subRef.current?.cancel();
			subRef.current = undefined;
		};
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
