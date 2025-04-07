import type { DojoCall, DojoProvider } from "@dojoengine/core";
import {
	type Account,
	type AccountInterface,
	type BigNumberish,
	type ByteArray,
	CairoCustomEnum,
	CairoOption,
} from "starknet";
import * as models from "./models.gen";

export function setupWorld(provider: DojoProvider) {
	const build_designer_createArea_calldata = (t: Array<Area>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "create_area",
			calldata: [t],
		};
	};

	const designer_createArea = async (
		snAccount: Account | AccountInterface,
		t: Array<Area>,
	) => {
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

	const build_designer_createEntity_calldata = (t: Array<Entity>): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "create_entity",
			calldata: [t],
		};
	};

	const designer_createEntity = async (
		snAccount: Account | AccountInterface,
		t: Array<Entity>,
	) => {
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

	const designer_createExit = async (
		snAccount: Account | AccountInterface,
		t: Array<Exit>,
	) => {
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

	const build_designer_createInspectable_calldata = (
		t: Array<Inspectable>,
	): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "create_inspectable",
			calldata: [t],
		};
	};

	const designer_createInspectable = async (
		snAccount: Account | AccountInterface,
		t: Array<Inspectable>,
	) => {
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

	const build_designer_deleteArea_calldata = (
		ids: Array<BigNumberish>,
	): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "delete_area",
			calldata: [ids],
		};
	};

	const designer_deleteArea = async (
		snAccount: Account | AccountInterface,
		ids: Array<BigNumberish>,
	) => {
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

	const build_designer_deleteEntity_calldata = (
		ids: Array<BigNumberish>,
	): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "delete_entity",
			calldata: [ids],
		};
	};

	const designer_deleteEntity = async (
		snAccount: Account | AccountInterface,
		ids: Array<BigNumberish>,
	) => {
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

	const build_designer_deleteExit_calldata = (
		ids: Array<BigNumberish>,
	): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "delete_exit",
			calldata: [ids],
		};
	};

	const designer_deleteExit = async (
		snAccount: Account | AccountInterface,
		ids: Array<BigNumberish>,
	) => {
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

	const build_designer_deleteInspectable_calldata = (
		ids: Array<BigNumberish>,
	): DojoCall => {
		return {
			contractName: "designer",
			entrypoint: "delete_inspectable",
			calldata: [ids],
		};
	};

	const designer_deleteInspectable = async (
		snAccount: Account | AccountInterface,
		ids: Array<BigNumberish>,
	) => {
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

	const build_prompt_prompt_calldata = (cmd: ByteArray): DojoCall => {
		return {
			contractName: "prompt",
			entrypoint: "prompt",
			calldata: [cmd],
		};
	};

	const prompt_prompt = async (
		snAccount: Account | AccountInterface,
		cmd: ByteArray,
	) => {
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
			createArea: designer_createArea,
			buildCreateAreaCalldata: build_designer_createArea_calldata,
			createEntity: designer_createEntity,
			buildCreateEntityCalldata: build_designer_createEntity_calldata,
			createExit: designer_createExit,
			buildCreateExitCalldata: build_designer_createExit_calldata,
			createInspectable: designer_createInspectable,
			buildCreateInspectableCalldata: build_designer_createInspectable_calldata,
			deleteArea: designer_deleteArea,
			buildDeleteAreaCalldata: build_designer_deleteArea_calldata,
			deleteEntity: designer_deleteEntity,
			buildDeleteEntityCalldata: build_designer_deleteEntity_calldata,
			deleteExit: designer_deleteExit,
			buildDeleteExitCalldata: build_designer_deleteExit_calldata,
			deleteInspectable: designer_deleteInspectable,
			buildDeleteInspectableCalldata: build_designer_deleteInspectable_calldata,
		},
		prompt: {
			prompt: prompt_prompt,
			buildPromptCalldata: build_prompt_prompt_calldata,
		},
	};
}
