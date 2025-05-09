import { schema } from "@lib/dojo_bindings/typescript/models.gen";
import manifestJson from "@lore/contracts/manifest";
import type manifestJsonType from "@lore/contracts/manifest_dev.json";
import { cleanEnv, str, url } from "envalid";
import { Account, Contract, RpcProvider } from "starknet";

const getOrFail = <T>(value: T | undefined, name?: string): T => {
	if (value === undefined || value === null) {
		throw new Error(name ? `Value {${name}} is undefined` : "Value is undefined");
	}
	return value;
};

const slotEnv = import.meta.env.MODE === "slot" ? { VITE_SLOT: str() } : {};
const isLocalhost = window.location.hostname === "localhost";
const isEditor = window.location.pathname.startsWith("/editor");

const env = cleanEnv(import.meta.env, {
	VITE_CONTROLLER_CHAINID: str(),
	VITE_TOKEN_HTTP_RPC: url(),
	VITE_TOKEN_CONTRACT_ADDRESS: str(),
	VITE_KATANA_HTTP_RPC: str(),
	VITE_TORII_HTTP_RPC: url(),
	VITE_TORII_WS_RPC: str(),
	VITE_BURNER_ADDRESS: str(),
	VITE_BURNER_PRIVATE_KEY: str(),
	...slotEnv,
});

const endpoints = {
	katana: isLocalhost ? "/katana" : env.VITE_KATANA_HTTP_RPC,
	torii: {
		http: env.VITE_TORII_HTTP_RPC,
		ws: env.VITE_TORII_WS_RPC,
	},
};

const katanaProvider = new RpcProvider({
	nodeUrl: isLocalhost ? "/katana" : env.VITE_KATANA_HTTP_RPC,
	headers: {
		//nocors
		"Access-Control-Allow-Origin": "*",
		mode: "no-cors",
	},
});

// @dev: for future ref we can dynamically import manifest as well
// const mf = await import("@lore/contracts/manifest_dev.json");
// console.log(mf.default);
const manifest = {
	default: manifestJson as typeof manifestJsonType,
	entity: getOrFail(
		manifestJson.contracts.find((c) => c.tag === "lore-prompt"),
		"lore-prompt",
	),
	designer: getOrFail(
		manifestJson.contracts.find((c) => c.tag === "lore-designer"),
		"lore-designer",
	),
	world: manifestJson.world,
};

const wallet = (() => {
	const address = env.VITE_BURNER_ADDRESS;
	const private_key = env.VITE_BURNER_PRIVATE_KEY;
	const account = new Account(katanaProvider, address, private_key);
	return {
		address,
		private_key,
		account,
	};
})();

const entity = new Contract(
	manifest.entity.abi,
	manifest.entity.address,
	katanaProvider,
);

entity.connect(wallet.account);

const designer = new Contract(
	manifest.designer.abi,
	manifest.designer.address,
	katanaProvider,
);

designer.connect(wallet.account);

export const LORE_CONFIG = {
	endpoints,
	katanaProvider,
	contracts: {
		entity,
		designer,
	},
	wallet,
	manifest,
	schema,
	token: {
		provider: env.VITE_TOKEN_HTTP_RPC,
		chainId: env.VITE_CONTROLLER_CHAINID,
		// Contract address
		contract_address: env.VITE_TOKEN_CONTRACT_ADDRESS,
		erc20: ["0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7"],
	},
	useController: import.meta.env.MODE === "slot",
	env: env,
	LOCALHOST: isLocalhost,
	EDITOR_MODE: isEditor,
};
