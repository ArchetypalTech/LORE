import type { PropsWithChildren } from "react";
import { jsonRpcProvider, StarknetConfig } from "@starknet-react/core";
import { controllerConnector } from "@/dojo/connector";
import { selectedProfileConfig } from "@/dojo/dojoConfig";

const provider = jsonRpcProvider({
	rpc: () => ({ nodeUrl: selectedProfileConfig.rpcUrl }),
});

export function StarknetProvider({ children }: PropsWithChildren) {
	return (
		<StarknetConfig
			autoConnect
			chains={[selectedProfileConfig.chain]}
			connectors={[controllerConnector]}
			provider={provider}
		>
			{children}
		</StarknetConfig>
	);
}
