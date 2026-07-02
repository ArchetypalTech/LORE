import { DojoProvider, DojoCall } from "@dojoengine/core";
import { Account, AccountInterface, BigNumberish, CairoOption, CairoCustomEnum } from "starknet";
import * as models from "./models.gen";

export function setupWorld(provider: DojoProvider) {

	const build_actions_token_allowance_calldata = (owner: string, spender: string): DojoCall => {
		return {
			contractName: "actions_token",
			entrypoint: "allowance",
			calldata: [owner, spender],
		};
	};

	const actions_token_allowance = async (owner: string, spender: string) => {
		try {
			return await provider.call("lore", build_actions_token_allowance_calldata(owner, spender));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_actions_token_approve_calldata = (spender: string, amount: BigNumberish): DojoCall => {
		return {
			contractName: "actions_token",
			entrypoint: "approve",
			calldata: [spender, amount],
		};
	};

	const actions_token_approve = async (snAccount: Account | AccountInterface, spender: string, amount: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_actions_token_approve_calldata(spender, amount),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_actions_token_balanceOf_calldata = (account: string): DojoCall => {
		return {
			contractName: "actions_token",
			entrypoint: "balanceOf",
			calldata: [account],
		};
	};

	const actions_token_balanceOf = async (account: string) => {
		try {
			return await provider.call("lore", build_actions_token_balanceOf_calldata(account));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_actions_token_calculateActionCost_calldata = (player: models.Player, commandType: CairoCustomEnum): DojoCall => {
		return {
			contractName: "actions_token",
			entrypoint: "calculate_action_cost",
			calldata: [player, commandType],
		};
	};

	const actions_token_calculateActionCost = async (snAccount: Account | AccountInterface, player: models.Player, commandType: CairoCustomEnum) => {
		try {
			return await provider.execute(
				snAccount,
				build_actions_token_calculateActionCost_calldata(player, commandType),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_actions_token_chargePlayerActions_calldata = (playerAddress: string, trailId: BigNumberish, actionsAmount: BigNumberish, gameId: BigNumberish): DojoCall => {
		return {
			contractName: "actions_token",
			entrypoint: "charge_player_actions",
			calldata: [playerAddress, trailId, actionsAmount, gameId],
		};
	};

	const actions_token_chargePlayerActions = async (snAccount: Account | AccountInterface, playerAddress: string, trailId: BigNumberish, actionsAmount: BigNumberish, gameId: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_actions_token_chargePlayerActions_calldata(playerAddress, trailId, actionsAmount, gameId),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_actions_token_claimActions_calldata = (recipient: string, actionsCount: BigNumberish): DojoCall => {
		return {
			contractName: "actions_token",
			entrypoint: "claim_actions",
			calldata: [recipient, actionsCount],
		};
	};

	const actions_token_claimActions = async (snAccount: Account | AccountInterface, recipient: string, actionsCount: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_actions_token_claimActions_calldata(recipient, actionsCount),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_actions_token_claimFreeActions_calldata = (): DojoCall => {
		return {
			contractName: "actions_token",
			entrypoint: "claim_free_actions",
			calldata: [],
		};
	};

	const actions_token_claimFreeActions = async (snAccount: Account | AccountInterface) => {
		try {
			return await provider.execute(
				snAccount,
				build_actions_token_claimFreeActions_calldata(),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_actions_token_claimRewards_calldata = (rewardsCount: BigNumberish): DojoCall => {
		return {
			contractName: "actions_token",
			entrypoint: "claim_rewards",
			calldata: [rewardsCount],
		};
	};

	const actions_token_claimRewards = async (snAccount: Account | AccountInterface, rewardsCount: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_actions_token_claimRewards_calldata(rewardsCount),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_actions_token_decimals_calldata = (): DojoCall => {
		return {
			contractName: "actions_token",
			entrypoint: "decimals",
			calldata: [],
		};
	};

	const actions_token_decimals = async () => {
		try {
			return await provider.call("lore", build_actions_token_decimals_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_actions_token_getClaimableRewardsCount_calldata = (recipient: string): DojoCall => {
		return {
			contractName: "actions_token",
			entrypoint: "get_claimable_rewards_count",
			calldata: [recipient],
		};
	};

	const actions_token_getClaimableRewardsCount = async (recipient: string) => {
		try {
			return await provider.call("lore", build_actions_token_getClaimableRewardsCount_calldata(recipient));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_actions_token_getFreeActionsCount_calldata = (): DojoCall => {
		return {
			contractName: "actions_token",
			entrypoint: "get_free_actions_count",
			calldata: [],
		};
	};

	const actions_token_getFreeActionsCount = async () => {
		try {
			return await provider.call("lore", build_actions_token_getFreeActionsCount_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_actions_token_mintTo_calldata = (recipient: string, actionsCount: BigNumberish): DojoCall => {
		return {
			contractName: "actions_token",
			entrypoint: "mint_to",
			calldata: [recipient, actionsCount],
		};
	};

	const actions_token_mintTo = async (snAccount: Account | AccountInterface, recipient: string, actionsCount: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_actions_token_mintTo_calldata(recipient, actionsCount),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_actions_token_name_calldata = (): DojoCall => {
		return {
			contractName: "actions_token",
			entrypoint: "name",
			calldata: [],
		};
	};

	const actions_token_name = async () => {
		try {
			return await provider.call("lore", build_actions_token_name_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_actions_token_sendRewards_calldata = (recipient: string, rewardsCount: BigNumberish): DojoCall => {
		return {
			contractName: "actions_token",
			entrypoint: "send_rewards",
			calldata: [recipient, rewardsCount],
		};
	};

	const actions_token_sendRewards = async (snAccount: Account | AccountInterface, recipient: string, rewardsCount: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_actions_token_sendRewards_calldata(recipient, rewardsCount),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_actions_token_setActionCostAmount_calldata = (actionCostAmount: BigNumberish): DojoCall => {
		return {
			contractName: "actions_token",
			entrypoint: "set_action_cost_amount",
			calldata: [actionCostAmount],
		};
	};

	const actions_token_setActionCostAmount = async (snAccount: Account | AccountInterface, actionCostAmount: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_actions_token_setActionCostAmount_calldata(actionCostAmount),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_actions_token_setFreeActionClaimInterval_calldata = (freeActionClaimInterval: BigNumberish): DojoCall => {
		return {
			contractName: "actions_token",
			entrypoint: "set_free_action_claim_interval",
			calldata: [freeActionClaimInterval],
		};
	};

	const actions_token_setFreeActionClaimInterval = async (snAccount: Account | AccountInterface, freeActionClaimInterval: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_actions_token_setFreeActionClaimInterval_calldata(freeActionClaimInterval),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_actions_token_setInitialFreeActionsCount_calldata = (initialFreeActionsCount: BigNumberish): DojoCall => {
		return {
			contractName: "actions_token",
			entrypoint: "set_initial_free_actions_count",
			calldata: [initialFreeActionsCount],
		};
	};

	const actions_token_setInitialFreeActionsCount = async (snAccount: Account | AccountInterface, initialFreeActionsCount: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_actions_token_setInitialFreeActionsCount_calldata(initialFreeActionsCount),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_actions_token_setMaxFreeActionsCount_calldata = (maxFreeActionsCount: BigNumberish): DojoCall => {
		return {
			contractName: "actions_token",
			entrypoint: "set_max_free_actions_count",
			calldata: [maxFreeActionsCount],
		};
	};

	const actions_token_setMaxFreeActionsCount = async (snAccount: Account | AccountInterface, maxFreeActionsCount: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_actions_token_setMaxFreeActionsCount_calldata(maxFreeActionsCount),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_actions_token_setSnContract_calldata = (snContract: string): DojoCall => {
		return {
			contractName: "actions_token",
			entrypoint: "set_sn_contract",
			calldata: [snContract],
		};
	};

	const actions_token_setSnContract = async (snAccount: Account | AccountInterface, snContract: string) => {
		try {
			return await provider.execute(
				snAccount,
				build_actions_token_setSnContract_calldata(snContract),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_actions_token_setTrailRewardActionsCount_calldata = (trailRewardActionsCount: BigNumberish): DojoCall => {
		return {
			contractName: "actions_token",
			entrypoint: "set_trail_reward_actions_count",
			calldata: [trailRewardActionsCount],
		};
	};

	const actions_token_setTrailRewardActionsCount = async (snAccount: Account | AccountInterface, trailRewardActionsCount: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_actions_token_setTrailRewardActionsCount_calldata(trailRewardActionsCount),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_actions_token_symbol_calldata = (): DojoCall => {
		return {
			contractName: "actions_token",
			entrypoint: "symbol",
			calldata: [],
		};
	};

	const actions_token_symbol = async () => {
		try {
			return await provider.call("lore", build_actions_token_symbol_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_actions_token_totalSupply_calldata = (): DojoCall => {
		return {
			contractName: "actions_token",
			entrypoint: "totalSupply",
			calldata: [],
		};
	};

	const actions_token_totalSupply = async () => {
		try {
			return await provider.call("lore", build_actions_token_totalSupply_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_actions_token_transfer_calldata = (recipient: string, amount: BigNumberish): DojoCall => {
		return {
			contractName: "actions_token",
			entrypoint: "transfer",
			calldata: [recipient, amount],
		};
	};

	const actions_token_transfer = async (snAccount: Account | AccountInterface, recipient: string, amount: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_actions_token_transfer_calldata(recipient, amount),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_actions_token_transferFrom_calldata = (sender: string, recipient: string, amount: BigNumberish): DojoCall => {
		return {
			contractName: "actions_token",
			entrypoint: "transferFrom",
			calldata: [sender, recipient, amount],
		};
	};

	const actions_token_transferFrom = async (snAccount: Account | AccountInterface, sender: string, recipient: string, amount: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_actions_token_transferFrom_calldata(sender, recipient, amount),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_approveProposal_calldata = (proposal: models.ApprovedProposal): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "approve_proposal",
			calldata: [proposal],
		};
	};

	const designer_approveProposal = async (snAccount: Account | AccountInterface, proposal: models.ApprovedProposal) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_approveProposal_calldata(proposal),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

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

	const build_designer_createHub_calldata = (t: Array<Hub>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "create_hub",
			calldata: [t],
		};
	};

	const designer_createHub = async (snAccount: Account | AccountInterface, t: Array<Hub>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_createHub_calldata(t),
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

	const build_designer_createTrail_calldata = (t: Array<Trail>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "create_trail",
			calldata: [t],
		};
	};

	const designer_createTrail = async (snAccount: Account | AccountInterface, t: Array<Trail>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_createTrail_calldata(t),
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

	const build_designer_deleteHub_calldata = (ids: Array<BigNumberish>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "delete_hub",
			calldata: [ids],
		};
	};

	const designer_deleteHub = async (snAccount: Account | AccountInterface, ids: Array<BigNumberish>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_deleteHub_calldata(ids),
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

	const build_designer_deleteTrail_calldata = (ids: Array<BigNumberish>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "delete_trail",
			calldata: [ids],
		};
	};

	const designer_deleteTrail = async (snAccount: Account | AccountInterface, ids: Array<BigNumberish>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_deleteTrail_calldata(ids),
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

	const build_designer_getRoleAdmin_calldata = (role: BigNumberish): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "get_role_admin",
			calldata: [role],
		};
	};

	const designer_getRoleAdmin = async (role: BigNumberish) => {
		try {
			return await provider.call("lore", build_designer_getRoleAdmin_calldata(role));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_grantAccessToEntity_calldata = (account: string, inst: BigNumberish, granting: boolean): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "grant_access_to_entity",
			calldata: [account, inst, granting],
		};
	};

	const designer_grantAccessToEntity = async (snAccount: Account | AccountInterface, account: string, inst: BigNumberish, granting: boolean) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_grantAccessToEntity_calldata(account, inst, granting),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_grantAccessToTrail_calldata = (account: string, trailId: BigNumberish, granting: boolean): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "grant_access_to_trail",
			calldata: [account, trailId, granting],
		};
	};

	const designer_grantAccessToTrail = async (snAccount: Account | AccountInterface, account: string, trailId: BigNumberish, granting: boolean) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_grantAccessToTrail_calldata(account, trailId, granting),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_grantRole_calldata = (role: BigNumberish, account: string): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "grant_role",
			calldata: [role, account],
		};
	};

	const designer_grantRole = async (snAccount: Account | AccountInterface, role: BigNumberish, account: string) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_grantRole_calldata(role, account),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_hasRole_calldata = (role: BigNumberish, account: string): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "has_role",
			calldata: [role, account],
		};
	};

	const designer_hasRole = async (role: BigNumberish, account: string) => {
		try {
			return await provider.call("lore", build_designer_hasRole_calldata(role, account));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_isAdmin_calldata = (account: string): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "is_admin",
			calldata: [account],
		};
	};

	const designer_isAdmin = async (account: string) => {
		try {
			return await provider.call("lore", build_designer_isAdmin_calldata(account));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_isEditor_calldata = (account: string): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "is_editor",
			calldata: [account],
		};
	};

	const designer_isEditor = async (account: string) => {
		try {
			return await provider.call("lore", build_designer_isEditor_calldata(account));
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

	const build_designer_rejectProposal_calldata = (trailId: BigNumberish, proposer: string): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "reject_proposal",
			calldata: [trailId, proposer],
		};
	};

	const designer_rejectProposal = async (snAccount: Account | AccountInterface, trailId: BigNumberish, proposer: string) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_rejectProposal_calldata(trailId, proposer),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_renounceRole_calldata = (role: BigNumberish, account: string): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "renounce_role",
			calldata: [role, account],
		};
	};

	const designer_renounceRole = async (snAccount: Account | AccountInterface, role: BigNumberish, account: string) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_renounceRole_calldata(role, account),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_revokeRole_calldata = (role: BigNumberish, account: string): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "revoke_role",
			calldata: [role, account],
		};
	};

	const designer_revokeRole = async (snAccount: Account | AccountInterface, role: BigNumberish, account: string) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_revokeRole_calldata(role, account),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_setAdmin_calldata = (account: string, isAdmin: boolean): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "set_admin",
			calldata: [account, isAdmin],
		};
	};

	const designer_setAdmin = async (snAccount: Account | AccountInterface, account: string, isAdmin: boolean) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_setAdmin_calldata(account, isAdmin),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_setEditor_calldata = (account: string, isEditor: boolean): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "set_editor",
			calldata: [account, isEditor],
		};
	};

	const designer_setEditor = async (snAccount: Account | AccountInterface, account: string, isEditor: boolean) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_setEditor_calldata(account, isEditor),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_submitForReview_calldata = (trailId: BigNumberish, entities: Array<Entity>, reactables: Array<Reactable>, areas: Array<Area>, exits: Array<Exit>, hubs: Array<Hub>, descriptionTexts: Array<DescriptionText>, inventoryItems: Array<InventoryItem>, containers: Array<Container>, trails: Array<Trail>, triggers: Array<Trigger>, conditions: Array<Condition>, effects: Array<Effect>, actions: Array<Action>, parents: Array<ParentToChildren>, children: Array<ChildToParent>, deletedEntityInsts: Array<BigNumberish>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "submit_for_review",
			calldata: [trailId, entities, reactables, areas, exits, hubs, descriptionTexts, inventoryItems, containers, trails, triggers, conditions, effects, actions, parents, children, deletedEntityInsts],
		};
	};

	const designer_submitForReview = async (snAccount: Account | AccountInterface, trailId: BigNumberish, entities: Array<Entity>, reactables: Array<Reactable>, areas: Array<Area>, exits: Array<Exit>, hubs: Array<Hub>, descriptionTexts: Array<DescriptionText>, inventoryItems: Array<InventoryItem>, containers: Array<Container>, trails: Array<Trail>, triggers: Array<Trigger>, conditions: Array<Condition>, effects: Array<Effect>, actions: Array<Action>, parents: Array<ParentToChildren>, children: Array<ChildToParent>, deletedEntityInsts: Array<BigNumberish>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_submitForReview_calldata(trailId, entities, reactables, areas, exits, hubs, descriptionTexts, inventoryItems, containers, trails, triggers, conditions, effects, actions, parents, children, deletedEntityInsts),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_supportsInterface_calldata = (interfaceId: BigNumberish): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "supports_interface",
			calldata: [interfaceId],
		};
	};

	const designer_supportsInterface = async (interfaceId: BigNumberish) => {
		try {
			return await provider.call("lore", build_designer_supportsInterface_calldata(interfaceId));
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

	const build_game_token_createTrophies_calldata = (): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "create_trophies",
			calldata: [],
		};
	};

	const game_token_createTrophies = async (snAccount: Account | AccountInterface) => {
		try {
			return await provider.execute(
				snAccount,
				build_game_token_createTrophies_calldata(),
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

	const build_game_token_setMintingPaused_calldata = (isPaused: boolean): DojoCall => {
		return {
			contractName: "game_token",
			entrypoint: "set_minting_paused",
			calldata: [isPaused],
		};
	};

	const game_token_setMintingPaused = async (snAccount: Account | AccountInterface, isPaused: boolean) => {
		try {
			return await provider.execute(
				snAccount,
				build_game_token_setMintingPaused_calldata(isPaused),
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

	const build_trail_token_approve_calldata = (to: string, tokenId: BigNumberish): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "approve",
			calldata: [to, tokenId],
		};
	};

	const trail_token_approve = async (snAccount: Account | AccountInterface, to: string, tokenId: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_trail_token_approve_calldata(to, tokenId),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_availableSupply_calldata = (): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "availableSupply",
			calldata: [],
		};
	};

	const trail_token_availableSupply = async () => {
		try {
			return await provider.call("lore", build_trail_token_availableSupply_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_balanceOf_calldata = (account: string): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "balanceOf",
			calldata: [account],
		};
	};

	const trail_token_balanceOf = async (account: string) => {
		try {
			return await provider.call("lore", build_trail_token_balanceOf_calldata(account));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_contractUri_calldata = (): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "contractURI",
			calldata: [],
		};
	};

	const trail_token_contractUri = async () => {
		try {
			return await provider.call("lore", build_trail_token_contractUri_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_createTrail_calldata = (recipient: string): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "create_trail",
			calldata: [recipient],
		};
	};

	const trail_token_createTrail = async (snAccount: Account | AccountInterface, recipient: string) => {
		try {
			return await provider.execute(
				snAccount,
				build_trail_token_createTrail_calldata(recipient),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_createTrophies_calldata = (): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "create_trophies",
			calldata: [],
		};
	};

	const trail_token_createTrophies = async (snAccount: Account | AccountInterface) => {
		try {
			return await provider.execute(
				snAccount,
				build_trail_token_createTrophies_calldata(),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_defaultRoyalty_calldata = (): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "defaultRoyalty",
			calldata: [],
		};
	};

	const trail_token_defaultRoyalty = async () => {
		try {
			return await provider.call("lore", build_trail_token_defaultRoyalty_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_getApproved_calldata = (tokenId: BigNumberish): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "getApproved",
			calldata: [tokenId],
		};
	};

	const trail_token_getApproved = async (tokenId: BigNumberish) => {
		try {
			return await provider.call("lore", build_trail_token_getApproved_calldata(tokenId));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_isApprovedForAll_calldata = (owner: string, operator: string): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "isApprovedForAll",
			calldata: [owner, operator],
		};
	};

	const trail_token_isApprovedForAll = async (owner: string, operator: string) => {
		try {
			return await provider.call("lore", build_trail_token_isApprovedForAll_calldata(owner, operator));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_isMintedOut_calldata = (): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "is_minted_out",
			calldata: [],
		};
	};

	const trail_token_isMintedOut = async () => {
		try {
			return await provider.call("lore", build_trail_token_isMintedOut_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_isMintingPaused_calldata = (): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "is_minting_paused",
			calldata: [],
		};
	};

	const trail_token_isMintingPaused = async () => {
		try {
			return await provider.call("lore", build_trail_token_isMintingPaused_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_isOwnerOf_calldata = (address: string, tokenId: BigNumberish): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "is_owner_of",
			calldata: [address, tokenId],
		};
	};

	const trail_token_isOwnerOf = async (address: string, tokenId: BigNumberish) => {
		try {
			return await provider.call("lore", build_trail_token_isOwnerOf_calldata(address, tokenId));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_lastTokenId_calldata = (): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "last_token_id",
			calldata: [],
		};
	};

	const trail_token_lastTokenId = async () => {
		try {
			return await provider.call("lore", build_trail_token_lastTokenId_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_maxSupply_calldata = (): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "maxSupply",
			calldata: [],
		};
	};

	const trail_token_maxSupply = async () => {
		try {
			return await provider.call("lore", build_trail_token_maxSupply_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_mintedSupply_calldata = (): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "mintedSupply",
			calldata: [],
		};
	};

	const trail_token_mintedSupply = async () => {
		try {
			return await provider.call("lore", build_trail_token_mintedSupply_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_name_calldata = (): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "name",
			calldata: [],
		};
	};

	const trail_token_name = async () => {
		try {
			return await provider.call("lore", build_trail_token_name_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_ownerOf_calldata = (tokenId: BigNumberish): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "ownerOf",
			calldata: [tokenId],
		};
	};

	const trail_token_ownerOf = async (tokenId: BigNumberish) => {
		try {
			return await provider.call("lore", build_trail_token_ownerOf_calldata(tokenId));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_reservedSupply_calldata = (): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "reservedSupply",
			calldata: [],
		};
	};

	const trail_token_reservedSupply = async () => {
		try {
			return await provider.call("lore", build_trail_token_reservedSupply_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_royaltyInfo_calldata = (tokenId: BigNumberish, salePrice: BigNumberish): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "royaltyInfo",
			calldata: [tokenId, salePrice],
		};
	};

	const trail_token_royaltyInfo = async (tokenId: BigNumberish, salePrice: BigNumberish) => {
		try {
			return await provider.call("lore", build_trail_token_royaltyInfo_calldata(tokenId, salePrice));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_safeTransferFrom_calldata = (from: string, to: string, tokenId: BigNumberish, data: Array<BigNumberish>): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "safeTransferFrom",
			calldata: [from, to, tokenId, data],
		};
	};

	const trail_token_safeTransferFrom = async (snAccount: Account | AccountInterface, from: string, to: string, tokenId: BigNumberish, data: Array<BigNumberish>) => {
		try {
			return await provider.execute(
				snAccount,
				build_trail_token_safeTransferFrom_calldata(from, to, tokenId, data),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_setApprovalForAll_calldata = (operator: string, approved: boolean): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "setApprovalForAll",
			calldata: [operator, approved],
		};
	};

	const trail_token_setApprovalForAll = async (snAccount: Account | AccountInterface, operator: string, approved: boolean) => {
		try {
			return await provider.execute(
				snAccount,
				build_trail_token_setApprovalForAll_calldata(operator, approved),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_setMintingPaused_calldata = (isPaused: boolean): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "set_minting_paused",
			calldata: [isPaused],
		};
	};

	const trail_token_setMintingPaused = async (snAccount: Account | AccountInterface, isPaused: boolean) => {
		try {
			return await provider.execute(
				snAccount,
				build_trail_token_setMintingPaused_calldata(isPaused),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_supportsInterface_calldata = (interfaceId: BigNumberish): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "supports_interface",
			calldata: [interfaceId],
		};
	};

	const trail_token_supportsInterface = async (interfaceId: BigNumberish) => {
		try {
			return await provider.call("lore", build_trail_token_supportsInterface_calldata(interfaceId));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_symbol_calldata = (): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "symbol",
			calldata: [],
		};
	};

	const trail_token_symbol = async () => {
		try {
			return await provider.call("lore", build_trail_token_symbol_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_tokenRoyalty_calldata = (tokenId: BigNumberish): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "tokenRoyalty",
			calldata: [tokenId],
		};
	};

	const trail_token_tokenRoyalty = async (tokenId: BigNumberish) => {
		try {
			return await provider.call("lore", build_trail_token_tokenRoyalty_calldata(tokenId));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_tokenUri_calldata = (tokenId: BigNumberish): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "tokenURI",
			calldata: [tokenId],
		};
	};

	const trail_token_tokenUri = async (tokenId: BigNumberish) => {
		try {
			return await provider.call("lore", build_trail_token_tokenUri_calldata(tokenId));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_tokenExists_calldata = (tokenId: BigNumberish): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "token_exists",
			calldata: [tokenId],
		};
	};

	const trail_token_tokenExists = async (tokenId: BigNumberish) => {
		try {
			return await provider.call("lore", build_trail_token_tokenExists_calldata(tokenId));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_totalSupply_calldata = (): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "totalSupply",
			calldata: [],
		};
	};

	const trail_token_totalSupply = async () => {
		try {
			return await provider.call("lore", build_trail_token_totalSupply_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_transferFrom_calldata = (from: string, to: string, tokenId: BigNumberish): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "transferFrom",
			calldata: [from, to, tokenId],
		};
	};

	const trail_token_transferFrom = async (snAccount: Account | AccountInterface, from: string, to: string, tokenId: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_trail_token_transferFrom_calldata(from, to, tokenId),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_updateContractMetadata_calldata = (): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "update_contract_metadata",
			calldata: [],
		};
	};

	const trail_token_updateContractMetadata = async (snAccount: Account | AccountInterface) => {
		try {
			return await provider.execute(
				snAccount,
				build_trail_token_updateContractMetadata_calldata(),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_updateTokenMetadata_calldata = (tokenId: BigNumberish): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "update_token_metadata",
			calldata: [tokenId],
		};
	};

	const trail_token_updateTokenMetadata = async (snAccount: Account | AccountInterface, tokenId: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_trail_token_updateTokenMetadata_calldata(tokenId),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_trail_token_updateTokensMetadata_calldata = (fromTokenId: BigNumberish, toTokenId: BigNumberish): DojoCall => {
		return {
			contractName: "trail_token",
			entrypoint: "update_tokens_metadata",
			calldata: [fromTokenId, toTokenId],
		};
	};

	const trail_token_updateTokensMetadata = async (snAccount: Account | AccountInterface, fromTokenId: BigNumberish, toTokenId: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_trail_token_updateTokensMetadata_calldata(fromTokenId, toTokenId),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};



	return {
		actions_token: {
			allowance: actions_token_allowance,
			buildAllowanceCalldata: build_actions_token_allowance_calldata,
			approve: actions_token_approve,
			buildApproveCalldata: build_actions_token_approve_calldata,
			balanceOf: actions_token_balanceOf,
			buildBalanceOfCalldata: build_actions_token_balanceOf_calldata,
			calculateActionCost: actions_token_calculateActionCost,
			buildCalculateActionCostCalldata: build_actions_token_calculateActionCost_calldata,
			chargePlayerActions: actions_token_chargePlayerActions,
			buildChargePlayerActionsCalldata: build_actions_token_chargePlayerActions_calldata,
			claimActions: actions_token_claimActions,
			buildClaimActionsCalldata: build_actions_token_claimActions_calldata,
			claimFreeActions: actions_token_claimFreeActions,
			buildClaimFreeActionsCalldata: build_actions_token_claimFreeActions_calldata,
			claimRewards: actions_token_claimRewards,
			buildClaimRewardsCalldata: build_actions_token_claimRewards_calldata,
			decimals: actions_token_decimals,
			buildDecimalsCalldata: build_actions_token_decimals_calldata,
			getClaimableRewardsCount: actions_token_getClaimableRewardsCount,
			buildGetClaimableRewardsCountCalldata: build_actions_token_getClaimableRewardsCount_calldata,
			getFreeActionsCount: actions_token_getFreeActionsCount,
			buildGetFreeActionsCountCalldata: build_actions_token_getFreeActionsCount_calldata,
			mintTo: actions_token_mintTo,
			buildMintToCalldata: build_actions_token_mintTo_calldata,
			name: actions_token_name,
			buildNameCalldata: build_actions_token_name_calldata,
			sendRewards: actions_token_sendRewards,
			buildSendRewardsCalldata: build_actions_token_sendRewards_calldata,
			setActionCostAmount: actions_token_setActionCostAmount,
			buildSetActionCostAmountCalldata: build_actions_token_setActionCostAmount_calldata,
			setFreeActionClaimInterval: actions_token_setFreeActionClaimInterval,
			buildSetFreeActionClaimIntervalCalldata: build_actions_token_setFreeActionClaimInterval_calldata,
			setInitialFreeActionsCount: actions_token_setInitialFreeActionsCount,
			buildSetInitialFreeActionsCountCalldata: build_actions_token_setInitialFreeActionsCount_calldata,
			setMaxFreeActionsCount: actions_token_setMaxFreeActionsCount,
			buildSetMaxFreeActionsCountCalldata: build_actions_token_setMaxFreeActionsCount_calldata,
			setSnContract: actions_token_setSnContract,
			buildSetSnContractCalldata: build_actions_token_setSnContract_calldata,
			setTrailRewardActionsCount: actions_token_setTrailRewardActionsCount,
			buildSetTrailRewardActionsCountCalldata: build_actions_token_setTrailRewardActionsCount_calldata,
			symbol: actions_token_symbol,
			buildSymbolCalldata: build_actions_token_symbol_calldata,
			totalSupply: actions_token_totalSupply,
			buildTotalSupplyCalldata: build_actions_token_totalSupply_calldata,
			transfer: actions_token_transfer,
			buildTransferCalldata: build_actions_token_transfer_calldata,
			transferFrom: actions_token_transferFrom,
			buildTransferFromCalldata: build_actions_token_transferFrom_calldata,
		},
		designer: {
			approveProposal: designer_approveProposal,
			buildApproveProposalCalldata: build_designer_approveProposal_calldata,
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
			createHub: designer_createHub,
			buildCreateHubCalldata: build_designer_createHub_calldata,
			createInventoryItem: designer_createInventoryItem,
			buildCreateInventoryItemCalldata: build_designer_createInventoryItem_calldata,
			createParent: designer_createParent,
			buildCreateParentCalldata: build_designer_createParent_calldata,
			createPlayer: designer_createPlayer,
			buildCreatePlayerCalldata: build_designer_createPlayer_calldata,
			createReactable: designer_createReactable,
			buildCreateReactableCalldata: build_designer_createReactable_calldata,
			createTrail: designer_createTrail,
			buildCreateTrailCalldata: build_designer_createTrail_calldata,
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
			deleteHub: designer_deleteHub,
			buildDeleteHubCalldata: build_designer_deleteHub_calldata,
			deleteInventoryItem: designer_deleteInventoryItem,
			buildDeleteInventoryItemCalldata: build_designer_deleteInventoryItem_calldata,
			deleteParent: designer_deleteParent,
			buildDeleteParentCalldata: build_designer_deleteParent_calldata,
			deletePlayer: designer_deletePlayer,
			buildDeletePlayerCalldata: build_designer_deletePlayer_calldata,
			deleteReactable: designer_deleteReactable,
			buildDeleteReactableCalldata: build_designer_deleteReactable_calldata,
			deleteTrail: designer_deleteTrail,
			buildDeleteTrailCalldata: build_designer_deleteTrail_calldata,
			deleteTrigger: designer_deleteTrigger,
			buildDeleteTriggerCalldata: build_designer_deleteTrigger_calldata,
			getRoleAdmin: designer_getRoleAdmin,
			buildGetRoleAdminCalldata: build_designer_getRoleAdmin_calldata,
			grantAccessToEntity: designer_grantAccessToEntity,
			buildGrantAccessToEntityCalldata: build_designer_grantAccessToEntity_calldata,
			grantAccessToTrail: designer_grantAccessToTrail,
			buildGrantAccessToTrailCalldata: build_designer_grantAccessToTrail_calldata,
			grantRole: designer_grantRole,
			buildGrantRoleCalldata: build_designer_grantRole_calldata,
			hasRole: designer_hasRole,
			buildHasRoleCalldata: build_designer_hasRole_calldata,
			isAdmin: designer_isAdmin,
			buildIsAdminCalldata: build_designer_isAdmin_calldata,
			isEditor: designer_isEditor,
			buildIsEditorCalldata: build_designer_isEditor_calldata,
			registerPropertyRegistry: designer_registerPropertyRegistry,
			buildRegisterPropertyRegistryCalldata: build_designer_registerPropertyRegistry_calldata,
			rejectProposal: designer_rejectProposal,
			buildRejectProposalCalldata: build_designer_rejectProposal_calldata,
			renounceRole: designer_renounceRole,
			buildRenounceRoleCalldata: build_designer_renounceRole_calldata,
			revokeRole: designer_revokeRole,
			buildRevokeRoleCalldata: build_designer_revokeRole_calldata,
			setAdmin: designer_setAdmin,
			buildSetAdminCalldata: build_designer_setAdmin_calldata,
			setEditor: designer_setEditor,
			buildSetEditorCalldata: build_designer_setEditor_calldata,
			submitForReview: designer_submitForReview,
			buildSubmitForReviewCalldata: build_designer_submitForReview_calldata,
			supportsInterface: designer_supportsInterface,
			buildSupportsInterfaceCalldata: build_designer_supportsInterface_calldata,
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
			createTrophies: game_token_createTrophies,
			buildCreateTrophiesCalldata: build_game_token_createTrophies_calldata,
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
			setMintingPaused: game_token_setMintingPaused,
			buildSetMintingPausedCalldata: build_game_token_setMintingPaused_calldata,
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
		trail_token: {
			approve: trail_token_approve,
			buildApproveCalldata: build_trail_token_approve_calldata,
			availableSupply: trail_token_availableSupply,
			buildAvailableSupplyCalldata: build_trail_token_availableSupply_calldata,
			balanceOf: trail_token_balanceOf,
			buildBalanceOfCalldata: build_trail_token_balanceOf_calldata,
			contractUri: trail_token_contractUri,
			buildContractUriCalldata: build_trail_token_contractUri_calldata,
			createTrail: trail_token_createTrail,
			buildCreateTrailCalldata: build_trail_token_createTrail_calldata,
			createTrophies: trail_token_createTrophies,
			buildCreateTrophiesCalldata: build_trail_token_createTrophies_calldata,
			defaultRoyalty: trail_token_defaultRoyalty,
			buildDefaultRoyaltyCalldata: build_trail_token_defaultRoyalty_calldata,
			getApproved: trail_token_getApproved,
			buildGetApprovedCalldata: build_trail_token_getApproved_calldata,
			isApprovedForAll: trail_token_isApprovedForAll,
			buildIsApprovedForAllCalldata: build_trail_token_isApprovedForAll_calldata,
			isMintedOut: trail_token_isMintedOut,
			buildIsMintedOutCalldata: build_trail_token_isMintedOut_calldata,
			isMintingPaused: trail_token_isMintingPaused,
			buildIsMintingPausedCalldata: build_trail_token_isMintingPaused_calldata,
			isOwnerOf: trail_token_isOwnerOf,
			buildIsOwnerOfCalldata: build_trail_token_isOwnerOf_calldata,
			lastTokenId: trail_token_lastTokenId,
			buildLastTokenIdCalldata: build_trail_token_lastTokenId_calldata,
			maxSupply: trail_token_maxSupply,
			buildMaxSupplyCalldata: build_trail_token_maxSupply_calldata,
			mintedSupply: trail_token_mintedSupply,
			buildMintedSupplyCalldata: build_trail_token_mintedSupply_calldata,
			name: trail_token_name,
			buildNameCalldata: build_trail_token_name_calldata,
			ownerOf: trail_token_ownerOf,
			buildOwnerOfCalldata: build_trail_token_ownerOf_calldata,
			reservedSupply: trail_token_reservedSupply,
			buildReservedSupplyCalldata: build_trail_token_reservedSupply_calldata,
			royaltyInfo: trail_token_royaltyInfo,
			buildRoyaltyInfoCalldata: build_trail_token_royaltyInfo_calldata,
			safeTransferFrom: trail_token_safeTransferFrom,
			buildSafeTransferFromCalldata: build_trail_token_safeTransferFrom_calldata,
			setApprovalForAll: trail_token_setApprovalForAll,
			buildSetApprovalForAllCalldata: build_trail_token_setApprovalForAll_calldata,
			setMintingPaused: trail_token_setMintingPaused,
			buildSetMintingPausedCalldata: build_trail_token_setMintingPaused_calldata,
			supportsInterface: trail_token_supportsInterface,
			buildSupportsInterfaceCalldata: build_trail_token_supportsInterface_calldata,
			symbol: trail_token_symbol,
			buildSymbolCalldata: build_trail_token_symbol_calldata,
			tokenRoyalty: trail_token_tokenRoyalty,
			buildTokenRoyaltyCalldata: build_trail_token_tokenRoyalty_calldata,
			tokenUri: trail_token_tokenUri,
			buildTokenUriCalldata: build_trail_token_tokenUri_calldata,
			tokenExists: trail_token_tokenExists,
			buildTokenExistsCalldata: build_trail_token_tokenExists_calldata,
			totalSupply: trail_token_totalSupply,
			buildTotalSupplyCalldata: build_trail_token_totalSupply_calldata,
			transferFrom: trail_token_transferFrom,
			buildTransferFromCalldata: build_trail_token_transferFrom_calldata,
			updateContractMetadata: trail_token_updateContractMetadata,
			buildUpdateContractMetadataCalldata: build_trail_token_updateContractMetadata_calldata,
			updateTokenMetadata: trail_token_updateTokenMetadata,
			buildUpdateTokenMetadataCalldata: build_trail_token_updateTokenMetadata_calldata,
			updateTokensMetadata: trail_token_updateTokensMetadata,
			buildUpdateTokensMetadataCalldata: build_trail_token_updateTokensMetadata_calldata,
		},
	};
}