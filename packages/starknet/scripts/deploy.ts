import { getProfileEnv, runProcess, stringToFelt } from "./common.ts";

const PROFILE = process.argv[2];

export const deployStarknet = async () => {
	console.log(`:: DEPLOY profile [${PROFILE}]`);
	const seed = await getProfileEnv(PROFILE, "seed");
	const salt = stringToFelt(seed ?? "");
	const rpc_url = await getProfileEnv(PROFILE, "rpc_url");
	const settlement_chain_id = await getProfileEnv(PROFILE, "settlement_chain_id");
	const appchain_id = await getProfileEnv(PROFILE, "appchain_id");
	const core_contract_address = await getProfileEnv(PROFILE, "core_contract_address");
	const core_contract_deployed_block = await getProfileEnv(PROFILE, "core_contract_deployed_block");
	const fact_registry_address = await getProfileEnv(PROFILE, "fact_registry_address");
	
	console.log(`:: settlement_chain_id [${settlement_chain_id}]`);
	console.log(`:: appchain_id [${appchain_id}]`);
	console.log(`:: seed [${seed}]`);
	console.log(`:: salt [${salt}]`);

	// required env:
	// SETTLEMENT_ACCOUNT_ADDRESS:...
	// SETTLEMENT_ACCOUNT_PRIVATE_KEY:...
	const env = {
		SETTLEMENT_ACCOUNT_ADDRESS: import.meta.env.SETTLEMENT_ACCOUNT_ADDRESS,
		SETTLEMENT_ACCOUNT_PRIVATE_KEY: import.meta.env.SETTLEMENT_ACCOUNT_PRIVATE_KEY,
		SETTLEMENT_CHAIN_ID: settlement_chain_id,
		SETTLEMENT_RPC_URL: rpc_url,
		CORE_CONTRACT_ADDRESS: core_contract_address,
		CORE_CONTRACT_DEPLOYED_BLOCK: core_contract_deployed_block,
		FACT_REGISTRY_ADDRESS: fact_registry_address,
	}

	if (!salt) throw new Error(`!! seed not found for profile [${PROFILE}]`);
	if (!settlement_chain_id) throw new Error(`!! settlement_chain_id not found for profile [${PROFILE}]`);
	if (!appchain_id) throw new Error(`!! appchain_id not found for profile [${PROFILE}]`);
	if (!rpc_url) throw new Error(`!! rpc_url not found for profile [${PROFILE}]`);
	if (!env.SETTLEMENT_ACCOUNT_ADDRESS) throw new Error(`!! SETTLEMENT_ACCOUNT_ADDRESS env variable not set`);
	if (!env.SETTLEMENT_ACCOUNT_PRIVATE_KEY) throw new Error(`!! SETTLEMENT_ACCOUNT_PRIVATE_KEY env variable not set`);

	// Deploy core contract (once)
	console.log(`::`);
	console.log(`:: Deploying core contract...`, env);
	await runProcess(`saya core-contract declare`, env);
	await runProcess(`saya core-contract deploy --salt ${salt}`, env);
	// core_contract_address is printed...
	if (!core_contract_address) throw new Error(`!! core_contract_address not found for profile [${PROFILE}]`);
	if (!core_contract_deployed_block) throw new Error(`!! core_contract_deployed_block not found for profile [${PROFILE}]`);
	if (!fact_registry_address) throw new Error(`!! fact_registry_address not found for profile [${PROFILE}]`);
	console.log(`:: Setting up program...`);
	await runProcess(`saya core-contract setup-program --chain-id ${appchain_id}`, env);

	// Deploy Dojo contracts
	console.log(`:: DEPLOYING DOJO CONTRACTS`);
	await runProcess(`sozo build --profile ${PROFILE} --typescript`);
	await runProcess(`sozo inspect --profile ${PROFILE}`);
	await runProcess(`sozo migrate --profile ${PROFILE}`);
};

await deployStarknet();
