import type { PropsWithChildren } from "react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { StarknetProvider } from "@/context/starknet-provider";
import { TokensProvider } from "@/context/tokens-provider";
import { ToriiAppchainProvider } from "@/context/torii-appchain-provider";
import { ToriiStarknetProvider } from "@/context/torii-starknet-provider";

const queryClient = new QueryClient();

export function Providers({ children }: PropsWithChildren) {
	return (
		<QueryClientProvider client={queryClient}>
			<StarknetProvider>
				<ToriiStarknetProvider>
					<ToriiAppchainProvider>
						<TokensProvider>
							{children}
						</TokensProvider>
					</ToriiAppchainProvider>
				</ToriiStarknetProvider>
			</StarknetProvider>
		</QueryClientProvider>
	);
}
