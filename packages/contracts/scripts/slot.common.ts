import { log } from "@clack/prompts";
import { bgDarkGray, bgGreen, white } from "ansicolor";
import { config, runCommands } from "./common";

const _exit = (message: string) => {
	log.error(message);
	process.exit(1);
}

export const rpcUrl = config.profile_config.rpcUrl;
export const slotName = config.profile_config.slotName;
export const worldAddress = config.profile_config.contractAddresses.world;
export const gameTokenAddress = config.profile_config.contractAddresses.game_token;
export const trailTokenAddress = config.profile_config.contractAddresses.trail_token;

if (!rpcUrl) _exit(`Missing: ${bgDarkGray(white("RPC URL"))}`);
if (!slotName) _exit(`Missing: ${bgDarkGray(white("Slot Name"))}`);
if (!BigInt(worldAddress ?? 0)) _exit(`Missing: ${bgDarkGray(white("World Address"))}`);
if (!BigInt(gameTokenAddress ?? 0)) _exit(`Missing: ${bgDarkGray(white("Game Token Address"))}`);
if (!BigInt(trailTokenAddress ?? 0)) _exit(`Missing: ${bgDarkGray(white("Trail Token Address"))}`);

export const cmd_deploy_slot = [
	`slot deployments create ${slotName} katana --version ${config.katana_version}`,
	`slot deployments create ${slotName} torii --version ${config.torii_version} --world ${worldAddress} --rpc ${rpcUrl} --indexing.transactions --indexing.contracts erc721:${gameTokenAddress},erc721:${trailTokenAddress}  --sql.historical lore-TrophyProgression`,
	`slot deployments list`,
];
export const cmd_view_slot = [`slot deployments list`];

const parseServiceEntries = (
	input: string,
): { Project: string; Service: string }[] =>
	input
		.split("---")
		.filter(Boolean)
		.map((section) =>
			Object.fromEntries(
				section
					.trim()
					.split("\n")
					.map((line) => line.split(":").map((part) => part.trim()))
					.filter((pair) => pair.length === 2),
			),
		) as { Project: string; Service: string }[];

// Check if we have existing Katana and/or Torii services for this namespace

export const getSlotServices = async () => {
	const services = parseServiceEntries(
		await runCommands(cmd_view_slot, true, true),
	);
	const slotServices = services
		.filter((service) => service.Project === slotName)
		.map((service) => service.Service);
	return slotServices;
};

export const runSlotDeployment = async () => {
	const slotServices = await getSlotServices();

	const hasKatana = slotServices.includes("katana");
	const hasTorii = slotServices.includes("torii");
	if (!hasKatana || !hasTorii) {
		log.error("No existing Slot deployments found");
		process.exit(1);
	}
	log.info(bgGreen(` 🪐 Deploying Contracts to slot `));
	await runCommands(
		[
			`sozo build --profile ${config.mode} --typescript --bindings-output ../client/src/lib/dojo_bindings/`,
		],
		false,
		false,
	);
	await runCommands([`sozo migrate --profile ${config.mode}`]);
	await runCommands([`scarb --profile ${config.mode} run post_migrate`], false, false);
	await runCommands([`sozo inspect --profile ${config.mode}`], false, false);
	await runCommands([`starkli chain-id --rpc ${rpcUrl}`], false, false);
	await runCommands(cmd_view_slot);
};
