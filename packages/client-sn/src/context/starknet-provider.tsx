import type { PropsWithChildren } from "react";
import { sepolia } from "@starknet-react/chains";
import { jsonRpcProvider, StarknetConfig } from "@starknet-react/core";
import { controllerConnector } from "@/dojo/connector";
import { RPC_URL } from "@/dojo/dojoConfig";

const provider = jsonRpcProvider({ rpc: () => ({ nodeUrl: RPC_URL }) });

export function StarknetProvider({ children }: PropsWithChildren) {
	return (
		<StarknetConfig
			autoConnect
			chains={[sepolia]}
			connectors={[controllerConnector]}
			provider={provider}
		>
			{children}
		</StarknetConfig>
	);
}
