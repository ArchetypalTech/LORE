import {
	getProfileEnv,
	stringToFelt,
} from "./common.ts";

export const buildEnv = async (profile: string) => {
	console.log(`:: PROFILE [${profile}]`);
	const seed = await getProfileEnv(profile, "seed");
	const SAYA_SALT = stringToFelt(seed ?? "");
	const SETTLEMENT_RPC_URL = await getProfileEnv(profile, "rpc_url");
	const SETTLEMENT_CHAIN_ID = await getProfileEnv(profile, "settlement_chain_id");
	const CORE_CONTRACT_ADDRESS = await getProfileEnv(profile, "core_contract_address");
	const CORE_CONTRACT_DEPLOYED_BLOCK = await getProfileEnv(profile, "core_contract_deployed_block");
	const FACT_REGISTRY_ADDRESS = await getProfileEnv(profile, "fact_registry_address");
	const APPCHAIN_ID = await getProfileEnv(profile, "appchain_id");
	const APPCHAIN_CONFIG_PATH = `./data/${APPCHAIN_ID}`;
	const KATANA_L3_BIN = `./bin/katana-1.7.0-snos.4`;
	const SLOT_SERVICE_NAME = (APPCHAIN_ID ?? '').replaceAll("_", "-");
	
	console.log(`:: SETTLEMENT_CHAIN_ID (L2) [${SETTLEMENT_CHAIN_ID}]`);
	console.log(`:: APPCHAIN_ID (L3) [${APPCHAIN_ID}]`);

	// required env:
	// SETTLEMENT_ACCOUNT_ADDRESS:...
	// SETTLEMENT_ACCOUNT_PRIVATE_KEY:...
	const env = {
		// secrets, from .env
		SETTLEMENT_ACCOUNT_ADDRESS: import.meta.env.SETTLEMENT_ACCOUNT_ADDRESS,
		SETTLEMENT_ACCOUNT_PRIVATE_KEY: import.meta.env.SETTLEMENT_ACCOUNT_PRIVATE_KEY,
		DOJO_ACCOUNT_ADDRESS: import.meta.env.DOJO_ACCOUNT_ADDRESS,
		DOJO_PRIVATE_KEY: import.meta.env.DOJO_PRIVATE_KEY,
		// used by sozo and saya
		SETTLEMENT_CHAIN_ID,
		SETTLEMENT_RPC_URL,
		CORE_CONTRACT_ADDRESS,
		CORE_CONTRACT_DEPLOYED_BLOCK,
		FACT_REGISTRY_ADDRESS,
		// required parameters
		SAYA_SALT,
		APPCHAIN_ID,
		APPCHAIN_CONFIG_PATH,
		KATANA_L3_BIN,
		SLOT_SERVICE_NAME,
	}

	return env;
};
