import {
	runProcess,
	fileExistsAsync,
} from "./common.ts";
import { buildEnv } from "./env.ts";

const PROFILE = process.argv[2];

export const deployCoreContract = async () => {
	const env = await buildEnv(PROFILE);

	if (!env.SAYA_SALT) throw new Error(`!! SAYA_SALT not found for profile [${PROFILE}]`);
	if (!env.SETTLEMENT_CHAIN_ID) throw new Error(`!! SETTLEMENT_CHAIN_ID not found for profile [${PROFILE}]`);
	if (!env.APPCHAIN_ID) throw new Error(`!! APPCHAIN_ID not found for profile [${PROFILE}]`);
	if (!env.SETTLEMENT_RPC_URL) throw new Error(`!! SETTLEMENT_RPC_URL not found for profile [${PROFILE}]`);
	if (!env.SETTLEMENT_ACCOUNT_ADDRESS) throw new Error(`!! SETTLEMENT_ACCOUNT_ADDRESS env variable not set`);
	if (!env.SETTLEMENT_ACCOUNT_PRIVATE_KEY) throw new Error(`!! SETTLEMENT_ACCOUNT_PRIVATE_KEY env variable not set`);

	// Deploy core contract (once)
	console.log(`::`);
	console.log(`:: Deploying core contract...`, env);
	await runProcess(`saya core-contract declare`, env);
	await runProcess(`saya core-contract deploy --salt ${env.SAYA_SALT}`, env);
	// core_contract_address is printed...
	if (!env.CORE_CONTRACT_ADDRESS) throw new Error(`!! CORE_CONTRACT_ADDRESS not found for profile [${PROFILE}]`);
	if (!env.CORE_CONTRACT_DEPLOYED_BLOCK) throw new Error(`!! CORE_CONTRACT_DEPLOYED_BLOCK not found for profile [${PROFILE}]`);
	if (!env.FACT_REGISTRY_ADDRESS) throw new Error(`!! FACT_REGISTRY_ADDRESS not found for profile [${PROFILE}]`);
	console.log(`:: Setting up program...`);
	await runProcess(`saya core-contract setup-program --chain-id ${env.APPCHAIN_ID}`, env);

	// Build appchain config
	console.log(`::`);
	console.log(`:: Building appchain config...`);
	if (!env.APPCHAIN_CONFIG_PATH) throw new Error(`!! APPCHAIN_CONFIG_PATH not found for profile [${PROFILE}]`);
	if (!await fileExistsAsync(env.KATANA_L3_BIN)) throw new Error(`!! KATANA_L3_BIN not found [${env.KATANA_L3_BIN}]`);
	const cmd = [
		env.KATANA_L3_BIN,
		`init`,
		`--settlement-chain ${env.SETTLEMENT_RPC_URL}`,
		`--id ${env.APPCHAIN_ID}`,
		`--settlement-contract ${env.CORE_CONTRACT_ADDRESS}`,
		`--settlement-contract-deployed-block ${env.CORE_CONTRACT_DEPLOYED_BLOCK}`,
		`--settlement-facts-registry ${env.FACT_REGISTRY_ADDRESS}`,
		`--output-path ${env.APPCHAIN_CONFIG_PATH}`
	]
	await runProcess(cmd.join(" "), env);
	await runProcess(`ls -l ${env.APPCHAIN_CONFIG_PATH}`, env);
};

export const deployDojoContracts = async () => {
	const env = await buildEnv(PROFILE);

	if (!env.DOJO_ACCOUNT_ADDRESS) throw new Error(`!! DOJO_ACCOUNT_ADDRESS env variable not set`);
	if (!env.DOJO_PRIVATE_KEY) throw new Error(`!! DOJO_PRIVATE_KEY env variable not set`);

	// Deploy Dojo contracts
	console.log(`::`);
	console.log(`:: DEPLOYING DOJO CONTRACTS`);
	await runProcess(`sozo build --profile ${PROFILE} --typescript`);
	await runProcess(`sozo inspect --profile ${PROFILE}`);
	await runProcess(`sozo migrate --profile ${PROFILE}`);
};

await deployCoreContract();
await deployDojoContracts();
