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

	const build_designer_createInspectable_calldata = (t: Array<Inspectable>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "create_inspectable",
			calldata: [t],
		};
	};

	const designer_createInspectable = async (snAccount: Account | AccountInterface, t: Array<Inspectable>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_createInspectable_calldata(t),
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

	const build_designer_deleteInspectable_calldata = (ids: Array<BigNumberish>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "delete_inspectable",
			calldata: [ids],
		};
	};

	const designer_deleteInspectable = async (snAccount: Account | AccountInterface, ids: Array<BigNumberish>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_deleteInspectable_calldata(ids),
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

	const build_prompt_prompt_calldata = (cmd: string): DojoCall => {
		return {
			contractName: "prompt",
			entrypoint: "prompt",
			calldata: [cmd],
		};
	};

	const prompt_prompt = async (snAccount: Account | AccountInterface, cmd: string) => {
		try {
			return await provider.execute(
				snAccount,
				build_prompt_prompt_calldata(cmd),
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
			createEffect: designer_createEffect,
			buildCreateEffectCalldata: build_designer_createEffect_calldata,
			createEntity: designer_createEntity,
			buildCreateEntityCalldata: build_designer_createEntity_calldata,
			createExit: designer_createExit,
			buildCreateExitCalldata: build_designer_createExit_calldata,
			createInspectable: designer_createInspectable,
			buildCreateInspectableCalldata: build_designer_createInspectable_calldata,
			createInventoryItem: designer_createInventoryItem,
			buildCreateInventoryItemCalldata: build_designer_createInventoryItem_calldata,
			createParent: designer_createParent,
			buildCreateParentCalldata: build_designer_createParent_calldata,
			createPlayer: designer_createPlayer,
			buildCreatePlayerCalldata: build_designer_createPlayer_calldata,
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
			deleteEffect: designer_deleteEffect,
			buildDeleteEffectCalldata: build_designer_deleteEffect_calldata,
			deleteEntity: designer_deleteEntity,
			buildDeleteEntityCalldata: build_designer_deleteEntity_calldata,
			deleteExit: designer_deleteExit,
			buildDeleteExitCalldata: build_designer_deleteExit_calldata,
			deleteInspectable: designer_deleteInspectable,
			buildDeleteInspectableCalldata: build_designer_deleteInspectable_calldata,
			deleteInventoryItem: designer_deleteInventoryItem,
			buildDeleteInventoryItemCalldata: build_designer_deleteInventoryItem_calldata,
			deleteParent: designer_deleteParent,
			buildDeleteParentCalldata: build_designer_deleteParent_calldata,
			deletePlayer: designer_deletePlayer,
			buildDeletePlayerCalldata: build_designer_deletePlayer_calldata,
			deleteTrigger: designer_deleteTrigger,
			buildDeleteTriggerCalldata: build_designer_deleteTrigger_calldata,
			registerPropertyRegistry: designer_registerPropertyRegistry,
			buildRegisterPropertyRegistryCalldata: build_designer_registerPropertyRegistry_calldata,
		},
		prompt: {
			prompt: prompt_prompt,
			buildPromptCalldata: build_prompt_prompt_calldata,
		},
	};
}