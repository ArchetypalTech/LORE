import {
	runProcess,
} from "./common.ts";
import { buildEnv } from "./env.ts";

const PROFILE = process.argv[2];

const KATANA_TIER = "basic";
// const TORII_TIER = "basic";

export const deployKatana = async () => {
	const env = await buildEnv(PROFILE);

	if (!env.DOJO_ACCOUNT_ADDRESS) throw new Error(`!! DOJO_ACCOUNT_ADDRESS env variable not set`);
	if (!env.DOJO_PRIVATE_KEY) throw new Error(`!! DOJO_PRIVATE_KEY env variable not set`);

	// Deploy Dojo contracts
	console.log(`::`);
	console.log(`:: Creating Katana instance...`);
	const cmd = [
		`slot deployments create`,
		`--tier ${KATANA_TIER}`,
		`${env.SLOT_SERVICE_NAME}`,
		`katana`,
		`--config ${env.APPCHAIN_CONFIG_PATH}/config.toml`
	]
	await runProcess(cmd.join(" "), env);
	await runProcess(`slot deployments describe ${env.SLOT_SERVICE_NAME} katana`);
};

await deployKatana();
// await deployTorii();
