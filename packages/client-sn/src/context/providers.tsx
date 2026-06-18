import type { PropsWithChildren } from "react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { StarknetProvider } from "@/context/starknet-provider";
import { TokensProvider } from "@/context/tokens-provider";

const queryClient = new QueryClient();

export function Providers({ children }: PropsWithChildren) {
	return (
		<QueryClientProvider client={queryClient}>
			<StarknetProvider>
				<TokensProvider>
					{children}
				</TokensProvider>
			</StarknetProvider>
		</QueryClientProvider>
	);
}
