import type { PropsWithChildren } from "react";
import { jsonRpcProvider, StarknetConfig } from "@starknet-react/core";
import { controllerConnector } from "@/dojo/connector";
import { PROFILE } from "@/dojo/dojoConfig";

const provider = jsonRpcProvider({
	rpc: () => ({ nodeUrl: PROFILE.rpcUrl.starknet }),
});

export function StarknetProvider({ children }: PropsWithChildren) {
	return (
		<StarknetConfig
			autoConnect
			chains={[PROFILE.chain]}
			connectors={[controllerConnector]}
			provider={provider}
		>
			{children}
		</StarknetConfig>
	);
}
