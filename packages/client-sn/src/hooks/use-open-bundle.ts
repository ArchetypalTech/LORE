import type ControllerConnector from "@cartridge/connector/controller";
import { useAccount } from "@starknet-react/core";
import { useQueryClient } from "@tanstack/react-query";
import { useCallback } from "react";
import { selectedProfileConfig } from "@/dojo/dojoConfig";

// The permit bundle registered in the `setup` contract (see setup.cairo
// "create bundle 0"). Purchasing it mints permit_token(s) to the buyer.
const PERMIT_BUNDLE_ID = 0;

// The `setup` system acts as the bundle registry for openBundle.
const REGISTRY_ADDRESS = selectedProfileConfig.contractAddresses.setup;

/**
 * Returns a callback that opens the Controller's bundle (starterpack) flow for
 * the permit bundle. On a completed purchase the cached permit count is
 * invalidated so the UI refetches the buyer's new balance.
 */
export function useOpenBundle() {
	const { connector } = useAccount();
	const queryClient = useQueryClient();

	return useCallback(() => {
		const controller = (connector as ControllerConnector | undefined)
			?.controller;
		if (!controller) return;

		// console.log(`>> REGISTRY`, REGISTRY_ADDRESS);

		controller.openBundle(PERMIT_BUNDLE_ID, REGISTRY_ADDRESS, {
			onPurchaseComplete: () => {
				queryClient.invalidateQueries({ queryKey: ["permit-count"] });
			},
		});
	}, [connector, queryClient]);
}
