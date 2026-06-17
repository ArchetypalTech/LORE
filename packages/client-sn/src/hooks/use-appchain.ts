import { useMemo } from "react";
import { RpcProvider } from "starknet";
import { PROFILE } from "@/dojo/dojoConfig";

export function useAppchainProvider() {
	const provider = useMemo(() => {
      return new RpcProvider({
        nodeUrl: PROFILE.rpcUrl.appchain,
      })
	}, []);
	return provider;
}
