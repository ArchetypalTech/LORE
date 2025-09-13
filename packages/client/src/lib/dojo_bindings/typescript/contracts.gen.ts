import { DojoProvider, DojoCall } from "@dojoengine/core";
import { Account, AccountInterface, BigNumberish, CairoOption, CairoCustomEnum } from "starknet";
import * as models from "./models.gen";

export function setupWorld(provider: DojoProvider) {

	const build_designer_createAction_calldata = (t: Array<Action>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "create_action",
			calldata: [t],
		};
	};

	const designer_createAction = async (snAccount: Account | AccountInterface, t: Array<Action>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_createAction_calldata(t),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_createArea_calldata = (t: Array<Area>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "create_area",
			calldata: [t],
		};
	};

	const designer_createArea = async (snAccount: Account | AccountInterface, t: Array<Area>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_createArea_calldata(t),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_createChild_calldata = (t: Array<ChildToParent>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "create_child",
			calldata: [t],
		};
	};

	const designer_createChild = async (snAccount: Account | AccountInterface, t: Array<ChildToParent>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_createChild_calldata(t),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_createCondition_calldata = (t: Array<Condition>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "create_condition",
			calldata: [t],
		};
	};

	const designer_createCondition = async (snAccount: Account | AccountInterface, t: Array<Condition>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_createCondition_calldata(t),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_createContainer_calldata = (t: Array<Container>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "create_container",
			calldata: [t],
		};
	};

	const designer_createContainer = async (snAccount: Account | AccountInterface, t: Array<Container>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_createContainer_calldata(t),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_createDescriptionText_calldata = (t: Array<DescriptionText>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "create_description_text",
			calldata: [t],
		};
	};

	const designer_createDescriptionText = async (snAccount: Account | AccountInterface, t: Array<DescriptionText>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_createDescriptionText_calldata(t),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_createEffect_calldata = (t: Array<Effect>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "create_effect",
			calldata: [t],
		};
	};

	const designer_createEffect = async (snAccount: Account | AccountInterface, t: Array<Effect>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_createEffect_calldata(t),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_createEntity_calldata = (t: Array<Entity>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "create_entity",
			calldata: [t],
		};
	};

	const designer_createEntity = async (snAccount: Account | AccountInterface, t: Array<Entity>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_createEntity_calldata(t),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_createExit_calldata = (t: Array<Exit>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "create_exit",
			calldata: [t],
		};
	};

	const designer_createExit = async (snAccount: Account | AccountInterface, t: Array<Exit>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_createExit_calldata(t),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_createInventoryItem_calldata = (t: Array<InventoryItem>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "create_inventory_item",
			calldata: [t],
		};
	};

	const designer_createInventoryItem = async (snAccount: Account | AccountInterface, t: Array<InventoryItem>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_createInventoryItem_calldata(t),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_createParent_calldata = (t: Array<ParentToChildren>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "create_parent",
			calldata: [t],
		};
	};

	const designer_createParent = async (snAccount: Account | AccountInterface, t: Array<ParentToChildren>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_createParent_calldata(t),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_createPlayer_calldata = (t: Array<Player>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "create_player",
			calldata: [t],
		};
	};

	const designer_createPlayer = async (snAccount: Account | AccountInterface, t: Array<Player>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_createPlayer_calldata(t),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_createReactable_calldata = (t: Array<Reactable>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "create_reactable",
			calldata: [t],
		};
	};

	const designer_createReactable = async (snAccount: Account | AccountInterface, t: Array<Reactable>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_createReactable_calldata(t),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_createTrigger_calldata = (t: Array<Trigger>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "create_trigger",
			calldata: [t],
		};
	};

	const designer_createTrigger = async (snAccount: Account | AccountInterface, t: Array<Trigger>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_createTrigger_calldata(t),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_deleteAction_calldata = (ids: Array<[BigNumberish, BigNumberish]>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "delete_action",
			calldata: [ids],
		};
	};

	const designer_deleteAction = async (snAccount: Account | AccountInterface, ids: Array<[BigNumberish, BigNumberish]>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_deleteAction_calldata(ids),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_deleteArea_calldata = (ids: Array<BigNumberish>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "delete_area",
			calldata: [ids],
		};
	};

	const designer_deleteArea = async (snAccount: Account | AccountInterface, ids: Array<BigNumberish>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_deleteArea_calldata(ids),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_deleteChild_calldata = (ids: Array<BigNumberish>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "delete_child",
			calldata: [ids],
		};
	};

	const designer_deleteChild = async (snAccount: Account | AccountInterface, ids: Array<BigNumberish>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_deleteChild_calldata(ids),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_deleteCondition_calldata = (ids: Array<[BigNumberish, BigNumberish]>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "delete_condition",
			calldata: [ids],
		};
	};

	const designer_deleteCondition = async (snAccount: Account | AccountInterface, ids: Array<[BigNumberish, BigNumberish]>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_deleteCondition_calldata(ids),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_deleteContainer_calldata = (ids: Array<BigNumberish>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "delete_container",
			calldata: [ids],
		};
	};

	const designer_deleteContainer = async (snAccount: Account | AccountInterface, ids: Array<BigNumberish>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_deleteContainer_calldata(ids),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_deleteDescriptionText_calldata = (ids: Array<[BigNumberish, BigNumberish]>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "delete_description_text",
			calldata: [ids],
		};
	};

	const designer_deleteDescriptionText = async (snAccount: Account | AccountInterface, ids: Array<[BigNumberish, BigNumberish]>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_deleteDescriptionText_calldata(ids),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_deleteEffect_calldata = (ids: Array<[BigNumberish, BigNumberish]>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "delete_effect",
			calldata: [ids],
		};
	};

	const designer_deleteEffect = async (snAccount: Account | AccountInterface, ids: Array<[BigNumberish, BigNumberish]>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_deleteEffect_calldata(ids),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_deleteEntity_calldata = (ids: Array<BigNumberish>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "delete_entity",
			calldata: [ids],
		};
	};

	const designer_deleteEntity = async (snAccount: Account | AccountInterface, ids: Array<BigNumberish>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_deleteEntity_calldata(ids),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_deleteExit_calldata = (ids: Array<BigNumberish>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "delete_exit",
			calldata: [ids],
		};
	};

	const designer_deleteExit = async (snAccount: Account | AccountInterface, ids: Array<BigNumberish>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_deleteExit_calldata(ids),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_deleteInventoryItem_calldata = (ids: Array<BigNumberish>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "delete_inventory_item",
			calldata: [ids],
		};
	};

	const designer_deleteInventoryItem = async (snAccount: Account | AccountInterface, ids: Array<BigNumberish>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_deleteInventoryItem_calldata(ids),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_deleteParent_calldata = (ids: Array<BigNumberish>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "delete_parent",
			calldata: [ids],
		};
	};

	const designer_deleteParent = async (snAccount: Account | AccountInterface, ids: Array<BigNumberish>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_deleteParent_calldata(ids),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_deletePlayer_calldata = (ids: Array<BigNumberish>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "delete_player",
			calldata: [ids],
		};
	};

	const designer_deletePlayer = async (snAccount: Account | AccountInterface, ids: Array<BigNumberish>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_deletePlayer_calldata(ids),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_deleteReactable_calldata = (ids: Array<BigNumberish>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "delete_reactable",
			calldata: [ids],
		};
	};

	const designer_deleteReactable = async (snAccount: Account | AccountInterface, ids: Array<BigNumberish>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_deleteReactable_calldata(ids),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_deleteTrigger_calldata = (ids: Array<[BigNumberish, BigNumberish]>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "delete_trigger",
			calldata: [ids],
		};
	};

	const designer_deleteTrigger = async (snAccount: Account | AccountInterface, ids: Array<[BigNumberish, BigNumberish]>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_deleteTrigger_calldata(ids),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_registerPropertyRegistry_calldata = (done: Array<boolean>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "register_property_registry",
			calldata: [done],
		};
	};

	const designer_registerPropertyRegistry = async (snAccount: Account | AccountInterface, done: Array<boolean>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_registerPropertyRegistry_calldata(done),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_approve_calldata = (to: string, tokenId: BigNumberish): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "approve",
			calldata: [to, tokenId],
		};
	};

	const game_token_approve = async (snAccount: Account | AccountInterface, to: string, tokenId: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_game_token_approve_calldata(to, tokenId),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_availableSupply_calldata = (): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "availableSupply",
			calldata: [],
		};
	};

	const game_token_availableSupply = async () => {
		try {
			return await provider.call("lore", build_game_token_availableSupply_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_balanceOf_calldata = (account: string): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "balanceOf",
			calldata: [account],
		};
	};

	const game_token_balanceOf = async (account: string) => {
		try {
			return await provider.call("lore", build_game_token_balanceOf_calldata(account));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_contractUri_calldata = (): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "contractURI",
			calldata: [],
		};
	};

	const game_token_contractUri = async () => {
		try {
			return await provider.call("lore", build_game_token_contractUri_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_createGame_calldata = (recipient: string): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "create_game",
			calldata: [recipient],
		};
	};

	const game_token_createGame = async (snAccount: Account | AccountInterface, recipient: string) => {
		try {
			return await provider.execute(
				snAccount,
				build_game_token_createGame_calldata(recipient),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_defaultRoyalty_calldata = (): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "defaultRoyalty",
			calldata: [],
		};
	};

	const game_token_defaultRoyalty = async () => {
		try {
			return await provider.call("lore", build_game_token_defaultRoyalty_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_getApproved_calldata = (tokenId: BigNumberish): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "getApproved",
			calldata: [tokenId],
		};
	};

	const game_token_getApproved = async (tokenId: BigNumberish) => {
		try {
			return await provider.call("lore", build_game_token_getApproved_calldata(tokenId));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_isApprovedForAll_calldata = (owner: string, operator: string): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "isApprovedForAll",
			calldata: [owner, operator],
		};
	};

	const game_token_isApprovedForAll = async (owner: string, operator: string) => {
		try {
			return await provider.call("lore", build_game_token_isApprovedForAll_calldata(owner, operator));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_isMintedOut_calldata = (): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "is_minted_out",
			calldata: [],
		};
	};

	const game_token_isMintedOut = async () => {
		try {
			return await provider.call("lore", build_game_token_isMintedOut_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_isMintingPaused_calldata = (): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "is_minting_paused",
			calldata: [],
		};
	};

	const game_token_isMintingPaused = async () => {
		try {
			return await provider.call("lore", build_game_token_isMintingPaused_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_isOwnerOf_calldata = (address: string, tokenId: BigNumberish): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "is_owner_of",
			calldata: [address, tokenId],
		};
	};

	const game_token_isOwnerOf = async (address: string, tokenId: BigNumberish) => {
		try {
			return await provider.call("lore", build_game_token_isOwnerOf_calldata(address, tokenId));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_lastTokenId_calldata = (): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "last_token_id",
			calldata: [],
		};
	};

	const game_token_lastTokenId = async () => {
		try {
			return await provider.call("lore", build_game_token_lastTokenId_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_maxSupply_calldata = (): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "maxSupply",
			calldata: [],
		};
	};

	const game_token_maxSupply = async () => {
		try {
			return await provider.call("lore", build_game_token_maxSupply_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_mintedSupply_calldata = (): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "mintedSupply",
			calldata: [],
		};
	};

	const game_token_mintedSupply = async () => {
		try {
			return await provider.call("lore", build_game_token_mintedSupply_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_name_calldata = (): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "name",
			calldata: [],
		};
	};

	const game_token_name = async () => {
		try {
			return await provider.call("lore", build_game_token_name_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_ownerOf_calldata = (tokenId: BigNumberish): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "ownerOf",
			calldata: [tokenId],
		};
	};

	const game_token_ownerOf = async (tokenId: BigNumberish) => {
		try {
			return await provider.call("lore", build_game_token_ownerOf_calldata(tokenId));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_reservedSupply_calldata = (): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "reservedSupply",
			calldata: [],
		};
	};

	const game_token_reservedSupply = async () => {
		try {
			return await provider.call("lore", build_game_token_reservedSupply_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_royaltyInfo_calldata = (tokenId: BigNumberish, salePrice: BigNumberish): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "royaltyInfo",
			calldata: [tokenId, salePrice],
		};
	};

	const game_token_royaltyInfo = async (tokenId: BigNumberish, salePrice: BigNumberish) => {
		try {
			return await provider.call("lore", build_game_token_royaltyInfo_calldata(tokenId, salePrice));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_safeTransferFrom_calldata = (from: string, to: string, tokenId: BigNumberish, data: Array<BigNumberish>): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "safeTransferFrom",
			calldata: [from, to, tokenId, data],
		};
	};

	const game_token_safeTransferFrom = async (snAccount: Account | AccountInterface, from: string, to: string, tokenId: BigNumberish, data: Array<BigNumberish>) => {
		try {
			return await provider.execute(
				snAccount,
				build_game_token_safeTransferFrom_calldata(from, to, tokenId, data),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_setApprovalForAll_calldata = (operator: string, approved: boolean): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "setApprovalForAll",
			calldata: [operator, approved],
		};
	};

	const game_token_setApprovalForAll = async (snAccount: Account | AccountInterface, operator: string, approved: boolean) => {
		try {
			return await provider.execute(
				snAccount,
				build_game_token_setApprovalForAll_calldata(operator, approved),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_setAdmin_calldata = (adminAddress: string): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "set_admin",
			calldata: [adminAddress],
		};
	};

	const game_token_setAdmin = async (snAccount: Account | AccountInterface, adminAddress: string) => {
		try {
			return await provider.execute(
				snAccount,
				build_game_token_setAdmin_calldata(adminAddress),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_setPaused_calldata = (isPaused: boolean): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "set_paused",
			calldata: [isPaused],
		};
	};

	const game_token_setPaused = async (snAccount: Account | AccountInterface, isPaused: boolean) => {
		try {
			return await provider.execute(
				snAccount,
				build_game_token_setPaused_calldata(isPaused),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_supportsInterface_calldata = (interfaceId: BigNumberish): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "supports_interface",
			calldata: [interfaceId],
		};
	};

	const game_token_supportsInterface = async (interfaceId: BigNumberish) => {
		try {
			return await provider.call("lore", build_game_token_supportsInterface_calldata(interfaceId));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_symbol_calldata = (): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "symbol",
			calldata: [],
		};
	};

	const game_token_symbol = async () => {
		try {
			return await provider.call("lore", build_game_token_symbol_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_tokenRoyalty_calldata = (tokenId: BigNumberish): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "tokenRoyalty",
			calldata: [tokenId],
		};
	};

	const game_token_tokenRoyalty = async (tokenId: BigNumberish) => {
		try {
			return await provider.call("lore", build_game_token_tokenRoyalty_calldata(tokenId));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_tokenUri_calldata = (tokenId: BigNumberish): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "tokenURI",
			calldata: [tokenId],
		};
	};

	const game_token_tokenUri = async (tokenId: BigNumberish) => {
		try {
			return await provider.call("lore", build_game_token_tokenUri_calldata(tokenId));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_tokenExists_calldata = (tokenId: BigNumberish): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "token_exists",
			calldata: [tokenId],
		};
	};

	const game_token_tokenExists = async (tokenId: BigNumberish) => {
		try {
			return await provider.call("lore", build_game_token_tokenExists_calldata(tokenId));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_totalSupply_calldata = (): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "totalSupply",
			calldata: [],
		};
	};

	const game_token_totalSupply = async () => {
		try {
			return await provider.call("lore", build_game_token_totalSupply_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_transferFrom_calldata = (from: string, to: string, tokenId: BigNumberish): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "transferFrom",
			calldata: [from, to, tokenId],
		};
	};

	const game_token_transferFrom = async (snAccount: Account | AccountInterface, from: string, to: string, tokenId: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_game_token_transferFrom_calldata(from, to, tokenId),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_updateContractMetadata_calldata = (): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "update_contract_metadata",
			calldata: [],
		};
	};

	const game_token_updateContractMetadata = async (snAccount: Account | AccountInterface) => {
		try {
			return await provider.execute(
				snAccount,
				build_game_token_updateContractMetadata_calldata(),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_updateTokenMetadata_calldata = (tokenId: BigNumberish): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "update_token_metadata",
			calldata: [tokenId],
		};
	};

	const game_token_updateTokenMetadata = async (snAccount: Account | AccountInterface, tokenId: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_game_token_updateTokenMetadata_calldata(tokenId),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_game_token_updateTokensMetadata_calldata = (fromTokenId: BigNumberish, toTokenId: BigNumberish): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "update_tokens_metadata",
			calldata: [fromTokenId, toTokenId],
		};
	};

	const game_token_updateTokensMetadata = async (snAccount: Account | AccountInterface, fromTokenId: BigNumberish, toTokenId: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_game_token_updateTokensMetadata_calldata(fromTokenId, toTokenId),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_prompt_prompt_calldata = (cmd: string, gameId: CairoOption<BigNumberish>): DojoCall => {
		return {
			contractName: "prompt",
			entrypoint: "prompt",
			calldata: [cmd, gameId],
		};
	};

	const prompt_prompt = async (snAccount: Account | AccountInterface, cmd: string, gameId: CairoOption<BigNumberish>) => {
		try {
			return await provider.execute(
				snAccount,
				build_prompt_prompt_calldata(cmd, gameId),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};



	return {
		designer: {
			createAction: designer_createAction,
			buildCreateActionCalldata: build_designer_createAction_calldata,
			createArea: designer_createArea,
			buildCreateAreaCalldata: build_designer_createArea_calldata,
			createChild: designer_createChild,
			buildCreateChildCalldata: build_designer_createChild_calldata,
			createCondition: designer_createCondition,
			buildCreateConditionCalldata: build_designer_createCondition_calldata,
			createContainer: designer_createContainer,
			buildCreateContainerCalldata: build_designer_createContainer_calldata,
			createDescriptionText: designer_createDescriptionText,
			buildCreateDescriptionTextCalldata: build_designer_createDescriptionText_calldata,
			createEffect: designer_createEffect,
			buildCreateEffectCalldata: build_designer_createEffect_calldata,
			createEntity: designer_createEntity,
			buildCreateEntityCalldata: build_designer_createEntity_calldata,
			createExit: designer_createExit,
			buildCreateExitCalldata: build_designer_createExit_calldata,
			createInventoryItem: designer_createInventoryItem,
			buildCreateInventoryItemCalldata: build_designer_createInventoryItem_calldata,
			createParent: designer_createParent,
			buildCreateParentCalldata: build_designer_createParent_calldata,
			createPlayer: designer_createPlayer,
			buildCreatePlayerCalldata: build_designer_createPlayer_calldata,
			createReactable: designer_createReactable,
			buildCreateReactableCalldata: build_designer_createReactable_calldata,
			createTrigger: designer_createTrigger,
			buildCreateTriggerCalldata: build_designer_createTrigger_calldata,
			deleteAction: designer_deleteAction,
			buildDeleteActionCalldata: build_designer_deleteAction_calldata,
			deleteArea: designer_deleteArea,
			buildDeleteAreaCalldata: build_designer_deleteArea_calldata,
			deleteChild: designer_deleteChild,
			buildDeleteChildCalldata: build_designer_deleteChild_calldata,
			deleteCondition: designer_deleteCondition,
			buildDeleteConditionCalldata: build_designer_deleteCondition_calldata,
			deleteContainer: designer_deleteContainer,
			buildDeleteContainerCalldata: build_designer_deleteContainer_calldata,
			deleteDescriptionText: designer_deleteDescriptionText,
			buildDeleteDescriptionTextCalldata: build_designer_deleteDescriptionText_calldata,
			deleteEffect: designer_deleteEffect,
			buildDeleteEffectCalldata: build_designer_deleteEffect_calldata,
			deleteEntity: designer_deleteEntity,
			buildDeleteEntityCalldata: build_designer_deleteEntity_calldata,
			deleteExit: designer_deleteExit,
			buildDeleteExitCalldata: build_designer_deleteExit_calldata,
			deleteInventoryItem: designer_deleteInventoryItem,
			buildDeleteInventoryItemCalldata: build_designer_deleteInventoryItem_calldata,
			deleteParent: designer_deleteParent,
			buildDeleteParentCalldata: build_designer_deleteParent_calldata,
			deletePlayer: designer_deletePlayer,
			buildDeletePlayerCalldata: build_designer_deletePlayer_calldata,
			deleteReactable: designer_deleteReactable,
			buildDeleteReactableCalldata: build_designer_deleteReactable_calldata,
			deleteTrigger: designer_deleteTrigger,
			buildDeleteTriggerCalldata: build_designer_deleteTrigger_calldata,
			registerPropertyRegistry: designer_registerPropertyRegistry,
			buildRegisterPropertyRegistryCalldata: build_designer_registerPropertyRegistry_calldata,
		},
		game_token: {
			approve: game_token_approve,
			buildApproveCalldata: build_game_token_approve_calldata,
			availableSupply: game_token_availableSupply,
			buildAvailableSupplyCalldata: build_game_token_availableSupply_calldata,
			balanceOf: game_token_balanceOf,
			buildBalanceOfCalldata: build_game_token_balanceOf_calldata,
			contractUri: game_token_contractUri,
			buildContractUriCalldata: build_game_token_contractUri_calldata,
			createGame: game_token_createGame,
			buildCreateGameCalldata: build_game_token_createGame_calldata,
			defaultRoyalty: game_token_defaultRoyalty,
			buildDefaultRoyaltyCalldata: build_game_token_defaultRoyalty_calldata,
			getApproved: game_token_getApproved,
			buildGetApprovedCalldata: build_game_token_getApproved_calldata,
			isApprovedForAll: game_token_isApprovedForAll,
			buildIsApprovedForAllCalldata: build_game_token_isApprovedForAll_calldata,
			isMintedOut: game_token_isMintedOut,
			buildIsMintedOutCalldata: build_game_token_isMintedOut_calldata,
			isMintingPaused: game_token_isMintingPaused,
			buildIsMintingPausedCalldata: build_game_token_isMintingPaused_calldata,
			isOwnerOf: game_token_isOwnerOf,
			buildIsOwnerOfCalldata: build_game_token_isOwnerOf_calldata,
			lastTokenId: game_token_lastTokenId,
			buildLastTokenIdCalldata: build_game_token_lastTokenId_calldata,
			maxSupply: game_token_maxSupply,
			buildMaxSupplyCalldata: build_game_token_maxSupply_calldata,
			mintedSupply: game_token_mintedSupply,
			buildMintedSupplyCalldata: build_game_token_mintedSupply_calldata,
			name: game_token_name,
			buildNameCalldata: build_game_token_name_calldata,
			ownerOf: game_token_ownerOf,
			buildOwnerOfCalldata: build_game_token_ownerOf_calldata,
			reservedSupply: game_token_reservedSupply,
			buildReservedSupplyCalldata: build_game_token_reservedSupply_calldata,
			royaltyInfo: game_token_royaltyInfo,
			buildRoyaltyInfoCalldata: build_game_token_royaltyInfo_calldata,
			safeTransferFrom: game_token_safeTransferFrom,
			buildSafeTransferFromCalldata: build_game_token_safeTransferFrom_calldata,
			setApprovalForAll: game_token_setApprovalForAll,
			buildSetApprovalForAllCalldata: build_game_token_setApprovalForAll_calldata,
			setAdmin: game_token_setAdmin,
			buildSetAdminCalldata: build_game_token_setAdmin_calldata,
			setPaused: game_token_setPaused,
			buildSetPausedCalldata: build_game_token_setPaused_calldata,
			supportsInterface: game_token_supportsInterface,
			buildSupportsInterfaceCalldata: build_game_token_supportsInterface_calldata,
			symbol: game_token_symbol,
			buildSymbolCalldata: build_game_token_symbol_calldata,
			tokenRoyalty: game_token_tokenRoyalty,
			buildTokenRoyaltyCalldata: build_game_token_tokenRoyalty_calldata,
			tokenUri: game_token_tokenUri,
			buildTokenUriCalldata: build_game_token_tokenUri_calldata,
			tokenExists: game_token_tokenExists,
			buildTokenExistsCalldata: build_game_token_tokenExists_calldata,
			totalSupply: game_token_totalSupply,
			buildTotalSupplyCalldata: build_game_token_totalSupply_calldata,
			transferFrom: game_token_transferFrom,
			buildTransferFromCalldata: build_game_token_transferFrom_calldata,
			updateContractMetadata: game_token_updateContractMetadata,
			buildUpdateContractMetadataCalldata: build_game_token_updateContractMetadata_calldata,
			updateTokenMetadata: game_token_updateTokenMetadata,
			buildUpdateTokenMetadataCalldata: build_game_token_updateTokenMetadata_calldata,
			updateTokensMetadata: game_token_updateTokensMetadata,
			buildUpdateTokensMetadataCalldata: build_game_token_updateTokensMetadata_calldata,
		},
		prompt: {
			prompt: prompt_prompt,
			buildPromptCalldata: build_prompt_prompt_calldata,
		},
	};
}