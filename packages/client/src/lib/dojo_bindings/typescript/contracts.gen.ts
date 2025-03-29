import { DojoProvider, DojoCall } from "@dojoengine/core";
import { Account, AccountInterface, BigNumberish, CairoOption, CairoCustomEnum, ByteArray } from "starknet";
import * as models from "./models.gen";

export function setupWorld(provider: DojoProvider) {

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

	const build_designer_deleteEntities_calldata = (ids: Array<BigNumberish>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "delete_entities",
			calldata: [ids],
		};
	};

	const designer_deleteEntities = async (snAccount: Account | AccountInterface, ids: Array<BigNumberish>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_deleteEntities_calldata(ids),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_designer_deleteInspectables_calldata = (ids: Array<BigNumberish>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "delete_inspectables",
			calldata: [ids],
		};
	};

	const designer_deleteInspectables = async (snAccount: Account | AccountInterface, ids: Array<BigNumberish>) => {
		try {
			return await provider.execute(
				snAccount,
				build_designer_deleteInspectables_calldata(ids),
				"lore",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_prompt_prompt_calldata = (cmd: ByteArray): DojoCall => {
		return {
			contractName: "prompt",
			entrypoint: "prompt",
			calldata: [cmd],
		};
	};

	const prompt_prompt = async (snAccount: Account | AccountInterface, cmd: ByteArray) => {
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
			createEntity: designer_createEntity,
			buildCreateEntityCalldata: build_designer_createEntity_calldata,
			createInspectable: designer_createInspectable,
			buildCreateInspectableCalldata: build_designer_createInspectable_calldata,
			deleteEntities: designer_deleteEntities,
			buildDeleteEntitiesCalldata: build_designer_deleteEntities_calldata,
			deleteInspectables: designer_deleteInspectables,
			buildDeleteInspectablesCalldata: build_designer_deleteInspectables_calldata,
		},
		prompt: {
			prompt: prompt_prompt,
			buildPromptCalldata: build_prompt_prompt_calldata,
		},
	};
}